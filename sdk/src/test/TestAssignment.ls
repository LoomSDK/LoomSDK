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

class TestAssignment extends Test
{

    var memberVar:Number = 10;
    
    function returnANumber():Number {
        return 42;
    }
    
    function set propertyNumber(value:Number) {
    
        _propertyNumber = value;
        
    }
    
    function get propertyNumber():Number {
    
        return _propertyNumber;
        
    }
    
    var _propertyNumber:Number = 43;
    
    function test()
    {
    
        var x = 1;
        
        assert(x == 1);
        
        var y = 2;
        
        assert(y == 2);
        
        x = y = 3;
                        
        assert(x == 3);
        assert(y == 3);
        
        var z = x = y = 4;
                        
        assert(x == 4);
        assert(y == 4);
        assert(z == 4);
        
        assert(memberVar == 10);
        
        var w = z = memberVar = x = y = 5;
        
        assert(x == 5);
        assert(y == 5);
        assert(z == 5);
        assert(w == 5);
        assert(memberVar == 5);
        
        var a = z = memberVar = x = y = w = returnANumber();
        
        assert(x == 42);
        assert(y == 42);
        assert(z == 42);
        assert(w == 42);
        assert(memberVar == 42);
        assert(a == 42);
        
        propertyNumber = a = z = memberVar = x = y = w = propertyNumber + 1;
        
        assert(propertyNumber == 44);
        assert(x == 44);
        assert(y == 44);
        assert(z == 44);
        assert(w == 44);
        assert(memberVar == 44);
        assert(a == 44);
    
    }
    
    function TestAssignment()
    {
        name = "TestAssignment";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "";
}

}



