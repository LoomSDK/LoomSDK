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
 *  A Dictionary is a collection of key-value pairs, which uses strict equality (`===`) for key comparison.
 *
 *  * When an object is used as a key, the object's identity is used to look up the object, and not the value returned from calling `toString()` on it.
 *  * Keys are unique. Re-assigning to a key simply overwrites the existing value. Declaring a dictionary with duplicate keys does not error, but takes the last value.
 *  * When typing a dictionary variable or instantiating a new Dictionary, the element types must be specified in `<KeyType, ValueType>` format.
 *
 *  Dictionaries in LoomScript can be instantiated via their constructor function, or with a literal syntax using curly brackets (`{}`):
 *
 *  ```as3
 *  var d1:Dictionary.<String, Number> = new Dictionary.<String, Number>();
 *  d1['one'] = 1;
 *  d1['two'] = 2;
 *
 *  var d2:Dictionary.<String, Number> = { 'three': 3, 'four': 4 };
 *  ```
 */
final class Dictionary extends Object {
    
    /**
     *  Creates a new Dictionary object.
     *  
     * 
     *  @param weakKeys
     *      If true, the dictionary will not hold a reference to its keys. If the key is garbage collected, it will be removed from the Dictionary. (Please note that a full GC may need to
     *      be run for the key to be removed from the weak dictionary).
     */
    public native function Dictionary(weakKeys:Boolean = false);
    
    /**
     *  Removes all of the properties in the Dictionary.
     */
    public native function clear();
    
    /**
     *  Gets the number of properties in the Dictionary.
     */
    public native function get length():Number;
    
    /**
     *  Removes a property from the dictionary based on the Object key.
     *
     *  @param key The key for the property.
     */
    public native function deleteKey(key:Object);

    /**
     * Assign a dictionary's values to the corresponding fields (if present) on an Object.
     */
    public static function mapToObject(dictionary:Dictionary.<String, Object>, object:Object):void
    {
        //Debug.assert(dictionary, "Must provide a valid Dictionary!");
        //Debug.assert(object, "Must provide a non-null object to which to apply fields.");

        if(!dictionary)
            return;

        if(!object)
            return;

        const t = object.getType();
        for(var key:String in dictionary)
        {
            if(!t.setFieldOrPropertyValueByName(object, key, dictionary[key]))
                trace("Could not find field '" + key + "' on " + object.toString());
        }
    }

    /**
     * When called on a Dictionary, intercepts all lookups and writes and passes them
     * to the provided functions. The Dictionary is not modified after intercept() is
     * called, so if you leave it empty you'll see all traffic.
     *
     * @param dict The dictionary to intercept.
     * @param read A function that has parameters (table, key) and returns a value.
     * @param write A function that has paraneters (table, key, value) and returns void.
     */
    public native static function intercept(dict:Object, read:Function, write:Function):void;

}

}