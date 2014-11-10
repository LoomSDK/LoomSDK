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
     *
     * NOTES: 
     *
     * 1) If you are not using Loom CLI and you wish to use the Camera on Android, 
     * you will manually need to add the "android.permission.CAMERA" permission, 
     * as well as the "android.hardware.camera" and "android.hardware.camera.autofocus" 
     * features to the AndroidManifest.xml file.
     *
     * 2) If you are using Loom CLI and you wish to not include CAMERA permissions or
     * features in your App, you can disable them by specifying "uses_camera": "false"
     * in your loom.config file.
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
         * Fire to save a photo to the device's library; payload is the path to the image to save.
         */
        public static var SAVE_TO_PHOTO_LIBARY:String = "saveToPhotoLibrary";

        /**
         * Fired when the device successfully saves an image to its photo lobrary; no payload.
         */
        public static var SAVE_TO_PHOTO_LIBARY_SUCCESS:String = "saveToPhotoLibrarySuccess";

        /**
         * Fired when the device fails to save an image to its photo lobrary. Payload is either
         * an ApplicationEventErrorType constant, or a localized description of the error
         * if a constant does not exist for it.
         */
        public static var SAVE_TO_PHOTO_LIBARY_FAIL:String = "saveToPhotoLibraryFail";

        /**
         * Fired when the soft keyboard (IME) becomes visible. Payload is the new 
         * visible height of the screen. (ie, if the screen is 1024px high and the
         * keyboard takes up 200px, you are passed 824px when the keyboard becomes
         * visible and 1024px when the keyboard goes away.)
         */
        public static var KEYBOARD_RESIZE:String = "keyboardResize";

        /**
         * On mobile devices, hide the status bar across the top of the screen.
         */
        public static var HIDE_STATUS_BAR:String = "hideStatusBar";

        /**
         * On mobile devices, show the status bar across the top of the screen.
         */
        public static var SHOW_STATUS_BAR:String = "showStatusBar";
    }

}
