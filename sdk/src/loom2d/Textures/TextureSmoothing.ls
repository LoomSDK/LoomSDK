
package loom2d.textures
{
    /**
     * A static class that provides constant values for the possible smoothing algorithms of a texture.
     */
    public static class TextureSmoothing
    {

        /**
         * Nearest neighbor sampling
         */   
        public static const NONE:int = 0;

        /**
         * Bilear filitering
         */   
        public static const BILINEAR:int = 1;

        /**
         * The MAX constant for smoothing modes
         */   
        public static const MAX:int = 1;

        /**
         * The default smoothing mode for new textures, this can be modified 
         * to set a new global smoothing mode
         */   
        public static var defaultSmoothing:int = BILINEAR;

    }

}