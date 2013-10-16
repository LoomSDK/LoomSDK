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

package loom
{

    /**
     * Event types for various generic application events. There are many
     * low-bandwidth events which need to be processed; rather than exposing
     * strict APIs, we have a simple and flexible event bus. Use these with
     * Application.fireGenericEvent and Application.event.
     */
    public static class ApplicationEvents
    {
        /**
         * Fired when the simulator menu is used; payload is "nextRes" or "prevRes".
         */
        public static var SIMULATOR:String = "simulator";

        /**
         * Fire to show native Camera UI. No payload.
         */
        public static var CAMERA_REQUEST:String = "cameraRequest";

        /**
         * Fired when native Camera UI finished; payload is the path to the saved camera image.
         */
        public static var CAMERA_SUCCESS:String = "cameraSuccess";

        /**
         * Fired when native Camera UI has failed; payload is an error message.
         */
        public static var CAMERA_FAIL:String = "cameraFail";

        /**
         * Fired when the soft keyboard (IME) becomes visible. Payload is the new 
         * visible height of the screen. (ie, if the screen is 1024px high and the
         * keyboard takes up 200px, you are passed 824px when the keyboard becomes
         * visible and 1024px when the keyboard goes away.)
         */
        public static var KEYBOARD_RESIZE:String = "keyboardResize";

        /**
         * Fired when the soft keyboard (IME) becomes visible.
         */
        public static var KEYBOARD_SHOW:String = "keyboardShow";

        /**
         * Fired when the soft keyboard (IME) is hidden by the user or the system
         */
        public static var KEYBOARD_HIDE:String = "keyboardHide";


    }

}
