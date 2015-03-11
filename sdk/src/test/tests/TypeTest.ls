package tests {
    
    import system.reflection.Type;
    import unittest.Assert;
    
    public class TypeTest {
        
        function equalsType(value:Object, type:Type, name:String) {
            Assert.compare(name, type.getFullName());
            Assert.isTrue(value instanceof type, "instanceof failed");
            Assert.isTrue(value is type, "is failed");
            Assert.isTrue((value as type) != null, "as failed");
        }
        
        [Test] function testBoolean() {
            equalsType(true, Boolean, "system.Boolean");
            equalsType(false, Boolean, "system.Boolean");
        }
        
        [Test] function testNumber() {
            equalsType(123, Number, "system.Number");
            equalsType(123.456, Number, "system.Number");
            equalsType(-123, Number, "system.Number");
            equalsType(-123.456, Number, "system.Number");
        }
        
    }
    
}