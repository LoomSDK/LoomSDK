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
     * Loom Parse API.
     *
     * Loom provides access to the Parse API on mobile devices for social networking services.
     *
     */


    /**
     * Static control class for accessing the Parse API functionality
     */
    public native class Parse 
    {
        /**
         * Starts up the Parse API service
         *
         *  @param appID The Parse Application ID, obtained after creating your App on www.parse.com
         *  @param clientKey The Parse Client ID, obtained after creating your App on www.parse.com
         */
        public static native function startUp(appID:String, clientKey:String):Boolean;
    }
}