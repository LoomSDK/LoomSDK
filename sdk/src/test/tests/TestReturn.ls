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

class TestReturn extends LegacyTest
{
    // We need to have compiler tests so that we can intentionally have broken code and have
    // the test report this, for now we don't have this, but we have a ticket!
    // https://theengineco.atlassian.net/browse/LOOM-482
    
    function returnAString():String {
        
        // not returning this would break compiler test
        return "This is a String";
        
    }

    var _seedCurrent:uint;

    public function get rUint():uint
    {
        return _seedCurrent = 42;
    }
    
    function returnAnInt():int {
    
        return 6;
    
        // returning a string instead of a number would break compiler test
        //return "A String";
        
    }

    function test()
    {
        assert( rUint == 42);
        
        
    }
    
    function TestReturn()
    {
        name = "TestReturn";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "";    
}

}



