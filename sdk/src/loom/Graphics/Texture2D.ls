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
    import loom2d.display.DisplayObject;
    import loom2d.math.Matrix;
    /**
     * Called when a TextureInfo's backing texture is updated with new dimensions.
     */
    delegate TextureInfoUpdateDelegate(newWidth:int, newHeight:int);

    /**
     * For asynchronous loads, this is called when a TextureInfo's backing texture 
     * has completed loading.
     */
    delegate TextureInfoAsyncLoadCompleteDelegate();

    /**
     * Representation of native low level texture.
     */
    public native class TextureInfo
    {
        /**
         * Texture handle is currently busy loading and should not be used.
         */
        public static const HANDLE_LOADING:int    = 0xfffe;

        /**
         * Texture handle is invalid and should not be used.
         */
        public static const HANDLE_INVALID:int    = 0xffff;


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

        /**
         * For asynchronous loads, this is fired when the texture has completed loading.
         */
        public native var asyncLoadComplete:TextureInfoAsyncLoadCompleteDelegate;

        /**
         * Gets the native handle ID of the texture. Can be checked against HANDLE_LOADING 
         * or HANDLE_INVALID to see if it has been properly initialized yet.
         */
        public native function get handleID():int;

        /**
         * Gets the path that the backing asset was loaded from.
         */
        public native function get path():String;
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
     * Used in conjunction with Texture2D.initFromAssetAsync to pass through the loaded 
     * texture data once it has completed the asynchronous loading process.
     *
     * @param texInfo The newly created TextureInfo object for the loaded texture.
     */
    delegate AsyncLoadCompleteDelegate(texInfo:TextureInfo);

    /**
     * Interface for managing native texture state.
     */
    public static class Texture2D
    {
        /**
         * Blocking function to create a new TextureInfo instance describing the requested
         * asset loaded as a Texture2D.
         */
        public static native function initFromAsset(path:string):TextureInfo;
        
        /**
         * Blocking function used to create a new TextureInfo instance describing the requested 
         * asset loaded as a Texture2D from the provided ByteArray.  An optional unique name can
         * be specified if you wish the texture to take advantage of caching, otherwise
         * null can be specified.
         */
        public static native function initFromBytes(bytes:ByteArray, uniqueName:String=null):TextureInfo;

        /**
         * Non-blocking function to create a new TextureInfo instance describing the requested 
         * asset loaded as a Texture2D.

         * @param path Path of the texture asset to load.
         * @param highPriority Whether or not this request should jump the queue to the front, 
         * otherwise it will slot in at the back.
         * @return TextureInfo Reserved texture information structure that is not filled with 
         * usable texture data yet (will be once its 'asyncLoadComplete' has been called).
         */
        public static native function initFromAssetAsync(path:string, highPriority:Boolean=false):TextureInfo;

        /**
         * Non-blocking function used to create a new TextureInfo instance describing the requested 
         * asset loaded as a Texture2D from the provided ByteArray.  On optional unique name can
         * be specified if you wish the texture to take advantage of caching, otherwise
         * null can be specified.
         */
        public static native function initFromBytesAsync(bytes:ByteArray, uniqueName:String=null, highPriority:Boolean=false):TextureInfo;

        
        public static native function initEmptyTexture(width:int, height:int):TextureInfo;
        
        public static native function clear(nativeID:int, color:uint = 0x000000, alpha:Number = 0);
        
        /**
         * Set the specified native texture id as the new render target.
         * 
         * @param nativeID The native texture id to set as the new render target.
         *                 When finished, call this function again with -1 to complete the rendering.
         */
        public static native function setRenderTarget(nativeID:int = -1);
        
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