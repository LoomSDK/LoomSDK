/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom.Application;
    
    [ExcludeClass]
    public final class ValidationQueue
    {
        /**
         * Constructor.
         */
        public function ValidationQueue()
        {
            Application.ticks += process;
        }

        private var _isValidating:Boolean = false;

        /**
         * If true, the queue is currently validating.
         */
        public function get isValidating():Boolean
        {
            return this._isValidating;
        }

        private var _delayedQueue:Vector.<IFeathersControl> = new Vector.<IFeathersControl>[];
        private var _queue:Vector.<IFeathersControl> = new Vector.<IFeathersControl>[];

        /**
         * @private
         * Adds a control to the queue.
         */
        public function addControl(control:IFeathersControl, delayIfValidating:Boolean):void
        {
            const currentQueue:Vector.<IFeathersControl> = (this._isValidating && delayIfValidating) ? this._delayedQueue : this._queue;
            const queueLength:int = currentQueue.length;
            const containerControl:DisplayObjectContainer = control as DisplayObjectContainer;
            for(var i:int = 0; i < queueLength; i++)
            {
                if(currentQueue[i].nativeDeleted())
                    continue;

                var item:DisplayObject = DisplayObject(currentQueue[i]);
                if((control as DisplayObject) == item && currentQueue == this._queue)
                {
                    //already queued
                    return;
                }
                if(containerControl && containerControl.contains(item))
                {
                    break;
                }
            }
            currentQueue.splice(i, 0, control);
        }

        /**
         * @private
         */
        public function process():void
        {
            this._isValidating = true;
            while(this._queue.length > 0)
            {
                var item:IFeathersControl = _queue.shift();
                if(item.nativeDeleted())
                    continue;
                item.validate();
            }
            const temp:Vector.<IFeathersControl> = this._queue;
            this._queue = this._delayedQueue;
            this._delayedQueue = temp;
            this._isValidating = false;
        }
    }
}
