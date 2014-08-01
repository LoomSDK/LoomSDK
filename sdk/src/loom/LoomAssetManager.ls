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
     * Called when the pending asset update count changes during streaming of
     * live assets.
     *
     * @param count How many asset updates are pending?
     */
    delegate PendingAssetUpdateCountDelegate(count:int);

    /**
     * Asset handling interface.
     *
     * The low level asset manager handles streaming, loading, and 
     * decompressing files as needed, but it can be useful to manage it from
     * LoomScript.
     */
    public native class LoomAssetManager
    {
        /**
         * How many asset updates are left to stream?
         */
        public static native function pendingUpdateCount():int;

        /**
         * Preload a give asset; useful to prevent loading hitches later.
         */
        public static native function preload(filename:String):void;

        /**
         * Forcibly unload the requested asset.
         */
        public static native function flush(filename:String):void;

        /**
         * Forcibly unload all assets.
         */
        public static native function flushAll():void;

        /**
         * True when connected to the asset manager.
         */
        public static native function isConnected():Boolean;

        /**
         * Called when the pending asset update count changes.
         */
        public static native var pendingCountChange:PendingAssetUpdateCountDelegate;
    }
}