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

package loom.modestmaps 
{
    /**
     * Loom Modest Maps Helper.
     *
     */


    /**
     * Static native class for helping with optimal Modest Maps logic.
     */
    public native class ModestMaps 
    {
        /**
         * Returns the key for the tile given it's coordinates
         *
         *  @param col Column of the tile
         *  @param row Row of the tile
         *  @param zoom Zoom of the tile
         */
        public static native function tileKey(col:int, row:int, zoom:int):String;
    }
}