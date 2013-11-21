
package loom2d.textures
{
    /**
     * A static class that provides constant values for the possible wrapping modes of a texture.
     */
    public static class TextureWrap
    {

        /**
         * Repeat the texture across outside of the 0-1 UV range
         */   
        public static const REPEAT:int = 0;

        /**
         * Mirror the texture across outside of the 0-1 UV range
         */   
        public static const MIRROR:int = 1;

        /**
         * Clamp the texture to the 0-1 UV range
         */   
        public static const CLAMP:int = 2;

        /**
         * The default wrap mode for new textures, this can be modified 
         * to set a new global smoothing mode
         */   
        public static var defaultWrap:int = CLAMP;
    }
}