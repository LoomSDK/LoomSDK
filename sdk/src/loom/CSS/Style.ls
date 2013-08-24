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
    /*
        Class: Style
        Represents a style in a <StyleSheet>, can be applied to an object via a <StyleApplicator>

        Package:
            UI.CSS.*

        Assembly:
            UI.loomlib

        See Also:
            <IStyle>
            <StyleSheet>
            <StyleApplicator>
    */
    class Style implements IStyle
    {
        //____________________________________________
        //  Constructor
        //____________________________________________
        public function Style()
        {
            styleName = "default";
        }

        /*
            Group: Public Functions
        */

        //____________________________________________
        //  IStyle Implementation
        //____________________________________________
        public function get properties():Dictionary.<String,String>
        {
            return _properties;
        }

        public function set styleName(value:String):void
        {
            _styleName = value;
        }

        public function get styleName():String
        {
            return _styleName;
        }

        /*
    
            Merges one IStyle into this style. Any properties
            that conflict will be overwritten by the IStyle passed in

        */
        public function merge(object:IStyle):void
        {
            for (var prop:String in object.properties)
            {
                this.properties[prop] = object.properties[prop];
            }
        }

        public function toString():String
        {
            return _styleName;
        }

        public function clone():IStyle
        {
            var cloneProp:Style = new Style();
            var total:Number = properties.length;

            for(var key:String in properties)
            {
                cloneProp.properties[key] = this.properties[key];
            }

            return cloneProp;
        }

        //____________________________________________
        //  Protected Properties
        //____________________________________________
        protected var _styleName:String;
        protected var _properties:Dictionary.<String,String> = new Dictionary.<String,String>();
    }

}