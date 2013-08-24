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

class TestSuperBase {

    public var numberValue:Number;
    
    public function TestSuperBase(x:Number) {
        numberValue = x;
    }
    
    public static function anotherStaticMethod(x:String):String {

        return "Hello" + x;
        
    }
    
        public static function staticMethod(x:Number, y:String):Number {

        return x + y.toNumber();
        
    }
    
    public function instanceMethod(x:String, y:Number, z:Boolean):String {

        return this.getType().getName() + numberValue + x + y + z;
        
    }
    
    public function anotherInstanceMethod(x:String):String {

        return this.getType().getName() + x + "Hello";
        
    }
    
    public static function staticDoIt(x:String):String {
    
        return x + "TestSuperBase::staticDoIt";
        
    }
    
    public function instanceDoIt(x:String):String {
    
        return x + "TestSuperBase::instanceDoIt";
        
    }
    
    
}

class TestSuperChild extends TestSuperBase {


    public var stringValue:String;    
    
    public function TestSuperChild(x:String, y:Number) {
    
        stringValue = x;
        super(y);
    }
    
    public function instanceMethod(x:String, y:Number, z:Boolean):String {

        return this.getType().getName() + stringValue + x + y + z 
               + super(y.toString(), x.toNumber(), !z) + staticMethod("201", 201, false) 
               + super.staticMethod(200, "yes") + super.anotherStaticMethod("World") 
               + super.anotherInstanceMethod("World");    
        
    }
    
    
    public static function staticMethod(x:String, y:Number, z:Boolean):String {

        return x + y + z + super(y, x) + super.anotherStaticMethod("World");    
        
    }
    
    public static function staticDoIt(x:String):String {
    
        return x + super("TestSuperChild::staticDoIt");
        
    }
    
    public function instanceDoIt(x:String):String {
    
        return x + super("TestSuperChild::instanceDoIt");
        
    }
    
    
}

class TestSuperAnotherChild extends TestSuperChild {

    public function TestSuperAnotherChild(x:String, y:Number) {
    
        super(x, y);
    }

    public static function staticDoIt(x:String):String {
        
        return x + super("TestSuperAnotherChild::staticDoIt");
        
    }
    
    public function instanceDoIt(x:String):String {
    
        return x + stringValue + numberValue + super("TestSuperAnotherChild::instanceDoIt");
        
    }

}


class TestSuper extends Test
{
    function test()
    {
        assert(TestSuperChild.staticMethod("1",2,true) == "12true3HelloWorld");
        assert(TestSuperChild.staticMethod("3",4,false) == "34false7HelloWorld");
        
        var x = new TestSuperChild("LittleWing", 1001);
        x.stringValue = "LittleWing";
        
        assert(x.instanceMethod("BigBird", 789, true) == "TestSuperChildLittleWingBigBird789trueTestSuperChild1001789-1false201201false402HelloWorld199HelloWorldTestSuperChildWorldHello");
        
        var y = new TestSuperChild("PizzaParty", 2001);
        assert(y.instanceMethod("BigBird", 789, true) == "TestSuperChildPizzaPartyBigBird789trueTestSuperChild2001789-1false201201false402HelloWorld199HelloWorldTestSuperChildWorldHello");
        
        assert(TestSuperAnotherChild.staticDoIt("YES!") == "YES!TestSuperAnotherChild::staticDoItTestSuperChild::staticDoItTestSuperBase::staticDoIt");
        
        var z = new TestSuperAnotherChild("Whee", 10000);
        assert(z.instanceDoIt("SUPER_CHAIN_FTW!") == "SUPER_CHAIN_FTW!Whee10000TestSuperAnotherChild::instanceDoItTestSuperChild::instanceDoItTestSuperBase::instanceDoIt");

        
    }
    
    function TestSuper()
    {
        name = "TestSuper";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "";    
}

}



