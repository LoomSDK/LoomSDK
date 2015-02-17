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

class TestWhile extends LegacyTest
{
    function test()
    {
        
        
        var i:Number = 0;
        var result:Number = 0;
        var j:Number = 0; 
        var k:Number = 0; 
        
        while (i<3) {
            j = 0; 
            while (j<1000) {
                k = 0; 
                while (k<1000) {
                    k++; 
                    result++; 
                }
                j++; 
            }
            i++;
            log(i);
        }
        log(result);
        log(j);
        log(k);
        
        
    }
    
    function TestWhile()
    {
        name = "TestWhile";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "1
2
3
3000000
1000
1000";   
}

}



