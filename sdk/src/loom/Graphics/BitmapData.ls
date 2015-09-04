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

package loom.graphics
{
/**
 * BitmapData is an utility class for loading and comparing image data.
 *
 * This should not be used for general use, it's meant to be used in tests.
 * The performance of this class may not be the greatest, do not use in
 * performance critical code.
 */
[Native]
public native class BitmapData
{
    /**
      * Releases resources used by this object.
      */
    public function dispose():void
    {
        deleteNative();
    }

    // Saves the current data into an asset. This is meant to be used to Save
    // the results of diff()
    public native function save(path:String):void;

    // Loads the object from an asset.
    public static native function fromAsset(name:String):BitmapData;

    // Loads the object from the current framebuffer (screenshot)
    public static native function fromFramebuffer():BitmapData;

    // Compares two images. Returns a number between 0 and 1, where that value is
    // the ratio of equal pixels. If the size of the two images is not equal, 0 is returned.
    public static native function compare(a:BitmapData, b:BitmapData):Number

    // Returns a new object where each pixel has been substracted between a and b.
    public static native function diff(a:BitmapData, b:BitmapData):BitmapData;
}
}
