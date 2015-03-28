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

class TestConditional extends LegacyTest
{
    
    var ix:Number = 100;

    function doX():Number {
        log("X");
        
        return 1;
    }
    
    function doY():Number {
        log("Y");
        
        return 0;
    }

    // tests boolean conversion from object
    // which under JIT, as we have an unmodified VM, 
    // and Lua considers "" and 0 as true becomes interesting.
    // In cases where we know value is a number or string
    // this is handled, but when we are going from 
    // Object the compiler does not have this information
    // so it must be a runtime check
    // The "classic" Lua VM has additional opcodes
    // LoomScript adds to deal with this at runtime
    function testObject(value:Object):Boolean {

        if (value)  
            return true;

        return false;

    }

    function test()
    {
        
        assert(testObject(true));
        assert(!testObject(false));

        assert(!testObject(""));
        assert(!testObject(0));
        assert(testObject(1));
        assert(testObject("1"));
        assert(!testObject(null));

        var true1:Object;
        var true2:Object;
        var false1:Object;
        var false2:Object;

        true1 = 1;
        true2 = "1";
        false1 = 0;
        false2 = "";

        assert(true1 && true2 && !false1 && !false2 && !(true1 && false1) && !(false2 && true2));

        var x:Number = 1 == 1 ? 100 : 101;
        
        log(x);
        
        if (x == 10) {
            log(10);
        }
        else if (x == 50) {
            log(50);
        }
        else if (x == 60) {
            log(60);
        }
        else {
            log(x);
        }
        
        // another test
        
        if (x == 10) {
            log(10);
        }
        else if (x == 100) {
            log(x);
        }
        else if (x == 60) {
            log(60);
        }
        else {
            log(1000);
        }
        
        x = 1 == 2 ? 100 : 101;
        
        log(x);
        
        3 > 2 ? doX() : doY();
        
        doX() < doY() ? doX() : doY();
        
        var anumber = 1001;
        if( anumber ) 
            assert(anumber.getType().getName() == "Number" && anumber == 1001);
        else
            assert(false, "anumber was false");
            
        var astring = "hey";
        if( astring ) 
            assert(astring.getType().getName() == "String" && astring == "hey", astring);
        else 
            assert(false, "astring was false");
        
        ix = ix == 100 ? 101 : 100;
        assert(ix == 101);

        var i = 0;
        i ? assert(false, "ternary test 0 failed") : true;

        var j = "";
        j ? assert(false, "ternary test \"\" failed") : true;
        
    }
    
    function TestConditional()
    {
        name = "TestConditional";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
"100
100
100
101
X
X
Y
Y";    
}

}



