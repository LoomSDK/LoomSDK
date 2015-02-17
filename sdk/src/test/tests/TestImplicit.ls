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

class TestImplicitHelper
{
    public var anumber:Number = 100.123;
}

class TestImplicit extends LegacyTest
{

    function usesAVariableImplicitlyDefinedAfter():String
    {
        // implicit of an implicit defined after the function declaration
        var fixed = variableDeclatedAfter.anumber.toFixed(2);
        return fixed;
    }

    var variableDeclatedAfter = new TestImplicitHelper;

    function takesANumber(x:Number) {
        
    }
    
    function takesAString(x:String) {
    
        assert(x == "This should not cause a warning");
        
    }
    
    
    function getADictionaryLiteral():Dictionary.<String, Number> {
        return {"Hello" : 1002 };
    }
    
    
    // implicit typing of member variable with template type
    var memberDict = new Dictionary.<String, Number>();
    
    public function get properties():Dictionary.<String, Number>
    {
        return memberDict;
    }
    
    function test()
    {
        // implicit number
        var x = 100;
        assert(x.getType() == Number);
        
        // this shouldn't cause a warning
        takesANumber(x);
        
        // implicit Vector.<Object> from []
        var iv = [];

        assert(iv.length == 0);
        
        // implicit Vector.Object of length 3
        var iv2 = ["one", 2, true];
        
        assert(iv2.length == 3);
        
        // implicit Dictionary.<Object, Object> literal of length 0
        var id = {};
        
        assert(id.length == 0);
        
        // implicit Dictionary.<Object, Object> literal of length 3
        var id2 = { "one" : 1, "two" : 2, 3: "three" };
        
        assert(id2.length == 3);
        assert(id2["one"] == 1);
        assert(id2["two"] == 2);
        assert(id2[3] == "three");
        
        // implicit vector assign
        var v = new Vector.<String>;
        v.pushSingle("This should not cause a warning");
        
        takesAString(v[0]);
        
        // implicit i assign to v index type
        for each (var i in v) {
        
            takesAString(i);
        
        }
        
        // implicit i assign to v index type
        for (var j in v) {
        
            assert(j == 0);
            takesANumber(j);
        
        }
        
        var d = new Dictionary.<Number, String>;
        d[1001] = "This should not cause a warning";

        // implicit i assign to v value type        
        for each (var k in d) {
            takesAString(k);
        }
        
        // explicit assign (reusing local variable) to key types
        for (x in d) {
            assert(x == 1001);
            takesANumber(x);
        }
        
        // implicit assign to key types
        for (var y in d) {
            assert(y == 1001);
            takesANumber(y);
        }
        
        // explicit var with type over keys
        for (var z:Number in d) {
            assert(z == 1001);
            takesANumber(z);
        }
        
        // explicit var with type over keys
        for each(var zz:String in d) {
            takesAString(zz);
        }
        
        // implicit typing from return value on values
        for each(var n in getADictionaryLiteral()) {
            assert(n == 1002);
        }
        
        // implicit typing from return value on keys
        for (var s in getADictionaryLiteral()) {
            assert(s == "Hello");
        }

        memberDict["World"] = 777;
        
        for (var ss in memberDict) {
            assert(ss == "World");
        }

        for each(var nn in memberDict) {
            assert(nn == 777);
        }
        
        memberDict["World"] = null;
        memberDict["Hello"] = 1003;
        
        for (ss in properties) {
            assert(ss == "Hello");
        }

        for each(nn in properties) {
            assert(nn == 1003);
        }

        assert (usesAVariableImplicitlyDefinedAfter() == "100.12");
        
    }
    
    function TestImplicit()
    {
        name = "TestImplicit";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "";
}

}



