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

package system
{

    import system.reflection.Type;

    /**
     *  The Object class is at the root of the LoomScript class hierarchy. Objects are created by constructors using the new operator syntax.
     *  All classes that don't declare an explicit base class extend the built-in Object class.
     */
    class Object
    {

        /**
         *  Gets the Type that describes the Object.
         *
         *  @return The Type that describes the object.
         */
        public native function getType():Type;

        /**
         *  Gets the type name of the Object.
         *
         *  @return type name of the Object.
         */
        public native function getTypeName():String;

        /**
         *  Gets the fully qualified type name of the Object.  The fully qualified type name
         *  includes the package of the type.
         *
         *  @return fully qualified type name of the Object.
         */
        public native function getFullTypeName():String;

        
        /**
         * @private
         */
        public native function getNativeDebugString():String;

        /**
         *  Deletes the Object from memory if it is a native Object.
         *  @hide-from-inherited
         */
        public native function deleteNative();
        
        /**
         *  True if this instance's native backing has been deleted.
         *  @hide-from-inherited
         */
        public native function nativeDeleted():Boolean;
        
        /**
         *  Returns a String that describes the Object. 
         *  This can be overriden to provide extra details when printing objects using trace().
         *
         *  @return String that described the Object.
         */
        public native function toString():String;

        /**
         * Returns true if this object has a property with the provided name.
         * @param name Property to test for.
         * @hide-from-inherited
         */
        public native function hasOwnProperty(name:String):Boolean;

        /**
         *  Prints a variable number of arguments to the console output.
         *
         *  Passing objects to this method calls Object.toString() on them.
         *  To format objects for pretty printing, override the Object.toString() method.
         *
         *  @param args A variable number of arguments to print.
         *  @see Object#toString()
         *  @hide-from-inherited
         */
        public static native function trace(... args);

        /**
         *  @private
         *  @hide-from-inherited
         */
        public static native function get NaN():Number;
        
        /**
         *  Returns true if the provided Number is NaN.
         *  @param n Number to check if it is NaN.
         *  @hide-from-inherited
         */
        public static native function isNaN(n:Number):Boolean;
       
        // private transformations which handle primitive and complex types
        private static native function _is (o:Object, classPath:String):Boolean;
        private static native function _as (o:Object, type:Type):Object;
        private static native function _instanceof (o:Object, classPath:String):Boolean;
        
        private static native function _toString(o:Object):String;
        private static native function _toInt(o:Object):Number;
        
        // these exist for primitive types, internally these method calls on a string, number, bool, null will get transformed
        // to the static method call
        private static native function _getTypeName(o:Object):String;
        private static native function _getFullTypeName(o:Object):String;
        private static native function _getType(o:Object):Type;
        private static native function _nativeDeleted(o:Object):Boolean;
        
        private static native function _hasOwnProperty(o:Object, name:String):Boolean;
    }

}