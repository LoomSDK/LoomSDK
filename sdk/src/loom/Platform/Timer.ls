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
 * Called when a Timer fires various events (start, complete, stop, pause).
 */
public delegate TimerCallback(timer:Timer):void;

/**
 * Simple self-contained timer class that fires events as time passes.
 */
class Timer 
{
    //_________________________________________________
    //  Constructor
    //_________________________________________________

    /** 
     * Create a timer with an optional starting delay.
     */
    public function Timer(delay:Number = 0.0)
    {
        _delay = delay;
    }

    //_________________________________________________
    //  Public Properties
    //_________________________________________________
    public function get delay():Number
    {
        return _delay;
    }

    public function set delay(value:Number):void
    {
        _delay = value;
    }

    public function get elapsed():Number
    {
        return _elapsed;
    }

    public function get repeats():Boolean
    {
        return _repeats;
    }

    public function set repeats(value:Boolean):void
    {
        _repeats = value;
    }

    public function get currentCount():int
    {
        return _currentCount;
    }

    public function set currentCount(value:int):void
    {
        _currentCount = value;
    }

    public function get running():Boolean
    {
        return _running;
    }

    //_________________________________________________
    //  Public Functions
    //_________________________________________________
    /**
     * Starts the timer, will call the onStart() delegate
     * on this Timer instance and add it to the list of 
     * timer objects.
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

    public function reset():void
    {
        start();
    }

    /**
     * Stops the Timer and resets the elapsed time back
     * to zero. Will call the onStop() delegate on this
     * Timer instance and remove it from the list of timer
     * objects.
     */
    public function stop():void
    {
        var wasRunning = _running;

        // remove the update function from the ticks
        Application.ticks -= update;
        _elapsed = 0;
        _lastTickTime = -1;
        _running = false;

        if (wasRunning)
            onStop(this);
    }

    /**
     * Pauses the Timer. Will call the onPause() delegate on this
     * Timer instance and remove it from the list of timer
     * objects.
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
     * Plays a timer after a pause.
     */
    public function play():void
    {
        Application.ticks += update;
        _running = true;
    }

    //_________________________________________________
    //  Delegate Members
    //_________________________________________________

    /**
     * Called when the timer starts.
     */
    public var onStart:TimerCallback;

    /**
     * Called when the timer fires.
     */
    public var onComplete:TimerCallback;

    /**
     * Called when the timer stops.
     */
    public var onStop:TimerCallback;

    /**
     * Called when the timer is paused.
     */
    public var onPause:TimerCallback;

    //_________________________________________________
    //  Protected Properties
    //_________________________________________________
    protected var _delay:Number = 0;
    protected var _elapsed:Number = 0;
    protected var _lastTickTime:Number = -1;
    protected var _repeats:Boolean = false;
    protected var _currentCount:int = 0;
    protected var _running:Boolean = false;

    //_________________________________________________
    //  Protected Functions
    //_________________________________________________
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