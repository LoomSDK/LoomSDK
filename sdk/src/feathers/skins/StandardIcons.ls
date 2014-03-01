/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.skins
{
    import loom2d.textures.Texture;

    /**
     * A set of icon textures, expected to be populated by the current theme. If
     * the standard icons are not populated by a theme, the icons will be
     * `null`.
     */
    public class StandardIcons
    {
        /**
         * An arrow pointing to the right that appears as an accessory in a list
         * item renderer to indicate that selecting the item will drill down to
         * the next level of data (most likely in another list).
         */
        public static var listDrillDownAccessoryTexture:Texture;
    }
}
