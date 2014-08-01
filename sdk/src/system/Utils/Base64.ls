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


package system.utils
{

    /**
     * Utility for conversion to/from Base64.
     */
    public static native class Base64
    {
        /**
         * Convert binary data in a ByteArray to a Base64 encoded string.
         */
        public native static function encode(data:ByteArray):String;

        /**
         * Convert data from a Base64 string into the provided ByteArray.
         */
        public native static function decode(base64:String, data:ByteArray):void;
    }

}