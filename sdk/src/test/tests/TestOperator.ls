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

class OpClass {

    public function OpClass(x:Number = 0, y:Number = 0) {
        this.x = x;
        this.y = y;
    }

    public var x:Number;
    
    public var y:Number;
 
    // Addition overload
    public static operator function +(a:OpClass, b:OpClass):OpClass
    {
        return new OpClass(a.x + b.x, a.y + b.y);
    }    
    
    public static operator function -(a:OpClass, b:OpClass):OpClass
    {
        return new OpClass(a.x - b.x, a.y - b.y);
    }    
    

}

class TestOperator extends LegacyTest
{    
    
    function test()
    {
        
        
        var o1:OpClass = new OpClass(1,2);
        var o2:OpClass = new OpClass(3,4);
        
        log( (o1 + o2).x );
        log( (o2 - o1).x );
        log( (o1 + o2).y );
        log( (o2 - o1).y );    
                
    }
    
    function TestOperator()
    {
        name = "TestOperator";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "4262";    
}

}



