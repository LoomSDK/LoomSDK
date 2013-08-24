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

package tests {

import unittest.Test;

class TestStringCoerce
{
    public var x = 0;
    public var y = 0;

    override public function toString():String
    {
        return x + ":" + y;
    }

}

class TestString extends Test
{

    var strings:Dictionary.<int, String> = new Dictionary.<int, String>();

    function getAString():String {
    
        return "LoomScript";
        
    }    
    
    function test()
    {
        
        assert("|X|A|X|B|X|C|X|".split("|X|").length == 5);        
        
        var svalue = "This is a Test!";
        
        assert(("Test the the result of a concat is a string for compiler and runtime"+1).getType() == String);
        assert(String == ("Test the the result of a concat is a string for compiler and runtime, in the other direction"+1).getType());
   
        var x:int;
        for (x = 0; x < svalue.length; x++)
            log(svalue.charAt(x));
            
        for (x = 0; x < getAString().length; x++)
            log(getAString().charAt(x));
            
        strings[0] = "Hello";
        strings[1] = "World";
        
        for (x = 0; x < 2; x++)
            for (var y = 0; y < strings[x].length; y++)
                log(strings[x].charAt(y));
        
        
        log(getAString().toUpperCase());
        log(getAString().toLowerCase());
        
        log(svalue.indexOf("is", 3));
                
        svalue = strings[0];
        
        log(svalue.concat(10, this, true, " from ", getAString()));
        
        svalue = "This is a test";
        log(svalue.substr(10));
        log(svalue.substr(1, 4));
        log(svalue.substr(10, 4000));
        
        log(svalue.charCodeAt(3));
        log(svalue.charCodeAt(1000));
        
        log(String.fromCharCode(65));
        
        svalue = "test is a test";
        log(svalue.lastIndexOf("test"));
        log(svalue.lastIndexOf("test", 8));
        log(svalue.lastIndexOf("nope"));
        
        log(svalue.slice(10));
        log(svalue.slice(5, 7));
        log(svalue.slice(5, -1));

        // Testing toBoolean() and toNumber()
        var shouldBeTrue = "true";
        log(shouldBeTrue.toBoolean());
        shouldBeTrue = "TRUE";
        log(shouldBeTrue.toBoolean());

        var shouldBeFalse = "false";
        log(shouldBeFalse.toBoolean());

        var oneHundred = "100";
        log((oneHundred.toNumber()+100).toString());

        // Coverage for split.
        var stringToSplit = "|X|A|X|B|X|C|X|";
        log(stringToSplit.split("|X|").length);

        stringToSplit = "|X|A|X|B|X|C";
        log(stringToSplit.split("|X|").length);

        stringToSplit = "|X|";
        log(stringToSplit.split("|X|").length);

        stringToSplit = "1|2|3|4|5|6|7";
        var splitRes:Vector.<String> = stringToSplit.split("|");
        for(var i=0; i<splitRes.length; i++)
            log(splitRes[i]);
            
        svalue = "setb myfile.ls 100";
        var found:Vector.<String> = svalue.find("^([a-z]+)%s+(.-)%s+(%d+)%s*$");
        log(found[0]); // command
        log(found[1]); // filename
        log(found[2]); // line numver        
               
        assert("test " + null + " " + getAString + 100 == "test null getAString():system.String100");
        
        // now test the substring with is a close relation to substr, here's looking at you AS3
        
        svalue = "This is a test";
        assert(svalue.substring() == "This is a test");
        assert(svalue.substring(-1) == "This is a test");
        assert(svalue.substring(1000) == "");
        assert(svalue.substring(-1, 1000) == "This is a test");
        assert(svalue.substring(5, 7) == "is");
        assert(svalue.substring(10) == "test");

        var sformat = String.format("This is a %s %i", "test", 101);
        assert(sformat == "This is a test 101");
        
        assert(String.format("This is a test %i", 101) == "This is a test 101");

        assert(String.format("Hey %s", String.format("You: %s", String.format("This is a test %i", 101))) == "Hey You: This is a test 101");

        var tsc = new TestStringCoerce;
        assert(string(tsc) == "0:0");
        tsc.x = 1001;
        tsc.y = 32;
        assert(string(tsc) == "1001:32");

        var testnull = null + "testme" + null;
        assert(testnull == "nulltestmenull");
        testnull = null + "anothertest";
        assert(testnull == "nullanothertest");
        testnull = "yetanothertest" + null;
        assert(testnull == "yetanothertestnull");

    }
    
    function TestString()
    {
        name = "TestString";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
"This is a Test!LoomScriptHelloWorldLOOMSCRIPTloomscript5
Hello10Object:tests.TestStringtrue from LoomScript
testhistest115-1A
100-1testisis a test
true
true
false
200
5
4
2
1
2
3
4
5
6
7
setb
myfile.ls
100
"
;
    
}

}



