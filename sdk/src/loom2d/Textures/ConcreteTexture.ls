// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.textures
{
    import loom.graphics.TextureInfo;
    import loom2d.events.Event;

    /** A ConcreteTexture wraps a Cocos texture object, storing the properties of the texture. */
    public class ConcreteTexture extends Texture
    {
        //private var mBase:TextureBase;
        private var mFormat:String;
        private var mWidth:int;
        private var mHeight:int;
        private var mMipMapping:Boolean;
        private var mPremultipliedAlpha:Boolean;
        private var mOptimizedForRenderTexture:Boolean;
        private var mData:Object;
        private var mScale:Number;
        private var mAssetPath:String;
        
        /** Creates a ConcreteTexture object from a TextureBase, storing information about size,
         *  mip-mapping, and if the channels contain premultiplied alpha values. */
        public function ConcreteTexture(path:String, width:Number, height:Number)
        {
            textureInfo = null;
            mAssetPath = path;
            mScale = 1.0; // scale <= 0 ? 1.0 : scale;
            mWidth = width;
            mHeight = height;
            mPremultipliedAlpha = false;
        }

        public function setDimensions(width:Number, height:Number):void
        {
            mWidth = width;
            mHeight = height;            
        }
        
        public function setTextureInfo(ti:TextureInfo):void
        {
            textureInfo = ti;
            
            if (textureInfo)
            {
                textureInfo.smoothing = mSmoothing;
                textureInfo.wrapU = mWrapU;
                textureInfo.wrapV = mWrapV;
                textureInfo.update += onUpdate;
            }
        }

        private function onUpdate(width:Number, height:Number):void
        {
            mWidth = width;
            mHeight = height;

            update();
        }

        /** Disposes the TextureBase object. */
        public override function dispose():void
        {
            //if (mBase) mBase.dispose();
            //restoreOnLostContext(null); // removes event listener & data reference 
            textureInfo.update -= onUpdate;
            textureInfo.asyncLoadComplete = null;
            super.dispose();
        }
        
        // properties
        
        /** Indicates if the base texture was optimized for being used in a render texture. */
        public function get optimizedForRenderTexture():Boolean { return mOptimizedForRenderTexture; }
        
        /** @inheritDoc */
        //public override function get base():TextureBase { return null; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture { return this; }
        
        /** @inheritDoc */
        public override function get format():String { return mFormat; }
        
        /** @inheritDoc */
        public override function get width():Number  { return mWidth / mScale;  }
        
        /** @inheritDoc */
        public override function get height():Number { return mHeight / mScale; }
        
        /** @inheritDoc */
        public override function get nativeWidth():Number { return mWidth; }
        
        /** @inheritDoc */
        public override function get nativeHeight():Number { return mHeight; }
        
        /** The scale factor, which influences width and height properties. */
        public override function get scale():Number { return mScale; }
        
        /** @inheritDoc */
        public override function get mipMapping():Boolean { return mMipMapping; }
        
        /** @inheritDoc */
        public override function get premultipliedAlpha():Boolean { return mPremultipliedAlpha; }
        
        /** @inheritDoc */
        public override function get assetPath():String { return mAssetPath; }
    }
}