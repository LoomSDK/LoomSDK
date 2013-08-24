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

delegate MyNativeDelegate(x:Number, y:Number);
delegate TestRecursionDelegate(one:Number, two:Number, three:Number, four:Number, five:Number);
delegate MyDelegate(x:Number, y:Number):String;
delegate MyOtherDelegate(x:String, y:String):Number;
delegate ClosureDelegate(x:Number);

native class TestNativeDelegate {

    public native var nativeDelegate:MyNativeDelegate;
    
    public native function triggerDelegate();

    // recursion test

    public native var recursionDelegate:TestRecursionDelegate;    

    // triggers the nativeDelegateRecursionInvoked which in turn calls this, so recurses up to recursionCount
    public native function testRecursion(one:Number, two:Number, three:Number, four:Number, five:Number);
    
}

class TestDelegate extends Test
{
    
    var callback:MyDelegate;
    
    static var scallback:MyOtherDelegate;
    
    var counter:Number;
    
    function func(x:Number, y:Number):String {
        
        return "Hello " + x + " " + y;
        
    }
    
    function nfunc(x:Number, y:Number) {
        
        log("Hello Native " + x + " " + y);
        
    }
    
    function nfunc2(x:Number, y:Number) {
        
        log("Hello Native2 " + x + " " + y);
        
    }
    
    
    var callCount = 0;
    
    function otherFunc(x:String, y:String):Number {
    
        callCount++;
        log(x + " " + y);
        return 100;
        
    }
    
    function multiCall(x:String, y:String):Number {
            
        callCount++;
        return 200;
    
    }
    
    function testNativeDelegate() {
        
        var nd = new TestNativeDelegate();
        
        // check op assign
        nd.nativeDelegate = nfunc;
        nd.triggerDelegate();
        
        // check that += on already assigned is nop
        nd.nativeDelegate += nfunc;
        nd.triggerDelegate();
        
        // check -= on method
        nd.nativeDelegate -= nfunc;
        nd.triggerDelegate();
        
        // and add it back
        nd.nativeDelegate += nfunc;
        // add another to it
        nd.nativeDelegate += nfunc2;
        nd.triggerDelegate();
        
        // remove the first one
        nd.nativeDelegate -= nfunc;
        nd.triggerDelegate();
        
        nd.nativeDelegate += nfunc;
        nd.triggerDelegate();
        
        nd.nativeDelegate = null;
        nd.triggerDelegate();
        
        
        // native delegate is called with x, y arguments of 10/20 arguments from C++
        
        var result:Number;
        
        var f:Function = function(x:Number, y:Number) { result += x * y + 3; };
        
        nd.nativeDelegate = function(x:Number, y:Number) { result += x * y + 1; };
        nd.triggerDelegate();
        
        nd.nativeDelegate += function(x:Number, y:Number) { result += x * y + 2; };
        nd.triggerDelegate();
        
        nd.nativeDelegate += f;
        nd.triggerDelegate();
        
        nd.nativeDelegate -=f;
        nd.triggerDelegate();
        
        assert(result == 1613);
        
        // clear
        nd.nativeDelegate = null;
        nd.triggerDelegate();
        
        assert(result == 1613);
        
        
    }
    
    public static function closurize(func:Function, ...args):Function
    {
        // Create a new function...
        return function():Object
        {
            // Call the original function with provided args.
            return func.apply(null, args);
        };
    }

    // recursion test

    var recursionTest = new TestNativeDelegate;
    var recursionCount = 10;

    function nativeDelegateRecursionInvoked(one:Number, two:Number, three:Number, four:Number, five:Number) 
    {

        recursionCount--;
        
        if (recursionCount > 0)
        {
            recursionTest.testRecursion(recursionCount + one, recursionCount + two, recursionCount + three, recursionCount + four, recursionCount + five);
        }
        else
        {
            // make sure recursion was handled properly
            assert(one == 46 && two == 47 && three == 48 && four == 49 && five == 50, "recursion test error");
        }

    }
 
    function test()
    {
        
        
        // call empty delegate
        callback(10, 20);
        
        // call empty static delegate
        scallback("Empty", "Delegate");
        
        callback = func;
        
        var callback2:MyOtherDelegate = otherFunc; 
        
        callback2 += multiCall;
        
        var x:String = callback(10, 20);
        
        callback2("It!", "Works!");
        
        log(callCount);        
        
        callback2 -= multiCall;
        
        log(callback2("It!", "Works!"));
        
        scallback = otherFunc;
        
        scallback("It!", "Works!");
        
        log(x);
        
        // test instantiated delegate
        var icallback = new MyDelegate();
        icallback += func;
        log(icallback(1000, 1001));
        
        testNativeDelegate();
        
        var closure = new ClosureDelegate();
        
        for(var i=0; i<4; i++)
            closure += closurize(function(param:int):void { this.counter += param + 1; }, i);     
            
        closure(0); 
        
        assert(counter == 10);
        
        // reset the delegate
        closure = null;
        counter = 0;
        
        // j will always be 4 in the function 
        for(var j=0; j<4; j++)
            closure += function(param:int):void { counter += j + param; };
            
        closure(1);
        
        assert(counter == 20);

        // recursion test
        recursionTest.recursionDelegate += nativeDelegateRecursionInvoked;
        recursionTest.testRecursion(1, 2, 3, 4, 5);
        
    }
    
    function TestDelegate()
    {
        name = "TestDelegate";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
    "It! Works!
2
It! Works!
100
It! Works!
Hello 10 20
Hello 1000 1001
Hello Native 10 20
Hello Native 10 20
Hello Native 10 20
Hello Native2 10 20
Hello Native2 10 20
Hello Native2 10 20
Hello Native 10 20
";
    
}

}



