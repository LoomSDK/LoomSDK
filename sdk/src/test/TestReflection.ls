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

class ReflectClass {
    
    [MetaTag(id="thisIsAnID")]
    public var numberField:Number = 100;
    
    public static function someStaticMethodNoArgs() {
    
        Test.log("Static No Args!");
        
    }
    
    public function someMethodNoArgs() {
    
        Test.log("No Args!");
        
    }
    
    public static function someStaticMethod(value:String, value2:Number) {
        
        Test.log(value);
        Test.log(value2);
        
    }
    
    
    public function someMethod(value:String, value2:Number) {
        
        Test.log(value);
        Test.log(value2);
        
    }

    public function set someProperty(value:String) {
        Test.log(value);
    }
    
    public function testGetType() 
    {
    
        var rc:ReflectClass = this;
        
        var t1 = getType();
        var t2 = this.getType();
        var t3 = rc.getType();
        
        Debug.assert(t1 == t2, "getType() failure");
        Debug.assert(t1 == t3, "getType() failure");
    }
    
}

class TestReflection extends Test
{
    function takeAnInferredType(type:Type) {
    
        Debug.assert(type.getName() == "ReflectClass", "TestReflection::takeAnInferredType didn't receive a ReflectClass type");
    }

    function test()
    {
        // LoomScript supports infering types, the following will 
        // assign stringType to an instance of system.reflection.Type 
        // for the String primitive type, note that we are also
        // inferring the type to the variable!
        
        
        var i:int;
        
        var stringType = String;
        Debug.assert(stringType.getName() == "String", "error getting String type");
        
        var numberType = Number;
        Debug.assert(numberType.getName() == "Number", "error getting Number type");
        
        var type:Type = Type;
        Debug.assert(type.getName() == "Type", "error getting Type type");
        Debug.assert(type.getAssembly().getName() == "System", "Type isn't a member of the System assembly?");
        
        takeAnInferredType(ReflectClass);
        
        var typeDict:Dictionary.<Type, String> = new Dictionary.<Type, String>();
        typeDict[Number] = "Number";
        Debug.assert(typeDict[Number] == "Number");
        Debug.assert(typeDict[Number] != "String");
        
        var typeDictKeys:Dictionary.<String, Type> = new Dictionary.<String, Type>();
        typeDictKeys["Number"] = Number;
        Debug.assert(typeDictKeys["Number"] == Number);
        Debug.assert(typeDictKeys["Number"] != String);

        // We will receive a "Unable to resolve memberInfo System.String:getName"
        // error, which makes sense as here we are looking for a static member
        // on the String class
        // Console.print(String.getName());
        
        var stype:Type = Type.getTypeByName("tests.ReflectClass");
        
        log(stype.getFullName());
        log(stype.getName());
        
        var minfo:MethodInfo = stype.getMethodInfoByName("someMethod");
        var sinfo:MethodInfo = stype.getMethodInfoByName("someStaticMethod");
        
        var method = stype.getMethodInfoByName("someMethod");
        for (i = 0; i < method.getNumParameters(); i++) {
            var param = method.getParameter(i);
            log(param.getName() + " : " + param.getParameterType().getFullName());
        }
        
        var constructor = stype.getConstructor();
        
        stype.getMethodInfoByName("someStaticMethodNoArgs").invoke(null);
        sinfo.invoke(null, "Hey!", "7331");
        
        var c:ReflectClass = constructor.invoke() as ReflectClass;
        minfo.invoke(c, "Josh!", 1337);
        
        stype.getMethodInfoByName("someMethodNoArgs").invoke(c);
        
        type = c.getType();
        
        for (i = 0; i < type.getFieldInfoCount(); i++) {
            
            var fieldInfo = type.getFieldInfo(i);
            
            log(fieldInfo.getName());
            log(fieldInfo.getType().getFullName());

            log(c.numberField);
            fieldInfo.setValue(c, 102);
            log(fieldInfo.getValue(c));
            log(c.numberField);

            log(fieldInfo.getMetaInfo("MetaTag") != null); // true
            log(fieldInfo.getMetaInfo("MetaTag").name);
            log(fieldInfo.getMetaInfo("MetaTag").getAttribute("id"));
            
        }

        // testing properties
        c.someProperty = "Property";
        log(type.getPropertyInfoCount().toString());
        var propInfo = type.getPropertyInfo(0);
        propInfo.getSetMethod().invoke(c,"Setting a Property");
        
        c.testGetType();

        assert (this.getTypeName() == "TestReflection");
        assert (this.getFullTypeName() == "tests.TestReflection");

        var ftn = 101;

        assert (ftn.getTypeName() == "Number");
        assert (ftn.getFullTypeName() == "system.Number");

        assert ((ftn.getType() + "->" + "HelloNumber") == "Object:system.reflection.Type->HelloNumber");
        assert (("HelloNumber" + "<-" + ftn.getType()) == "HelloNumber<-Object:system.reflection.Type");

    }
    
    function TestReflection()
    {
        name = "TestReflection";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
    "
tests.ReflectClass
ReflectClass
value : system.String
value2 : system.Number
Static No Args!
Hey!
7331
Josh!
1337
No Args!
numberField
system.reflection.FieldInfo
100
102
102
true
MetaTag
thisIsAnID
Property
2
Setting a Property
";    
}

}



