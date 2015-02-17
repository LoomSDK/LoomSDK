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

delegate SimpleFunction();

class TestSwitch extends LegacyTest
{
    function test()
    {

        
        
        for (var i:Number = -1; i < 4; i++)
        {            
            switch(i) {
                case 1:
                    var x:SimpleFunction = function () { log (1);};
                    x();
                    break;
                case 2:
                    log("2");
                    for (var j:Number = 0; j < 4; j++)
                    {
                        switch(j) {
                        
                            case 0:
                                log ("duck");
                                break;
                            case 1:
                                log ("deer");
                                break;
                            case 2:
                                log ("bear");
                                break;
                            default:
                                log ("forest");
                        }
                    }
                    break;
                case 3:
                    log("3");
                case 0:
                    log("0");
                    break;
                default: 
                    log("default"); 
            }
        
        }
        
        
    }
    
    function TestSwitch()
    {
        name = "TestSwitch";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "default
0
1
2
duck
deer
bear
forest
3
0";   
}

}



