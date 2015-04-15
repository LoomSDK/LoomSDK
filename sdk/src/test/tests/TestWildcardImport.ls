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

import LegacyTest.Wildcards1.*;
import LegacyTest.Wildcards2.*;

class TestWildcardImport extends LegacyTest
{
    function test()
    {
        assert(LegacyTest.Wildcards1.WildCardImport1.n == 101);
        assert(LegacyTest.Wildcards2.WildCardImport1.n == 102);

        assert(LegacyTest.Wildcards1.WildCardImport2.s == "This is a test");
        assert(LegacyTest.Wildcards2.WildCardImport2.s == "This is also a test");

        var w1w1 = new LegacyTest.Wildcards1.WildCardImport1();
        var w2w1 = new LegacyTest.Wildcards2.WildCardImport1();

        var w1w2 = new LegacyTest.Wildcards1.WildCardImport2();
        var w2w2 = new LegacyTest.Wildcards2.WildCardImport2();

        assert(w1w1.getNumber() == 101);
        assert(w2w1.getNumber() == 102);

        assert(w1w2.getString() == "This is a test");
        assert(w2w2.getString() == "This is also a test");

        var uwc1 = new UniqueWildCard1();
        assert(uwc1.getNumber() == 1001);

        var uwc2 = new UniqueWildCard2();
        assert(uwc2.getString() == "A unique string");

    }
    
    public function TestWildcardImport()
    {
        name = "TestWildcardImport";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "";
}

}



