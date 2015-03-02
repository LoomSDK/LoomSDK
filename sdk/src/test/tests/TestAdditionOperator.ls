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

class TestAdditionOperator extends LegacyTest
{
    function test()
    {
        log(1 + "2" + "hello" + 1000);
        var t:String = 1000 + 10 + "a" + "c" + 1;
        
        log(t);
        
        log(1 + 2 + 3);
        log(1 + (2 * 3));
        
        var a:Number = 10000;
        var b:Number = 1;
        var c:Number = 2;
        
        log(a + b + c + 10);
        
        log(10 + 11);
    }
    
    function TestAdditionOperator()
    {
        name = "TestAdditionOperator";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "12hello1000
1010ac1
6
7
10013
21";    
}

}



