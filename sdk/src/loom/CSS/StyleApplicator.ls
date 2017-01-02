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
     * A class that can set properties and field to a LoomScript object based on a Style.
     */
    [Native(managed)]
    public native class StyleApplicator
    {
        /*
         * Applys a style to a LoomScript object through reflection. Property values of a
         * style will be applied to fields or properties of the object where the names match.
         */
        public function applyStyle(target:Object, style:Style):void
        {
            StyleApplicator._applyStyle(target, style);
        }

        private native static function _applyStyle(target:Object, style:Style):void;
    }
}