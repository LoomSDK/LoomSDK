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

package system.platform {

    /**
     * Delegate for receiving button events.
     * @param button The index of the button.
     * @param state True for pressed, false for released.
     */
    delegate GamePadButtonDelegate(button:int, state:Boolean):void;

    /**
     * Delegate for receiving hat events.
     * @param hat The index of the hat (directional pad).
     * @param state See constants for hat positions in Gamepad.
     */
    delegate GamePadHatDelegate(hat:int, state:int):void;

    /**
     * Delegate for receiving axis events.
     * @param axis The index of the axis.
     * @param state The normalized state of the gamepad axis (-1 to 1).
     * Note that some gamepads return only a range of 0 - 1 for a given axis.
     */
    delegate GamePadAxisDelegate(axis:int, state:float):void;

    /**
     * The Gamepad class provides cross platform access to gamepad controllers.
     * It is currently supported on the Windows and OUYA platforms.
     */
    [Native(managed)]
    final public native class Gamepad 
    {

        // Constants for hat (dpad) positions.
        
        public static const HAT_CENTERED = 0;
        public static const HAT_UP = 1;
        public static const HAT_RIGHT = 2;
        public static const HAT_DOWN = 4;
        public static const HAT_LEFT = 8;
        public static const HAT_RIGHTUP = 3;
        public static const HAT_RIGHTDOWN = 6;
        public static const HAT_LEFTUP = 9;
        public static const HAT_LEFTDOWN  = 12;
        
        
        // Delegates for event processing.
        
        /**
         * Delegate called when a button is pressed or released.
         */
        public var buttonEvent:GamePadButtonDelegate;
        
        /**
         * Delegate called when the direction of a hat (dpad) changes.
         */
        public var hatEvent:GamePadHatDelegate;
        
        /**
         * Delegate called when there's a change on an axis.
         */
        public var axisEvent:GamePadAxisDelegate;
        
        
        // Direct gamepad state access.
        
        /** Direct access to the button state. */
        public var buttons:Vector.<Boolean> = [];
        
        /** Direct access to the axis state. */
        public var axis:Vector.<Number> = [];
        
        /** Direct access to the hat (dpad) state. */
        public var hats:Vector.<Number> = [];
        
        
        // Metrics for this gamepad.
        
        /** The number of buttons on the gamepad. */
        public native var numButtons:Number;
        
        /** The number of axes on the gamepad. */
        public native var numAxis:Number;
        
        /** The number of hats on the gamepad. */
        public native var numHats:Number;
        
        
        /**
         *  Direct access to all gamepads enumerated on the system.
         */
        public static var gamepads:Vector.<Gamepad> = [];
        
        /**
         *  The number of gamepads available.
         */        
        public static native var numGamepads:Number;
        
        /**
         *  Retrieve the system name of the given gamepad.
         */
        public static native function getGamePadName(index:Number):String;        
        
        /**
         *  Initializes the system gamepads and opens them.
         *  This must be called before accessing any gamepad methods.
         */
        public static function initialize()
        {
            if (!_initialize())
                return;

            if (!numGamepads)
                return;

            for (var i = 0; i < numGamepads; i++)
            {
                var gamepad = open(i);
                gamepad.buttons.length = gamepad.numButtons;
                gamepad.axis.length = gamepad.numAxis;
                gamepad.hats.length = gamepad.numHats;
                gamepad.buttonState.length = gamepad.numButtons;
                gamepad.axisState.length = gamepad.numAxis;
                gamepad.hatState.length = gamepad.numHats;
                gamepads.pushSingle(gamepad);
            }
        }

        /**
         *  Gamepads are a polled device, update is called 
         *  to poll gamepad data, update state, and fire
         *  any attached event delegates.
         */
        public static function update() 
        {
            _update();

            for (var i = 0; i < numGamepads; i++)
            {
 
                var gamepad = gamepads[i];

                // handle state delegates
                var j = 0;
                var nstate = 0;
                var value = 0;
                for (j in gamepad.buttons)
                {
                    nstate = 0;
                    var down = gamepad.buttons[j];

                    nstate = (down && !gamepad.buttonState[j]) ? 1 : 0;
                    if (!nstate)
                        nstate = (!down && gamepad.buttonState[j]) ? 2 : 0;

                    gamepad.buttonState[j] = down;

                    // pressed
                    if (nstate == 1)
                        gamepad.buttonEvent(j, true);

                    // released
                    if (nstate == 2)
                        gamepad.buttonEvent(j, false);

                }

                for (j in gamepad.hats)
                {
                 
                    value = gamepad.hats[j];

                    if( value != gamepad.hatState[j] )
                    {
                        gamepad.hatState[j] = value;
                        gamepad.hatEvent(j, value);
                        
                    }

                }

                for (j in gamepad.axis)
                {
                 
                    value = gamepad.axis[j];

                    if( value != gamepad.axisState[j] )
                    {
                        gamepad.axisState[j] = value;
                        gamepad.axisEvent(j, value);
                    }

                }

            }
        }        
        
        
        // Privates
        
        private static native function _update():void;

        private var buttonState:Vector.<Boolean> = [];
        private var axisState:Vector.<Number> = [];
        private var hatState:Vector.<Number> = [];

        private static native function open(index:int):Gamepad;
        private static native function _initialize():Boolean;

    }

}

