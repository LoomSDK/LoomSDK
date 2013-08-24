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

class TestVarArg extends Test
{

    function passingADictionaryToVariableArgs(... args) {
        
        if (args[0]) {
        
            var strings:Dictionary.<Number, String> = args[1] as Dictionary.<Number, String>;
            assert(strings[1] == "one");
            assert(strings[2] == "two");
            assert(strings[3] == "three");
            
        } else {
        
            assert(args[1] == "one");
            assert(args[2] == "two");
            assert(args[3] == "three");
            
        }
        
    }

    function testParsingVarArgWithArrayType(... args:Array):void
    {
    }
    
    function testParsingVarArgWithVectorType(... args:Vector.<Object>):void
    {
    }

    function passingADictionaryToVariableArgs2(... args) {
        
        var strings:Dictionary.<Number, String> = args[0] as Dictionary.<Number, String>;
        assert(strings[1] == "one");
        assert(strings[2] == "two");
        assert(strings[3] == "three");
    }
    

    function doSomethingElse(v:Vector.<Object>)
    {
        for (var i:Number = 0; i < v.length; i++)
            log(v[i]);
    }

    function doSomething(x:Number, s:String, ...args)
    {
        log(x);
        log(s);
        for (var i:Number = 0; i < args.length; i++)
            log(args[i]);
            
        doSomethingElse(args);
        
    }
    
    function doSomethingWithDefaultArg(x:Number, s:String = "this is the default", ...args)
    {
                
        assert(x == 42);
        
        if (args && args.length == 2) {
        
            assert(s == "this is not the default", "s == \"this is not the default\"");
            assert(args[0] == 1, "args[0] == 1");
            assert(args[1] == 2, "args[1] == 2");
            
        } else {
        
            assert(s == "this is the default", "this is the default");
        
        }
        
    }
    
    static function staticDoSomethingWithDefaultArg(x:Number, y:Number = 7, s:String = "this is the default!", ...args)
    {
                
        assert(x == 42);
        
        if (args && args.length == 3) {
        
            assert(y == 8);
            assert(s == "this is not the default!", "s == \"this is not the default!\"");
            assert(args[0] == 1, "args[0] == 1");
            assert(args[1] == 2, "args[1] == 2");
            assert(args[2] == 3, "args[2] == 3");
            
        } else {

            assert(y == 7);        
            assert(s == "this is the default!", "this is the default!");
        
        }
        
    }

    

    function test()
    {
        var strings:Dictionary.<Number, String> = { 1 : "one", 2 : "two", 3 : "three" };
        passingADictionaryToVariableArgs(true, strings);
        
        passingADictionaryToVariableArgs(false, strings[1], strings[2], strings[3]);
        
        passingADictionaryToVariableArgs2(strings);
        
        doSomething(1, "California");
        doSomething(2, "Minnesota", "Minneapolis");
        doSomething(3, "Oregon", "Eugene", "USA");
    
        doSomethingWithDefaultArg(42);
        doSomethingWithDefaultArg(42, "this is not the default", 1, 2);
        
        staticDoSomethingWithDefaultArg(42);
        staticDoSomethingWithDefaultArg(42, 8, "this is not the default!", 1, 2, 3);

        
    }
    
    function TestVarArg()
    {
        name = "TestVarArg";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "1
California
2
Minnesota
Minneapolis
Minneapolis
3
Oregon
Eugene
USA
Eugene
USA";    
}

}



