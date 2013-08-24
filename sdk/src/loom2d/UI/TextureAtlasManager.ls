package loom2d.ui 
{
    import loom2d.textures.Texture;
    import loom2d.textures.TextureAtlas;
    import loom.LoomTextAsset;

    /**
     * Manager for registering texture atlases globally by name for use with 
     * TextureAtlasSprite.
     * 
     * Because LML doesn't give us an easy way to get at arbitrary object references,
     * we just use a static class and string lookups for this purpose. It also helps
     * us avoid loading the same texture atlas multiple times, hopefully saving
     * on memory.
     * 
     * @see Loom.Textures.TextureAtlas
     */
    public class TextureAtlasManager
    {
        protected static var atlases:Dictionary.<String,TextureAtlas> = new Dictionary.<String,TextureAtlas>();
        
        /**
         * Register a texture atlas for later use. You provide a name ("Monsters")
         * and its path ("assets/sheets/") - this is combined into a file to load
         * ("assets/sheets/Monsters.xml"), and the path is used for resolving any
         * textures referenced by the atlas, which should be in the same directory.
         * 
         * @param   name
         * @param   parentPath
         */
        public static function register(name:String, path:String):void
        {
            // Figure out what we are loading.
            var atlas = new TextureAtlas(null);
            atlas.bindToFile(path);
            atlases[name] = atlas;
        }
        
        /**
         * Look up a texture from an atlas previously registered.
         * @param   atlasName The name of the atlas (ie, "Monsters")
         * @param   frameName The frame (ie, "walk_0001" - whatever you set up in the atlas)
         * @return
         */
        public static function getTexture(atlasName:String, frameName:String):Texture
        {
            Debug.assert(atlases, "No atlas dictionary.");
            
            if (!atlasName || !frameName)
                return null;
            
            var foundAtlas = atlases[atlasName];

            if (foundAtlas == null)
                return null;
            
            return foundAtlas.getTexture(frameName);
        }

    }    
}