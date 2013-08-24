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
 *   The JSON class lets applications parse data using JavaScript %Object Notation (JSON) format.
 */
native class JSON {

    /**
     *  Loads a JSON-formatted String into the object.
     *
     *  This call is required to successfully call any other functions on this class.
     *
     *  @param json - JSON-formatted String object.
     *  @return True if the JSON loaded properly, false if there was an error.
     *  @see getError()
     */
    public native function loadString(json:String):Boolean;

    /**
     * Serialize this object to a JSON String.
     */
    public native function serialize():String;

    /**
     *  Gets a string representation of the last error thrown by this JSON object.
     *  
     *  @return The error text String
     */
    public native function getError():String;
    
    /** Get the type of this object.
     */
    public native function getJSONType():JSONType;

    /**
     *  Gets the int value mapped to the key String on this JSON object.
     *
     *  @param key String key mapped to the int value.
     *  @return the int value mapped to the String key.
     */
    public native function getInteger(key:String):int;

    /**
     *  Gets the float value mapped to the key String on this JSON object.
     *
     *  @param key String key mapped to the float value.
     *  @return the int value mapped to the String key.
     */
    public native function getFloat(key:String):float;

    /**
     *  Gets the String value mapped to the key String on this JSON object.
     *
     *  @param key String key mapped to the String value.
     *  @return The String value mapped to the key String.
     */
    public native function getString(key:String):String;
    
    /**
     *  Gets the Boolean value mapped to the key String on this JSON object.
     *  
     *  @param key String key mapped to the Boolean value.
     *  @return The Boolean value mapped to the key String.
     */
    public native function getBoolean(key:String):Boolean;
    
    /**
     *  Gets the JSON value mapped to the key String on this JSON object.
     *
     *  @param key String key mapped to the JSON value.
     *  @return The JSON value mapped to the key String.
     */
    public native function getObject(key:String):JSON;
    
    /**
     *  Gets the JSON value mapped to the key String on this JSON object.
     *
     *  The object returned is a JSON array. Calling JSON.isArray on this object will
     *  resolve to true and the following array methods can be successfully called:
     *  - JSON.getArrayCount
     *  - JSON.getArrayBoolean
     *  - JSON.getArrayInteger
     *  - JSON.getArrayString
     *  - JSON.getArrayObject
     *
     *  @param key String key mapped to the JSON value
     *  @return The JSON value mapped to the key String.
     */
    public native function getArray(key:String):JSON;

    /**
     * Set an integer value on this JSON object.
     */
    public native function setInteger(key:String, value:int):void;

    /**
     * Set an string value on this JSON object.
     */
    public native function setString(key:String, value:String):void;

    /**
     * Set a float value on this JSON object.
     */
    public native function setFloat(key:String, value:Number):void;

    /**
     * Set a boolean value on this JSON object.
     */
    public native function setBoolean(key:String, value:Boolean):void;

    /**
     * Set an Object value on this JSON object.
     */
    public native function setObject(key:String, value:JSON):void;

    /**
     * Set an Array value on this JSON object.
     */
    public native function setArray(key:String, value:JSON):void;

    /**
     *  Indicates whether the JSON object is considered an object.
     *
     *  @return True if the JSON object is an object, false otherwise
     */
    public native function isObject():Boolean;

    /**
     *  Gets the first key's name in the property list of an object.
     *
     *  @return The name if the matching key or an empty string.
     */
    public native function getObjectFirstKey():String;
    
    /**
     *  Gets the key's name that follows the key given as a parameter
     *  in the property list of an object.
     *
     *  @return The name if the matching key or an empty string.
     */
    public native function getObjectNextKey(key:String):String;
    
    /**
     *  Indicates whether the JSON object is considered an array.
     *
     *  @return True if the JSON object is an array, false otherwise
     */
    public native function isArray():Boolean;
    
    /**
     *  Gets the number of items in the JSON array.
     *
     *  @return The number of items, 0 if object is not a JSON array.
     */
    public native function getArrayCount():int;
    
    /**
     *  Gets a Boolean value at the specified index in the JSON array.
     *
     *  @param index The index of the Boolean value
     *  @return The Boolean value
     */
    public native function getArrayBoolean(index:int):Boolean;
    
    /**
     *  Gets a int value at the specified index in the JSON array.
     *
     *  @param index The index of the int value
     *  @return The int value
     */
    public native function getArrayInteger(index:int):int;
    
    /**
     *  Gets a real value at the specified index in the JSON array.
     *
     *  @param index The index of the int value
     *  @return The int value
     */
    public native function getArrayFloat(index:int):Number;

    /**
     *  Gets a String value at the specified index in the JSON array.
     *
     *  @param index The index of the String value
     *  @return The String value
     */
    public native function getArrayString(index:int):String;
    
    /**
     *  Gets a JSON value at the specified index in the JSON array.
     *
     *  @param index The index of the JSON value
     *  @return The JSON value
     */
    public native function getArrayObject(index:int):JSON;

    /**
     *  Gets an Array value at the specified index in the JSON array.
     *
     *  @param index The index of the JSON value
     *  @return The JSON value
     */
    public native function getArrayArray(index:int):JSON;

    /**
     *  Set a Boolean value at the specified index in the JSON array.
     */
    public native function setArrayBoolean(index:int, value:Boolean):void;

    /**
     *  Set a Boolean value at the specified index in the JSON array.
     */
    public native function setArrayInteger(index:int, value:int):void;

    /**
     *  Set a Boolean value at the specified index in the JSON array.
     */
    public native function setArrayFloat(index:int, value:Number):void;

    /**
     *  Set a Boolean value at the specified index in the JSON array.
     */
    public native function setArrayString(index:int, value:String):void;

    /**
     *  Set a Boolean value at the specified index in the JSON array.
     */
    public native function setArrayObject(index:int, value:JSON):void;

    /**
     *  Set a Boolean value at the specified index in the JSON array.
     */
    public native function setArrayArray(index:int, value:JSON):void;

    
}
    
}