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

package loom.platform 
{
    /**
     * Loom Mobile API.
     *
     * Loom provides various platform specific mobile functionality.
     * Note that not all of the items found here will be available 
     * on every mobile platform.
     *
     *  Custom URL Schemes:
     *
     * In order to use custom URL Scheme launching of your app, you must specify
     * a 'custom_url_scheme' inside of your loom.config file for the app such as:
     * "custom_url_scheme": "startmygame"
     * This will allow a url such as: "startmygame://?key=myData" to launch your app
     * as send Query data to it to be parsed
     * NOTE: Custom URL schemes need to be unique enough that another app on the same device
     * will not also use the same one as your.
     *
     */

    /**
     * Delegate used to register changes in a mobile sensor that come in the form of an XYZ triple
     *
     *  @param sensor MobileSensorType defining the sensor that the data is for
     *  @param x Value for the X of the triple
     *  @param y Value for the Y of the triple
     *  @param z Value for the Z of the triple
     */
    public delegate MobileSensorChangedTripleDelegate(sensor:MobileSensorType, x:Number, y:Number, z:Number):void;


    /**
     * The different types of mobile device sensors available
     */
    public enum MobileSensorType
    {
        /**
         * Sensor that measures the acceleration applied to the device.  
         * Changes in the sensor are sent to onSensorTripleChanged().
         */
        ///NOTE: Don't use Accelerometer for now...
        // Accelerometer = 0,

        /**
         * Sensor that measures the ambient magnetic field in the X, Y and Z axis in in micro-Tesla (uT).  
         * Changes in the sensor are sent to onSensorTripleChanged().
         */
        ///NOTE: Don't use Magnometer for now...
        // Magnometer = 1,

        /**
         * Sensor that meansures the rate of rotation around the device's local X, Y and Z axis in radians/second 
         * Changes in the sensor are sent to onSensorTripleChanged().
         */
        ///NOTE: Don't use Gyroscope for now...
        // Gyroscope = 2,

        /**
         * Sensor that measures the local rotation of the device *in it's currently set orientation* 
         * around the X (Screen-Horizontal Right), Y (Screen-Vertical Up), and Z axis (Screen-Out Up) 
         * in radians between -PI and PI
         * 
         * IMPORTANT NOTE: Some Android hardware has shown to return one or more of these values to be in 
         * the ranage of -PI/2 and PI/2.
         *
         * IMPORTANT NOTE #2: This is only reliable on hardware that has an Accelerometer / Magnometer combination, 
         * OR a Gyroscope.  However, the results can differ depending on which method the hardware uses.  
         * For instance, if a Magnometer is present, the Z rotation will alawys be in relation to Magnetic North 
         * in the World.  However, if there is only a Gyroscope present, Z will be in relation to the orientation 
         * of the device at application start time.  In addition, Gryoscope-only devices will not track the 
         * difference in Z rotation while this sensor has been disabled, so if you disable it manually and then 
         * enable later, you may need to account for this descrepency.
         *
         * Changes in the sensor are sent to onSensorTripleChanged().
         */
         Rotation = 3,

        /**
         * Sensor that measures the direction and magnitude of gravity in m/s^2.
         * Changes in the sensor are sent to onSensorTripleChanged().
         */
        Gravity = 4
    };


    /**
     * Static control class for accessing various Mobile specific functionality.
     */
    public native class Mobile 
    {
        /**
         * Tells the device to perform a brief vibration, if supported by the hardware.
         *
         * NOTES: 
         *
         * 1) If you are not using Loom CLI and you wish to use vibrate() on Android, 
         * you will manually need to add the "android.permission.VIBRATE" permission to 
         * the AndroidManifest.xml file.
         *
         * 2) If you are using Loom CLI and you wish to not include VIBRATE permissions
         * in your App, you can disable them by specifying "uses_vibrate": "false" in your
         * loom.config file.
         */
        public static native function vibrate():void;

        /**
         * Enables or disables the device's screen sleep timer. Useful for stopping 
         * the device screen from auto-locking during gameplay if the screen isn't touched.
         *
         *  @param sleep true to allow for the device to sleep as per its settings,
         *          false to disable device sleeping completely
         */
        public static native function allowScreenSleep(sleep:Boolean):void;

        /**
         * Shares the specified text to other applications (ie. Twitter, Facebook, Email) 
         * via the device's native sharing dialog
         *
         *  @param subject The Subject of the text to share, for certain applications 
         *          (ie. email). NOTE: Android Only!
         *  @param text Text to share to another application
         */
        public static native function shareText(subject:String, text:String):Boolean;

        /**
         * Checks whether or not the application was opened with a Custom URL launch
         *
         *  @return true if the application was opened via a Custom URL Scheme, false if not
         */
        public static native function wasOpenedViaCustomURL():Boolean;

        /**
         * Gets the the specified query key data from any custom scheme URL path 
         * that the application was launched with, or an Empty String if not found.
         *
         * Valid URLs are formatted as such:   myscheme://someHostOrNoHost/?key1=someData&key2=moreData
         *
         *  @param queryKey The key to search for in the URL query to return the data of
         *  @return Data string for the given query key, or "" one was not found
         */
        public static native function getOpenURLQueryData(queryKey:String):String;

        /**
         * Queries whether or not the specified sensor is supported on this device
         *
         *  @param type MobileSensorType value for the desired sensor
         *  @return Boolean Whether or not the sensor is supported
         */
        public static native function isSensorSupported(type:MobileSensorType):Boolean;

        /**
         * Queries whether or not the specified sensor is currently enabled
         *
         *  @param type MobileSensorType value for the desired sensor
         *  @return Boolean Whether or not the sensor is enabled
         */
        public static native function isSensorEnabled(type:MobileSensorType):Boolean;

        /**
         * Queries whether or not the specified sensor has received any data yet. 
         * Sensors can be faulty on some hardward, and at time, a sensor may be 
         * reported to be available but in fact it does not receive any data. It 
         * is wise to check this value to see if you are able to receive reliable 
         * data for the given sensor.
         *
         *  @param type MobileSensorType value for the desired sensor
         *  @return Boolean Whether or not the sensor has received any data to use
         */
        public static native function hasSensorReceivedData(type:MobileSensorType):Boolean;

        /**
         * Enables the specified sensor
         *
         *  @param type MobileSensorType value for the desired sensor
         *  @return Boolean Whether or not the sensor was enabled successfully
         */
        public static native function enableSensor(type:MobileSensorType):Boolean;

        /**
         * Disables the specified sensor
         *
         *  @param type MobileSensorType value for the desired sensor
         */
        public static native function disableSensor(type:MobileSensorType):void;

        /**
         * Called when the a sensor triple changes
         *
         *  @param x Value for the X of the triple
         *  @param y Value for the Y of the triple
         *  @param z Value for the Z of the triple
         */
        public static native var onSensorTripleChanged:MobileSensorChangedTripleDelegate;

        /**
         * Called when app has been opened via a Custom URL launch
         *
         */
        public static native var onOpenedViaCustomURL:NativeDelegate;
    }



    /**
     * Static control class for accessing Dolby Audio on complient Android devices
     */
    public native class DolbyAudio
    {
        /**
         * Constant representing the 'Music' Dolby Audio Profile
         */
        public static var MUSIC_PROFILE:String = "Music";

        /**
         * Constant representing the 'Movie' Dolby Audio Profile
         */
        public static var MOVIE_PROFILE:String = "Movie";

        /**
         * Constant representing the 'Game' Dolby Audio Profile
         */
        public static var GAME_PROFILE:String = "Game";

        /**
         * Constant representing the 'Void' Dolby Audio Profile
         */
        public static var VOICE_PROFILE:String = "Voice";

        /**
         * Indicates whether or not Dolby Audio is supported on the current platform
         */
        public static native var supported:Boolean;

        /**
         * Sets Dolby Audio processing status
         *
         *  @param enable Boolean indicating the status to set Dolby Audio processing to
         */
        public static native function setProcessingEnabled(enable:Boolean):void;

        /**
         * Queries whether or not Dolby Audio processing is enabled
         *
         *  @return Boolean Status of Dolby Audio processing
         */
        public static native function isProcessingEnabled():Boolean;

        /**
         * Sets Dolby Audio processing profile type
         *
         *  @param profileIndex Name of the processing profile to set as the active one for Dolby Audio.  Valid indices are obtaind through getNumProfile()
         *  @return Boolean Whether or not the profile is supported on this hardware
         */
        public static native function isProfileSupported(profile:String):Boolean;

        /**
         * Sets Dolby Audio processing profile type
         *
         *  @param profileIndex Name of the processing profile to set as the active one for Dolby Audio.  Valid indices are obtaind through getNumProfile()
         *  @return Boolean Whether or not the profile was set properly.  Possibly false if this profile isn't supported and the hardware.
         */
        public static native function setProfile(profile:String):Boolean;

        /**
         * Queries the currently selected Dolby Audio processing profile
         *
         *  @return String Name of the currently selected Dolby Audio processing profile
         */
        public static native function getSelectedProfile():String;
    }    
}