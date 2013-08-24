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
import system.Coroutine;
import system.Console;

class TestCoroutine extends Test
{
    
    var svalue:String = "I hope this works";
    
    static var staticValue:String = "I hope this works too";
    
    function methodCoroutine(a:Number, b:Number):Number {
            
        log("I am in a method");
        log(svalue);
        yield(1);
        log("I am leaving method");
        log(svalue);
                
        yield(a + b);
        
        return 42;
    
    }
    
    static function staticMethodCoroutine(a:Number, b:Number):String {
    
        log("I am in a static method");
        log(staticValue);
        yield(2);
        log("I am leaving the static method");
        log(staticValue);
        
        yield( a + b );
        
        return "42";
        
    }
    
    function earlyExitCoroutine(a:Number, b:Number):String {
    
        yield("one : " + a);
        yield("two : " + b);
        yield("three");
        
        if (true)
            return "four";
            
        yield("five");
        yield("six");
        
        return "";
        
    }
    
    
    function test()
    {
        
        var c:Coroutine;
        
        c = Coroutine.create(function(a:Number, b:Number, c:Number):Number { a = yield(a + b + c) as Number; yield (a * a); return 42;});
        assert((c.resume(1, 2, 3) as Number) == 6);
        assert(c.resume(7) == 49);
        assert(c.resume() == 42);
        assert(!c.alive);
        
        c = Coroutine.create(function():Number { log("One"); yield(); log("Two"); return 42;});
        
        c.resume();
        assert(c.resume() == 42);
        assert(!c.alive);
        
        c = Coroutine.create(methodCoroutine);
        
        
        assert(c.resume(10, 20) == 1);
        svalue = "it does!";
        assert(c.resume() == 30);
        assert(c.resume() == 42);
        assert(!c.alive);
        
        c = Coroutine.create(staticMethodCoroutine);
        
        assert(c.resume(30, 40) == 2);
        staticValue = "it does too!";
        assert(c.resume() == 70);
        assert(c.resume() == "42");
        assert(!c.alive);
        
        c = Coroutine.create(earlyExitCoroutine);
        assert(c.resume(1, 2) == "one : 1");
        assert(c.resume() == "two : 2");
        assert(c.resume() == "three");
        assert(c.resume() == "four");
        assert(!c.alive);

        c = Coroutine.create(function():String { 

            var resolutions:Vector.<String> = ["1280x720", "1368x768", "1920x1080"];
            var r:String;
            var r2:String;
            var r3:String;

            for each (r in resolutions)
            {
                yield("not done");
                for each (r2 in resolutions)
                {
                    yield("not done");
                    for each (r3 in resolutions)
                    {
                        yield("not done");
                        if (r3 == "1368x768")
                            break;
                    }
                }
            }

            assert(r == "1920x1080" && r2 == "1920x1080" && r3 == "1368x768");
            
            return "done";

        });

        while(c.alive)
        {
            var status = c.resume();
            if (!c.alive)
                assert(status == "done");

        }

        
        
                
    }
    
    function TestCoroutine()
    {
        name = "TestCoroutine";   
        expected = EXPECTED_TEST_RESULT;

    }    
        
    var EXPECTED_TEST_RESULT:String = "
One
Two
I am in a method
I hope this works
I am leaving method
it does!
I am in a static method
I hope this works too
I am leaving the static method
it does too!";    
}

}



