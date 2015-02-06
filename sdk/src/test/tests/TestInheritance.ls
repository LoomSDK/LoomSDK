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

class TestInheritance extends LegacyTest
{

    function test()
    {
                
        var o:Orange = new Orange();
        
        var a:Apple = new Apple();
        
        var fuji:Fuji = new Fuji();
        
        log(o.id);
        log(o.category);
        log(o.specific);
        
        log(a.id);
        log(a.category);
        log(a.specific);
    
        log(fuji.id);
        log(fuji.category);
        log(fuji.specific);
        log(fuji.reallySpecific);
        fuji.eat("crunch");
        fuji.diddle("piddle");
        
        log(a.onAdd());
        log(fuji.onAdd());
        log(o.onAdd());
        
        a.waste();
        o.waste();
        fuji.waste();
    }
    
    function TestInheritance()
    {
        name = "TestInheritance";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    
    var EXPECTED_TEST_RESULT:String = 
"102
I'm a fruit!
I'm an orange!
101
I'm a fruit!
I'm an apple!
103
I'm a fruit!
I'm an apple!
I'm a special kind of apple called a Fuji!
crunch
munch
crunch
diddle
piddle
In Apple.onAdd
In Fruit.onAdd
true
In Fuji.onAdd
In Apple.onAdd
In Fruit.onAdd
true
In Orange.onAdd
In Fruit.onAdd
true
Don't waste fruit!
Don't waste fruit!
Don't waste fruit!";    

}

}











