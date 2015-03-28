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

class TestBitOps extends LegacyTest
{
    function test()
    {
        var x: Number = 1;

        // 2        
        x = x << 1;
        log(x);
        
        // 4
        x <<= 1;
        log(x);
        
        var y:Number = 1;

        // 2        
        x = x >> y;
        log(x);
        
        // 1
        x >>= y;
        log(x);
        
        // 16
        y = 4;
        x <<= y;
        log(x);
        
        // 17
        x = x | 1;
        log(x);
        
        // 16
        x &= 0xFFF0;
        log(x);
        
        // 65504
        x = x ^ 0xFFF0;
        log(x);
        
        // 16
        x ^= 0xFFF0;
        log(x);
        
        // -17
        x = ~x;
        log(x);
    }
    
    function TestBitOps()
    {
        name = "TestBitOps";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "2
4
2
1
16
17
16
65504
16
-17";
}

}



