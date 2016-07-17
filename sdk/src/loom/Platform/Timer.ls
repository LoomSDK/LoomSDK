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

package loom.platform {

import system.platform.Platform;
import loom.Application;

/**
 *  Delegate signature for listeners of Timer events.
 *
 *  @param timer The Timer instance that triggered the event.
 */
public delegate TimerCallback(timer:Timer):void;

/**
 *  A Timer counts milliseconds and triggers delegates when it starts, completes, or is halted.
 *
 *  * Calling `start()` or `reset()` will call the `onStart` delegate
 *  * Calling `pause()` will call the `onPause` delegate
 *  * Calling `stop()` will call the `onStop` delegate
 *  * The `onComplete` delegate is called when the timer's elapsed time exceeds its `delay` value
 *
 *  By default, a Timer will not repeat; once started, it will run to completion,
 *  call the `onComplete` delegate, and be done.
 *
 *  Setting the `repeats` property to `true` will cause the timer to cycle until
 *  `stop()` is called.
 *
 *  The `currentCount` property keeps track of the number of cycles the timer has completed.
 *
 *  The snippet below shows how to instantiate and start a repeating timer instance,
 *  reacting to its `onComplete` event, which will fire approximately once per second:
 *
 *  ```as3
 *  private function onTimerComplete(timer:Timer):void
 *  {
 *     ⇥trace('the timer has completed ' +timer.currentCount +' cycles.')
 *     ⇥trace('the last cycle lasted ' +timer.elapsed +'ms.');
 *  }
 *
 *  var timer:Timer = new Timer(1000);
 *  timer.repeats = true;
 *  timer.onComplete = onTimerComplete;
 *  timer.start();
 *  ```
 */
class Timer
{
    /**
     *  Create a timer with an optional starting delay (in milliseconds).
     *
     *  The minimum duration is one application tick, approximately 1/60th of a second (16.6ms).
     */
    public function Timer(delay:Number = 0.0)
    {
        _delay = delay;
    }

    /**
     *  Retrieve the currently set duration for the timer (in milliseconds).
     *
     *  @return The currently set duration of the timer (in milliseconds).
     */
    public function get delay():Number
    {
        return _delay;
    }

    /**
     *  Set a duration for the timer (in milliseconds).
     *
     *  The minimum duration is one application tick, approximately 1/60th of a second (16.6ms).
     *
     *  @param value Duration in milliseconds between `onStart` and `onComplete` events.
     */
    public function set delay(value:Number):void
    {
        _delay = value;
    }

    /**
     *  Retrieve the number of milliseconds elapsed since the timer was started.
     *
     *  @return The number of milliseconds elapsed since the timer was started.
     */
    public function get elapsed():Number
    {
        return _elapsed;
    }


    /**
     *  Query whether the timer is set to repeat.
     *
     *  A repeating timer calls `onStart` immediately after `onComplete`.
     *
     *  @return `true` when the timer is set to repeat; `false` otherwise.
     */
    public function get repeats():Boolean
    {
        return _repeats;
    }

    /**
     *  Specify whether the timer should repeat.
     *
     *  A repeating timer calls `onStart` immediately after `onComplete`.
     *
     *  @param `true` to repeat; `false` to stop after completion.
     *
     *  @see #onStart
     *  @see #onComplete
     */
    public function set repeats(value:Boolean):void
    {
        _repeats = value;
    }

    /**
     *  Retrieve the number of full cycles the timer has completed.
     *
     *  @return The number of full cycles the timer has completed.
     */
    public function get currentCount():int
    {
        return _currentCount;
    }

    /**
     *  Override the timer's count of completed cycles.
     *
     *  On the next repeat, whatever value the timer has for `currentCount` will be incremented by 1.
     */
    public function set currentCount(value:int):void
    {
        _currentCount = value;
    }

    /**
     *  Query whether the timer is currently running.
     *
     *  A running timer will call the `onComplete` delegate when
     *  it finishes, and will start again if set to repeat.
     *
     *  @return `true` if the timer is currently running; `false` otherwise (paused or stopped).
     */
    public function get running():Boolean
    {
        return _running;
    }

    /**
     *  (Re-)start the timer.
     *
     *  Results in the `onStart` delegate being called.
     *
     *  If the timer was already running, it is stopped before being started again,
     *  resulting in the `onStop` delegate being called first.
     *
     *  @see #onStart
     */
    public function start():void
    {
        // ensure no update functions are left in the tick queue
        stop();

        // add the update function to the ticks
        Application.ticks += update;
        _elapsed = 0;

        _running = true;

        onStart(this);
    }

    /**
     *  (Re-)start the timer. This is an alias for `start()`.
     *
     *  @see #start()
     */
    public function reset():void
    {
        start();
    }

    /**
     *  Stop the timer.
     *
     *  Results in the `onStop` delegate being called.
     *
     *  A stopped timer has an elapsed time of zero and is not running.
     *
     *  @see #onStop
     */
    public function stop():void
    {
        // remove the update function from the ticks
        Application.ticks -= update;
        _elapsed = 0;
        _lastTickTime = -1;
        _running = false;

        onStop(this);
    }

    /**
     *  Pause the timer.
     *
     *  Results in the `onPause` delegate being called.
     *
     *  A paused timer is not running, but can be queried for elapsed time.
     *
     *  @see #onPause
     */
    public function pause():void
    {
        // remove the update function from the ticks
        Application.ticks -= update;

        _lastTickTime = -1;
        _running = false;

        onPause(this);
    }

    /**
     *  Resume a paused timer.
     *
     *  No delegate is called when a timer resumes.
     */
    public function play():void
    {
        Application.ticks += update;
        _running = true;
    }

    /**
     *  Called when the timer is started and when it repeats.
     *
     *  @see #start()
     *  @see #reset()
     */
    public var onStart:TimerCallback;

    /**
     *  Called when the timer completes a cycle of `delay` milliseconds.
     */
    public var onComplete:TimerCallback;

    /**
     *  Called when the timer is stopped.
     *
     *  @see #stop()
     */
    public var onStop:TimerCallback;

    /**
     *  Called when the timer is paused.
     *
     *  @see #pause()
     *  @see #play()
     */
    public var onPause:TimerCallback;

    protected var _delay:Number = 0;
    protected var _elapsed:Number = 0;
    protected var _lastTickTime:Number = -1;
    protected var _repeats:Boolean = false;
    protected var _currentCount:int = 0;
    protected var _running:Boolean = false;

    protected function update():void
    {
        var currentTime = Platform.getTime();

        // is this the first update?
        if(_lastTickTime == -1)
            _lastTickTime = currentTime;

        var delta:Number = currentTime - _lastTickTime;

        // clamp the delta to <= 500ms
        // note that when pausing the timer the _lastTickTime is set
        // to -1 which will avoid large deltas on resume
        if (delta > 500)
            delta = 500;

        _elapsed += delta;
        _lastTickTime = currentTime;

        if(_elapsed >= _delay)
        {
            Application.ticks -= update;

            onComplete(this);

            if(repeats)
            {
                currentCount++;
                start();
            }

        }
    }
}

}
