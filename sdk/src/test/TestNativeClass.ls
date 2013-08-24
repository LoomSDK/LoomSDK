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

native class MyNativeClass {
    
    native public var intField:int;
    native public var floatField:float;
    native public var doubleField:float;
    native public var stringField:String;
    native public var structField:MyNativeStruct;
    native public static var staticIntField:int;
    
    public native function getDescString(value:int):String;
    public native function getDescStringBool(value:Boolean):String;
    
    public native function passStructByValueReturnsByValue(value:MyNativeStruct):MyNativeStruct;
    public native function passStructByPointerReturnsByValue(value:MyNativeStruct):MyNativeStruct;
    public native function passStructByValueReturnsByPointer(value:MyNativeStruct):MyNativeStruct;
    public native function passStructByPointerReturnsByPointer(value:MyNativeStruct):MyNativeStruct;
    
    // check that the native value is indeed set on natve member, instead of just being stored to class table
    public static native function checkStaticIntField(value:int):Boolean;
    
    
    
}

native class MyChildNativeClass extends MyNativeClass {
    
    public native function getDescStringChildOverride(value:String):String;
    
}

final native class MyGrandChildNativeClass extends MyChildNativeClass {

    public native function MyGrandChildNativeClass(_structField:MyNativeStruct, _floatField:float, _intField:int = 321, _doubleField:float = 555, _stringField:String = "a default string");

    public static native function getAsMyNativeClass(nc:MyNativeClass):MyNativeClass;
    public static native function getAsMyChildNativeClass(nc:MyNativeClass):MyChildNativeClass;
    public static native function getAsMyGrandChildNativeClass(nc:MyNativeClass):MyGrandChildNativeClass;

    
}


final native struct MyNativeStruct {

   public native function MyNativeStruct(numberValue:Number = 0, stringValue:String = "default" , anotherStringValue:String = "another default", boolValue:Boolean = true);

   public native var numberValue:Number;
   public native var stringValue:String; // this is backed by a const char*
   public native var anotherStringValue:String; // this is backed by a utString
   public native var boolValue:Boolean;
   
   public static native operator function =(a:MyNativeStruct, b:MyNativeStruct):MyNativeStruct;
   
}


class TestNativeClass extends Test
{
    function test()
    {
     
        assert(MyNativeClass.staticIntField == 1001, "static field mismatch");   
        
        // set a static native field
        MyNativeClass.staticIntField = 1002;
        assert(MyNativeClass.checkStaticIntField(1002), "static field mismatch on get/set");   
        
        
        var instance = new MyNativeClass();
        log(instance.getDescString(100));
        log(instance.getDescStringBool(true));
        
        var child = new MyChildNativeClass();
        log(child.getDescStringChildOverride("hello"));
        
        child.intField = 3000;
        child.doubleField = 10000;
        child.stringField = "goodbye";
        
        log(child.getDescStringBool(false));
        
        // test dynamic casting
        
        var ninstance = new MyNativeClass();
        var cinstance = new MyChildNativeClass();
        var ginstance = new MyGrandChildNativeClass(new MyNativeStruct(), 100);

        // default parameters on native constructor        
        assert(ginstance.floatField == 100);
        assert(ginstance.intField == 321);
        assert(ginstance.doubleField == 555);
        assert(ginstance.stringField == "a default string");
        
        // identity cast
        assert(ninstance as MyNativeClass == ninstance);
        assert(cinstance as MyChildNativeClass == cinstance);
        assert(ginstance as MyGrandChildNativeClass == ginstance);        
        
        // upcast
        assert(ninstance as MyNativeClass == ninstance);
        assert(cinstance as MyNativeClass == cinstance);
        assert(ginstance as MyNativeClass == ginstance);        
                
        // strip off type info as these aren't managed
        var tninstance:MyNativeClass = MyGrandChildNativeClass.getAsMyNativeClass(ninstance);
        var tcinstance:MyNativeClass = MyGrandChildNativeClass.getAsMyNativeClass(cinstance);
        var tginstance:MyNativeClass = MyGrandChildNativeClass.getAsMyNativeClass(ginstance);
                
        // downcast tests
        assert(tninstance as MyNativeClass == tninstance);
        assert(tninstance as MyChildNativeClass == null);
        assert(tninstance as MyGrandChildNativeClass == null);
        
        assert(tcinstance as MyNativeClass == cinstance);
        assert(tcinstance as MyChildNativeClass == cinstance);
        assert(tcinstance as MyGrandChildNativeClass == null);
        
        assert(tginstance as MyNativeClass == ginstance);
        assert(tginstance as MyChildNativeClass == ginstance);
        assert(tginstance as MyGrandChildNativeClass == ginstance);
        
        assert(ninstance is MyNativeClass && tninstance is MyNativeClass);
        assert(!(ninstance is MyChildNativeClass) && !(tninstance is MyChildNativeClass));
        assert(!(ninstance is MyGrandChildNativeClass) && !(tninstance is MyGrandChildNativeClass));
        
        assert(cinstance is MyNativeClass && tcinstance is MyNativeClass);
        assert(cinstance is MyChildNativeClass && tcinstance is MyChildNativeClass);
        assert(!(cinstance is MyGrandChildNativeClass) && !(tcinstance is MyGrandChildNativeClass));

        assert(ginstance is MyNativeClass && tginstance is MyNativeClass);
        assert(ginstance is MyChildNativeClass && tginstance is MyChildNativeClass);
        assert(ginstance is MyGrandChildNativeClass && tginstance is MyGrandChildNativeClass);
        
        // partial defaults
        ginstance = new MyGrandChildNativeClass(new MyNativeStruct(), 123, 456, 789);

        assert(ginstance.floatField == 123);
        assert(ginstance.intField == 456);
        assert(ginstance.doubleField == 789);
        assert(ginstance.stringField == "a default string");

        // full with nested native struct taking default args
        ginstance = new MyGrandChildNativeClass(new MyNativeStruct(42), 987, 654, 321, "testing");

        assert(ginstance.floatField == 987);
        assert(ginstance.intField == 654);
        assert(ginstance.doubleField == 321);
        assert(ginstance.stringField == "testing");
        assert(ginstance.structField.numberValue == 42);
        assert(ginstance.structField.stringValue == "default");
        
        // native struct as member
        var nstruct:MyNativeStruct;
        nstruct.stringValue = "YES!";
        instance.structField = nstruct;
        nstruct.stringValue = "NO!";
        log(instance.structField.stringValue);
        log( nstruct.stringValue );
        
        
        // pass and return by value
        var nstruct2 = instance.passStructByValueReturnsByValue(nstruct);
        log( nstruct2.stringValue );
        nstruct.stringValue = "TEST!";
        log( nstruct.stringValue );
        log( nstruct2.stringValue );
        
        // pass by pointer and return as value
        nstruct2 = instance.passStructByPointerReturnsByValue(nstruct);
        log( nstruct.stringValue );
        log( nstruct2.stringValue );
        
        log(nstruct.numberValue);
        nstruct2.numberValue = 1001;
        nstruct = instance.passStructByValueReturnsByPointer(nstruct2);
        nstruct2.numberValue = 1002;
        log(nstruct.numberValue);
        log(nstruct2.numberValue);
        
        log(nstruct.anotherStringValue);
        nstruct2.anotherStringValue = "Hello";
        var nstruct3 = instance.passStructByPointerReturnsByPointer(nstruct2);
        nstruct2.anotherStringValue = "Goodbye";
        log(nstruct3.anotherStringValue);
        log(nstruct2.anotherStringValue);
        
        
        // this will call the native constructor with the default parms (structs are implicitly constructed)
        var testConstruct:MyNativeStruct;
        assert(testConstruct.stringValue == "default");
        assert(testConstruct.anotherStringValue == "another default");        
        assert(testConstruct.boolValue);        

        assert(!!(testConstruct.numberValue == 0));        
        assert(!testConstruct.numberValue);        

        
    }
    
    function TestNativeClass()
    {
        name = "TestNativeClass";   
        expected = EXPECTED_TEST_RESULT;
    }    
    
    var EXPECTED_TEST_RESULT:String = 
"
100 0 0.00 0.00
true 0 0.00 0.00
hello 1 1.00 1.00 default string
false 3000 1.00 10000.00 goodbye
YES!
NO!
NO!
TEST!
NO!
TEST!
TEST!
0
1001
1002
another default
Hello
Goodbye
";    
}


}



