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
   import loom.Application;
   import loom.utils.SimplePriorityQueue;
   import loom.utils.IPrioritizable;
   import loom.gameframework.Logger;
   import system.platform.Platform;
   import system.Profiler;

   /**
    * Called by TimeManager on every frame.
    */
   delegate FrameDelegate():void;

    /**
     * An object which will be called back at a specific time. This interface
     * contains all the storage needed for the queueing which the ProcessManager
     * performs, so that the queue has zero memory allocation overhead. 
     * 
     * @see ThinkingComponent
     */
    public interface IQueued extends IPrioritizable
    {
        /**
         * Time (in milliseconds) at which to process this object.
         */
        function get nextThinkTime():Number;
        
        /**
         * Callback to call at the nextThinkTime.
         */
        function get nextThinkCallback():Function;
    }

    /**
     * This interface should be implemented by objects that need to perform
     * actions every frame. This is most often things directly related to
     * rendering, such as advancing frames of a sprite animation. For performing
     * physics, processing AI, or other things of that nature, responding to
     * ticks would be more appropriate.
     * 
     * Along with implementing this interface, the object needs to be added
     * to the ProcessManager via the AddAnimatedObject method.
     * 
     * @see ProcessManager
     * @see ITickedObject
     */
    public interface IAnimated
    {
        /**
         * This method is called every frame by the ProcessManager on any objects
         * that have been added to it with the AddAnimatedObject method.
         * 
         * @param deltaTime The amount of time (in seconds) that has elapsed since
         * the last frame.
         * 
         * @see ProcessManager#AddAnimatedObject()
         */
        function onFrame():void;
    }

    /**
     * This interface should be implemented by objects that need to perform
     * actions every tick, such as moving, or processing collision. Performing
     * events every tick instead of every frame will give more consistent and
     * correct results. However, things related to rendering or animation should
     * happen every frame so the visual result appears smooth.
     * 
     * Along with implementing this interface, the object needs to be added
     * to the ProcessManager via the addTickedObject method.
     * 
     * @see TimeManager
     * @see IAnimated
     */
    public interface ITicked
    {
        /**
         * This method is called every tick by the TimeManager on any objects
         * that have been added to it with the addTickedObject method.
         * 
         * @see ProcessManager#AddTickedObject()
         */
        function onTick():void;
    }

    /**
     * Internal class for TimeManager
     * @private
     */
   class ProcessObject
   {
      public var profilerKey:String = null;
      public var listener:Object = null;
      public var listenerAnimated:IAnimated = null;
      public var listenerTicked:ITicked = null;
      public var priority:Number = 0.0;
   }

    /**
     * Internal class for TimeManager
     * @private
     */
   class DeferredMethod
   {
      public var method:Function = null;
      public var args:Vector.<Object> = null;
   }

    /**
     * Helper class for internal use by ProcessManager. This is used to 
     * track scheduled callbacks from schedule().
     *
     * @private
     */
    class ScheduleEntry implements IPrioritizable
    {
        public var dueTime:Number = 0.0;
        public var thisObject:Object = null;
        public var callback:Function = null;
        public var arguments:Vector.<Object> = null;
        
        public function get priority():int
        {
            return -dueTime;
        }
        
        public function set priority(value:int):void
        {
            Debug.assert(false, "Unimplemented.");
        }
    }

    /**
     * The process manager manages all time related functionality in the engine.
     * It provides mechanisms for performing actions every frame, every tick, or
     * at a specific time in the future.
     * 
     * A tick happens at a set interval defined by the TICKS_PER_SECOND constant.
     * Using ticks for various tasks that need to happen repeatedly instead of
     * performing those tasks every frame results in much more consistent output.
     * However, for animation related tasks, frame events should be used so the
     * display remains smooth.
     * 
     * @see ITickedObject
     * @see IAnimatedObject
     */
   class TimeManager implements ILoomManager
   {

        /**
         * If true, disables warnings about losing ticks.
         */
        public var disableSlowWarning:Boolean = true;
        
        /**
         * The number of ticks that will happen every second.
         */
        public const TICKS_PER_SECOND:int = 60;
        
        /**
         * The rate at which ticks are fired, in seconds.
         */
        public const TICK_RATE:Number = 1.0 / TICKS_PER_SECOND;
        
        /**
         * The rate at which ticks are fired, in milliseconds.
         */
        public const TICK_RATE_MS:Number = TICK_RATE * 1000;
        
        /**
         * The maximum number of ticks that can be processed in a frame.
         * 
         * In some cases, a single frame can take an extremely long amount of
         * time. If several ticks then need to be processed, a game can
         * quickly get in a state where it has so many ticks to process
         * it can never catch up. This is known as a death spiral.
         * 
         * To prevent this we have a safety limit. Time is dropped so the
         * system can catch up in extraordinary cases. If your game is just
         * slow, then you will see that the ProcessManager can never catch up
         * and you will constantly get the "too many ticks per frame" warning,
         * if you have disableSlowWarning set to true.
         */
        public const MAX_TICKS_PER_FRAME:int = 2;
        
        /**
         * The scale at which time advances. If this is set to 2, the game
         * will play twice as fast. A value of 0.5 will run the
         * game at half speed. A value of 1 is normal.
         */
        public function get timeScale():Number
        {
            return _timeScale;
        }
        
        /**
         * @private
         */
        public function set timeScale(value:Number):void
        {
            _timeScale = value;
        }
        
        /**
         * TweenMax uses timeScale as a config property, so by also having a
         * capitalized version, we can tween TimeScale instead and get along 
         * just fine.
         */
        public function set TimeScale(value:Number):void
        {
            timeScale = value;
        }
        
        /**
         * @private
         */ 
        public function get TimeScale():Number
        {
            return timeScale;
        }
        
        /**
         * Used to determine how far we are between ticks. 0.0 at the start of a tick, and
         * 1.0 at the end. Useful for smoothly interpolating visual elements.
         */
        public function get interpolationFactor():Number
        {
            return _interpolationFactor;
        }
        
        /**
         * The amount of time that has been processed by the process manager. This does
         * take the time scale into account. Time is in milliseconds.
         */
        public function get virtualTime():Number
        {
            return _virtualTime;
        }
        
        /**
         * Current time reported by getTimer(), updated every frame. Use this to avoid
         * costly calls to getTimer(), or if you want a unique number representing the
         * current frame.
         */
        public function get platformTime():Number
        {
            return _platformTime;
        }
        
        /**
         * Amount of time that has elapsed since the previous frame, in Milliseconds.
         */
        public function get deltaTimeMS():Number
        {
            return _deltaTimeMS;
        }

        /**
         * Amount of time that has elapsed since the previous frame, in Seconds.
         */
        public function get deltaTime():Number
        {
            return _deltaTime;
        }

        /**
         * Integer identifying this frame. Incremented by one for every frame.
         */
        public function get frameCounter():int
        {
            return _frameCounter;
        }
        
        public function initialize():void
        {
            if(!started)
                start();
        }
        
        public function destroy():void
        {
            if(started)
                stop();
        }
        
        /**
         * Starts the process manager. This is automatically called when the first object
         * is added to the process manager. If the manager is stopped manually, then this
         * will have to be called to restart it.
         */
        public function start():void
        {
            if (started)
            {
                Logger.warn(this, "start", "The ProcessManager is already started.");
                return;
            }
            
            lastTime = -1.0;
            elapsed = 0.0;
            
            Application.ticks += process;
            started = true;
        }
        
        /**
         * Stops the process manager. This is automatically called when the last object
         * is removed from the process manager, but can also be called manually to, for
         * example, pause the game.
         */
        public function stop():void
        {
            if (!started)
            {
                Logger.warn(this, "stop", "The TimeManager isn't started.");
                return;
            }
            
            Application.ticks -= process;
            started = false;
        }
        
        /**
         * Returns true if the process manager is advancing.
         */ 
        public function get isTicking():Boolean
        {
            return started;
        }
        
        /**
         * Schedules a function to be called at a specified time in the future.
         * 
         * @param delay The number of milliseconds in the future to call the function.
         * @param thisObject The object on which the function should be called. This
         * becomes the 'this' variable in the function.
         * @param callback The function to call.
         * @param arguments The arguments to pass to the function when it is called.
         */
        public function schedule(delay:Number, thisObject:Object, callback:Function, ...arguments):void
        {
            if (!started)
                start();
            
            var scheduleEntry:ScheduleEntry = new ScheduleEntry();
            scheduleEntry.dueTime = _virtualTime + delay;
            scheduleEntry.thisObject = thisObject;
            scheduleEntry.callback = callback;
            scheduleEntry.arguments = arguments;
            
            thinkHeap.enqueue(scheduleEntry);
        }
        
        /**
         * Registers an object to receive frame callbacks.
         * 
         * @param object The object to add.
         * @param priority The priority of the object. Objects added with higher priorities
         * will receive their callback before objects with lower priorities. The highest
         * (first-processed) priority is Number.MAX_VALUE. The lowest (last-processed) 
         * priority is -Number.MAX_VALUE.
         */
        public function addAnimatedObject(object:IAnimated, priority:Number = 0.0):void
        {
            addObject(object, priority, animatedObjects);
        }
        
        /**
         * Registers an object to receive tick callbacks.
         * 
         * @param object The object to add.
         * @param priority The priority of the object. Objects added with higher priorities
         * will receive their callback before objects with lower priorities. The highest
         * (first-processed) priority is Number.MAX_VALUE. The lowest (last-processed) 
         * priority is -Number.MAX_VALUE.
         */
        public function addTickedObject(object:ITicked, priority:Number = 0.0):void
        {
            addObject(object, priority, tickedObjects);
        }
        
        /**
         * Queue an IQueuedObject for callback. This is a very cheap way to have a callback
         * happen on an object. If an object is queued when it is already in the queue, it
         * is removed, then added.
         */
        public function queueObject(object:IQueued):void
        {
            // Assert if this is in the past.
            if(object.nextThinkTime < _virtualTime)
                Debug.assert(false, "Tried to queue something into the past, but no flux capacitor is present!");
            
            if(object.nextThinkTime >= _virtualTime && thinkHeap.contains(object))
                thinkHeap.remove(object);
            
            if(!thinkHeap.enqueue(object))
                Logger.print(this, "Thinking queue length maxed out!");
        }
        
        /**
         * Remove an IQueuedObject for consideration for callback. No error results if it
         * was not in the queue.
         */
        public function dequeueObject(object:IQueued):void
        {
            if(thinkHeap.contains(object))
                thinkHeap.remove(object);
        }
        
        /**
         * Unregisters an object from receiving frame callbacks.
         * 
         * @param object The object to remove.
         */
        public function removeAnimatedObject(object:IAnimated):void
        {
            removeObject(object, animatedObjects);
        }
        
        /**
         * Unregisters an object from receiving tick callbacks.
         * 
         * @param object The object to remove.
         */
        public function removeTickedObject(object:ITicked):void
        {
            removeObject(object, tickedObjects);
        }
        
        public function get msPerTick():Number
        {
            return TICK_RATE_MS;
        }
        
        /**
         * Forces the process manager to advance by the specified amount. This should
         * only be used for unit testing.
         * 
         * @param amount The amount of time to simulate.
         */
        public function testAdvance(amount:Number):void
        {
            advance(amount * _timeScale, true);
        }
        
        /**
         * Forces the process manager to seek its virtualTime by the specified amount.
         * This moves virtualTime without calling advance and without processing ticks or frames.
         * WARNING: USE WITH CAUTION AND ONLY IF YOU REALLY KNOW THE CONSEQUENCES.
         */
        public function seek(amount:Number):void
        {
            _virtualTime += amount;
        }
        
        /**
         * Deferred function callback - called back at start of processing for next frame. Useful
         * any time you are going to do setTimeout(someFunc, 1) - it's a lot cheaper to do it 
         * this way.
         * @param method Function to call.
         * @param args Any arguments.
         */
        public function callLater(method:Function, args:Vector.<Object> = null):void
        {
            var dm:DeferredMethod = new DeferredMethod();
            dm.method = method;
            dm.args = args;
            deferredMethodQueue.push(dm);
        }
        
        /**
         * @return How many objects are depending on the TimeManager right now?
         */
        private function get listenerCount():int
        {
            return tickedObjects.length + animatedObjects.length;
        }
        
        /**
         * Internal function add an object to a list with a given priority.
         * @param object Object to add.
         * @param priority Priority; this is used to keep the list ordered.
         * @param list List to add to.
         */
        private function addObject(object:Object, priority:Number, list:Vector.<ProcessObject>):void
        {
            // If we are in a tick, defer the add.
            if(duringAdvance)
            {
                callLater(addObject, [ object, priority, list]);
                return;
            }
            
            if (!started)
                start();
            
            var position:int = -1;
            for (var i:int = 0; i < list.length; i++)
            {
                if(!list[i])
                    continue;
                
                if (list[i].listener == object)
                {
                    Logger.warn(object, "AddProcessObject", "This object has already been added to the process manager.");
                    return;
                }
                
                if (list[i].priority < priority)
                {
                    position = i;
                    break;
                }
            }
            
            var processObject:ProcessObject = new ProcessObject();
            processObject.listener = object;
            processObject.priority = priority;
            if(object is IAnimated)
                processObject.listenerAnimated = object as IAnimated;
            if(object is ITicked)
                processObject.listenerTicked = object as ITicked;
            processObject.profilerKey = object.getType().getFullName();
            
            if (position < 0 || position >= list.length)
                list.push(processObject);
            else
                list.splice(position, 0, processObject);
        }
        
        /**
         * Peer to addObject; removes an object from a list. 
         * @param object Object to remove.
         * @param list List from which to remove.
         */
        private function removeObject(object:Object, list:Vector.<ProcessObject>):void
        {
            if (listenerCount == 1 && thinkHeap.size == 0)
                stop();
            
            for (var i:int = 0; i < list.length; i++)
            {
                if(!list[i])
                    continue;
                
                if (list[i].listener == object)
                {
                    if(duringAdvance)
                    {
                        list[i] = null;
                        needPurgeEmpty = true;
                    }
                    else
                    {
                        list.splice(i, 1);                        
                    }
                    
                    return;
                }
            }
            
            Logger.warn(object, "RemoveProcessObject", "This object has not been added to the process manager.");
        }
        
        /**
         * Main callback; this is called every frame and allows game logic to run. 
         */
        private function process():void
        {            
            // Track current time.
            var currentTime:Number = Platform.getTime();
            if (lastTime < 0)
            {
                lastTime = currentTime;
                return;
            }
                        
            // Bump the frame counter.
            _frameCounter++;
            
            // Calculate time since last frame and advance that much.
            var deltaTime:Number = (currentTime - lastTime) * _timeScale;
            advance(deltaTime);
            
            // Note new last time.
            lastTime = currentTime;
        }
        
        public function advance(deltaTime:Number, suppressSafety:Boolean = false):void
        {            
            // Update platform time, to avoid lots of costly calls to getTimer.
            _platformTime = Platform.getTime();

            // Update the delta time
            _deltaTimeMS = deltaTime;
            _deltaTime = _deltaTimeMS / 1000.0;
            
            // Note virtual time we started advancing from.
            var startTime:Number = _virtualTime;
            
            // Add time to the accumulator.
            elapsed += deltaTime;
            
            // Perform ticks, respecting tick caps.
            var tickCount:int = 0;
            //while (elapsed >= TICK_RATE_MS && (suppressSafety || tickCount < MAX_TICKS_PER_FRAME))
            //{
                fireTick();
                tickCount++;
            //}
            
            // Safety net - don't do more than a few ticks per frame to avoid death spirals.
            if (tickCount >= MAX_TICKS_PER_FRAME && !suppressSafety && !disableSlowWarning)
            {
                // By default, only show when profiling.
                //Logger.warn(this, "advance", "Exceeded maximum number of ticks for frame (" + elapsed.toFixed() + "ms dropped) .");
                Logger.warn(this, "advance", "Exceeded maximum number of ticks for frame (" + elapsed + "ms dropped) .");
            }
            
            // Make sure that we don't fall behind too far. This helps correct
            // for short-term drops in framerate as well as the scenario where
            // we are consistently running behind.
            elapsed = Math.clamp(elapsed, 0, 300);
            
            // Make sure we don't lose time to accumulation error.
            // Not sure this gains us anything, so disabling -- BJG
            //_virtualTime = startTime + deltaTime;
            
            // We process scheduled items again after tick processing to ensure between-tick schedules are hit
            // Commenting this out because it can cause too-often calling of callLater methods. -- BJG
            // processScheduledObjects();
            

            duringAdvance = true;
            _interpolationFactor = elapsed / TICK_RATE_MS;
            for(var i:int=0; i<animatedObjects.length; i++)
            {
                var animatedObject:ProcessObject = animatedObjects[i];
                if(!animatedObject)
                    continue;
                
                animatedObject.listenerAnimated.onFrame();
            }
            duringAdvance = false;
            
            // Purge the lists if needed.
            if(needPurgeEmpty)
            {
                needPurgeEmpty = false;
                                
                for(var j:int=0; j<animatedObjects.length; j++)
                {
                    if(animatedObjects[j])
                        continue;
                    
                    animatedObjects.splice(j, 1);
                    j--;
                }
                
                for(var k:int=0; k<tickedObjects.length; k++)
                {                    
                    if(tickedObjects[k])
                        continue;
                    
                    tickedObjects.splice(k, 1);
                    k--;
                }
                
            }
        }
        
        public function fireTick():void
        {
            // Ticks always happen on interpolation boundary.
            _interpolationFactor = 0.0;
            
            // Process pending events at this tick.
            // This is done in the loop to ensure the correct order of events.
            processScheduledObjects();
            
            duringAdvance = true;
            for(var j:int=0; j<tickedObjects.length; j++)
            {
                var object:ProcessObject = tickedObjects[j];
                if(!object)
                    continue;
                
                object.listenerTicked.onTick();

            }
            duringAdvance = false;
                        
            // Update virtual time by subtracting from accumulator.
            _virtualTime += TICK_RATE_MS;
            elapsed -= TICK_RATE_MS;            
        }
        
        private function processScheduledObjects():void
        {
            // Do any deferred methods.
            var oldDeferredMethodQueue:Vector.<DeferredMethod> = deferredMethodQueue;
            if(oldDeferredMethodQueue.length)
            {                
                // Put a new array in the queue to avoid getting into corrupted
                // state due to more calls being added.
                deferredMethodQueue = [];
                
                for(var j:int=0; j<oldDeferredMethodQueue.length; j++)
                {
                    var curDM:DeferredMethod = oldDeferredMethodQueue[j];
                    curDM.method.apply(null, curDM.args);
                }
                
                // Wipe the old array now we're done with it.
                oldDeferredMethodQueue.length = 0;
                
            }
            
            // Process any queued items.
            if(thinkHeap.size)
            {
                
                while(thinkHeap.size && thinkHeap.front.priority >= -_virtualTime)
                {
                    var itemRaw:IPrioritizable = thinkHeap.dequeue();
                    var qItem:IQueued = itemRaw as IQueued;
                    var sItem:ScheduleEntry = itemRaw as ScheduleEntry;
                    
                    var type:String = itemRaw.getType().getFullName();
                    
                    if(qItem)
                    {
                        // Check here to avoid else block that throws an error - empty callback
                        // means it unregistered.
                        if(qItem.nextThinkCallback != null)
                        {
                           // Review this in light of LOOM-315
                            qItem.nextThinkCallback.call();
                        }
                    }
                    else if(sItem && sItem.callback != null)
                    {
                       // Review this in light of LOOM-315
                       sItem.callback.apply(sItem.thisObject, sItem.arguments);
                    }
                    else
                    {
                        Debug.assert(false, "Unknown type found in thinkHeap.");
                    }
                    
                }
                
            }
        }
        /**
         * Dumps the contents of the thinking queue to the console.
         */ 
        public function printThinkingQueue():void
        {
/*            // Review based on LOOM-352
            //Logger.print(this, sprintf("%-11s%-80s%-3s", "Priority", "Class Name", "Has Owner"));         
            // Get the contents of the think heap as an array
            var queue:Vector.<Object> = thinkHeap.toArray();
            
            // traverse the think heap and print it to the console. 
            for(var i:int=0; i< queue.length(); ++i)
            {
                var item:IPrioritizable = queue[i];
                var component:LoomComponent = item as LoomComponent;
                var hasOwner:String = "no";
                if(component && component.owner)
                    hasOwner = "yes";
                // Review based on LOOM-352
                var queueEntry:String = "NYI"; //sprintf( "%-11s%-80s%-3s", item.priority, item.getType().getFullName(), hasOwner);
                Logger.print(TimeManager, queueEntry);
            }
            
            Logger.print(this, "There are " + queue.length() + " items in the queue."); */
        }
        
        protected var deferredMethodQueue:Vector.<DeferredMethod> = new Vector.<DeferredMethod>();
        protected var started:Boolean = false;
        protected var _virtualTime:int = 0;
        protected var _interpolationFactor:Number = 0.0;
        protected var _timeScale:Number = 1.0;
        protected var lastTime:int = -1;
        protected var elapsed:Number = 0.0;
        protected var animatedObjects:Vector.<ProcessObject> = new Vector.<ProcessObject>();
        protected var tickedObjects:Vector.<ProcessObject> = new Vector.<ProcessObject>;
        protected var needPurgeEmpty:Boolean = false;
        
        protected var _deltaTime:Number = 0;
        protected var _deltaTimeMS:Number = 0;

        protected var _platformTime:int = 0;

        protected var _frameCounter:int = 0;
        
        protected var duringAdvance:Boolean = false;
        
        protected var thinkHeap:SimplePriorityQueue = new SimplePriorityQueue(4096);
   }
}