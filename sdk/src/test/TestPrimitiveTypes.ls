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

delegate TestPrimitiveTypesDelegate(a:Number, b:Number):Number;


class TestPrimitiveTypes extends Test
{

    function test()
    {
        
        
        var o:Object;
        var s:String = "Whee!";
        var n:Number = 1001;
        
        o = n;
        
        log(o is Number);
        var n2:Number = o as Number;
        log(n2);
        log(o.getTypeName());
        
        var type = o.getType();
        log(type.getFullName());
        
        o = s;
        log(o is Number);
        log(o is String);
        
        var s2 = o as String;
        log(s2);
        
        o = true;
        log(o is Number);
        log(o is String);
        log(o is Boolean);
        
        type = o.getType();
        
        log(type.getFullName());
        
        o = function (a:Number,b:Number):Number {
            var c:Number = a+b;
            var d:Number = a * b;
            log(c);
            log(d);
            return d;
        };

        log(o is Number);
        log(o is String);
        log(o is Boolean);
        log(o is Function);
        
        type = o.getType();
        log(type.getFullName());
        
        var funcd = o as Function;
        
        // please note, delegates are strongly typed
        // but being able to call/make anonymous closures/function is cool :)
        var n3 = funcd.call(null, 20, 21) as Number;
        
        log(n3);

        var fixed = 3.1415;
        assert(fixed.toFixed(2) == "3.14");
        assert(fixed.toFixed(1) == "3.1");
        assert(fixed.toFixed(0) == "3");
        assert(fixed.toFixed(4) == "3.1415");
        
        
    }
    
    function TestPrimitiveTypes()
    {
        name = "TestPrimitiveTypes";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
"
true
1001
Number
system.Number
false
true
Whee!
false
false
true
system.Boolean
false
false
false
true
system.Function
41
420
420
";
    
}

}



