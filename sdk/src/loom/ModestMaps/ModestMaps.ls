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
    import loom2d.math.Matrix;
    import loom2d.display.DisplayObject;


    /**
     * Static native class for helping with optimal Modest Maps logic.
     */
    public native class ModestMaps 
    {
        /**
         * Helper vars to get native calculations back into script.
         */
        public static native var LastCoordinateX:Number;
        public static native var LastCoordinateY:Number;
        public static native var ParentLoadCol:int;
        public static native var ParentLoadRow:int;
        public static native var ParentLoadChild:int;
        public static native var ParentLoadZoom:int;
        public static native var GridZoom:Number;
        public static native var GridTLx:Number;
        public static native var GridTLy:Number;
        public static native var GridBRx:Number;
        public static native var GridBRy:Number;
        public static native var GridTRx:Number;
        public static native var GridTRy:Number;
        public static native var GridBLx:Number;
        public static native var GridBLy:Number;
        public static native var GridCx:Number;
        public static native var GridCy:Number;


        /**
         * Returns the key for the tile given it's coordinates
         *
         *  @param col Column of the tile
         *  @param row Row of the tile
         *  @param zoom Zoom of the tile
         */
        public static native function tileKey(col:int, row:int, zoom:int):String;

        /**
         * Preps the ParentLoad helper vars for use and returns the name of the parent tile.
         */
        public static native function prepParentLoad(col:int, row:int, zoom:int, parentZoom:int):String;

        /**
         * Preps the LastCoordinate helper vars for use.
         */
        public static native function setLastCoordinate(col:Number, 
                                                        row:Number, 
                                                        zoom:Number, 
                                                        zoomLevel:Number, 
                                                        invTileWidth:Number, 
                                                        mat:Matrix, 
                                                        context:DisplayObject,
                                                        object:DisplayObject):void;
        /**
         * Preps the Grid helper vars for use.
         */
        public static native function setGridCoordinates(invMatrix:Matrix,
                                                            mapWidth:int, 
                                                            mapHeight:int, 
                                                            mapScale:Number):void;
        /**
         * Calculates and returns the inverse matrix for the TileGrid.
         */
        public static native function getGridInverseMatrix(worldMatrix:Matrix,
                                                            tileWidth:int, 
                                                            tileHeight:int, 
                                                            mapScale:Number,
                                                            resultMatrix:Matrix);

        /**
         * Gets the Microsoft Map Provider compatible zoom string.
         */
        public static native function getMSProviderZoomString(col:Number, row:Number, zoom:Number):String;
    }
}