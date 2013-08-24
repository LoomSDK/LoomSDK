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

class MyTestObject {
    
    public function toString():String {
        
        return "I am a MyTestObject!";
        
    }
    
}

class TestToString extends Test
{
    function test()
    {
        var n:Number = 10000;
        
        var b:Boolean = true;
        
        var s:String = "I am a string";
        
        var x:MyTestObject = new MyTestObject;
        
        log(x.toString());
        
        log(n.toString());
        
        log(b.toString());
        
        log(s.toString());
        
        log(this.toString());

        // String cast        
        log(String(x));
        
        log(String(n));
        
        log(String(b));
        
        log(String(s));
        
        log(String(this));
        
        log(String(String(x) + n + 100));
    }
    
    function TestToString()
    {
        name = "TestToString";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "
I am a MyTestObject!
10000
true
I am a string
Object:tests.TestToString
I am a MyTestObject!
10000
true
I am a string
Object:tests.TestToString
I am a MyTestObject!10000100";    
}

}



