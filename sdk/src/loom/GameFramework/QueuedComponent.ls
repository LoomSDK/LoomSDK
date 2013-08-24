/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package loom.gameframework
{
    /**
     * Base class for components which want to use think notifications.
     * 
     * "Think notifications" allow a component to specify a time and
     * callback function which should be called back at that time. In this
     * way you can easily build complex behavior (by changing which callback
     * you pass) which is also efficient (because it is only called when 
     * needed, not every tick/frame). It is also light on the GC because
     * no allocations are required beyond the initial allocation of the
     * ThinkingComponent.
     */
    public class QueuedComponent extends LoomComponent implements IQueued
    {
        protected var _nextThinkTime:int;
        protected var _nextThinkCallback:Function;
        
        [Inject]
        public var timeManager:TimeManager;
        
        /**
         * Schedule the next time this component should think. 
         * @param nextCallback Function to be executed.
         * @param timeTillThink Time in ms from now at which to execute the function (approximately).
         */
        public function think(nextCallback:Function, timeTillThink:int):void
        {
            Debug.assert(timeManager, "think called before a timeManager was assigned. Are you calling it before the component was initialized?");
            _nextThinkTime = timeManager.virtualTime + timeTillThink;
            _nextThinkCallback = nextCallback;
            
            timeManager.queueObject(this);
        }
        
        public function unthink():void
        {
            timeManager.dequeueObject(this);
        }
        
        override protected function onRemove() : void
        {
            super.onRemove();
            
            // Do not allow us to be called back if we are still
            // in the queue.
            _nextThinkCallback = null;
        }
        
        public function get nextThinkTime():Number
        {
            return _nextThinkTime;
        }
        
        public function get nextThinkCallback():Function
        {
            return _nextThinkCallback;
        }
        
        public function get priority():int
        {
            return -_nextThinkTime;
        }
        
        public function set priority(value:int):void
        {
            Debug.assert(false, "Unimplemented.");
        }
    }   
}