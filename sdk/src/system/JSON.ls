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

package system {


/**
 *   Types supported by the Loom JSON parser
 */
enum JSONType
{
    JSON_OBJECT,
    JSON_ARRAY,
    JSON_STRING,
    JSON_INTEGER,
    JSON_REAL,
    JSON_TRUE,
    JSON_FALSE,
    JSON_NULL
};

/**
 *  Provides utilities for parsing data in JavaScript Object Notation (JSON) format.
 *
 *  Populate the JSON data structure by calling `loadString()`.
 *  Dump the JSON data structure by calling `serialize()`.
 *
 *  In order to return strongly typed values from the data structure, every data type has its own getter and setter.
 *  The getters and setters come in two flavors, for operating on Objects or Arrays, e.g.:
 *
 *  * `getBoolean(key)`, `setBoolean(key, value)`
 *  * `getArrayBoolean(index)`, `setArrayBoolean(index, value)`
 *
 *  @see http://www.json.org/
 *  @see #loadString()
 *  @see #serialize()
 */
native class JSON {

    /** Loads a JSON-formatted string into memory. Required before getters can be called.
     *
     *  If parsing fails, the `getError()` method will return the error message.
     *
     *  The `serialize()` method will convert the in-memory data back to a JSON string.
     *
     *  @param json A JSON formatted String
     *  @return true if the JSON string was parsed successfully, false if there was an error.
     *  @see #getError()
     *  @see #serialize()
     */
    public native function loadString(json:String):Boolean;

    /**
     *  Serializes the in-memory data structure to a JSON formatted String.
     *
     *  @return A JSON formatted String that can be parsed with loadString()
     *  @see #loadString()
     */
    public native function serialize():String;

    /** Retrieves a string representation of the last error thrown.
     */
    public native function getError():String;

    /** Retrieves the type of the current JSON Object.
     *
     *  @return An enumerated type value
     *  @see JSONType
     */
    public native function getJSONType():JSONType;

    /** For a JSON Object, retrieves the type of the value associated with the provided key.
     *
     *  @param key Identifies the item in the Object to be queried
     */
    public native function getObjectJSONType(key:String):JSONType;

    /** For a JSON Array, retrieves the type of the value at the provided index.
     *
     *  @param index Identifies the item in the Array to be queried
     */
    public native function getArrayJSONType(index:int):JSONType;

    /** For a JSON Object, retrieves a String representation of the 64-bit Integer value associated with the provided key.
     *
     *  LoomScript does not support 64-bit integers natively.
     *
     *  @param key Identifies the number in the Object to be retrieved (as a String)
     */
    public native function getLongLongAsString(key:String):String;

    /** For a JSON Object, retrieves the 32-bit Integer value associated with the provided key.
     *
     *  _Note:_ LoomScript does not support 64-bit integers natively, but longer integers can be retrieved as Strings via `getLongLongAsString()`.
     *
     *  @param key Identifies the number to be retrieved
     *  @see #getLongLongAsString()
     */
    public native function getInteger(key:String):int;

    /** For a JSON Object, retrieves the 64-bit Float value associated with the provided key.
     *
     *  @param key Identifies the number to be retrieved
     *  @see #setFloat()
     */
    public native function getFloat(key:String):float;

    /**
     *  For a JSON Object, retrieves the String value associated with the provided key.
     *
     *  @param key Identifies the string to be retrieved
     *  @see #setString()
     */
    public native function getString(key:String):String;

    /**
     *  For a JSON Object, retrieves the Boolean value associated with the provided key.
     *
     *  @param key Identifies the boolean to be retrieved
     *  @see #setBoolean()
     */
    public native function getBoolean(key:String):Boolean;

    /**
     *  For a JSON Object, retrieves the JSON Object value associated with the provided key.
     *
     *  The object returned is a JSON Object (map of key-value pairs).
     *
     *  @param key Identifies the object to be retrieved
     *  @see #getObjectJSONType()
     *  @see #getObjectFirstKey()
     *  @see #getObjectNextKey()
     *  @see #getBoolean()
     *  @see #getInteger()
     *  @see #getLongLongAsString()
     *  @see #getFloat()
     *  @see #getString()
     *  @see #getArray()
     *  @see #getObject()
     */
    public native function getObject(key:String):JSON;

    /**
     *  For a JSON Object, retrieves the JSON Array value associated with the provided key.
     *
     *  The object returned is a JSON array (ordered set of values).
     *
     *  @param key Identifies the array to be retrieved
     *  @see #getArrayJSONType()
     *  @see #getArrayCount()
     *  @see #getArrayBoolean()
     *  @see #getArrayInteger()
     *  @see #getArrayString()
     *  @see #getArrayArray()
     *  @see #getArrayObject()
     */
    public native function getArray(key:String):JSON;

    /** For a JSON Object, associates an Integer value with the provided key.
     *
     *  This value can be later retrieved with `getInteger(key)`.
     *
     *  @param key Identifier for the integer
     *  @param value Integer to be associated with the key
     *  @see #getInteger()
     */
    public native function setInteger(key:String, value:int):void;

    /** For a JSON Object, associates a String value with the provided key.
     *
     *  This value can be later retrieved with `getString(key)`.
     *
     *  @param key Identifier for the string
     *  @param value String to be associated with the key
     *  @see #getString()
     */
    public native function setString(key:String, value:String):void;

    /** For a JSON Object, associates a 64-bit Float value with the provided key.
     *
     *  This value can be later retrieved with `getFloat(key)`.
     *
     *  @param key Identifier for the float
     *  @param value Float to be associated with the key
     *  @see #getFloat()
     */
    public native function setFloat(key:String, value:Number):void;

    /** For a JSON Object, associates a Boolean value with the provided key.
     *
     *  This value can be later retrieved with `getBoolean(key)`.
     *
     *  @param key Identifier for the boolean
     *  @param value Boolean to be associated with the key
     *  @see #getBoolean()
     */
    public native function setBoolean(key:String, value:Boolean):void;

    /** For a JSON Object, associates a JSON Object value with the provided key.
     *
     *  This value can be later retrieved with `getObject(key)`.
     *
     *  @param key Identifier for the object
     *  @param value JSON Object to be associated with the key
     *  @see #getObject()
     */
    public native function setObject(key:String, value:JSON):void;

    /** For a JSON Object, associates a JSON Array value with the provided key.
     *
     *  This value can be later retrieved with `getArray(key)`.
     *
     *  @param key Identifier for the array
     *  @param value JSON Array to be associated with the key
     *  @see #getArray()
     */
    public native function setArray(key:String, value:JSON):void;

    /** Indicates whether the JSON Object is considered an Object.
     *
     *  @return true if the JSON object represents an object, false otherwise
     */
    public native function isObject():Boolean;

    /** For a JSON Object, retrieves the name of the first key in the property list.
     */
    public native function getObjectFirstKey():String;

    /** For a JSON Object, retrieves the name of the key immediately following the provided key in the property list.
     *
     *  @return The next key, or null if no further keys exist.
     */
    public native function getObjectNextKey(key:String):String;

    /** Indicates whether the JSON Object is considered an Array.
     *
     *  @return true if the JSON object represents an Array, false otherwise
     */
    public native function isArray():Boolean;

    /** For a JSON Array, retrieves the number of items.
     *
     *  @return The number of items, 0 if object is not a JSON Array.
     */
    public native function getArrayCount():int;

    /** For a JSON Array, retrieves a Boolean value at the provided index.
     *
     *  @param index Identifies the item in the Array to be retrieved as a Boolean
     */
    public native function getArrayBoolean(index:int):Boolean;

    /** For a JSON Array, retrieves a 32-bit Integer value at the provided index.
     *
     *  @param index Identifies the item in the Array to be retrieved as an Integer
     */
    public native function getArrayInteger(index:int):int;

    /** For a JSON Array, retrieves a 64-bit Float value at the provided index.
     *
     *  @param index Identifies the item in the Array to be retrieved as a Float
     */
    public native function getArrayFloat(index:int):Number;

    /** For a JSON Array, retrieves a String value at the provided index.
     *
     *  @param index Identifies the item in the Array to be retrieved as a String
     */
    public native function getArrayString(index:int):String;

    /** For a JSON Array, retrieves a JSON Object value at the provided index.
     *
     *  @param index Identifies the item in the Array to be retrieved as a JSON Object
     */
    public native function getArrayObject(index:int):JSON;

    /** For a JSON Array, retrieves a JSON Array value at the provided index.
     *
     *  @param index Identifies the item in the Array to be retrieved as a JSON Array
     */
    public native function getArrayArray(index:int):JSON;

    /** For a JSON Array, associates a Boolean value with the provided index.
     *
     *  This value can be later retrieved with `getArrayBoolean(index)`.
     *
     *  @param index Array position to receive the Boolean
     *  @param value Boolean to be set at the index
     *  @see #getArrayBoolean()
     */
    public native function setArrayBoolean(index:int, value:Boolean):void;

    /** For a JSON Array, associates a 32-bit Integer value with the provided index.
     *
     *  This value can be later retrieved with `getArrayInteger(index)`.
     *
     *  @param index Array position to receive the Integer
     *  @param value Integer to be set at the index
     *  @see #getArrayInteger()
     */
    public native function setArrayInteger(index:int, value:int):void;

    /** For a JSON Array, associates a 64-bit Float value with the provided index.
     *
     *  This value can be later retrieved with `getArrayFloat(index)`.
     *
     *  @param index Array position to receive the Float
     *  @param value Float to be set at the index
     *  @see #getArrayFloat()
     */
    public native function setArrayFloat(index:int, value:Number):void;

    /** For a JSON Array, associates a String value with the provided index.
     *
     *  This value can be later retrieved with `getArrayString(index)`.
     *
     *  @param index Array position to receive the String
     *  @param value String to be set at the index
     *  @see #getArrayString()
     */
    public native function setArrayString(index:int, value:String):void;

    /** For a JSON Array, associates a JSON Object value with the provided index.
     *
     *  This value can be later retrieved with `getArrayObject(index)`.
     *
     *  @param index Array position to receive the JSON Object
     *  @param value JSON Object to be set at the index
     *  @see #getArrayObject()
     */
    public native function setArrayObject(index:int, value:JSON):void;

    /** For a JSON Array, associates a JSON Array value with the provided index.
     *
     *  This value can be later retrieved with `getArrayArray(index)`.
     *
     *  @param index Array position to receive the JSON Array
     *  @param value JSON Array to be set at the index
     *  @see #getArrayArray()
     */
    public native function setArrayArray(index:int, value:JSON):void;

}

}