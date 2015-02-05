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
 *
 *  Dictionary values are accessed via the square bracket operators (`[]`) and a key:
 *
 *  ```as3
 *  var n:Number = d1['two'];
 *  d2['five'] = 5;
 *  ```
 *
 *  Iteration over dictionaries can be done in a couple of ways:
 *
 *  * with a `for..in` loop, for iteration by key
 *  * with a `for each` loop, for iteration by value
 *
 *  ```as3
 *  var d:Dictionary.<String, Number> = {
 *      'one' : 1,
 *      'two' : 2,
 *      'three' : 3,
 *  };
 *
 *  for (var key:String in d) {
 *      trace('d["' +key +'"] =', d[key]);
 *  }
 *
 *  for each(var val:Number in d)
 *  {
 *      trace(val);
 *  }
 *  ```
 */
final class Dictionary extends Object {

    /**
     *  Creates a new Dictionary object.
     *
     *  @param weakKeys Set to true to indicate that the dictionary should not hold a reference to its keys. If the key is garbage collected, it will be removed from the Dictionary. (Please note that a full GC may need to be run for the key to be removed from the weak dictionary).
     */
    public native function Dictionary(weakKeys:Boolean = false);

    /**
     *  Removes all of the key-value pairs in the Dictionary.
     */
    public native function clear():void;

    /**
     *  Gets the number of keys in the Dictionary.
     */
    public native function get length():Number;

    /**
     *  Removes a key-value pair from the dictionary given the key.
     *
     *  @param key The key of the key-value pair to remove from the Dictionary.
     */
    public native function deleteKey(key:Object):void;

    /**
     *  Returns the value for the given key if found in the dictionary, or else the default value.
     *
     *  @param key The key for the value to retrieve from the Dictionary.
     *  @param defaultValue The value to return if the key is not found in the Dictionary. This may be a function that will accept the key and generate a value to return; its signature should be: function(key:Object):Object
     *  @param thisObject Required if the defaultValue generator is an instance method and not a local or static function.
     */
    public function fetch(key:Object, defaultValue:Object, thisObject:Object = null):Object
    {
        var d:Dictionary.<Object, Object> = this;

        if (!d[key])
        {
            if (defaultValue is Function)
                return (defaultValue as Function).call(thisObject, key);

            else
                return defaultValue;
        }

        return d[key];
    }

    /**
     *  Assigns a Dictionary's values to the corresponding fields (if present) of a given Object.
     *
     *  @param dictionary A dictionary of String to Object pairs, to be applied to the given Object.
     *  @param object The object to update with values from the given dictionary. Only keys provided by the dictionary that exist in the object will be modified.
     */
    public static function mapToObject(dictionary:Dictionary.<String, Object>, object:Object):void
    {
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
     *  Intercepts all lookups and writes and passes them to the provided functions.
     *
     *  The Dictionary is not modified after intercept() is called, so if you leave it empty you'll see all traffic.
     *
     * @param dict The dictionary to intercept.
     * @param read A callback in the form of function(dict:Object, key:Object):Object that returns the value for dict[key].
     * @param write A callback in the form of function(dict:Object, key:Object, value:Object):void that updates dict[key] with value.
     */
    public native static function intercept(dict:Object, read:Function, write:Function):void;

}

}
