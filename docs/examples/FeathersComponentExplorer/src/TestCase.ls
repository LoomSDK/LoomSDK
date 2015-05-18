package {
    import unittest.Test;
    import unittest.TestRunner;
    
    public class TestCase {
        
        public function TestCase() {
            
        }
        
        public function run() {
            setUp();
            var tests:Vector.<Test> = TestRunner.getTests(this, false);
            TestRunner.run(tests, true);
            tearDown();
        }

        protected function setUp() { }
        protected function tearDown() { }
        
    }
    
}