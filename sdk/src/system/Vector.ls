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
 *  A Vector is an ordered collection of items where every item is of the same type.
 *
 *  * The base type can be any class, including built in classes and custom classes.
 *  * Vectors are dynamic (the number of items is allowed to change) unless the `setFixed` method is used to freeze the size.
 *  * Items will be initialized to `null` if a non-zero size is provided to the constructor.
 *  * When increasing the size of a Vector, the `push` or `unshift` methods must used. Assigning a value to an index beyond the final value will result in an out-of-bounds error.
 *
 *  Vectors can be instantiated via their constructor function, or with a literal syntax using square brackets (`[]`):
 *
 *  ```as3
 *  var v1:Vector.<String> = new Vector.<String>(26);
 *  v1[0] = 'a';
 *  v1[25] = 'z';
 *
 *  var v2:Vector.<String> = [ 'one', 'two', 'three' ];
 *  ```
 *
 *  Vector values are accessed via the square bracket operators (`[]`) and a zero-based index:
 *
 *  ```as3
 *  var m:String = v1[12];
 *  v2[1] = 'TWO';
 *  ```
 *
 *  Iteration over vectors can be done in several ways:
 *
 *  * with a `for` loop, for manual iteration
 *  * with a `for..in` loop, for iteration by index
 *  * with a `for each` loop, for iteration by value
 *  * using the callback iterators: `every()`, `filter()`, `forEach()`, `map()`, `some()`
 *
 *  ```as3
 *  var v:Vector.<String> = [ 'a', 'b', 'c' ];
 *
 *  for (var i:Number = 0; i < v.length; i++) {
 *      trace('v[' + i +'] =', v[i]);
 *  }
 *
 *  for (var n:Number in v)
 *  {
 *      trace('v[' +n +'] =', v[n]);
 *  }
 *
 *  for each(var s:String in v) {
 *      trace(s);
 *  }
 *  ```
 *
 *  @see #every()
 *  @see #filter()
 *  @see #forEach()
 *  @see #map()
 *  @see #some()
 */
final class Vector
{

    /**
     *  Adds one or more elements to the end of the Vector and returns the
     *  new length of the Vector.
     *
     *  @param args Arbitrary list of items to add to the Vector.
     *  @return The new length of the Vector.
     */
    public function push(...args):Number
    {
        // this will be optimized to native, testing var args script side

        for (var n:Number = 0; n < args.length; n++)
        {
            pushSingle(args[n]);
        }

        return length;
    }

    /**
     * Converts the elements in the Vector to strings, inserts the specified
     * separator between the elements, concatenates them, and returns the
     * resulting string.
     */
    public function join(sep:String = ","):String
    {
        var vlen = length;
        var returnString = "";

        for (var i:Number = 0; i < vlen; i++) {

            returnString += this[i].toString();
            if (i < vlen - 1)
                returnString += sep;

        }

        return returnString;
    }

    /**
     * Converts the elements in the Vector to strings, inserts a comma
     * separator between the elements, concatenates them, and returns the
     * resulting string.
     */
    public function toString():String {
        return join();
    }

    // TODO: rename this to push perhaps get rid of varargs flavor in favor or performance
    /**
     *  Adds an element to the end of the Vector and returns the new length of the Vector.
     *
     *  @param value The item to add to the end of the Vector.
     *  @return The new length of the Vector.
     */
    public native function pushSingle(value:Object):Object;

    /**
     *  Clear the Vector, resizing to zero in the process.
     */
    public native function clear():void;

    /*
     * Executes a callback function for each element of the Vector, stopping at the first `false` result of the callback.
     *
     * @param callback A callback in the form of function(item:Object, index:Number, v:Vector):Boolean which will be called on each element of the Vector.
     * @param thisObject Required if the callback is an instance method and not a local or static function.
     * @return True when every element passes the callback test, false if any one fails.
     */
    public function every(callback:Function, thisObject:Object = null):Boolean {

        if (!callback)
            return false;

        var count = length;
        for (var i = 0;  i < count; i++)
            if (!callback.call(thisObject, this[i], i, this))
                return false;

        return true;

    }

    /*
     * Executes a callback function for each element of the Vector, stopping at the first true result of the callback.
     *
     * @param callback A callback in the form of function(item:Object, index:Number, v:Vector):Boolean which will be called on each element of the Vector.
     * @param thisObject Required if the callback is an instance method and not a local or static function.
     * @return True when any element passes the callback test, false if every one fails.
     */
    public function some(callback:Function, thisObject:Object = null):Boolean {

        if (!callback)
            return false;

        var count = length;
        for (var i = 0;  i < count; i++)
            if (callback.call(thisObject, this[i], i, this))
                return true;

        return false;

    }


    /*
     * Executes a callback function for each element of the Vector and adds the element to the return Vector if the callback returns `true`.
     *
     * @param callback A callback in the form of function(item:Object, index:Number, vector:Vector):Boolean which will be called for each element of the Vector.
     * @param thisObject Required if the callback is an instance method and not a local or static function.
     * @return A new Vector containing only the elements from the original Vector that passed the callback function test.
     */
    public function filter(callback:Function, thisObject:Object = null):Vector {

        if (!callback)
            return null;

        var returnVector = [];

        var count = length;
        for (var i = 0;  i < count; i++)
            if (callback.call(thisObject, this[i], i, this))
                returnVector.pushSingle(this[i]);

        return returnVector;

    }

    /*
     * Executes a callback function for each element of the Vector, adding the result to a new return Vector.
     *
     * @param callback A callback in the form of function(item:Object, index:Number, vector:Vector):Object which will be called for each element of the Vector.
     * @param thisObject Required if the callback is an instance method and not a local or static function.
     * @return A new Vector whose elements are the return values of the callback. The result Vector will have the same number of elements as the source Vector.
     */
    public function map(callback:Function, thisObject:Object = null):Vector {

        if (!callback)
            return null;

        var returnVector = [];

        var count = length;
        for (var i = 0;  i < count; i++)
            returnVector.pushSingle(callback.call(thisObject, this[i], i, this));

        return returnVector;

    }


    /*
     * Executes a callback function for each element of the Vector.
     *
     * @param callback A callback in the form of function(item:Object, index:Number, vector:Vector):void which will be called for each element of the Vector.
     * @param thisObject Required if the callback is an instance method and not a local or static function.
     */
    public function forEach(callback:Function, thisObject:Object = null):void {

        if (!callback)
            return null;

        var count = length;
        for (var i = 0;  i < count; i++)
            callback.call(thisObject, this[i], i, this);

    }


    /**
     *  Removes the last element from the Vector and returns that element.
     *
     *  @return The value of the last element in the specified Vector.
     */
    public native function pop():Object;

    /**
     *  Removes the first element from the Vector and returns that element. The remaining Vector elements are moved from their original position, i, to i - 1.
     *
     *  @return The first element in the Vector.
     */
    public native function shift():Object;

    /**
     *  Adds one or more elements to the beginning of the Vector, shifting the other elements to the right.
     *
     *  @return The new length of the Vector.
     */
    public function unshift(...args):int {

        if (!args.length)
            return length;

        var tmp = new Vector.<Object>(args.length + length);

        var i:Number;
        var acount = args.length;
        for (i = 0; i < acount; i++) {
            tmp[i] = args[i];
        }

        var tcount = length;
        for (i = 0; i < tcount; i++) {
            tmp[i + acount] = this[i];
        }

        for (i = 0; i < tcount; i++) {
            this[i] = tmp[i];
        }

        for (i = tcount; i < tcount + acount; i++) {
            pushSingle(tmp[i]);
        }

        return length;

    }


    /**
     *  The number of elements in the Vector. The interval of valid indices is [0, length-1].
     */
    public native function get length():Number;

    /**
     *  Sets the length of the Vector.
     *
     *  If the new length is shorter than before, all objects at indices greater than or equal to the new length are removed from the Vector.
     *  If the new length is longer than before, indices beyond the previous length will be undefined until values are assigned to them.
     *
     *  @param value The new length for the Vector to assume. Shorter lengths delete values, longer lengths add undefined values.
     */
    public native function set length(value:Number):void;

    /**
     *  Searches forward for an item in the Vector from startIndex to the last item.
     *
     *  @param o The item to find in the Vector.
     *  @param startIndex The location in the Vector from which to start searching for the item. If no startIndex is given, the search begins at the first element of the Vector. If this parameter is negative, it is treated as length + fromIndex, meaning the search starts -fromIndex items from the end and continues from that position forward to the end of the Vector.
     *  @return The index of the item in the Vector, or -1 if the item is not found between the start index and the end of the Vector.
     */
    public native function indexOf(o:Object, startIndex:Number = 0):Number;

    /**
     *  Searches backward for an item in the Vector from startIndex to the first item.
     *
     *  @param o The item to find in the Vector.
     *  @param startIndex The index in the Vector to start the search from. If no startIndex is given, the search begins at the last element of the Vector.
     *  @return The index of the item in the Vector, or -1 if the item is not found between the start index and the beginning of the Vector.
     */
    public function lastIndexOf(o:Object, startIndex:Number = -1):Number {

        if (startIndex < 0 || startIndex >= length)
            startIndex = length - 1;

        while (startIndex >= 0) {
            if (this[startIndex] == o)
                return startIndex;
            startIndex--;
        }

        return -1;

    }

    /**
     *  Reverses the elements of a Vector in place.
     *
     *  @return Returns a reference to the modified Vector.
     */
    public function reverse():Vector {

        var count = length;
        var i:int;
        var j:int;
        var tmp:Object;

        j = count - 1;
        for (i = 0; i < count / 2; i++) {
            tmp = this[i];
            this[i] = this[j-i];
            this[j-i] = tmp;
        }

        return this;

    }


    /**
     *  Freezes the length of the Vector to the current length, optimizing Vector operations.
     */
    public native function setFixed():void;

    /**
     *  Indicates whether or not the Vector contains the provided value.
     *
     *  @param value The value to query.
     *  @return true if the value is contained in the Vector, false otherwise.
     *  @note This has been updated to work for numbers/string/etc, but untested.
     */
    public native function contains(value:Object):Boolean;

    /**
     *  Removes an object from the Vector.
     *
     *  @param value The object to be removed.
     */
    public native function remove(value:Object):void;

    /**
     *  Concatenates the Vectors specified in the parameters list with the elements in this Vector and creates a new Vector.
     *
     *  @param args A Vector with the same base type as this Vector that contains the elements from this Vector followed by elements from the Vectors in the parameters list.
     */
    public native function concat(... args):Vector;

    /**
     *  Adds elements to and removes elements from the Vector. This method modifies the Vector without making a copy.
     *
     *  @param startIndex An integer that specifies the index of the element in the Vector where the insertion or deletion begins. You can use a negative integer to specify a position relative to the end of the Vector (for example, -1 for the last element of the Vector).
     *  @param deleteCount An integer that specifies the number of elements to be deleted. This number includes the element specified in the startIndex parameter. If you do not specify a value for the deleteCount parameter, the method deletes all of the values from the startIndex element to the last element in the Vector. (The default value is uint.MAX_VALUE.) If the value is 0, no elements are deleted.
     *  @param items An optional list of one or more comma-separated values to insert into the Vector at the position specified in the startIndex parameter.
     *
     *  @return A Vector containing the elements that were removed from the original Vector.
     */
    public native function splice(startIndex:int, deleteCount:int /*= -1 LOOM:369 */, ... items):Vector;

    /**
     *  Returns a new Vector that consists of a range of elements from the original Vector, without modifying the original Vector.
     *
     *  @param startIndex A number specifying the index of the starting point for the slice. If startIndex is a negative number, the starting point begins at the end of the Vector, where -1 is the last element.
     *  @param endIndex A number specifying the index of the ending point for the slice. If you omit this parameter, the slice includes all elements from the starting point to the end of the Vector. If endIndex is a negative number, the ending point is specified from the end of the Vector, where -1 is the last element.
     */
    public native function slice(startIndex:int = 0, endIndex:int = 16777215):Vector;

    private static native function initialize(vector:Vector, size:Number);

    public function Vector(size:Number = 0) {
        initialize(this, size);
    }

    /**
     *  Sorting constant - String comparison will ignore case.
     *
     *  * `a` will be considered equal to `A`.
     */
    public static const CASEINSENSITIVE:uint = 1;

    /**
     *  Sorting constant - The result will be in descending order.
     *
     *  * `c` will be placed before `a`.
     *  * `3` will be placed before `1`.
     *  * `3` will also be placed before `11` unless combined with `NUMERIC`.
     */
    public static const DESCENDING:uint = 2;

    /**
     *  Sorting constant - Prevents sort unless all elements in the Vector are unique.
     *
     *  If there are any duplicates, the sort function will return the Number `0` and the original Vector will be unmodified.
     */
    public static const UNIQUESORT:uint = 4;

    /**
     *  Sorting constant - Original Vector is unmodified but the indices each element would assume if the sort were applied are returned in a new Vector.
     *
     *  The return value is a `Vector.<Number>` of sort-ordered indices.
     */
    public static const RETURNINDEXEDARRAY:uint = 8;

    /**
     *  Sorting constant - Sorts the elements numerically instead of alphabetically.
     *
     *  * `3` will be placed before `11`.
     *  * `'100'` will be placed after `'9'`.
     *
     *  Numeric sorting for types other than `String` or `Number` is undefined; a custom sorting function should be used instead.
     */
    public static const NUMERIC:uint = 16;

    /**
     *  Sorts the elements in the Vector.
     *
     *  By default, `Vector.sort()` sorts in the following manner:
     *
     *  * Sorting is case-sensitive (`Z` precedes `a`).
     *  * Sorting is ascending (`a` precedes `b`).
     *  * The Vector is modified in place to reflect the sort order.
     *  * Elements that sort identically are placed consecutively with no particular precedence.
     *  * All elements, regardless of data type, are sorted as if they were strings, so `100` precedes `9`, because "1" is a lower string value than "9".
     *
     *  To implement a different sorting behavior, provide one of the following as the value for the `sortBehavior` parameter:
     *
     *  * One or more sorting constants combined with bitwise OR (`|`), e.g. `myVector.sort(Vector.CASEINSENSITIVE | Vector.DESCENDING);`
     *  * A custom sorting function with the signature: `function (x:Object, y:Object):Number`
     *
     *  When providing a custom sorting function, the following behavior is expected:
     *
     *  * return `0` when the two items are equal
     *  * return `1` when the first item should be placed after the second
     *  * return `-1` when the first item should be placed before the second
     *
     *  @param sortBehavior Either a bitwise OR of sorting constants (CASEINSENSITIVE, DESCENDING, UNIQUESORT, RETURNINDEXEDARRAY, NUMERIC) or a sorting function in the form of "function (x:Object, y:Object):Number" where x/y can be of any type and the function returns 0 for equality, 1 for x&gt;y and -1 for x&lt;y.
     */
    public native function sort(sortBehavior:Object = 0):Object;
}

}
