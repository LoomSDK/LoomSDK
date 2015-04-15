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

class TPA 
{
    protected var _value:Number = 101;
    
    protected static var _svalue:Number = 1;
    
    public function set value(newValue:Number) {

        _value = newValue;
        
    }   
    
    public function get value():Number {

        return _value;
        
    }
    
    public static function set svalue(newValue:Number) {
    
        _svalue = newValue;
        
    }   
    
    public static function get svalue():Number {
    
        return _svalue;
    }
    
}

class TPB extends TPA 
{    
    public function logValue() 
    {
        LegacyTest.log(value);
    }
    
    public function logSValue() 
    {
        LegacyTest.log(svalue);
    }

    // value setter overridden, however getter is not and is accessed in
    // the parent
    public function set value(newValue:Number) 
    {

        super.value = newValue;
        
    }       
    
    public var testA:TPA = new TPA();

}

class TPC extends TPB
{    

    public function set value(newValue:Number) {

        super.value = newValue + 1;
        
    }   
    
    public function get value():Number {

        return super.value + 1;
        
    }

    public static function set svalue(newValue:Number) 
    {
        super.svalue = newValue + 3;   
    }   
}


class TestProperty extends LegacyTest
{

    var _max = 10;
    public function get max():int { return _max; }

    var _value:Number = 101;
    var _value2:Number = 102;
    var _value3:Number = 103;
    
    static var _svalue:Number = 1;
    
    
    public function set value(newValue:Number) {

        // access static property from instance
        log(svalue);
        _value = newValue;
        
    }   
    
    public function get value():Number {

        // access static property from instance
        log(svalue);    
        return _value;
        
    }

    public function set value2(newValue:Number) {

        _value2 = newValue;
        
    }   
    
    public function get value2():Number {

        return _value2;
        
    }

    public function set value3(newValue:Number) {

        _value3 = newValue;
        
    }   
    
    public function get value3():Number {

        return _value3;
        
    }


    public static function set svalue(newValue:Number) {
    
        _svalue = newValue;
        
    }   
    
    public static function get svalue():Number {
    
        return _svalue;
    }

    // Compiler Error
    /*
    public function get errorOnSpecifyParameterOnGetter(x:Number):Number
    {
        return 1;
    } 
    */   
    
    // test initializer with static property
    public static var testValue:Number = svalue;
    
    public var testB:TPB = new TPB();
    
    
    function test()
    {
        
        log(testValue);
    
        log(value);
    
        value = 102;
        
        log(_value);
        
        this.value = value + 1;
        
        log(_value);
        
        // test static properties
        log(TestProperty.svalue);
    
        svalue = 2;
        
        log(_svalue);
        
        svalue = svalue + 1;
        
        log(_svalue);
        
        log(svalue);
        
        // assign instance property to static property
        value = svalue;
        log(value);

        log(testB.value);        
        log(testB.svalue);
        log(testB.testA.value);        
        log(testB.testA.svalue);
        
        testB.testA.value = testB.value + 1;
        
        // toss in an Assignment operator
        var x:Number = 1000;
        x += 2;
        log(x);
        
        // 2
        TPA.svalue += 1;
        // 3
        TPB.svalue = TPA.svalue + 1;
        // 9
        TPB.svalue += TPB.svalue + 3;
        
        // 54
        TPB.svalue *= 6;
        
        
        log(testB.testA.value );        
        log(TPA.svalue);
        log(TPB.svalue);        
        
        
        var pdict:Dictionary.<Object, Object> = new Dictionary.<Object, Object>;
        
        pdict[TPB.svalue] = "Hello";
        pdict[TPB.svalue + " Yes "] = "World";
        
        assert(pdict[TPB.svalue] == "Hello");
        assert(pdict[TPB.svalue + " Yes "] == "World");

        assert (value2 == 102 && value3 == 103);
        value = 104;

        // setter = setter = getter;
        value2 = value3 = value;
        assert(value2 == 104);
        assert(value3 == 104);

        value3+=1;
        assert(value3 == 105);

        value3*=2;
        assert(value3 == 210);

        // test property increment and decrement
        value3++;
        assert(value3 == 211);
        --value3;
        assert(value3 == 210);

        // iteration with a property (value3)
        var count = 0;
        for (value3 = 0; value3 < 10; value3++)
            count+=1;

        assert(count == 10);
        assert(value3 == 10);

        // test overrides

        var tb = new TPB();
        assert(tb.value == 101);
        tb.value = 102;
        assert(tb.value == 102);

        var dict:Dictionary.<String, Number> = { "max":( false ? 9 : max) };
        var vect = [(false ? 9 : max)];

        assert(dict["max"] == 10);
        assert(vect[0] == 10);

        var tpc = new TPC;

        assert(tpc.value == 102);
        tpc.value = 102;
        assert(tpc.value == 104);

        TPA.svalue = 10;
        assert(TPC.svalue == 10);

        TPB.svalue = 10;
        assert(TPA.svalue == 10);
        assert(TPB.svalue == 10);
        assert(TPC.svalue == 10);

        TPC.svalue = 10;
        assert(TPA.svalue == 13);
        assert(TPB.svalue == 13);
        assert(TPC.svalue == 13);


    }
    
    function TestProperty()
    {
        name = "TestProperty";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
    "1
1
101
1
102
1
1
103
1
2
3
3
3
3
3
101
1
101
1
1002
102
54
54";    
}

}



