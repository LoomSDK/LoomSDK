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
 * The Vector class lets you access and manipulate a vector. The data type of 
 * a Vector's elements is known as the Vector's base type. The base type can be
 * any class, including built in classes and custom classes. The base type is
 * specified when declaring a Vector variable as well as when creating an 
 * instance by calling the class constructor.
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
    
    // todo, rename this to push perhaps get rid of varargs flavor 
    // in favor or performance
    public native function pushSingle(value:Object):Object;

    /**
     *  Clear the Vector resizing to zero in the process.
     */
    public native function clear();
    
    /*
     * Executes a callback function for each element of a vector, stopping at the first false result of the callback.
     *
     * @param callback A callback in the form of function(item:Object, index:Number, vector:Vector):Boolean which will be called for each element of the vector.
     * @param thisObject If the callback is an instance method and not a local or static function, thisObject must be specified.
     * @return Returns true when every element passes the callback test, false if any one fails
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
     * Executes a callback function for each element of a vector, stopping at the first true result of the callback
     *
     * @param callback A callback in the form of function(item:Object, index:Number, vector:Vector):Boolean which will be called for each element of the vector
     * @param thisObject If the callback is an instance method and not a local or static function, thisObject must be specified.
     * @return Returns true when any element passes the callback test, false if every one fails
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
     * Executes a callback function for each element of a vector, adding the element to a new return Vector if the callback returns true for it
     *
     * @param callback A callback in the form of function(item:Object, index:Number, vector:Vector):Boolean which will be called for each element of the vector
     * @param thisObject If the callback is an instance method and not a local or static function, thisObject must be specified.
     * @return Returns a new Vector containing only the elements from the original vector that passed the callback function test
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
     * Executes a callback function for every element of a vector, adding the result to a new return Vector
     *
     * @param callback A callback in the form of function(item:Object, index:Number, vector:Vector):Object which will be called for each element of the Vector
     * @param thisObject If the callback is an instance method and not a local or static function, thisObject must be specified.
     * @return Returns a new Vector whose elements are the return values of the callback. The result Vector will have the same number of elements as the source Vector.
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
     * Executes a callback function for every element of a Vector
     *
     * @param callback A callback in the form of function(item:Object, index:Number, vector:Vector):void which will be called for each element of the Vector
     * @param thisObject If the callback is an instance method and not a local or static function, thisObject must be specified.
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
     *  Adds one or more elements to the beginning of the vector, shifting the other elements to the right
     *
     *  @return The new number of elements in the vector
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
     *  The range of valid indices available in the Vector.
     */
    public native function get length():Number;

    /**
     *  Sets the length of the array - if the new length is less than the previous all objects at indices greater than
     *  or equal to the new length are removed from the Vector.
     */
    public native function set length(value:Number):void;
    
    /**
     *  Searches forwards for an item in the Vector from startIndex to the last item.
     *
     *  @param o The item to find in the Vector.
     *  @param startIndex The location in the Vector from which to start searching for the item. If this parameter is negative, it is treated as length + fromIndex, meaning the search starts -fromIndex items from the end and searches from that position forward to the end of the Vector.
     *  @return Returns the index of the item in the Vector, or -1 if the item is not found between the start index and the end of the Vector.
     */
    public native function indexOf(o:Object, startIndex:Number = 0):Number;
    
    /**
     *  Searches backwards for an item in the Vector from startIndex to the first item.
     *
     *  @param o The item to find in the Vector.
     *  @param startIndex The index of the vector to start the search. If no startIndex is given, the search begins at the last element of the vector.
     *  @return Returns the index of the item in the Vector, or -1 if the item is not found between the start index and the beginning of the Vector.
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
        var tmp = new Vector.<Object>(length);
        
        j = 0;
        for (i = count - 1; i >= 0; i--) {
        
            tmp[i] = this[j++];
            
        }
            
        for (i = 0; i < count; i++)
            this[i] = tmp[i];
            
        return this;    
        
    }
    
    
    /**
     *  Sets the the fised length of the Vector to the current length, optimizing vector operations.
     */
    public native function setFixed();
  
    /**
     *  Indicates whether or not the vector contains the value.
     *
     *  @param value The value to query.
     *  @return True if the value is contained by the Vector, false otherwise.
     *  @note This has been updated to work for numbers/string/etc, but untested.
     */
    public native function contains(value:Object):Boolean;
    
    /**
     *  Removes an object from the Vector.
     *
     *  @param value The value to remove.
     */
    public native function remove(value:Object);
    
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
     * Sorting constant - String comparison in sort will be case insensitive.
     */
    public static const CASEINSENSITIVE:uint = 1;

    /**
     * Sorting constant - The sort will be in descending order.
     */
    public static const DESCENDING:uint = 2;

    /**
     * Sorting constant - Ensures that all the elements in the sort are unique, if they are not the sort function will return 0 and the original array will be unmodified.
     */
    public static const UNIQUESORT:uint = 4;

    /**
     * Sorting constant - Original vector is unmodified by the sort, instead returns a Vector.&lt;Number&gt; of sorted indices.
     */
    public static const RETURNINDEXEDARRAY:uint = 8;

    /**
     * Sorting constant - Sorts the vector by numeric values instead of doing string conversion on numbers.
     */
    public static const NUMERIC:uint = 16;

    /**
     *   Sorts the elements in the Vector.
     *
     *   @param sortBehavior Either a bitwise or of sorting constants (CASEINSENSITIVE, DESCENDING, UNIQUESORT, RETURNINDEXEDARRAY, NUMERIC) 
     *          or a sorting function in the form of function (x:Object, y:Object):Number where x/y can be of any type, sort function should return 0 on equality, 1 on x>y and -1 on x<y.
     *
     *   By default, Array.sort() sorts in the following manner:
     *
     *   Sorting is case-sensitive (Z precedes a).
     *   Sorting is ascending (a precedes b).
     *   The array is modified to reflect the sort order; multiple elements that have identical sort fields are placed consecutively in the sorted array in no particular order.
     *   All elements, regardless of data type, are sorted as if they were strings, so 100 precedes 99, because "1" is a lower string value than "9".
     */
    public native function sort(sortBehavior:Object = 0):Object;
}

}