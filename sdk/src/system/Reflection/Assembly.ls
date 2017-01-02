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

package system.reflection {

/**
 * Represents a Loom Assembly that has been loaded into the runtime.
 * An Assembly contains a collection of Type's and each Type has an Assembly associated with it.
 */
native class Assembly {

    /**
     * Loads an assembly from the provided bytes and returns it as an Assembly object.
     * @param bytes The bytes to load the assembly from.
     * @return  The new Assembly object.
     */
    public native static function loadBytes(bytes:ByteArray):Assembly;

    /**
     * Loads an assembly from a file located at it's path returns it as an Assembly object.
     * @param Path of the assembly file.
     * @return The new Assembly object.
     */
    public native static function load(path:String):Assembly;

    /**
     *  Executes the Assembly by calling its main() function.
     *  Will throw an error if the assembly does not have a main() function.
     */
    public native function execute();
    
    public native function run();

    /**
     *  Gets the name of the assembly.
     *
     *  @return Name of the assembly
     */
    public native function getName():String;

    /**
     *  Gets the loom.config embedded in the assembly.
     *
     *  @return JSON string of the config file.
     */
    public native function getConfigJSON():String;

    /**
     *  Gets the unique identifier of the assembly. This changes at every compilation
     *  so dependencies can be verified to be the same.
     *
     *  @return Unique identifier of the assembly
     */
    public native function getUID():String;

    /**
     *  Gets the number of types associated with the Assembly.
     *
     *  @return Number of types in the assembly.
     */
    public native function getTypeCount():int;

    /**
     *  Gets the Type associated with the specified index.
     *
     *  @param index Index of associated Type.
     *  @return Instance of the associated Type.
     */
    public native function getTypeAtIndex(index:int):Type;

    /**
     *  Gets the number of referenced assembly by the Assembly.
     *
     *  @return Number of referenced assemblies.
     */
    public native function getReferenceCount():Number;

    /**
     *  Gets a referenced assembly at given index.
     *
     *  @return  A referenced assembly.
     */
    public native function getReference(index:int):Assembly;
}

}