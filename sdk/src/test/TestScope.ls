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

delegate TestScopeA(a:Number, b:Number, c:Number):TestScopeC;
delegate TestScopeB(a:Number, b:Number):TestScopeC;
delegate TestScopeC(a:Number):Number;

delegate TestScopeAnonymousFunctionDelegate(a:int, b:int, c:int);

class TestForAnonymousFunction
{
    public var id:int;

    public var func:TestScopeAnonymousFunctionDelegate;

    public static function addInstance(instance:TestForAnonymousFunction)
    {
        instances.push(instance);
    }

    public static function tick()
    {
        for each (var v in instances)
        {
            var id = v.id;
            
            // we only check the last id as this is the instance captured by the closure
            // http://theengine.co/forums/loom-with-loomscript/topics/closure-madness-and-closurize                

            var check = id == 18;
            v.func(1, 2, 3);
            if (check)
                Test.assert(v.id == id + 1);
        }

    }

    private static var instances:Vector.<TestForAnonymousFunction> = [];

}

class TestScope extends Test
{
    function test()
    {
        
        
        var abc:TestScopeA = function(a:Number, b:Number, c:Number):TestScopeC {
            var x:Number = 123;
            var fx:TestScopeB = function (a:Number, b:Number):TestScopeC {
                
                var sc:TestScopeC = function (f:Number):Number {
                    return x + a + b + c + f;
                };
                
                return sc;
            };
            
            return fx(a, b);
        };
    
        var fn:TestScopeC = abc(3, 5, 6);
    
        var fsh:TestScopeC = abc(100, 100, 100);
    
        var x:Number = fn(3);
    
        var y:Number = fsh(200);
    
        log(x);
    
        log(y);
        
        for (x=0;x<10;x++) 
        {
            var v = new TestForAnonymousFunction;

            v.id = x;

            TestForAnonymousFunction.addInstance(v);

            v.func = function(x:int, y:int, z:int) 
            {
                assert(x == 1 && y == 2 && z == 3);
                // NOTE: the v here will always be the last v created in loop!
                // http://theengine.co/forums/loom-with-loomscript/topics/closure-madness-and-closurize                
                v.id = v.id + 1;
            };
        }        

        TestForAnonymousFunction.tick();

        // note this loop is never executed we're testing AS3 scoping and
        // defaults
        for (x = 0; x > 0; x++)
        {
            Debug.assert(0, "should never run");


            var testone = 1;
            var testtwo = "test";
            var testthree = new TestForAnonymousFunction;
            var testfour = true;
        }

        assert(testone == 0);
        assert(testtwo == null);
        assert(testthree == null);
        assert(testfour == false);

    }
    
    function TestScope()
    {
        name = "TestScope";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "140 623";    
}

// Compiler error
//var thisVariableIsDeclaredOutsideOfClassScope:Number = 1;

// Compiler error
//private function thisFunctionIsDeclaredOutsideOfClassScope():void {}

}



