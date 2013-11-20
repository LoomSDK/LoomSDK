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

delegate TestFunctionDelegate(a:Number, b:Number):Number;

class FunctionMethodTestClass {

    public var intValue = 100;
    
    static var argTest:Vector.<String> = new Vector.<String>;
    
    public static function checkTestArgs(...args) {
    
        Test.assert(args != null, "checkTestArgs, null args");
                        
        Test.assert(args.length == argTest.length, "args.length != argTest.length");
            
        for (var argIdx:Number in args) {
            
            Test.assert(args[argIdx] == argTest[argIdx], "arg mismatch at index: " + argIdx);
            
        }
        
        argTest.clear();
        
    }
    
    static function testFunctionStaticMethod(hello:String, you:Number) {
    
        argTest.pushSingle(hello);
        argTest.pushSingle(you.toString());        
    }
    
    function testFunctionInstanceMethod(hello:String, you:Number) {
    
        argTest.pushSingle(this.getType().getName());        
        argTest.pushSingle(hello);
        argTest.pushSingle(you.toString());
        argTest.pushSingle(intValue.toString());
        
    }
    
    static function testFunctionStaticNoArgsMethod() {
    
        argTest.pushSingle("testFunctionStaticNoArgsMethod");
    
    }

    function testFunctionInstanceNoArgsMethod() {
    
        argTest.pushSingle(this.getType().getName());            
        argTest.pushSingle("testFunctionInstanceNoArgsMethod");        

    }
    
}

class TestFunction extends Test
{

    var memberFunction:Function;

    private function testVarArgs(...args)
    {
        // test for member function called from Function without args
        assert(args == null);
    }

    private function testVarArgsApply( ...args ):void
    {
        assert(args.getType().getFullName() == "system.Vector");
        assert(args[0] == 101);
        assert(args[1] == "hello1");
        assert(args[2] == "hello2");
    }


    function test()
    {
        

        var a:Number = 1;
        var b:Number = 2;
        
        var abc:TestFunctionDelegate = function (a:Number,b:Number):Number {
            var c:Number = a+b;
            var d:Number = a * b;
            log(c);
            log(d);
            return d;
        };

        var ret:Number = abc(5,6);
        var x:Number = ret + 100;
        log(x);
        
        log(a);
        log(b);
        ret = abc(3,4);
        log(ret+100);
        
        log(x);
        
        FunctionMethodTestClass.testFunctionStaticMethod.call(null, "Hello", 42);
        FunctionMethodTestClass.checkTestArgs("Hello", "42");
            
        var fm = new FunctionMethodTestClass;
        var fm2 = new FunctionMethodTestClass;
        fm2.intValue = 101;
        
        FunctionMethodTestClass.testFunctionInstanceMethod.call(fm, "Hello", 42);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Hello", "42", "100");
        
        FunctionMethodTestClass.testFunctionInstanceMethod.call(fm2, "Hello", 42);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Hello", "42", "101");

        fm.testFunctionInstanceMethod.call(fm, "Hello", 42);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Hello", "42", "100");
        fm2.testFunctionInstanceMethod.call(fm2, "Hello", 42);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Hello", "42", "101");
        
        // kris-kross
        fm.testFunctionInstanceMethod.call(fm2, "Hello", 42);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Hello", "42", "101");
        fm2.testFunctionInstanceMethod.call(fm, "Hello", 42);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Hello", "42", "100");
        
        var funkypants:Function = FunctionMethodTestClass.testFunctionInstanceMethod;
        funkypants.call(fm, "Hello", 1000000);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Hello", "1000000", "100");
        
        // assign, with kris-kross
        var funkypants2:Function = fm.testFunctionInstanceMethod;
        funkypants2.call(fm2, "Hello", 1000000);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Hello", "1000000", "101");
 
        // test apply
        var args:Vector.<Object> = new Vector.<Object> ["Zing", 2001];    
        funkypants2.apply(fm2, args);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Zing", "2001", "101");

        
        // implicit typing 
        var staticpants = FunctionMethodTestClass.testFunctionStaticMethod;
        staticpants.call(null, "I am the static pants", 1001);
        FunctionMethodTestClass.checkTestArgs("I am the static pants", "1001");
        
        FunctionMethodTestClass.testFunctionStaticNoArgsMethod.call();
        FunctionMethodTestClass.checkTestArgs("testFunctionStaticNoArgsMethod");
        FunctionMethodTestClass.testFunctionInstanceNoArgsMethod.call(fm);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "testFunctionInstanceNoArgsMethod");
                    
        var targs:Vector.<String> = new Vector.<String>;
        var anonymouspants = function (x:String, y:Number) {
            targs.pushSingle("Anonymous Pants");
            targs.pushSingle(x);
            targs.pushSingle(y.toString());
        };
        
        anonymouspants.call(null, "Whee", 200);
        
        assert(targs[0] == "Anonymous Pants");
        assert(targs[1] == "Whee");
        assert(targs[2] == "200");
        targs.clear();
        
        
        var args2:Vector.<Object> = new Vector.<Object> ["Whoo", 201];
        anonymouspants.apply(null, args2);
        
        assert(targs[0] == "Anonymous Pants");
        assert(targs[1] == "Whoo");
        assert(targs[2] == "201");
        targs.clear();
        
        var takesnothing = function () {
            targs.pushSingle("Takes Nothing");
        };
        
        takesnothing.call();
        assert(targs[0] == "Takes Nothing");
        targs.clear();
        
        
        takesnothing.apply();
        assert(targs[0] == "Takes Nothing");        
        targs.clear();

        takesnothing();
        assert(targs[0] == "Takes Nothing");
        targs.clear();

        anonymouspants("Hello", 201);
        assert(targs[0] == "Anonymous Pants");
        assert(targs[1] == "Hello");
        assert(targs[2] == "201");
        targs.clear();

        var _funkypants2:Function = fm.testFunctionInstanceMethod;
        _funkypants2("Hello", 1000000);
        FunctionMethodTestClass.checkTestArgs("FunctionMethodTestClass", "Hello", "1000000", "100");

        var _funkypants3 = FunctionMethodTestClass.testFunctionStaticMethod;
        _funkypants3("Hello", 42);
        FunctionMethodTestClass.checkTestArgs("Hello", "42");        

        assert(_funkypants2.length == 2);

        assert(_funkypants3.length == 2);       

        assert(takesnothing.length == 0);

        assert(anonymouspants.length == 2); 

        memberFunction = _funkypants3;
        assert(memberFunction.length == 2);
        memberFunction("HelloMemberFunction", 101);
        FunctionMethodTestClass.checkTestArgs("HelloMemberFunction", "101");   

        var funcTestVarArgs:Function;

        // assign to member, which takes var args
        funcTestVarArgs = testVarArgs;

        // call without var args, which will be null args
        funcTestVarArgs();    

        // anonymous function
        funcTestVarArgs = function (...args)  { 
            assert(args == null);
        };

        // call with no args,  will be null args
        funcTestVarArgs();   

        var funcRef:Function = testVarArgsApply;
        funcRef.apply( null, [101, "hello1", "hello2"] );

        

    }
    
    function TestFunction()
    {
        name = "TestFunction";   
        expected = EXPECTED_TEST_RESULT;

    }    
       
    var EXPECTED_TEST_RESULT:String = 
"113013012712112130";
        
}

}



