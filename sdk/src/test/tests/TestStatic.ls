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

package tests 
{

import unittest.LegacyTest;

class TestStaticClassOverrideBase 
{
    
    public static function myMethod(numArg:Number, stringArg:String):Number 
    {
    
        return numArg;
        
    }

    public static const overrideStatic:Number = 1001;

    public static function testOverride()
    {
        LegacyTest.assert(overrideStatic == 1001);
    }
    
}

class TestStaticClassOverrideChild extends TestStaticClassOverrideBase
{
    
    public static function myMethod(stringArg:String, numArg:Number, anotherArg:Number):String 
    {
    
        // super is TestStaticClassOverrideBase.myMethod which has a different method signature
        LegacyTest.assert(super(numArg, stringArg) == 100);
    
        return "TestStaticClassOverrideChild::myMethod " + stringArg + numArg + anotherArg;
        
    }

    public static const overrideStatic:String = "This is the overridden static";

    public static override function testOverride()
    {
        super();
        LegacyTest.assert(overrideStatic == "This is the overridden static");
    }

    
}


class TestStatic extends LegacyTest
{

    public static var x:Number = 101;
    public static var y:Number = 102;
    public static var z:Number = 103;
    
    public static var msg:String = "Hiya!";
    
    public var instanceVar:Number = 10000;
    
    public static function staticMethod (nx:String, y:String , z:String) 
    {

        // access static vars
        log(TestStatic.x);
        log(TestStatic.y);
        log(TestStatic.z);        
        
        // properly reference static x, note parameter is nx
        log(x);
        
        // local vars from call have proper scope
        log(nx);
        log(y);
        log(z);

        var base = new TestStaticClassOverrideBase();
        var child = new TestStaticClassOverrideChild();


        assert(TestStaticClassOverrideBase.overrideStatic == 1001);
        assert(TestStaticClassOverrideChild.overrideStatic == "This is the overridden static");

        assert(base.overrideStatic == 1001);
        assert(child.overrideStatic == "This is the overridden static");

        TestStaticClassOverrideBase.testOverride();
        TestStaticClassOverrideChild.testOverride();

        base.testOverride();
        child.testOverride();

    }

    function test()
    {
        
        
        // access instance var without qualifier
        log(instanceVar);
        
        // access instanceVar with this qualifier
        log(this.instanceVar);

        // make sure not available at static scope
        // this is an error now
        // log(TestStatic.instanceVar);        
        
        staticMethod("A", "B", "C");
        
        // access static var, via class, in bound method
        log(TestStatic.x);
        
        // set static member
        TestStatic.x = 104;
        
        // access static variable without qualified name
        log(x);
        
        // set static variable without qualified name
        x = 103;
        
        // ensure that the static is indeed set
        log(TestStatic.x);
        
        // strings too!
        log(msg);

        Debug.assert(TestStaticClassOverrideBase.myMethod(100, "Hello") == 100, "Error calling static override base");
        Debug.assert(TestStaticClassOverrideChild.myMethod("Hello", 100, 101) == "TestStaticClassOverrideChild::myMethod Hello100101", "Error calling static override child");
        
        
    }
    
    function TestStatic()
    {
        name = "TestStatic";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
"10000
10000
101
102
103
101
A
B
C
101
104
103
Hiya!";    
}

}



