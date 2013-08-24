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

class TestMath extends Test
{

    function passAnIntValue(x:int) {
        assert(x == 3);
    }
    
    function test()
    {
        assert(Math.min(10, -1) == -1);
        assert(Math.max(10, -1) == 10);
        
        assert(Math.min(10, -1, 50, -100, 61) == -100);
        assert(Math.max(10, -1, 100, 1000, -23, 5) == 1000);
        
        // int cast passed to method
        passAnIntValue(int(3.14));
        
        //implicit Number assign from int cast of Number Literal
        var z = int(1001.5);
        assert( z == 1001);
        
        var y:float = 1.8;
        // implicit Number type from cast of Number variable
        var x = int(y);
        assert (x == 1);
        
        // int cast from boolean
        assert (int(false) == 0);
        assert (int(true) == 1);

        // int cast from string        
        assert (int("1002.8") == 1002);

        // Use fromString too.
        assert (Number.fromString("1002.8") == 1002.8);

        // Test NaN and isNaN.
        assert(NaN != NaN);
        assert(isNaN(0) == false);
        assert(isNaN(-1) == false);
        assert(isNaN(100.34) == false);
        assert(isNaN(NaN) == true);
        assert(isNaN(0/0) == true);

        // Look at infinite and min/max value.
        assert(Number != null);
        assert(Number.MAX_VALUE > 0);
        assert(0.0 < Number.MIN_VALUE);
        assert(Number.POSITIVE_INFINITY > 0);
        assert(Number.NEGATIVE_INFINITY < 0);
        assert(Number.POSITIVE_INFINITY > Number.MAX_VALUE);
        assert(Number.NEGATIVE_INFINITY < -Number.MAX_VALUE);
    }
    
    function TestMath()
    {
        name = "TestMath";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "";   
}

}



