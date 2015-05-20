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
     *  The String class is a data type that represents a string of characters. The String class provides methods and properties that let you manipulate primitive string value types.
     */
    final class String extends Object {

    /**
     *  Gets the number of characters in the String.
     *
     *  @return The number of characters in the String.
     */
    public native function get length():Number;

    /**
     *  Gets the character at the specified index.
     *
     *  @param index The index of the character.
     *  @return The character at the specified index, Null if index is out of range.
     */
    public native function charAt(index:int):String;

    /**
     *  Gets the character code for the specified index.
     *
     *  @param index The index of the character code.
     *  @return The character code for the specified index, -1 if the index is out of range.
     */
    public native function charCodeAt(index:int):Number;

    /**
     *  Converts a char code to s String value.
     *
     *  @param code The char code to convert
     *  @return A String value that represents the char code.
     */
    public static native function fromCharCode(code:int):String;

    /**
     *  Converts every character in the String to upper case.
     *
     *  @return The uppercased String.
     */
    public native function toUpperCase():String;

    /**
     *  Converts every character in the String to lower case.
     *
     *  @return The lowercased String.
     */
    public native function toLowerCase():String;
    
    /**
     *  Converts every character in the String to upper case.
     *
     *  @return The uppercased String.
     */
    public native function toLocaleUpperCase():String;

    /**
     *  Converts every character in the String to lower case.
     *
     *  @return The lowercased String.
     */
    public native function toLocaleLowerCase():String;
    
    /**
     *  Gets the index of a search val in the string, starting at the index specified.
     *
     *  @param val The String to search.
     *  @param startIndex The index to begin the search on.
     *  @return The index of the first occurance of the seach string, -1 if the search string does not exist. 
     */
    public native function indexOf(val:String, startIndex:Number = 0):int;
    
    /**
     *  Gets the last index of a search val in the string, starting at the index specified.
     *
     *  @param val The String to search.
     *  @param startIndex The index to begin the search on.
     *  @return The index of the last occurance of the seach string, -1 if the search string does not exist. 
     */
    public native function lastIndexOf(val:String, startIndex:Number = -1):int;
    
    /**
     *  Concatenates a list of String%s onto the String.
     *
     *  @param args The list of String instances to concatenate onto ths String.
     *  @return The concatenated String.
     */
    public native function concat(... args):String;
    
    /**
     *  Returns a substring consisting of the characters that start at the specified startIndex and with a length specified by len.
     *
     *  @param startIndex An integer that specified the index of the first character to be used to create the substring. If startIndex is a negative number, the starting index is determined from the end of the string, where -1 is the last character.
     *  @param len The number of characters in the substring being created. The default value is the maximum value allowed. If len is not specified, the substring includes all the characters from startIndex to the end of the string.
     *  @return A substring based on the specified indices.
     */    
    public native function substr(startIndex:int = 0, len:int = -1):String;


    /**
     *  Returns a string consisting of the character specified by startIndex and all characters up to endIndex - 1. If endIndex is not specified, String.length is used. If the value of startIndex equals the value of endIndex, the method returns an empty string. If the value of startIndex is greater than the value of endIndex, the parameters are automatically swapped before the function executes. The original string is unmodified.
     *
     *  @param startIndex An integer specifying the index of the first character used to create the substring. Valid values for startIndex are 0 through String.length. If startIndex is a negative value, 0 is used.
     *  @param endIndex An integer that is one greater than the index of the last character in the extracted substring. Valid values for endIndex are 0 through String.length. The character at endIndex is not included in the substring. The default is the maximum value allowed for an index. If this parameter is omitted, String.length is used. If this parameter is a negative value, 0 is used.
     */
    public native function substring(startIndex:int = 0, endIndex:int = -1):String;
    
    /**
     *  Returns a string that includes the startIndex character and all characters up to, but not including, the endIndex character.
     *
     *  @param startIndex The zero-based index of the starting point for the slice. If startIndex is a negative number, the slice is created from right-to-left, where -1 is the last character.
     *  @param endIndex An integer that is one greater than the index of the ending point for the slice. The character indexed by the endIndex parameter is not included in the extracted string. If endIndex is a negative number, the ending point is determined by counting back from the end of the string, where -1 is the last character. The default is the maximum value allowed for an index. If this parameter is omitted, String.length is used.
     *  @return A substring based on the specified indices.
     */
    public native function slice(startIndex:Number = 0, endIndex:Number = 0x7fffffff):String;
    
    /**
     *  Safely evaluate the String to a Number value.
     *
     *  @return The Number value evaluated from the String.
     */
    public native function toNumber():Number;
    
    /**
     *  Safely evaluate the String to a Boolean value.
     *
     *  @return The Boolean value evaluated from the String.
     */
    public native function toBoolean():Boolean;
    
    /**
     *  Safely evaluate the String to an MD5 encoded string value.
     *
     *  @return The MD5 String value evaluated from the String.
     */
    public native function toMD5():String;
    
    /**
     *  Safely evaluate the String to a SHA2 256 encoded string value.
     *
     *  @return The SHA2 String value evaluated from the String.
     */
    public native function toSHA2():String;
    
    /**
     *  Splits a String object into an array of substrings by dividing it wherever the specified delimiter parameter occurs.
     *
     *  @param delimiter The pattern that specifies where to split this String.
     */
    public native function split(delimiter:String):Vector.<String>;

    private native static function _split(value:String, delimiter:String):Vector.<String>;

    /// @cond PRIVATE
    // this is buggy and not ready to be introduced in the public api.
    public native function trim():String;
    /// @endcond

    // TODO: this should be native
    private static function _trim(value:String):String
    {
        var i = 0;

        var c:String = value.charAt(i);
        while(isWhitespace(c))
        {
            i++;
            c = value.charAt(i);
        }

        value = value.slice(i);

        // now trim the backend
        i = value.length-1;
        c = value.charAt(i);
        while(isWhitespace(c))
        {
            i--;
            c = value.charAt(i);
        }

        if(i > 0 && i < value.length-1)
            value = value.slice(0,i+1);

        return value;
    }
    
    /**
     * Left pad the string s with the string c up to the width of l.
     * c is added to the left of s until it reaches the length of l.
     * @param s The string to add left padding on.
     * @param c The string to use as padding, usually a single character.
     * @param l The length or width of the final string. If the string is already as long or longer, it is returned unmodified.
     * @return  The new padded string.
     */
    public static function lpad(s:String, c:String, l:int):String {
        if (s == null || c == null || c.length < 1) return s;
        while (s.length < l) {
            s = c+s;
        }
        return s;
    }
    
    /**
     * Right pad the string s with the string c up to the width of l.
     * c is added to the right of s until it reaches the length of l.
     * @param s The string to add right padding on.
     * @param c The string to use as padding, usually a single character.
     * @param l The length or width of the final string. If the string is already as long or longer, it is returned unmodified.
     * @return  The new padded string.
     */
    public static function rpad(s:String, c:String, l:int):String {
        if (s == null || c == null || c.length < 1) return s;
        while (s.length < l) {
            s = s+c;
        }
        return s;
    }

    /**
     *  Determines if a string is a whitespace character.
     *
     *  @param c The string to check
     *  @return a Boolean value indicating the result of the test.
     */
    public static function isWhitespace(c:String):Boolean
    {
        return c==" " || c=="\n" || c=="\t" || c=="\r";
    }

    /**
     *  Determines if a string is either null or empty.
     *
     *  @param c The string to check
     *  @return a Boolean value indicating the result of the test.
     */
    public static function isNullOrEmpty(c:String):Boolean
    {
        return c==null || c=="";
    }

    /**
     * Returns a formatted version of its variable number of arguments following the description given 
     * in its first argument (which must be a string). 
     * The format string follows the same rules as the printf family of standard C functions. 
     * The only differences are that the options/modifiers *, l, L, n, p, and h are not supported and 
     * that there is an extra option, q. 
     * The q option formats a string in a form suitable to be safely read back by the LoomScript interpreter: 
     * the string is written between double quotes, and all double quotes, newlines, embedded zeros, 
     * and backslashes in the string are correctly escaped when written. 
     * For instance, the call
     * String.format('%q', 'a string with "quotes" and \n new line')
     * will produce the string:
     *
     * "a string with \"quotes\" and \
     *  new line"
     * The options c, d, E, e, f, g, G, i, o, u, X, and x all expect a number as argument, whereas q and s expect a string.
     * 
     * This function does not accept string values containing embedded zeros, except as arguments to the q option.
     *
     * @param formatString the string format
     * @return the formatted string based on the input args
     */
    public static native function format(formatString:String, ...args):String;

    /**
     *  Regex pattern matching using Lua regex rules. 
     *
     *  Note that without captures (the () syntax) you will get zero results.
     *
     *  @see http://lua-users.org/wiki/PatternsTutorial    
     *  
     *  @param pattern The Regex pattern.
     *  @return A Vector of String matches.
     */
    public native function find(pattern:String):Vector.<String>;

    // private methods which public instance methods get transformed to    
    private static native function _charAt(value:String, index:int):String;
    private static native function _charCodeAt(value:String, index:int):Number;

    private static native function _length(value:String):Number;
    
    private static native function _toUpperCase(value:String):String;
    private static native function _toLowerCase(value:String):String;
    private static native function _toLocaleUpperCase(value:String):String;
    private static native function _toLocaleLowerCase(value:String):String;
    
    private static native function _indexOf(value:String, val:String, startIndex:Number = 0):int;
    private static native function _lastIndexOf(value:String, val:String, startIndex:Number = -1):int;
    private static native function _concat(value:String, ... args):String;
    private static native function _slice(value:String, startIndex:Number = 0, endIndex:Number = 0x7fffffff):String;
    private static native function _substr(value:String, startIndex:Number = 0, len:Number = -1):String;
    private static native function _substring(value:String, startIndex:int = 0, endIndex:int = -1):String;
    private static native function _toNumber(value:String):Number;
    private static native function _toBoolean(value:String):Boolean;
    private static native function _toMD5(value:String):String;
    private static native function _toSHA2(value:String):String;
    private static native function _find(value:String, pattern:String):Vector.<String>;
    
    }

}
