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

struct MyStruct {

    public static var counter = 0;

    public function MyStruct(_x:Number = 1, _y:Number = 2) {
        this.x = _x;
        this.y = _y;
        counter++;        
    }

    public var x:Number;
    
    public var y:Number;

    // assignment overload    
    public static operator function =(a:MyStruct, b:MyStruct):MyStruct
    {           
        a.x = b.x;
        a.y = b.y;
        
        return a;
    }    
 
    // Addition overload
    public static operator function +(a:MyStruct, b:MyStruct):MyStruct
    {
        return new MyStruct(a.x + b.x, a.y + b.y);
    }    
    
    // Addition overload
    public operator function +=(b:MyStruct)
    {
        x += b.x;
        y += b.y;
    }    

}

class TestStruct extends Test
{

    // this should generate a compiler error
    /*
    public static function makeSureTryingToReturnNullErrors():MyStruct {
    
        return null;
        
    }
    */


    public static function get sa():MyStruct {
    
        return svalue;
        
    }
    
    public static function set sa(value:MyStruct) {
    
        svalue  = value;
        
    }
        
    public function get a():MyStruct {
    
        return value;
        
    }
    
    public function set a(value:MyStruct) {
    
        this.value  = value;
        
    }
    
    public function get nativeStruct():TestPoint2 {
    
        return testPoint;
        
    }
    
    public function set nativeStruct(value:TestPoint2) {
    
        testPoint  = value;
        
    }    
    
    public static var svalue:MyStruct = new MyStruct(-1, -2);
    public var value:MyStruct = svalue;
    public var testPoint:TestPoint2;

    function testLocalInitialization()
    {
        var p2:MyStruct;

        if(false) 
        { 
            var p:MyStruct = new MyStruct(1,2); 
        } 

        p = p2;

    }

    function test()
    {
        
        // ensure that we aren't creating unnecessary 
        // structs and that default args are properly handled

        // static svalue and instance value 
        // are the first 2, if more are added 
        // before this, the counter tests will need
        // to be offset

        var ms:MyStruct;
        assert(ms.x == 1, "init x wrong " + ms.x);
        assert(ms.y == 2, "init y wrong " + ms.y);

        // We currently are creating additional structs
        // reinstate these counter tests once LOOM-1595 is addressed
        //assert(MyStruct.counter == 3);

        var ms2:MyStruct = new MyStruct(2, 3);
        assert(ms2.x == 2 && ms2.y == 3);

        //assert(MyStruct.counter == 4);

        var ms3:MyStruct = ms2;
        assert(ms3.x == 2 && ms3.y == 3);

        //assert(MyStruct.counter == 5);

        ms3.x = ms.x = ms2.y = 0;

        assert(ms3.x == 0);
        assert(ms2.y == 0);
        assert(ms.x == 0);

        assert(!ms3.x);
        assert(!ms2.y);
        assert(!ms.x);
        
        assert(nativeStruct.x == 0);
        assert(nativeStruct.y == 0);
        
        var np = new TestPoint2();
        np.x = 100;
        np.y = 200;
        
        nativeStruct = np;
        
        assert(nativeStruct.x == 100);
        assert(nativeStruct.y == 200);
        
        assert(testPoint.x == 100);
        assert(testPoint.y == 200);
        
        
        // types which overload assignment operator
        // can be explicitly instantiated
        var o1 = new MyStruct(1, 2);
        var o2 = new MyStruct(3, 4);
        
        // a new instance which is the result of the operator+
        var o3 = o1 + o2;
        
        // a new instance which is the result of the operator=
        var o4:MyStruct = o3;
        
        assert(o3.x == 4);
        assert(o3.y == 6);

        assert(o4.x == 4);
        assert(o4.y == 6);
        
        o3.x = 100;

        assert(o3.x == 100);
        assert(o3.y == 6);

        assert(o4.x == 4);
        assert(o4.y == 6);
        
        // types which overload assignment are implicitly 
        // instantiated and they must provide a contructor
        // that takes no arguments or has default values for
        // all arguments

        // o5 is a valid instance         
        var o5:MyStruct;
        
        o5.x = 0;
        
        o5 = o3;
        
        o5.y += 100;
        
        // this generates a compiler error, cannot assign null to 
        // a type which overloads assignment
        //o5 = null;
        
        assert(o3.y == 6);
        assert(o5.y == 106);
        
        var o6 = sa;
        
        assert(o6.x == -1);
        
        o6 = a;
        
        a.x = 1000;
        
        assert(a.x == 1000);
        assert(o6.x == -1);
        
        a = new MyStruct(7,8);
        
        assert(a.x == 7);
        assert(a.y == 8);
        
        var a1 = new MyStruct(1, 2);
        var b1 = new MyStruct(3, 4);
        
        a1 += b1;
        
        assert(a1.x == 4);
        assert(a1.y == 6);   

        testLocalInitialization();     
    }
    
    function TestStruct()
    {
        name = "TestStruct";
    }    
}

}


