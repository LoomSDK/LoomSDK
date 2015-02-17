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

delegate TestLocalDelegate(a:Number, b:Number):Number;

class TestLocal extends LegacyTest
{
    function test()
    {
        

        var a:Number = 1;
        var b:Number = 2;
        
        var abc:TestLocalDelegate = function (a:Number,b:Number):Number {
            var c:Number = a+b;
            var d:Number = a * b;
            log(c);
            log(d);
            return d;
        };
        
        var ret:Number = abc(5,6);
        var x:Number =  ret + 100;
        log(x);
        
        log(a);
        log(b);
        ret = abc(3,4);
        log(ret+100);
        
        log(x);

        
        
    }
    
    function TestLocal()
    {
        name = "TestLocal";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
                            "11
                            30
                            130
                            1
                            2
                            7
                            12
                            112
                            130";
    
}

}



