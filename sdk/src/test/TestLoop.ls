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

class TestLoop extends Test
{
    var memberX:int;

    function test()
    {
        
        
        for ( var i:Number = 1; i < 10; i++) {
            if (i % 2 == 0) continue;
            for ( var j:Number = i; j < 10; j++) {
                if (j > 7) break;
                
                log(i + " * " + j + " = " + (i * j));
            }
        }    
        
        var x = 0;
        
        for (;;) {
            
            if (x == 10)
                break;
            
            x++;
            
        }
        
        assert(x == 10);
        
        
        x = 0;
        
        for (;;x++) {
            
            if (x == 10)
                break;
            
        }
        
        assert(x == 10);
        
        for (x = 0;;x++) {
            
            if (x == 10)
                break;
            
        }
        
        assert(x == 10);

        var resolutions:Vector.<String> = ["1280x720", "1368x768", "1920x1080"];
        var r:String;
        var r2:String;
        var r3:String;

        for each (r in resolutions)
        {
            for each (r2 in resolutions)
            {
                for each (r3 in resolutions)
                {
                    if (r3 == "1368x768")
                        break;
                }
            }
        }

        assert(r == "1920x1080" && r2 == "1920x1080" && r3 == "1368x768");

        for each (r in resolutions)
        {
            if (r == "1368x768")
                break;

        }

        assert(r == "1368x768");


        for (x in resolutions)
        {

        }

        assert ( x == 2);

        for (x in resolutions)
        {
            if (x == 1)
                break;

        }

        assert ( x == 1);

        for (memberX = 0; memberX < resolutions.length; memberX++)
        {

        }

        assert(memberX == 3);


        for (memberX = 0; memberX < resolutions.length; memberX++)
        {
            if (memberX == 2)
                break;

        }

        assert(memberX == 2);


        // These should error gracefully 
        /*
        for each(var foo:Foo in bar) {
            trace(foo);
        }  
        
        var bar:Foo = new Foo(); // local variable
        for each(var foo:Foo in bar) {
            trace(foo);
        }
        
        var fs:String = "Test";

        for each (var s in fs)
        {
            trace(s);
        }

        for (var s in fs)
        {
            trace(s);
        }            

        var bar:String="bar";
        for each(var foo:char in bar) 
        {
            trace(foo);
        }

        */           

    }
    
    function TestLoop()
    {
        name = "TestLoop";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
    "1 * 1 = 1
    1 * 2 = 2
    1 * 3 = 3
    1 * 4 = 4
    1 * 5 = 5
    1 * 6 = 6
    1 * 7 = 7
    3 * 3 = 9
    3 * 4 = 12
    3 * 5 = 15
    3 * 6 = 18
    3 * 7 = 21
    5 * 5 = 25
    5 * 6 = 30
    5 * 7 = 35
    7 * 7 = 49";    
}

}



