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
    import loom.Application;

    /**
     * Delegate for receiving x,y,z accelerometer data.
     */
    delegate AccelerometerDelegate(x:Number, y:Number, z:Number);    

    /**
    * Class for managing accelerometer data.
    */
    public static class Accelerometer
    {
        /**
        * @private
        */
        [Deprecated(msg="Use isSupported instead")]
        public static function get enabled():Boolean
        {        
            //return Application.internalLayer.isAccelerometerEnabled();
            return false;
        }

        /**
        * @private
        */
        public static function set enabled(value:Boolean):void
        {
            //Application.internalLayer.setAccelerometerEnabled(value);
        }

        /**
        * The isSupported property is set to true if the accelerometer sensor is available 
        * on the device, otherwise it is set to false.
        */
        public static function get isSupported():Boolean
        {
            return enabled;
        }

        /**
        * Delegate which will be called with accelerometer x, y, z.
        */
        public static var accelerated:AccelerometerDelegate;

    }

}