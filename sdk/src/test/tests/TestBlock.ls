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

class TestBlock extends LegacyTest
{
    function test()
    {
        for (var a:Number = 1; a < 10; a++) {
            for (var b:Number = 1; b < 10; b++) {
                if (b == a) continue;
                for (var c:Number = 1; c < 10; c++) {
                    if (c == a || c == b) continue;
                    for (var d:Number = 1; d < 10; d++) {
                        if (d == a || d == b || d == c) continue;
                        for (var e:Number = 1; e < 10; e++) {
                            if (e == a || e == b || e == c || e == d) continue;
                            for (var f:Number = 1; f < 10; f++) {
                                if (f == a || f == b || f == c || f == d || f == e) continue;
                                for (var g:Number = 1; g < 10; g++) {
                                    if (g == a || g == b || g == c || g == d || g == e || g == f) continue;
                                    for (var h:Number = 1; h < 10; h++) {
                                        if (h == a || h == b || h == c || h == d || h == e || h == f || h == g) continue;
                                        for (var i:Number = 1; i < 10; i++) {
                                            if (i == a || i == b || i == c || i == d || i == e || i == f || i == g || i == h) continue;
                                            
                                            if (a + b + c == 15 && 
                                                d + e + f == 15 &&
                                                g + h + i == 15 &&
                                                a + d + g == 15 &&
                                                b + e + h == 15 &&
                                                c + f + i == 15 &&
                                                a + e + i == 15 &&
                                                c + e + g == 15) {
                                                log(a + " " + b + " " + c);
                                                log(d + " " + e + " " + f);
                                                log(g + " " + h + " " + i);
                                                log("--------");
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    function TestBlock()
    {
        name = "TestBlock";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "2 7 6
9 5 1
4 3 8
--------
2 9 4
7 5 3
6 1 8
--------
4 3 8
9 5 1
2 7 6
--------
4 9 2
3 5 7
8 1 6
--------
6 1 8
7 5 3
2 9 4
--------
6 7 2
1 5 9
8 3 4
--------
8 1 6
3 5 7
4 9 2
--------
8 3 4
1 5 9
6 7 2
--------";
}

}



