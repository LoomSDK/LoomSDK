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
 * Identifiers for supported platforms.
 */
public enum PlatformType {
    WINDOWS = 1,
    OSX = 2,
    IOS = 3,
    ANDROID = 4,
    LINUX = 5
}

/**
 * Identifiers for display/device categories.
 */
public enum DisplayProfile {
    DESKTOP,
    SMALL,
    NORMAL,
    LARGE
}

/**
 * Query and control platform-specific state.
 */
class Platform 
{
   /*
    Return the current time in milliseconds since application start.
   */
   public static native function getTime():Number;

   /*
    Return the time in seconds since the Unix epoch.
   */
   public static native function getEpochTime():Number;

   /*
    Get the platform which we are currently running on.

    @see PlatformType
   */
   public static native function getPlatform():PlatformType;

   /*
    Get the device category which we are currently running on. This is the size
    of the screen, not pixel density - see getDPI() for that.

    @see DisplayProfile
   */
   public static native function getProfile():DisplayProfile;

   /*
    Return a best guess for the DPI of the current display.
   */
   public native static function getDPI():Number;

   /*
    Override the DPI reported by getDPI; this persists across restarts.
    */
   public native static function forceDPI(value:Number):void;

   /*
    Make the system sleep for the input number of milliseconds
    */
   public native static function sleep(sleepTime:int):void;

   public native static function isForcingDPI():Boolean;

   /*
    Opens the provided URL in the default system browser.
    Returns `true` if opened successfully.
    */
   public native static function openURL(url:String):Boolean;
}

}