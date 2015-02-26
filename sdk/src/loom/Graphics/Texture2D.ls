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
     * Called when a TextureInfo's backing texture is updated with new dimensions.
     */
    delegate TextureInfoUpdateDelegate(newWidth:int, newHeight:int);

    /**
     * Representation of native low level texture.
     */
    public native class TextureInfo
    {
        /**
         * Width of the texture in pixels.
         */
        public native var width:Number;

        /**
         * Height of the texture in pixels.
         */
        public native var height:Number;

        /**
         *  None/Nearest Neighbor = 0, Bilinear = 1
         *  See @TextureSmoothing for more details
         */        
        public native var smoothing:int;

        /**
         *  Repeat = 0, Mirror = 1, Clamp = 2. Default is Clamp.
         *  See @TextureWrap for more details
         */        
        public native var wrapU:int;

        /**
         *  Repeat = 0, Mirror = 1, Clamp = 2. Default is Clamp.
         *  See @TextureWrap for more details
         */        
        public native var wrapV:int;

        /**
         * ID identifying native side existence of this texture.
         */
        public native var id:int;

        /**
         * Fired when the texture is reloaded due to the backing asset changing.
         */
        public native var update:TextureInfoUpdateDelegate;
    }

    /**
     * Used in Texture2D.imageScaleProgress to report progress on scaling
     * operations.
     *
     * @param path The output path of the file being resampled.
     * @param progress Scalar from 0 .. 1 indicating completion of operation. 
     *        You will always be called with progress == 1.0 at the end.
     */
    delegate ResampleEventDelegate(path:String, progress:Number);

    /**
     * Interface for managing native texture state.
     */
    public static class Texture2D
    {
        /**
         * Create a new TextureInfo instance describing the requested asset loaded
         * as a Texture2D.
         */
        public static native function initFromAsset(path:string):TextureInfo;
        
        /**
         * Create a new TextureInfo instance describing the requested asset loaded
         * as a Texture2D from the provided ByteArray.
         */
        public static native function initFromBytes(bytes:ByteArray):TextureInfo;

        /**
         * Given the native id from a TextureInfo, dispose the specified texture. This
         * frees the GPU backing store and unloads the texture from memory.
         */
        public static native function dispose(nativeID:int);

        /**
         * Take an image from disk and resize it into the specified file. It performs
         * the resize in a background thread; add a function to the imageScaleProgress
         * delegate to get callbacks on progress. You will always get a callback with
         * progress == 1.0 when the image completes resampling. Note a new thread is
         * launched for each call to this method and too many will oversubscribe the
         * hardware and take much longer than if you staged them.
         *
         * Images are loaded via the asset system, but written as normal files; not all
         * paths are writable on all platforms.
         *
         * This method tries to do the resize with minimal memory footprint but large
         * images may still consume 20-40mb in RAM!
         *
         * @param outPath Path to which to write resized image.
         * @param inPath Image to load for processing.
         * @param outWidth The desired width of the output image.
         * @param outHeight The desired height of the output image.
         * @param preserveAspect Preserve the aspect ratio of the source image, fitting
         *        within the outWidth/outHeight dimensions.
         * @param skipPreload If true, then don't preload the image after it 
         *        has been resized. This is helpful if you don't plan on loading it, ie, 
         *        you just want to upload it somewhere.
         */
        public static native function scaleImageOnDisk(outPath:String, inPath:String, outWidth:int, outHeight:int, preserveAspect:Boolean, skipPreload:Boolean = false):void;

        /**
         * Takes any pending reports from scaling operations and fire them on the
         * imageScaleProgress delegate.
         */
        public static native function pollScaling();

        /**
         * Called when you call pollScaling with any progress reports from
         * scaling operations.
         */
        public static native var imageScaleProgress:ResampleEventDelegate;
    }

}