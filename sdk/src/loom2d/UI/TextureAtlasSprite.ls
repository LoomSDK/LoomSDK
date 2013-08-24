package loom2d.ui 
{
    import loom2d.display.DisplayObject;
    import loom2d.display.Image;
    import loom2d.math.Rectangle;
    import loom2d.textures.Texture;
    
    /**
     * Simple Image subclass that uses texture atlases/spritesheets stored in
     * the TextureAtlasManager class.
     * 
     * @see TextureAtlasManager
     */
    public class TextureAtlasSprite extends Image
    {
        private var _atlasName:String;
        private var _textureName:String;
        
        protected var _prevAtlasName:String = null, _prevTextureName:String = null;
        
        public function TextureAtlasSprite() 
        {
            // Start it up with placeholder art. This is embedded in the binary 
            // so it should always work.
            var tex = Texture.fromAsset("assets/tile.png");
            Debug.assert(tex, "TextureAtlasSprite - could not load assets/tile.png!");
            super(tex);
        }

        /** The atlas to use (ie, "Monsters"). If not set, textureName is treated as a path. */
        public function get atlasName():String 
        {
            return _atlasName;
        }
        
        public function set atlasName(value:String):void 
        {
            if (_atlasName != value)
            {
                _atlasName = value;
                valid = false;
            }
            
        }
        
        /** The texture to use (ie, "walk_0001"). If atlasName is not set, textureName is treated as a path. */
        public function get textureName():String 
        {
            return _textureName;
        }
        
        public function set textureName(value:String):void 
        {
            if (_textureName != value)
            {
                _textureName = value;
                valid = false;
            }
        }
        
        /** @inheritDoc */
        public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            updateTexture();
            
            return super.getBounds(targetSpace, resultRect);
        }
        
        protected function updateTexture():void
        {
            // If no change, ignore it.
            if (_prevAtlasName && _prevTextureName)
                if (_atlasName == _prevAtlasName && _textureName == _prevTextureName)
                    return;

            // Resolve the texture.
            var newTex:Texture;

            if (_atlasName)
            {
                newTex = TextureAtlasManager.getTexture(_atlasName, _textureName);
            }
            else
            {
                newTex = Texture.fromAsset(_textureName);
            }
            
            // Update assigned state.
            _prevAtlasName = _atlasName;
            _prevTextureName = _textureName;

            // Useful spam if no texture found.
            if (!newTex)
            {
                trace("Texture not found: atlasName=" + _atlasName + ", textureName=" + _textureName);
                return;
            }

            // Assign the texture.
            texture = newTex;

            onVertexDataChanged();
            readjustSize();
            
            // Hack to make width/height return proper values.
            //super.render();
        }

        protected override function validate():void
        {
            updateTexture();
            super();
        }
                
    }
    
}