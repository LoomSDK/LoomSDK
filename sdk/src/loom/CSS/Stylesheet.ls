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

    delegate StyleUpdatedDelegate(styleSheet:StyleSheet);

    /*
        Class: StyleSheet
        The StyleSheet class provides a way to parse a <String> of css and query/merge styles via stylename.

        Package:
            UI.CSS.*

        Assembly:
            UI.loomlib

        See Also:
            <IStyleSheet>
            <String>
    */
    public class StyleSheet implements IStyleSheet
    {
        //____________________________________________
        //  Constructor
        //____________________________________________
        public function StyleSheet(name:String="undefined")
        {
            super();

            _name = name;


            // add default attributes for platform
            var platform = Platform.getPlatform();
            switch(platform) {
                case PlatformType.WINDOWS:
                    defineAttribute("windows", true);
                    break;
                case PlatformType.OSX:
                    defineAttribute("osx", true);
                    break;
                case PlatformType.IOS:
                    defineAttribute("ios", true);
                    break;
                case PlatformType.ANDROID:
                    defineAttribute("android", true);
                    break;
                case PlatformType.LINUX:
                    defineAttribute("linux", true);
                    break;
            }

            var profile = Platform.getProfile();
            switch(profile) {
                case DisplayProfile.DESKTOP:
                    defineAttribute("desktop", true);
                    break;
                case DisplayProfile.SMALL:
                    defineAttribute("small", true);
                    break;
                case DisplayProfile.NORMAL:
                    defineAttribute("normal", true);
                    break;
                case DisplayProfile.LARGE:
                    defineAttribute("large", true);
                    break;
            }
        }

        //____________________________________________
        //  Loading Implementation
        //____________________________________________
        public var onUpdate:StyleUpdatedDelegate;

        public function set source(value:String):void
        {
            _source = value;

            if(_asset)
                _asset.updateDelegate -= onAssetChange;

            // load the stylsheet using the asset delegate
            _asset = LoomTextAsset.create(value);
            _asset.updateDelegate += onAssetChange;
            _asset.load(); // auto-parses the stylesheet
        }

        public function get source():String
        {
            return _source;
        }

        protected var _source:String;
        protected var _asset:LoomTextAsset;

        protected function onAssetChange(path:String, contents:String):void
        {
            clear();
            parseCSS(contents);
            onUpdate(this);
        }

        /*
            Group: Public Functions
        */

        public function defineAttribute(name:String,value:Object):void
        {
            attributes[name] = value;
        }

        //____________________________________________
        //  IStyleSheet Implementation
        //____________________________________________
        public function get name():String
        {
            return _name;
        }

        public function set name(value:String):void
        {
            _name = value; 
        }

        public function parseCSS(cssText:String)
        {
            // TODO: Give sane log output.
            //Console.print(cssText);
            
            var parser = new CSSParser();
            var document = parser.parse(cssText);

            for(var i = 0; i<document.styles.length; i++)
            {
                var style:StyleBlock = document.styles[i];

                // validate attributes
                var valid = true;
                for(var j = 0; j<style.attributes.length; j++)
                {
                    if(!attributes[style.attributes[j]])
                        valid = false;
                }

                if(!valid)
                    continue;

                if(!styleIndex[style.name])
                {
                    styleIndex[style.name] = new Dictionary.<String, String>();
                }
                
                var props:Dictionary.<String,String> = style.properties.properties;
                for (var key:String in props)
                {
                    styleIndex[style.name][key] = props[key];
                }
            }
        }

        public function clear():void
        {
            cachedStyles.clear();
        }

        public function hasStyle(name:String):Boolean
        {
            return styleIndex[name] != null;
        }

        public function relatedStyles(name:String):Vector.<String>
        {
            return (relatedStyleIndex[name]) ? relatedStyleIndex[name] : null;
        }

        public function toString():String
        {
            Debug.assert(0, "NYI");
            return null;
        }

        public function newStyle(name:String, style:IStyle):void
        {
            cachedStyles[name] = style;
        }

        public function getStyle(styleNames:String):IStyle
        {
            // Split styles and get the total related classes
            var names:Vector.<String> = styleNames.split(" ");
            var total:Number = names.length;
            var baseProperties:IStyle = new Style();
            // Loop through styles and merges them into a single style.
            for (var i:Number = 0; i < total; i ++)
            {
                if (hasStyle(names[i] as String))
                {
                    var currentPropertiesID:String = names[i] as String;
                    var tempProperties:IStyle = styleLookup(currentPropertiesID, false);

                    baseProperties.merge(tempProperties);
                }
            }

            // Returns megred style
            return baseProperties;
        }

        public function styleLookup(styleName:String, getRelated:Boolean = true):IStyle
        {
            var tempProperties:IStyle = (cachedStyles[styleName]) ? cachedStyles[styleName] : null;

            if (! tempProperties)
            {
                tempProperties = new Style();
                if (hasStyle(styleName))
                {
                    if (getRelated)
                    {
                        var ancestors:Vector.<String> = relatedStyleIndex[styleName];
                        var totalAncestors:Number = ancestors.length;
                        var ancestorProperties:IStyle;

                        for (var i:int = 0; i < totalAncestors; i ++)
                        {
                            ancestorProperties = styleLookup(ancestors[i]);
                            tempProperties.merge(ancestorProperties);
                        }
                    }

                    var props:Dictionary.<String,String> = styleIndex[styleName];

                    for (var key:String in props)
                    {
                        tempProperties.properties[key] = props[key];
                    }

                    tempProperties.styleName = styleName;

                    newStyle(styleName, tempProperties);
                }
            }

            return tempProperties.clone() as IStyle;
        }

        //____________________________________________
        //  Protected Properties
        //____________________________________________
        protected var _name:String;

        // Contains an index (value) of all style names that inherit from the base style (key)
        protected var relatedStyleIndex:Dictionary.<String,Vector.<String> > = new Dictionary.<String,Vector.<String> >();
        // Key represents style name and value represents the property blocks to be processed later
        protected var styleIndex:Dictionary.<String,Dictionary.<String,String> > = new Dictionary.<String,Dictionary.<String,String> >();
        protected var cachedStyles:Dictionary.<String,IStyle> = new Dictionary.<String,IStyle>();
        protected var attributes:Dictionary.<String,Object> = new Dictionary.<String,Object>();
    }

}