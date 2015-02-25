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

import TestImportResolution.PackageA.ClassA;
import TestImportResolution.PackageB.ClassA;

class ClassA {
    
    public var memberVar:String = "45";
    
}

// note that class name ALSO conflicts with top level package
class TestImportResolution extends LegacyTest
{    


    function takesPackageAClassA(a:TestImportResolution.PackageA.ClassA)
    {
        assert(a.memberVar == 42);

    }

    function takesPackageBClassA(a:TestImportResolution.PackageB.ClassA)
    {

        assert(a.memberVar == "43");

    }

    function test()
    {
        assert(TestImportResolution.PackageA.ClassA.getType().getFullName() == "TestImportResolution.PackageA.ClassA");
        assert(TestImportResolution.PackageB.ClassA.getType().getFullName() == "TestImportResolution.PackageB.ClassA");
        assert(tests.ClassA.getType().getFullName() == "tests.ClassA");
                
        var a = new TestImportResolution.PackageA.ClassA();
        var b = new TestImportResolution.PackageB.ClassA();
        var c = new tests.ClassA();
        
        // this will raise ambiguous class usage error
        //var d = new ClassA();
                
        assert(c.memberVar == "45");
        
        assert(a.getType().getFullName() == "TestImportResolution.PackageA.ClassA");
        assert(b.getType().getFullName() == "TestImportResolution.PackageB.ClassA");
        
        assert(a.memberVar == 42);
        assert(b.memberVar == "43");
                                
        assert(TestImportResolution.PackageA.ClassA.stringValue == "TestImportResolution.PackageA.ClassA");
        assert(TestImportResolution.PackageB.ClassA.stringValue == "TestImportResolution.PackageB.ClassA");
        assert(TestImportResolution.PackageA.ClassA.staticMethod() == "TestImportResolution.PackageA.ClassA.staticMethod");

        var aa:TestImportResolution.PackageA.ClassA = a;
        var ba:TestImportResolution.PackageB.ClassA = b;

        takesPackageAClassA(a);
        takesPackageBClassA(b);
        takesPackageAClassA(aa);
        takesPackageBClassA(ba);
                
    }
    
    function TestImportResolution()
    {
        name = "TestImportResolution";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "";    
}

}



