package tests {

import unittest.Test;

class TestTypeOps extends Test
{
    function TestTypeOps()
    {
        name = "TestTypeOps";
        expected = "";
    }    

    function test()
    {
        testTypeOps();
    }
 
    private function testPassedTypeOps(value:Object, type:Type, name:String):void
    {
        assert(type.getFullTypeName() == name);

        var val1 = value instanceof type;
        var val2 = value is type;
        var val3 = (value as type) != null;

        assert(val1 && val2 && val3);

    }

    private function testTypeOps():void
    {
        // test Boolean
        var name = true.getFullTypeName();
        assert((name == "system.Boolean") && (Boolean.getFullTypeName() == "system.Boolean"));

        var val1 = true instanceof Boolean;
        var val2 = true is Boolean;
        var val3 = (true as Boolean) != null;

        assert(val1 && val2 && val3);

        testPassedTypeOps( true, Boolean, name );

        // test Number
        var nval = 123;
        name = nval.getFullTypeName();
        assert((name == "system.Number") && (Number.getFullTypeName() == "system.Number"));

        val1 = 123 instanceof Number;
        val2 = 123 is Number;
        val3 = (123 as Number) != null;

        assert(val1 && val2 && val3);

        testPassedTypeOps( 123, Number, name );

        // test String
        var sval = "123";
        name = sval.getFullTypeName();        

        assert((name == "system.String") && (String.getFullTypeName() == "system.String"));

        val1 = "123" instanceof String;
        val2 = "123" is String;
        val3 = ("123" as String) != null;

        assert(val1 && val2 && val3);

        testPassedTypeOps( "123", String, name );
        
        // test Function
        var fval = function(){};
        name = fval.getFullTypeName();
        assert((name == "system.Function") && (Function.getFullTypeName() == "system.Function"));

        val1 = fval instanceof Function;
        val2 = fval is Function;
        val3 = (fval as Function) != null;

        assert(val1 && val2 && val3);

        testPassedTypeOps( fval, Function, name );

        // test Vector
        var vval = [];
        name = vval.getFullTypeName();
        assert((name == "system.Vector") && (Vector.getFullTypeName() == "system.Vector"));

        val1 = vval instanceof Vector;
        val2 = vval is Vector;
        val3 = (vval as Vector) != null;

        assert(val1 && val2 && val3);

        testPassedTypeOps( vval, Vector, name );

        // test Dictionary
        var dval = {};
        name = dval.getFullTypeName();
        assert((name == "system.Dictionary") && (Dictionary.getFullTypeName() == "system.Dictionary"));

        val1 = dval instanceof Dictionary;
        val2 = dval is Dictionary;
        val3 = (dval as Dictionary) != null;

        assert(val1 && val2 && val3);

        testPassedTypeOps( dval, Dictionary, name );


        // test TestTypeOps
        var oval = this;
        name = this.getFullTypeName();

        assert((name == "tests.TestTypeOps") && (TestTypeOps.getFullTypeName() == "tests.TestTypeOps"));

        val1 = oval instanceof TestTypeOps;
        val2 = oval is TestTypeOps;
        val3 = (oval as TestTypeOps) != null;

        assert(val1 && val2 && val3);

        testPassedTypeOps( oval, TestTypeOps, name );
        
    }
}

}