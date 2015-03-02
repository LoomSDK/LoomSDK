package tests {
    
    import system.reflection.ConstructorInfo;
    import system.reflection.FieldInfo;
    import system.reflection.MethodInfo;
    import system.reflection.ParameterInfo;
    import system.reflection.Type;
    import unittest.Assert;
    
    interface ReflectTestInterface {
        function someMethodNoArgs();
        function someMethod(value:String, value2:Number);
    }
    
    interface ReflectTestInterface2 {
        function testGetType();
    }
    
    class ReflectTestGrandparent {}
    
    class ReflectTestParent extends ReflectTestGrandparent {}
    
    class ReflectTest extends ReflectTestParent implements ReflectTestInterface, ReflectTestInterface2 {
        
        [MetaTag(id="thisIsAnID")]
        public var numberField:Number = 100;
        
        public static var result:String;
        
        public static function someStaticMethodNoArgs() {
            result = "someStaticMethodNoArgs";
        }
        
        public function someMethodNoArgs() {
            result = "someMethodNoArgs";
        }
        
        public static function someStaticMethod(value:String, value2:Number) {
            result = value+" "+value2;
        }
        
        public function someMethod(value:String, value2:Number) {
            result = value+" "+value2;
        }

        public function set someProperty(value:String) {
            result = value;
        }
        
        public function testGetType() 
        {
            var rc:ReflectTest = this;
            
            var t1 = getType();
            var t2 = this.getType();
            var t3 = rc.getType();
            
            Assert.equal(t1, t2, "getType failure");
            Assert.equal(t2, t3, "getType failure");
        }
        
    }

    public class ReflectionTest {
        
        /**
         * LoomScript supports infering types, the following will 
         * assign stringType to an instance of system.reflection.Type 
         * for the String primitive type, note that we are also
         * inferring the type to the variable!
         */
        [Test] function testInference() {
            var i:int;
            
            var stringType = String;
            Assert.compare("String", stringType.getName());
            
            var numberType = Number;
            Assert.compare("Number", numberType.getName());
        }
        
        [Test] function testType() {
            var type:Type = Type;
            Assert.compare("Type", type.getName());
            Assert.compare("System", type.getAssembly().getName(), "Type isn't a member of the System assembly?");
            Assert.compare("ReflectTest", (ReflectTest as Type).getName());
            
            new ReflectTest().testGetType();
        }
        
        [Test] function testDictionary() {
            var typeDict:Dictionary.<Type, String> = new Dictionary.<Type, String>();
            typeDict[Number] = "Number";
            Assert.compare("Number", typeDict[Number]);
            Assert.notEqual("String", typeDict[Number]);
            
            var typeDictKeys:Dictionary.<String, Type> = new Dictionary.<String, Type>();
            typeDictKeys["Number"] = Number;
            Assert.compare(Number, typeDictKeys["Number"]);
            Assert.notEqual(String, typeDictKeys["Number"]);
        }
        
        [Test] function testReflectTest() {
            var stype:Type = Type.getTypeByName("tests.ReflectTest");
            Assert.compare("tests.ReflectTest", stype.getFullName());
            Assert.compare("ReflectTest", stype.getName());
        }
        
        [Test] function testMethods() {
            var stype:Type = Type.getTypeByName("tests.ReflectTest");
            var minfo:MethodInfo = stype.getMethodInfoByName("someMethod");
            var sinfo:MethodInfo = stype.getMethodInfoByName("someStaticMethod");
            
            var method:MethodInfo = stype.getMethodInfoByName("someMethod");
            Assert.compare(2, method.getNumParameters());
            
            var param:ParameterInfo;
            
            param = method.getParameter(0);
            Assert.compare("value", param.getName());
            Assert.compare(String, param.getParameterType());
            
            param = method.getParameter(1);
            Assert.compare("value2", param.getName());
            Assert.compare(Number, param.getParameterType());
            
            Assert.compare(25, stype.getMethodInfoCount());
            var methodInfoNames:Vector.<String> = [];
            for (var i = 0; i < stype.getMethodInfoCount(); i++) {
                methodInfoNames.push(stype.getMethodInfo(i).getName());
            }
            Assert.contains("someMethodNoArgs", methodInfoNames);
            Assert.contains("someStaticMethod", methodInfoNames);
            Assert.contains("someMethod", methodInfoNames);
            Assert.contains("testGetType", methodInfoNames);
            Assert.contains("toString", methodInfoNames);
            
            var constructor:ConstructorInfo = stype.getConstructor();
            
            stype.getMethodInfoByName("someStaticMethodNoArgs").invoke(null);
            Assert.compare("someStaticMethodNoArgs", ReflectTest.result);
            sinfo.invoke(null, "Hey!", "7331");
            Assert.compare("Hey! 7331", ReflectTest.result);
            
            var c:ReflectTest = constructor.invoke() as ReflectTest;
            Assert.isNotNull(c);
            minfo.invoke(c, "Josh!", 1337);
            
            stype.getMethodInfoByName("someMethodNoArgs").invoke(c);
            Assert.compare("someMethodNoArgs", ReflectTest.result);
        }
        
        [Test] function testFields() {
            var test:ReflectTest = new ReflectTest();
            var type:Type = test.getType();
            
            var fieldInfoNames = new Vector.<String>();
            for (var i = 0; i < type.getFieldInfoCount(); i++) {
                var fieldInfo:FieldInfo = type.getFieldInfo(i);
                fieldInfoNames.push(fieldInfo.getName());
            }
            Assert.contains("numberField", fieldInfoNames);
            Assert.contains("result", fieldInfoNames);
            
            var f:FieldInfo = type.getFieldInfoByName("numberField");
            Assert.isNotNull(f);
            Assert.compare("numberField", f.getName());
            Assert.compare("system.Number", f.getTypeInfo().getFullName());
            Assert.compare(100, test.numberField);
            Assert.compare(100, f.getValue(test));
            f.setValue(test, 102);
            Assert.compare(102, f.getValue(test));
            Assert.compare(102, test.numberField);
            
            Assert.isNotNull(f.getMetaInfo("MetaTag"));
            Assert.compare("MetaTag", f.getMetaInfo("MetaTag").name);
            Assert.compare("thisIsAnID", f.getMetaInfo("MetaTag").getAttribute("id"));
        }
        
        [Test] function testProperties() {
            var test:ReflectTest = new ReflectTest();
            var type:Type = test.getType();
            test.someProperty = "Property";
            Assert.compare("Property", ReflectTest.result);
            Assert.compare(2, type.getPropertyInfoCount());
            
            var propInfo = type.getPropertyInfo(0);
            propInfo.getSetMethod().invoke(test, "Setting a Property");
            Assert.compare("Setting a Property", ReflectTest.result);
            
            Assert.compare("ReflectionTest", this.getTypeName());
            Assert.compare("tests.ReflectionTest", this.getFullTypeName());
            
            var ftn = 101;
            
            Assert.compare("Number", ftn.getTypeName());
            Assert.compare("system.Number", ftn.getFullTypeName());
            
            Assert.compare("Object:system.reflection.Type", ""+ftn.getType());
        }
        
        [Test] function testInterfaces() {
            var type:Type = ReflectTest;
            Assert.compare(2, type.getInterfaceCount());
            Assert.compare("ReflectTestInterface", type.getInterface(0).getName());
            Assert.compare("ReflectTestInterface2", type.getInterface(1).getName());
        }
        
        [Test] function testParent() {
            var type:Type = ReflectTest;
            Assert.compare("ReflectTestParent", type.getParent().getName());
            Assert.compare("ReflectTestGrandparent", type.getParent().getParent().getName());
        }
        
    }
    
}