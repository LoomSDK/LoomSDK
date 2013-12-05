/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/

package data
{
    import loom2d.textures.Texture;
    import loom2d.text.BitmapFont;
    import loom2d.text.TextField;

    public class EmbeddedAssets
    {
        public static var SKULL_ICON_DARK:Texture;
        public static var SKULL_ICON_LIGHT:Texture;
        
        public static function initialize():void
        {
            TextField.registerBitmapFont( BitmapFont.load( "assets/arialComplete.fnt" ), "SourceSansPro" );
            TextField.registerBitmapFont( BitmapFont.load( "assets/arialComplete.fnt" ), "SourceSansProSemibold" );
        
            //we can't create these textures untilloom2d.is ready
            SKULL_ICON_DARK = Texture.fromAsset( "assets/images/skull.png" );
            SKULL_ICON_LIGHT = Texture.fromAsset( "assets/images/skull-white.png" );
        }
    }
}
