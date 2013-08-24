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

enum LoomScript { Rocks, The, Enums  };

enum Days { Saturday = 1, Sunday, Monday, Tuesday, Wednesday, Thursday, Friday };

enum Permissions { 
    All = 3,
    Update = 2,
    Read = 1,
    None = 0 
};

enum EnumOne {
    One = 1,
    Two = 2, 
    Three = 3,
    Four = 4
}

enum EnumTwo {
    Five = 5,
    Six = 6, 
    Seven = 7,
    Eight = 8
}

class TestEnum extends Test
{

    var x:Days = Days.Friday;

    function test()
    {

        log(LoomScript.Rocks + " " + LoomScript.The + " " + LoomScript.Enums);
        
        var castToNumber:Number = x;
        
        var castFromNumber:Days = castToNumber;
        
        log(x);
        log(castFromNumber);
        log(castToNumber);
        
        log((Permissions.Update | Permissions.Read) == Permissions.All);

        assert((EnumOne.One + EnumOne.Two) == 3);
        assert((EnumOne.Three + EnumTwo.Seven) == 10);
        assert((EnumTwo.Eight - EnumOne.Two ) == 6);
        assert((EnumTwo.Six * EnumOne.Four ) == 24);

        assert((EnumOne.One + 2) == 3);
        assert((3 + EnumTwo.Seven) == 10);
        assert((8 - EnumOne.Two ) == 6);
        assert((EnumTwo.Six * 4 ) == 24);

    }
    
    function TestEnum()
    {
        name = "TestEnum";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
    "0 1 2
7
7
7
true";    
}

}



