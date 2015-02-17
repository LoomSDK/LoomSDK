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

import unittest.LegacyTest;

class TestIncrementExpression extends LegacyTest
{

    var memberCounter = 0;

    function testPreIncrementArgs(x:int, y:int, z:int)
    {
        LegacyTest.assert(x == 2);
        LegacyTest.assert(y == 3);
        LegacyTest.assert(z == 4);
    }


    function testPostIncrementArgs(x:int, y:int, z:int)
    {
        LegacyTest.assert(x == 1);
        LegacyTest.assert(y == 2);
        LegacyTest.assert(z == 3);
    }

    function testPostPreIncrementArgs(x:int, y:int, z:int, a:int, b:int)
    {
        LegacyTest.assert(x == 10);
        LegacyTest.assert(y == 12);
        LegacyTest.assert(z == 12);
        LegacyTest.assert(a == 14);
        LegacyTest.assert(b == 15);
    }

    var testIndexIncrementArg:Vector.<String> = ["one", "two", "three", "four", "five"];

    function testIndexIncrementArgs(one:String, two:String, three:String, five:String)
    {
        LegacyTest.assert(one == "one");
        LegacyTest.assert(two == "two");
        LegacyTest.assert(three == "three");
        LegacyTest.assert(five == "five");
    }

    function testPassAProp(x:int, y:int, z:int)
    {
        assert(x == 103);
        assert(y == 103);
        assert(z == 103);
    }


    function get property():int
    {
        return _property;
    }

    function set property(value:int)
    {
        _property = value;
    }

    var _property:int = 101;

    function test()
    {
        var x = 0;
        var y = x++;
        assert(y == 0);
        assert(++y == 1);
        assert(y++ == 1);
        assert(y == 2);
        
        var v = [1, 2, 3, 4, 5];
        assert(v[memberCounter++] == 1);
        assert(v[++memberCounter] == 3);
        assert(v[memberCounter++] == 3);
        assert(v[memberCounter++] == 4);
        assert(v[memberCounter] == 5);
        
        x = 1;
        y = x--;
        assert(y == 1);
        y = --x;
        assert(y == -1);
        
        x = 3;
        y = 2;
        var z = --x + y++;
        assert(z == 4);


        var xx = 1;
        testPreIncrementArgs(++xx, ++xx, ++xx);
        xx = 1;
        testPostIncrementArgs(xx++, xx++, xx++);
        xx = 10;

        testPostPreIncrementArgs(xx++, ++xx, xx++, ++xx, ++xx);

        xx = 0;
        testIndexIncrementArgs(testIndexIncrementArg[xx++], testIndexIncrementArg[xx++], testIndexIncrementArg[xx++], testIndexIncrementArg[++xx]);

        assert(property++ == 101);
        assert(++property == 103);

        testPassAProp(property++, --property, property--);

        assert(--property == 101);

        // test indexing with a property with increment
        property = 0;
        testIndexIncrementArgs(testIndexIncrementArg[property++], testIndexIncrementArg[property++], testIndexIncrementArg[property++], testIndexIncrementArg[++property]);

    }
    
    function TestIncrementExpression()
    {
        name = "TestIncrementExpression";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "";
}

}



