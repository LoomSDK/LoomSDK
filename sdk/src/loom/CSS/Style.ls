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
     * Style contains a dictionary of properties, a list of attributes and a selector.
     * It's used for changing the properties of LoomScript objects with StyleApplicator.
     */
    [Native(managed)]
    public native final class Style
    {
        public native function Style(selector:String);

        /*
         * Returns the number of unique properties the style defines.
         */
        public native function get propertyCount():Number;

        /*
         * Returns the name of the property at given index. Should not be called
         * with an index that is out of bounds.
         */
        public native function getPropertyNameByIndex(index:Number):String;

        /*
         * Returns the value of the property at given index as a string. Should not be called
         * with an index that is out of bounds.
         */
        public native function getPropertyValueByIndex(index:Number):String;

        /*
         * Returns the value of the property with the given name as a string. If such a
         * property doesn't exist, NULL is returned.
         */
        public native function getPropertyValue(name:String):String;

        /*
         * Returns true if the style defines a property with the given name, false othervise.
         */
        public native function hasProperty(name:String):Boolean;

        /*
         * Removes the property with the given name, if it exists.
         */
        public native function removeProperty(name:String):void;

        /*
         * Sets the value of a property with the given name. If a property with such a name
         * already exists, the old one is overriden.
         */
        public native function setPropertyValue(name:String, value:String):void;

        /*
         * Return the name (selector) this style responds to.
         */
        public native function get styleName():String;

        /*
         * Merges another style into the this style. The properties of the other
         * style are added or they override the properties of this style.
         */
        public native function merge(object:Style):void;

        /*
         * Return the selector as a representation of the object
         */
        public native function toString():String;

        /*
         * Create a new instance of the Style with the same name, properties and attributes.
         * The instance will be garbage collected by LoomScript.
         */
        public native function clone():Style;
    }

}