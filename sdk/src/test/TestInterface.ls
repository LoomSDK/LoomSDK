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

interface IFoo {
    
}

interface IBar extends IFoo {
    
}

class FooBarI implements IBar {
    
    
}

interface ISimpleA {

    function doSomething(svalue:String):Number;

}

interface ISimpleB extends ISimpleA {

    function doSomethingElse(svalue:String):Number;

}

interface ISimpleC {

    function doSomethingCompletelyDifferent(svalue:String):Number;
    
    function get testProp():String;
    function set testProp(value:String);

}


class ClassIA implements ISimpleB {

    public function doSomething(svalue:String):Number {
    
        Test.log("ClassIA::doSomething " + svalue);
        return 1;
    
    }

    public function doSomethingElse(svalue:String):Number {
    
        Test.log("ClassIA::doSomethingElse" + svalue);
        return 101;
    
    }

}

class ClassIB extends ClassIA implements ISimpleC, ISimpleD {

    public function get testProp():String {        
        return value;
    }
    
    public function set testProp(value:String) {
        this.value = value;
    }

    public function doSomethingElse(svalue:String):Number {
    
        super(svalue);
        Test.log("ClassIB::doSomethingElse " + svalue);
        return 3;
    
    }
    
    public function doSomethingCompletelyDifferent(svalue:String):Number {
    
        Test.log("ClassIB::doSomethingCompletelyDifferent " + svalue);
        return 4;
    
    }
    
    public function logCreepShow() {
        Test.log("Creepshow");
    }
    
    var value:String;

}

interface ISimpleD {

    function logCreepShow();

}

interface ISimpleE {


}


class TestInterface extends Test
{
    function test()
    {
        

        // test assign to null        
        var ni:ISimpleA;
        ni = null;
        
        var sa:ISimpleA = new ClassIB();
        
        var o:Object = sa;
        
        sa = o as ISimpleA;
        
        
        var cb:ClassIB = sa as ClassIB;
        var sc:ISimpleC = cb as ISimpleC;
        
        Test.log(cb is ISimpleA);
        Test.log(cb is ISimpleB);
        Test.log(cb is ISimpleC);
        Test.log(cb is ISimpleD);
        Test.log((cb as ISimpleC) != null);
        Test.log(cb is ISimpleE);
        
        sa.doSomething("hello");
        
        sc.testProp = "Whee!";
        cb.doSomethingCompletelyDifferent(cb.testProp);
        
        cb.doSomethingElse("Whoo!");
        
        var sd:ISimpleD = cb as ISimpleD;
        
        sd.logCreepShow();
        
        var sb:ISimpleB = cb as ISimpleB;
        
        var myfoo = new FooBarI();
        Test.log(myfoo is IFoo);
        
        
    }
    
    function TestInterface()
    {
        name = "TestInterface";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "
true
true
true
true
true
false    
ClassIA::doSomething hello
ClassIB::doSomethingCompletelyDifferent Whee!
ClassIA::doSomethingElseWhoo!
ClassIB::doSomethingElse Whoo!
Creepshow   
true 
";    
}

}



