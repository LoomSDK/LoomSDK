package {
    
    public class AssertTest {
        
        public var testFailures = false;
        
        static function staticTest() {
            Assert.isTrue(true, "staticTest");
        }
        
        function nonstaticTest() {
            Assert.isTrue(true, "nonstaticTest");
        }
        
        [Test(skip)] function testSkip() {
            Assert.fail();
        }
        
        [Test] function testFail() {
            if (testFailures) Assert.fail();
        }
        
        [Test] function testTrue() {
            Assert.isTrue(true);
            if (testFailures) Assert.isTrue(false);
        }
        
        [Test] function testFalse() {
            Assert.isFalse(false);
            if (testFailures) Assert.isFalse(true);
        }
        
        [Test] function testNull() {
            Assert.isNull(null);
            if (testFailures) Assert.isNull(new Object());
        }
        
        [Test] function testNotNull() {
            Assert.isNotNull(new Object());
            if (testFailures) Assert.isNotNull(null);
        }
        
        [Test] function testNaN() {
            Assert.isNaN(NaN);
            if (testFailures) Assert.isNaN(5);
        }
        
        [Test] function testNotNaN() {
            Assert.isNotNaN(5);
            if (testFailures) Assert.isNotNaN(null);
        }
        
        
        [Test] function testInstanceOf() {
            Assert.instanceOf("hi", String);
            Assert.instanceOf(5, Number);
            if (testFailures) Assert.instanceOf("hi", Number);
        }
        
        [Test] function testNotInstanceOf() {
            Assert.notInstanceOf("hi", Number);
            //Assert.notInstanceOf(5, String); // TODO: should not fail
            if (testFailures) Assert.notInstanceOf("hi", String);
        }
        
        
        [Test] function testCompare() {
            Assert.compare(123, 123);
            if (testFailures) Assert.compare(123, 456);
        }
        
        [Test] function testEqual() {
            Assert.equal(789, 789);
            if (testFailures) Assert.equal(789, 123);
        }
        
        [Test] function testNotEqual() {
            Assert.notEqual(123, 456);
            if (testFailures) Assert.compare(123, 123);
        }
        
        [Test] function testCompareNumber() {
            Assert.compareNumber(1.23, 1.23);
            Assert.compareNumber(0.0001, 0.0001);
            Assert.compareNumber(1e10, 1e10);
            Assert.compareNumber(1.0, 1.0000001);
            Assert.compareNumber(1.0, 1.001, null, 0.01);
            if (testFailures) {
                Assert.compareNumber(1.23, 1.24);
            }
        }
        
        [Test] function testEqualNumber() {
            Assert.equalNumber(1.23, 1.23);
            Assert.equalNumber(0.0001, 0.0001);
            Assert.equalNumber(1e10, 1e10);
            Assert.equalNumber(1.0, 1.0000001);
            Assert.equalNumber(1.0, 1.001, null, 0.01);
            if (testFailures) {
                Assert.equalNumber(1.23, 1.24);
            }
        }
        
        [Test] function testNotEqualNumber() {
            Assert.notEqualNumber(1.23, 1.24);
            Assert.notEqualNumber(-1, 1);
            Assert.notEqualNumber(1e10, 1.01e10);
            Assert.notEqualNumber(1.0, 1.000001);
            Assert.notEqualNumber(1.0, 1.1, null, 0.01);
            if (testFailures) {
                Assert.notEqualNumber(1.0, 1.0000001);
            }
        }
        
        
        [Test] function testGreater() {
            Assert.greater(2, 0);
            Assert.greater(2, 1);
            if (testFailures) Assert.greater(1, 2);
        }
        
        [Test] function testLess() {
            Assert.less(0, 2);
            Assert.less(1, 2);
            if (testFailures) Assert.less(2, 1);
        }
        
        [Test] function testGreaterOrEqual() {
            Assert.greaterOrEqual(2, 0);
            Assert.greaterOrEqual(2, 1);
            Assert.greaterOrEqual(2, 2);
            if (testFailures) Assert.greaterOrEqual(1, 2);
        }
        
        [Test] function testLessOrEqual() {
            Assert.lessOrEqual(0, 2);
            Assert.lessOrEqual(1, 2);
            Assert.lessOrEqual(2, 2);
            if (testFailures) Assert.lessOrEqual(2, 1);
        }
        
        [Test] function testContainsString() {
            Assert.contains("def", "abcdefghi");
            if (testFailures) {
                Assert.contains("jkl", "abcdefghi");
                Assert.contains("jkl", null);
            }
        }
        
        [Test] function testContainsVector() {
            Assert.contains(3, [1, 2, 3, 4, 5]);
            Assert.contains(1, [1, 2, 3, 4, 5]);
            Assert.contains(5, [1, 2, 3, 4, 5]);
            Assert.contains("lol", ["a", "b", "c", "lol", "omg"]);
            Assert.contains(12, ["a", 4, "b", 64, 12, "c", null, "lol", "omg"]);
            if (testFailures) Assert.contains(53, [1, 2, 3, 4, 5]);
        }
        
        
        
    }
    
}