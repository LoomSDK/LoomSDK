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

package loom.css
{
    import system.platform.Platform;
    import system.platform.PlatformType;
    import system.platform.DisplayProfile;
    import loom.LoomTextAsset;

    delegate StyleUpdatedDelegateInternal();
    delegate StyleUpdatedDelegate(stylesheet:StyleSheet);

    /*
     * The stylesheet is a collection of Styles in a CSS file/source. TODO more description
     */
    [Native(managed)]
    public native class StyleSheet
    {
        public function StyleSheet()
        {
            _onUpdate += function()
            {
                trace("update");
                onUpdate(this);
            };
        }

        /*
         * Get the name of this stylesheet.
         */
        public native function get name():String;

        /*
         * Set the name of this stylesheet.
         */
        public native function set name(value:String):void;

        /*
         * Return the name of the source file this stylesheet was loaded from.
         * If the stylesheet was not loaded from a file, an empty string will
         * be returned.
         */
        public native function get source():String;

        /*
         * Set the source file name for this stylesheet. The source will be loaded
         * as an asset, parsed for rules and the stylesheet will subscribe for live updates. It will
         * invoke the 'onUpdate' delegate.
         */
        public native function set source(value:String):void;

        /*
         * Parses a stylesheet from a string. If this stylesheet was using an asset
         * before, live reloading will be disabled.
         */
        public native function parseCSS(cssText:String);

        /*
         * Clears all the styles (rules). Attributes and the name are left unchanged,
         * they are not dependant on the source of the stylesheet.
         */
        public native function clear():void;

        /*
         * Checks the stylesheet for the presence of a style with a specific selector.
         * Returns true if it was found, false otherwise.
         */
        public native function hasStyle(name:String):Boolean;

        /*
         * Return a string representation of this object. For now this is it's name.
         */
        public native function toString():String;

        /*
         * Add a new style with the given name (selector). If an existing style with
         * the same selector already exists, it's added to an array.
         * There are multiple styles possible with the same selector, they might
         * have different attributes.
         * Note that the style's own selector doesn't matter at lookup.
         */
        public native function newStyle(name:String, style:Style):void;

        /*
         * Get a composite style from the given styleNames (selectors, separated with a space).
         * The styles found will be merged into a new style that will be returned.
         */
        public native function getStyle(styleNames:String):Style;

        /*
         * A delegate that triggers when the source updates either with an asset change or
         * invoking a source change manually.
         */
        public var onUpdate:StyleUpdatedDelegate;

        private native var _onUpdate:StyleUpdatedDelegateInternal;
    }
}