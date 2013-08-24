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
        Class: StyleApplicator
        Style applicators apply a <IStyle>'s properties on top of any objects properties via
        Looms System.Reflection API

        Package:
            UI.CSS.*

        Assembly:
            UI.loomlib

        See Also:
            <IStyleApplicator>
            <IStyle>
    */
    public class StyleApplicator implements IStyleApplicator
    {
        /*
            Group: Public Functions
        */

        //____________________________________________
        //  Public Functions
        //____________________________________________
        public function applyStyle(target:Object, style:IStyle):void
        {
            var type = target.getType();
            var props:Dictionary.<String,String> = style.properties;

            for (var prop:String in props)
            {
                var fieldInfo = type.getFieldInfoByName(prop);
                var propertyInfo = type.getPropertyInfoByName(prop);

                var value:String = props[prop] as String;

                if(fieldInfo)
                    setField(fieldInfo, value, target);
                else if(propertyInfo)
                    setProperty(propertyInfo, value, target);
            }
        }

        /*
            Group: Protected Functions
        */

        //____________________________________________
        //  Protected Properties
        //____________________________________________
        protected function setField(field:FieldInfo, value:String, target:Object):void
        {
            // transform the value from a string to the object it is supposed to be
            var typedValue:Object = valueFilter(field.getTypeInfo(), value);
            field.setValue(target, typedValue);
        }

        protected function setProperty(property:PropertyInfo, value:String, target:Object):void
        {
            // transform the value from a string to the object it is supposed to be
            var typedValue:Object = valueFilter(property.getTypeInfo(), value);
            property.getSetMethod().invoke(target, typedValue);
        }

        protected function valueFilter(type:Type, value:String):Object
        {
            var name = type.getFullName();   
            var result:Object;

            switch(name)
            {
                case "system.String":
                    result = value;
                    break;

                case "system.Number":
                    result = value.toNumber();
                    break;

                case "system.Boolean":
                    result = value.toBoolean();
                    break;

                default:
                    Debug.assert(0, "Loom CSS does not support complex types yet. Please use String, Number, or Boolean");
                    break;
            }

            return result;
        }

    }
}