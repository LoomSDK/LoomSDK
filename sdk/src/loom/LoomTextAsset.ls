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
     * Called when a LoomTextAsset has finished loading or has been updated
     * by live editing.
     */
    delegate LoomTextAssetUpdateDelegate(path:String, contents:String);

    /**
     * An asset loaded via Loom's asset system.
     *
     * Loom's asset system supports live reload. LoomTextAsset is designed to
     * make you write your code so that you automatically support live reload.
     *
     * To use LoomTextAsset, do the following:
     *
     * ~~~as3
     * var myAsset = LoomTextAsset.create("assets/myasset.txt");
     * myAsset.updateDelegate += function(path:String, contents:String):void { trace("Loaded " + path + "!")};
     * myAsset.load();
     * ~~~
     *
     * The handler on updateDelegate will be called when the asset is loaded via load(),
     * as well as any time the asset is updated via live reload.
     */
    public native class LoomTextAsset
    {
        /**
         * Create a new LoomTextAsset representing the requested path.
         */
        public static native function create(path:String):LoomTextAsset;

        /**
         * Initiate loading of the asset. Make sure to assign a callback to
         * updateDelegate before you call this! Loading may not be synchronous.
         */
        public native function load():void;

        /**
         * Called when the asset is loaded, and any time it changes.
         *
         * Parameters are a String containing the path and a String containing
         * the contents of the file.
         */
        public native var updateDelegate:LoomTextAssetUpdateDelegate;
    }
}
