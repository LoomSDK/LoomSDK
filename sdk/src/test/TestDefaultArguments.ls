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

import system.reflection.Type;
import unittest.Test;

class DefaultArgConstructorTestClass
{
        public function DefaultArgConstructorTestClass(type:String, touches:Vector.<Object>, shiftKey:Boolean=false, 
                                   ctrlKey:Boolean=false, bubbles:Boolean=true)
        {
            Test.assert(bubbles == true, "Should be true!");
        }
}

class DefaultArgConstructorTestReflectClass
{
        public var aNumber:int = 41;
        public var anotherNumber:int = 41;

        public function DefaultArgConstructorTestReflectClass(_anumber:int=42)
        {
            Test.assert(_anumber == 42, "Should be 42!");
            aNumber = _anumber + 1;
            anotherNumber = 43;
        }
}


class TestDefaultArguments extends Test
{

    static function get a():String {
        return "a";
    }

    function funcB(x:String = a, y:String = "b", z:String = "c", w:String = "d")
    {
        log(x);
        log(y);
        log(z);
        log(w);        
    }
    
    static function funcA(x:Number, y:String = "1", z:Number = 2)
    {
        log(x);
        log(y);
        log(z);
    }

    // This is for comparison to the constructor above, to determine if the fact it is a 
    // constructor is causing special behavior.
    static function testMethodStatic(type:String, touches:Vector.<Object>, shiftKey:Boolean=false, 
                                   ctrlKey:Boolean=false, bubbles:Boolean=true):void
    {
            Test.assert(bubbles == true, "Should be true!");
    }

    // This is for comparison to the constructor as well; to rule out if static vs. instance
    // calls affect behavior.
    static function testMethod(type:String, touches:Vector.<Object>, shiftKey:Boolean=false, 
                                   ctrlKey:Boolean=false, bubbles:Boolean=true):void
    {
            Test.assert(bubbles == true, "Should be true!");
    }

    function test()
    {
        new DefaultArgConstructorTestClass("A", null);

        var type:Type = DefaultArgConstructorTestReflectClass;
        var constructor = type.getConstructor();

        var dac = constructor.invoke() as DefaultArgConstructorTestReflectClass;
        assert(dac.aNumber == 43, "should be 43");
        assert(dac.anotherNumber == 43, "should be 43");

        testMethodStatic("B", null);
        testMethod("B", null);
        
        funcA(0);
        funcA(1, "test");
        funcA(2, "go", 4);
        
        funcB();
        funcB("1");
        funcB("1", "2");
        funcB("1", "2", "3");
        funcB("1", "2", "3", "4");
        
        
    }
    
    function TestDefaultArguments()
    {
        name = "TestDefaultArguments";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "0121test22go4abcd1bcd12cd123d1234";    
}

}


