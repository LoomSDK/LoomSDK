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
    import loom2d.math.Rectangle;
    import loom2d.textures.Texture;
    import loom2d.textures.SubTexture;
    import system.xml.XMLElement;
    import loom.LoomTextAsset;

    /** A texture atlas is a collection of many smaller textures in one big image. This class
     *  is used to access textures from such an atlas.
     *  
     *  Using a texture atlas for your textures solves two problems:
     *  
     *    - There is always one texture active at a given moment. Whenever you change the active
     *      texture, a "texture-switch" has to be executed, and that switch takes time.
     *    - Any Loom texture should have side lengths that are powers of two. Starling hides 
     *      this limitation from you, but at the cost of additional graphics memory.
     *  
     *  By using a texture atlas, you avoid both texture switches and the power-of-two 
     *  limitation. All textures are within one big "super-texture", and Starling takes care that 
     *  the correct part of this texture is displayed.
     *  
     *  There are several ways to create a texture atlas. One is to use the atlas generator 
     *  script that is bundled with Starling's sibling, the 
     *  [Sparrow framework](http://www.sparrow-framework.org).
     *  It was only tested in Mac OS X, though. A great multi-platform 
     *  alternative is the commercial tool [Texture Packer](http://www.texturepacker.com/)).
     *  
     *  Whatever tool you use, Starling expects the following file format:
     * 
     *  ~~~xml
     *  &lt;TextureAtlas imagePath='atlas.png'&gt;
     *    &lt;SubTexture name='texture_1' x='0'  y='0' width='50' height='50'/&gt;
     *    &lt;SubTexture name='texture_2' x='50' y='0' width='20' height='30'/&gt; 
     *  &lt;/TextureAtlas&gt;
     *  ~~~
     *  
     *  If your images have transparent areas at their edges, you can make use of the 
     *  `frame` property of the Texture class. Trim the texture by removing the 
     *  transparent edges and specify the original texture size like this:
     * 
     *  ~~~xml
     *  &lt;SubTexture name='trimmed' x='0' y='0' height='10' width='10'
     *      frameX='-10' frameY='-10' frameWidth='30' frameHeight='30'/&gt;
     *  ~~~
     */
    public class TextureAtlas
    {
        private var mAtlasTexture:Texture;
        private var mTextureRegions:Dictionary.<String, Rectangle>;
        private var mTextureFrames:Dictionary.<String, Rectangle>;
        private var mTextureSubTextures:Dictionary.<String, SubTexture>;
        private var mBackingAsset:LoomTextAsset;

        /** helper objects */
        private var sNames:Vector.<String> = [];
        
        /** Create a texture atlas from a texture by parsing the regions from an XML file. */
        public function TextureAtlas(texture:Texture, atlasXml:XMLNode=null)
        {
            mTextureRegions      = new Dictionary();
            mTextureFrames       = new Dictionary();
            mTextureSubTextures  = new Dictionary();
            mAtlasTexture        = texture;
            
            if (atlasXml)
                parseAtlasXml(atlasXml);
        }

        /** Enable live reload for this atlas when this file changes. */
        public function bindToFile(path:String):void
        {
            // Listen to the file.
            mBackingAsset = LoomTextAsset.create(path);
            mBackingAsset.updateDelegate += onChange;
            mBackingAsset.load();
        }

        protected function onChange(path:String, content:String):void
        {
            // Parse the content to XML...
            var xmld = new XMLDocument();
            var res = xmld.parse(content);
            if(res != XMLError.XML_NO_ERROR)
            {
                trace("TextureAtlas - failed to parse '" + path + "', ignoring...");
                return;
            }

            if(xmld.rootElement())
            {
                // ... load the texture...
                var imagePath = Path.folderFromPath(path) + "/" + xmld.rootElement().getAttribute("imagePath");
                mAtlasTexture = Texture.fromAsset(imagePath);

                // ... and push it into our state.
                parseAtlasXml(xmld.rootElement());
            }
        }
        
        /** Disposes the atlas texture. */
        public function dispose():void
        {
            mAtlasTexture.dispose();
        }
        
        /** This function is called by the constructor and will parse an XML in Starling's 
         *  default atlas file format. Override this method to create custom parsing logic
         *  (e.g. to support a different file format). */
        protected function parseAtlasXml(atlasXml:XMLNode):void
        {
            var scale:Number = mAtlasTexture.scale;
            var subTexture:XMLElement = atlasXml.firstChildElement("SubTexture");

            while(subTexture)
            {
                var name:String        = subTexture.getAttribute("name");
                var x:Number           = subTexture.getNumberAttribute("x") / scale;
                var y:Number           = subTexture.getNumberAttribute("y") / scale;
                var width:Number       = subTexture.getNumberAttribute("width") / scale;
                var height:Number      = subTexture.getNumberAttribute("height") / scale;
                var frameX:Number      = subTexture.getNumberAttribute("frameX") / scale;
                var frameY:Number      = subTexture.getNumberAttribute("frameY") / scale;
                var frameWidth:Number  = subTexture.getNumberAttribute("frameWidth") / scale;
                var frameHeight:Number = subTexture.getNumberAttribute("frameHeight") / scale;                

                var region:Rectangle = new Rectangle(x, y, width, height);
                var frame:Rectangle  = frameWidth > 0 && frameHeight > 0 ?
                        new Rectangle(frameX, frameY, frameWidth, frameHeight) : null;
                
                addRegion(name, region, frame);
                
                subTexture = subTexture.nextSiblingElement("SubTexture");
            }
        }
        
        /** Retrieves a subtexture by name. Returns `null` if it is not found. */
        public function getTexture(name:String):Texture
        {
            // Reuse subtexture instances.
            if(mTextureSubTextures[name])
                return mTextureSubTextures[name];

            var region:Rectangle = mTextureRegions[name];
            
            if (region == null) 
                return null;
            else
            {
                mTextureSubTextures[name] = Texture.fromTexture(mAtlasTexture, region, mTextureFrames[name]) as SubTexture;
            } 

            return mTextureSubTextures[name];
        }
        
        /** Returns all textures that start with a certain string, sorted alphabetically
         *  (especially useful for "MovieClip"). */
        public function getTextures(prefix:String="", result:Vector.<Texture> =null):Vector.<Texture>
        {
            if (result == null) result = [];
            
            for each (var name:String in getNames(prefix, sNames)) 
                result.push(getTexture(name)); 

            sNames.length = 0;
            return result;
        }
        
        /** Returns all texture names that start with a certain string, sorted alphabetically. */
        public function getNames(prefix:String="", result:Vector.<String> =null):Vector.<String>
        {
            if (result == null) result = [];
            
            for (var name:String in mTextureRegions)
                if (name.indexOf(prefix) == 0)
                    result.push(name);
            
            result.sort(Vector.CASEINSENSITIVE);
            return result;
        }
        
        /** Returns the region rectangle associated with a specific name. */
        public function getRegion(name:String):Rectangle
        {
            return mTextureRegions[name];
        }
        
        /** Returns the frame rectangle of a specific region, or `null` if that region 
         *  has no frame. */
        public function getFrame(name:String):Rectangle
        {
            return mTextureFrames[name];
        }
        
        /** Adds a named region for a subtexture (described by rectangle with coordinates in 
         *  pixels) with an optional frame. */
        public function addRegion(name:String, region:Rectangle, frame:Rectangle=null):void
        {
            // Override the region and frame.
            mTextureRegions[name] = region;
            mTextureFrames[name]  = frame;

            // If there is a subtexture, propagate state into it.
            if(mTextureSubTextures[name] != null)
            {
                var subTex = mTextureSubTextures[name];
                subTex.updateFrameAndClipping(region, frame);
            }
        }
        
        /** Removes a region with a certain name. */
        public function removeRegion(name:String):void
        {
            //delete mTextureRegions[name];
            mTextureRegions.deleteKey(name);
            //delete mTextureFrames[name];
            mTextureFrames.deleteKey(name);
        }
    }
}