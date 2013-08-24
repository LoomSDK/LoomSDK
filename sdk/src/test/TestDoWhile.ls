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

class TestDoWhile extends Test
{
    function test()
    {
        
        
        var x:Number = 10;
        
        do {
        
            log(x);
        
        } while(x-- > 0);
        
        
    }
    
    function TestDoWhile()
    {
        name = "TestDoWhile";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
    "10
9
8
7
6
5
4
3
2
1";    
}

}



