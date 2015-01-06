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

import system.Dictionary;

class TestObject {

    public var name:String;
    
    public var value:Number;
    
    public function TestObject(n:String, v:Number)
    {
        name = n;
        value = v;
    }
    
    public function log()
    {
        Test.log(name);
        Test.log(value);
    }

}

class TestDictionary extends Test

{
    var count:Number = 0;
    
    var d:Dictionary.<String, TestObject> = new Dictionary.<String, TestObject>();
    
    var dd:Dictionary.<String, Dictionary.<String, Number> > = new Dictionary.<String, Dictionary.<String, Number> >();
    
    var vd:Dictionary.<String, Dictionary.<String, Vector.<Number> > > = new Dictionary.<String, Dictionary.<String, Vector.<Number> > >;
    
    var vdd:Dictionary.<String, Dictionary.<String, Dictionary.<String, Vector.<Number> > > > = new Dictionary.<String, Dictionary.<String, Dictionary.<String, Vector.<Number> > > >;
    
    // property to test indexing dictionary by property        
    public function set pvalue(newValue:Number) {
        _pvalue = newValue;
        
    }   
    
    public function get pvalue():Number {
        return _pvalue;        
    }
    
    var _pvalue:Number;        
    
    function getANewDictionary():Dictionary.<String, String> {
        return new Dictionary.<String, String>();
    }
    
    function getADictionaryLiteral():Dictionary.<String, String> {
        return {"Hello" : "You!" };
    }
    
    
    function passInSomeDictionaryLiterals(d1:Dictionary.<String, Number>, d2:Dictionary.<String, Number>, d3:Dictionary.<String, Number>) {
        
        log(d1["one"]);
        log(d1["two"]);
        log(d2["three"]);
        log(d2["four"]);
        log(d3["five"]);
        log(d3["six"]);

    }

    var memberIndexer = "C:\\Users\\Josh\\Documents\\ImageId_2130820210309921560&userId_2114&Format_jpg_88_120.jpg";

    var memberTest:Dictionary.<String, int> = {};
        
    function test()
    {
        
            
        d["A"] = new TestObject("Hello", 1);
        d["B"] = new TestObject("World", 2);
        d["C"] = new TestObject("!!!!!", 3);
    
        d["A"].log();
        d["B"].log();
        
        log(d.length);
                
        // iterating over a dictionary is unordered        
        // thus the count
        var a:String;
        for (a in d)
        {
            if (a == "A")
                count += 1;
                
            if (a == "B")
                count += 2;
                
            if (a == "C")
                count += 3;
        }
        
        log(count);
        
        var b:TestObject;
        
        for each (b in d)
        {
            if (b.name == "Hello")
                count += 1;
                
            if (b.name == "World")
                count += 2;
                
            if (b.name == "!!!!!")
                count += 3;
                
        }
        
        log(count);
        
        // test break
        count = 0;
        for each (b in d)
        {
        
            count++;
            if (count == 1)
                break;
                
        }

        log(count);        
        
        // test continue
        count = 0;
        for each (b in d)
        {
        
            if (b.name == "Hello")
                continue;
        
            count++;
                
        }
        
        log(count);        
        
        // test continue
        count = 0;
        for (a in d)
        {
        
            if (a == "B")
                continue;
        
            count++;
                
        }
        
        log(count);        
        
               
        dd["A"] = new Dictionary.<String, Number>;
        dd["B"] = new Dictionary.<String, Number>;
        
        dd["A"]["One"] = 1;
        dd["A"]["Two"] = 2;
        
        dd["B"]["One"] = 10;
        dd["B"]["Two"] = 20;
        
        log(dd["A"]["One"]);
        log(dd["A"]["Two"]);
        log(dd["B"]["One"]);
        log(dd["B"]["Two"]);
        
        var localdd:Dictionary.<String, Dictionary.<String, String> > = new Dictionary.<String, Dictionary.<String, String> >();

        localdd["A"] = new Dictionary.<String, Number>;
        localdd["B"] = new Dictionary.<String, Number>;
        
        localdd["A"]["One"] = "1";
        localdd["A"]["Two"] = "2";
        
        localdd["B"]["One"] = "10";
        localdd["B"]["Two"] = "20";
        
        log(localdd["A"]["One"]);
        log(localdd["A"]["Two"]);
        log(localdd["B"]["One"]);
        log(localdd["B"]["Two"]);
        
        vd["A"] = new Dictionary.<String, Vector.<Number> >;
        vd["A"]["One"] = new Vector.<Number>;
        vd["A"]["One"].push(1);
        
        log(vd["A"]["One"][0]);
        
        vdd["A"] = new Dictionary.<String, Dictionary.<String, Vector.<Number> > >;
        vdd["A"]["A"] = new Dictionary.<String, Vector.<Number> >;
        vdd["A"]["A"]["A"] = new Vector.<Number>;
        vdd["A"]["A"]["A"].push(99);
        log(vdd["A"]["A"]["A"][0]);
        
        vdd["A"]["A"].deleteKey("A");
        
        log(vdd["A"]["A"]["A"].toString());
        
        var nd:Dictionary.<String, String> = getANewDictionary();
        nd["Whee"] = "Whoo";
        log(nd["Whee"]);
    
        var dict1:Dictionary.<String, Number> = { "one" : 1, "two" : 2 };
        var dict2:Dictionary.<String, Number> = { "three" : 3, "four" : 4 };
        
        passInSomeDictionaryLiterals( dict1, dict2, { "five" : 5, "six" : 6 });
        
        log(getADictionaryLiteral()["Hello"]);
        
        var testPropertyGet:Dictionary.<Number, String> = new Dictionary.<Number, String>();
        testPropertyGet[100] = "Hey";
        
        pvalue = 11;
        testPropertyGet[pvalue] = "YOU!";
        
        log(testPropertyGet[100]);
        log(testPropertyGet[pvalue]);
        log(testPropertyGet[11]);
        
        var dicto:Dictionary.<String, TestObject> = { "one" : new TestObject("OneThousand", 1000), "two" : new TestObject("TwoThousand", 2000) };
        
        log(dicto["one"].name);
        log(dicto["one"].value);
        log(dicto["two"].name);
        log(dicto["two"].value);
        
        var testimply:Dictionary.<String,Vector.<int> > = new Dictionary.<String,Vector.<int> >;
        
        testimply["test"] = new Vector.<int>();
        testimply["test"].pushSingle(1001);
        
        // note that we can't current imply type here
        // TODO: LOOM-516
        var myvector:Vector.<int> = testimply["test"]; 
        
        myvector.pushSingle(1002);
        
        assert(myvector[0] == 1001 && myvector[1] == 1002 && testimply["test"][0] == 1001 && testimply["test"][1] == 1002, "Vector imply test failed");
        
        var odict = new Dictionary();
        odict["x"] = 1000;
        assert(odict["x"] == 1000);
        
        var testNegativeIndex:Dictionary.<int, String > = {-3:"-3", -2:"-2", -1:"-1", 0:"0", 1:"1", 2:"2", 3:"3"};
        
        assert(testNegativeIndex[-3] == "-3");
        assert(testNegativeIndex[-2] == "-2");
        assert(testNegativeIndex[-1] == "-1");
        assert(testNegativeIndex[0] == "0");
        assert(testNegativeIndex[1] == "1");
        assert(testNegativeIndex[2] == "2");
        assert(testNegativeIndex[3] == "3");
        
        testNegativeIndex[-4] = testNegativeIndex[-5] = "-4 and -5";
        
        assert(testNegativeIndex[-4] == "-4 and -5");
        assert(testNegativeIndex[-5] == "-4 and -5");
        
        assert(testNegativeIndex[-6] == null);
        
        testNegativeIndex.clear();
        
        assert(testNegativeIndex[-3] == null);

        // test weak keys
        var to:TestObject = new TestObject("Hi", 101);

        var strong = new Dictionary.<TestObject, String>();
        var weak = new Dictionary.<TestObject, String>(true);

        strong[to] = "Hello";
        weak[to] = "World";

        // remove all references
        strong[to] = null;
        to = null;

        // do a full collection
        GC.fullCollect();

        assert(strong.length == 0);
        assert(weak.length == 0);

        // Test literal key syntax.
        var literalDict = {foo: "bar", butt: "teehee"};
        assert(literalDict["foo"] == "bar");

        // Test intercepting dictionary.
        var interceptedDict = new Dictionary.<String, Object>();
        
        var realDict = new Dictionary.<String, Object>();
        var readCount:int = 0, writeCount:int = 0;

        Dictionary.intercept(interceptedDict, function(garbage:Object, key:String):Object
        {
            //trace("See read! " + key);
            assert(key=="bob");
            readCount++;
            return realDict[key];
        }, 
        function (garbage:Object, key:String, value:Object):void
        {
            assert(key=="bob");
            writeCount++;
            realDict[key] = value;
        });

        interceptedDict["bob"] = 1;
        assert(interceptedDict["bob"] == 1);

        assert(readCount == 1);
        assert(writeCount == 1);

        var dsi:Dictionary.<String, int> = {};

        assert (dsi[memberIndexer] == null);
        assert (!dsi[memberIndexer]);

        dsi[memberIndexer] = 0;
        assert(++dsi[memberIndexer] == 1);
        assert(dsi[memberIndexer]++ == 1);
        assert(++dsi[memberIndexer] == 3);

        assert (memberTest[memberIndexer] == null);
        assert (!memberTest[memberIndexer]);

        memberTest[memberIndexer] = 0;
        assert(++memberTest[memberIndexer] == 1);
        assert(memberTest[memberIndexer]++ == 1);
        assert(++memberTest[memberIndexer] == 3);
        
        var checkIndexError = new Dictionary.<String, Number>;
        // Compiler Error
        //checkIndexError[100] = 100;

        // Fetch
        var validKey = "validKey";
        var defaultValue = "default";
        var regularValue = "regular";
        var generatedValue = "generated";

        var dss = new Dictionary.<String, String>;
        assert(dss.fetch(validKey, defaultValue) == defaultValue, "fetch on empty Dictionary should return default value");

        dss[validKey] = regularValue;
        assert(dss.fetch(validKey, defaultValue) == regularValue, "fetch on Dictionary with valid key should return associated value");
        assert(dss.fetch("invalidKey", defaultValue) == defaultValue, "fetch on Dictionary with invalid key should return default value");
        assert(dss.fetch("invalidKey", function(key:String):String{return generatedValue;}) == generatedValue, "fetch on Dictionary with invalid key should return generated value when default value is a function");
    }
    
    function TestDictionary()
    {
        name = "TestDictionary";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "Hello1World23612122121020121020199nullWhoo123456You!HeyYOU!YOU!OneThousand1000TwoThousand2000";    
}

}


