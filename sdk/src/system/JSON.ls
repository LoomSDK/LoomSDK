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
    import system.reflection.FieldInfo;
    import system.reflection.Type;


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
[Native(managed)]
native class JSON {
    
    private static var visited = new Vector.<Object>();
    
    /**
     * Convenience function parsing a JSON string and returning a JSON object.
     * @param json  The JSON string to be parsed.
     * @return  The JSON object parsed from the string.
     */
    public static function parse(json:String):JSON {
        var j = new JSON();
        Debug.assert(j.loadString(json), "JSON failed to load");
        return j;
    }
    
    /**
     * Traverses through the object's fields and builds a JSON string
     * from the hierarchy.
     * @param o The Object to traverse using the Reflection API.
     * @return  The JSON tree string built from the fields of the object.
     */
    public static function stringify(o:Object, visited:Vector.<Object> = null):String {
        if (o == null) return "null";
        
        var type:Type = o.getType();
        
        var name = type.getFullName();
        
        switch (name) {
            case "system.String": return '"' + escape(o.toString()) + '"';
            case "system.Number": return '' + o + '';
            case "system.Boolean": return '' + o + '';
        }
        
        var vec = name == "system.Vector";
        
        if (visited == null) visited = new Vector.<Object>();
        if (visited.indexOf(o) != -1) {
            trace("Recursive reference detected for " + o);
            return null;
        }
        
        var index = visited.length;
        visited.push(o);
        
        var i:int;
        var j:String;
        var vs:String;
        if (vec) {
            j = "[ ";
            var v:Vector.<Object> = o as Vector.<Object>;
            for (i = 0; i < v.length; i++) {
                vs = stringify(v[i], visited);
                if (vs == null) continue;
                j += vs;
                if (i < v.length-1) j += ", ";
            }
            j += " ]";
        } else {
            j = "{ ";
            var n:int;
            
            if (name == "system.Dictionary") {
                var d:Dictionary.<String, Object> = o as Dictionary.<String, Object>;
                if (d == null) {
                    trace("Unsupported Dictionary type: "+type.getFullName());
                    return null;
                }
                for (var k in d) {
                    vs = stringify(d[k], visited);
                    if (vs == null) continue;
                    j += '"' + escape(k) + '": ' + vs + ", ";
                }
                j = j.substr(0, j.length-2);
            } else {
                n = type.getFieldInfoCount();
                for (i = 0; i < n; i++) {
                    var f:FieldInfo = type.getFieldInfo(i);
                    vs = stringify(f.getValue(o), visited);
                    if (vs == null) continue;
                    j += '"' + f.getName() + '": ' + vs;
                    if (i < n-1) j += ", ";
                }
                
                /*
                // TODO: Should we add it for properties too?
                n = type.getPropertyInfoCount();
                for (i = 0; i < n; i++) {
                    var p:PropertyInfo = type.getPropertyInfo(i);
                    vs = stringify(p.getGetMethod().invoke(o), visited);
                    if (vs == null) continue;
                    j += '"' + p.getName() + '": ' + vs;
                    if (i < n-1) j += ", ";
                }
                */
            }
            
            j += " }";
        }
        
        visited.splice(index, 1);
        
        return j;
    }
    
    /**
     * Escapes characters to make the string JSON compatible.
     * @param s The unescaped string.
     * @return  The escaped string.
     */
    private static function escape(s:String):String {
        var e = "";
        for (var i = 0; i < s.length; i++) {
            var c = s.charAt(i);
            switch (c) {
                case '"': e += "\\\""; break;
                case "\\": e += "\\\\"; break;
                case "\r": e += "\\r"; break;
                case "\n": e += "\\n"; break;
                case "\t": e += "\\t"; break;
                default: e += c;
            }
        }
        return e;
    }
    
    /**
     * Creates a JSON object from the given Dictionary mapping keys to values. setValue is used to get the JSON representation of every Object.
     * @param d The Dictionary mapping Strings to Objects to source from.
     * @return  The JSON object having equivalent keys and values.
     */
    public static function fromDictionary(d:Dictionary.<String, Object>):JSON {
        var o = new JSON();
        o.initObject();
        for (var k in d) {
            o.setValue(k, d[k]);
        }
        return o;
    }
    
    /**
     * Creates a JSON array from the given Vector of objects. setArrayValue is used to get the JSON representation of every Object.
     * @param v The Vector containing Objects to source from.
     * @return  The JSON array containing equivalent values to the Vector.
     */
    public static function fromVector(v:Vector.<Object>):JSON {
        var a = new JSON();
        a.initArray();
        for (var i:int = 0; i < v.length; i++) {
            a.setArrayValue(i, v[i]);
        }
        return a;
    }
    
    /**
     * Convenience method that sets the field on the provided object using the JSON value of the same name.
     * @param o The Object to set the field on.
     * @param field The key name of the JSON object to get the value of and the field name on the Object to set the value on.
     */
    public function applyField(o:Object, field:String) {
        if (getObjectJSONType(field) == JSONType.JSON_NULL) return;
        var info:FieldInfo = o.getType().getFieldInfoByName(field);
        switch (info.getTypeInfo().getFullName()) {
            case "system.Boolean": info.setValue(o, getBoolean(field)); break;
            case "system.Number": info.setValue(o, getInteger(field)); break;
            case "system.String": info.setValue(o, getString(field)); break;
            default: throw new Error("Unsupported field type: "+info.getTypeInfo().getFullName());
        }
    }
    
    /**
     * General function that sets the value of the key based on the type of object.
     * @param key   The key name to set the value on.
     * @param o The value to set on the JSON object.
     */
    public function setValue(key:String, o:Object) {
        Debug.assert(visited.indexOf(o) == -1, "Circular reference detected at key: "+key);
        visited.push(o);
        
        var info:Type = o.getType();
        switch (info.getFullName()) {
            case "system.Boolean": setBoolean(key, o as Boolean); break;
            case "system.Number": setFloat(key, o as Number); break;
            case "system.String": setString(key, o as String); break;
            case "system.Vector": setVector(key, o as Vector.<Object>); break;
            case "system.Dictionary": setDictionary(key, o as Dictionary.<String, Object>); break;
            default: Debug.assert(false, "Unsupported object type: "+info.getFullName());
        }
        
        visited.remove(o);
    }
    
    /**
     * General function that sets the value of the array index based on the type of object.
     * @param index The array index to set on the JSON array.
     * @param o The value to set on the JSON array.
     */
    public function setArrayValue(index:int, o:Object) {
        Debug.assert(visited.indexOf(o) == -1, "Circular reference detected at index: "+index);
        visited.push(o);
        
        var info:Type = o.getType();
        switch (info.getFullName()) {
            case "system.Boolean": setArrayBoolean(index, o as Boolean); break;
            case "system.Number": setArrayFloat(index, o as Number); break;
            case "system.String": setArrayString(index, o as String); break;
            case "system.Vector": setArrayVector(index, o as Vector.<Object>); break;
            case "system.Dictionary": setArrayDictionary(index, o as Dictionary.<String, Object>); break;
            default: Debug.assert(false, "Unsupported object type: "+info.getFullName());
        }
        
        visited.remove(o);
    }
    
    /**
     * Sets the value of key to the JSON array created from the provided Vector using fromVector.
     * @param key   The key to set the JSON array on.
     * @param v The Vector from which to construct the JSON array.
     */
    public function setVector(key:String, v:Vector.<Object>) {
        setArray(key, fromVector(v));
    }
    
    /**
     * Sets the value of the array index to the JSON array created from the provided Vector using fromVector.
     * @param index The array index to set the JSON array on.
     * @param v The Vector from which to construct the JSON array.
     */
    public function setArrayVector(index:int, v:Vector.<Object>) {
        setArrayArray(index, fromVector(v));
    }
    
    /**
     * Sets the value of the key to the JSON object created from the provided Dictionary using fromDictionary.
     * @param key The key to set the JSON object on.
     * @param d The Dictionary from which to construct the JSON object.
     */
    public function setDictionary(key:String, d:Dictionary.<String, Object>) {
        setObject(key, fromDictionary(d));
    }
    
    /**
     * Sets the value of the array index to the JSON object created from the provided Dictionary using fromDictionary.
     * @param key The array index to set the JSON object on.
     * @param d The Dictionary from which to construct the JSON object.
     */
    public function setArrayDictionary(index:int, d:Dictionary.<String, Object>) {
        setArrayObject(index, fromDictionary(d));
    }
    
    /**
     * Initialize the JSON instance as an empty JSON object, clearing all the previously held values.
     * @return Returns true if creation was successful.
     */
    public native function initObject():Boolean;
    
    /**
     * Initialize the JSON instance as an empty JSON array, clearing all the previously held values.
     * @return Returns true if creation was successful.
     */
    public native function initArray():Boolean;
    

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

    /** For a JSON Object, retrieves the Number associated with the provided key.
     *  Alias of getNumber so it converts integers to floats instead of returning 0.
     *
     *  @param key Identifies the number to be retrieved
     *  @see #setFloat()
     */
    public native function getFloat(key:String):float;

    /** For a JSON Object, retrieves the number value (64-bit Float or 32-bit Integer) associated with the provided key.
     *
     *  @param key Identifies the number to be retrieved
     *  @see #setFloat()
     */
    public native function getNumber(key:String):Number;

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

    /** For a JSON Object, associates a 64-bit Float value with the provided key.
     *
     *  This value can be later retrieved with `getNumber(key)`.
     *
     *  @param key Identifier for the Number
     *  @param value Number to be associated with the key
     *  @see #getNumber()
     */
    public native function setNumber(key:String, value:Number):void;

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

    /** For a JSON Array, retrieves a Number value at the provided index.
     *  Alias of getNumber so it converts integers to floats instead of returning 0.
     *
     *  @param index Identifies the item in the Array to be retrieved as a Float
     */
    public native function getArrayFloat(index:int):Number;

    /** For a JSON Array, retrieves a Number (64-bit Float or 32-bit Integer) value at the provided index.
     *
     *  @param index Identifies the item in the Array to be retrieved as a Number
     */
    public native function getArrayNumber(index:int):Number;

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

    /** For a JSON Array, associates a Number (64-bit Float) value with the provided index.
     *
     *  This value can be later retrieved with `getArrayNumber(index)`.
     *
     *  @param index Array position to receive the Number
     *  @param value Number to be set at the index
     *  @see #getArrayNumber()
     */
    public native function setArrayNumber(index:int, value:Number):void;

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