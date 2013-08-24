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
    public interface IStyleSheet
    {
        function get name():String;

        function set name(value:String):void;

        function parseCSS(cssText:String):IStyleSheet;

        function clear():void;

        function newStyle(name:String, style:IStyle):void;

        function getStyle(styleName:String):IStyle;

        function hasStyle(name:String):Boolean;

        function relatedStyles(name:String):Vector.<String>;

        function toString():String;

        function styleLookup(styleName:String, getRelated:Boolean = true):IStyle;
    }
}