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

class TestBooleanExpr extends Test
{

    var falseObjectVar:Object = false;
    var falseStringVar:String = "";
    var falseNumberVar:Number = 0;

    static var sfalseObjectVar:Object = false;
    static var sfalseStringVar:String = "";
    static var sfalseNumberVar:Number = 0;


    function returnFalseString():String {
        return "";

    }

    function returnFalseNumber():Number {
        return 0;
        
    }

    function returnFalseObject():Object {
        return null;
        
    }

    function returnTrueString():String {
        return "yes";

    }

    function returnTrueNumber():Number {
        return 1;
        
    }

    function returnTrueObject():Object {
        var apple:Apple = new Apple();
        return apple;
        
    }

    function get falseNumber():Number {
        return 0;
    }

    function get falseString():String {
        return "";
    }

    function get falseObject():Object {
        return null;
    }

    function printObject(o:Object) {
        Console.print(o);
    }

    function test()
    {
        
        
        var v:Number = .000001;
        if (v)
            log("true");
        else
            log("false");
        
        v = 0;
        if (v)
            log("true");
        else
            log("false");
            
        if (!v)
            log("true");
        else
            log("false");
            
            
        v = -0.0;
        if (v)
            log("true");
        else
            log("false");
            
        if (0)
            log("true");
        else
            log("false");
            
        if (1)
            log("true");
        else
            log("false");
            
        var s:String = "";
        if (s)
            log("true");
        else
            log("false");

        s = "x";
        if (s)
            log("true");
        else
            log("false");
            
        if ("")
            log("true");
        else
            log("false");

        if ("x")
            log("true");
        else
            log("false");

        var o:Object = null;

        if (o)
            log("true");
        else
            log("false");

        o = 0;
        assert(!o);
        o = 1;
        assert(o);

        o = "";
        assert(!o);
        o = "Yes";
        assert(o);

        o = false;
        assert(!o);
        o = true;
        assert(o);

        o = new TestObject("", 0);
        assert(o);
            
        if (null)
            log("true");
        else
            log("false");
            
        var b:Boolean = true;
        if (b)
            log("true");
        else
            log("false");
            
        b = false;
        if (b)
            log("true");
        else
            log("false");
            
        if (true)
            log("true");
        else
            log("false");

        if (false)
            log("true");
        else
            log("false");
            
        s = "";
        if (s || "")
            log("true");
        else
            log("false");
            
        s = "x";
        if (s || "")
            log("true");
        else
            log("false");
            
        s = "";
        if ("x" || s)
            log("true");
        else
            log("false");
            
        v = 0;
        if (v || 0)
            log("true");
        else
            log("false");
            
        if (1 || v)
            log("true");
        else
            log("false");
            
            
        if (v && 1)
            log("true");
        else
            log("false");
            
        var sa:String = "a";
        var sa2:String = "a";
        var sb:String = "b";
        assert(sa < sb);
        assert(sa <= sb);
        assert(sa > sb == false);
        assert(sa >= sb == false);
        assert(sa < sa2 == false);
        assert(sa == sa2);

        for (var i = 0; i < 1000; i++) {    

            var x = int(Math.random() * 9);
            switch (x) {
                case 0:
                    assert(!returnFalseObject());
                    break;
                case 1:
                    assert(!returnFalseString());
                    break;
                case 2:
                    assert(!returnFalseNumber());
                    break;
                case 3:
                    assert(!falseObject);
                    break;
                case 4:
                    assert(!falseString);
                    break;
                case 5:
                    assert(!falseNumber);
                    break;
                case 6:
                    assert(!!returnTrueObject());
                    break;
                case 7:
                    assert(!!returnTrueString());
                    break;
                case 8:
                    assert(!!returnTrueNumber());
                    break;
 
            };
        }

        assert(!returnFalseObject() == true);
        assert(!returnFalseString() == true);
        assert(!returnFalseNumber() == true);

        o = returnFalseObject();
        assert(!o);
        o = returnFalseString();
        assert(!o);
        o = returnFalseNumber();
        assert(!o);

        o = returnTrueObject();
        assert(o);
        o = returnTrueString();
        assert(o);
        o = returnTrueNumber();
        assert(o);

        
        assert(!falseStringVar);
        assert(!falseNumberVar);
        assert(!falseObjectVar);

        assert(!this.falseStringVar);
        assert(!this.falseNumberVar);
        assert(!this.falseObjectVar);

        assert(!sfalseStringVar);
        assert(!sfalseNumberVar);
        assert(!sfalseObjectVar);

        assert(!TestBooleanExpr.sfalseStringVar);
        assert(!TestBooleanExpr.sfalseNumberVar);
        assert(!TestBooleanExpr.sfalseObjectVar);
        
    }
    
    function TestBooleanExpr()
    {
        name = "TestBooleanExpr";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "true
false
true
false
false
true
false
true
false
true
false
false
true
false
true
false
false
true
true
false
true
false";    

}

}



