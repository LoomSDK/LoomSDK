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

package loom.social 
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
         * Checks if Native Parse is active and ready for use
         *
         *  @return Whether or not the Native Parse API is currently active
         */
        public static native function isActive():Boolean;

        /**
         * Obtains the Parse Installation ID
         *
         *  @return the current installation ID, or and empty string if there was an error or Parse has not been initialized
         */
        public static native function getInstallationID():String;

        /**
         * Obtains the Parse Installation ObjectID
         *
         *  @return the current installation objectID, or an empty string if there was an error or Parse has not been initialized
         */
        public static native function getInstallationObjectID():String;

        /**
         * Sets the Parse Installation userId property
         *
         *  @param userId The new installation userID to set
         *  @return Whether or not the the userID was able to be updated
         */
        public static native function updateInstallationUserID(userId:String):Boolean;
    }


}