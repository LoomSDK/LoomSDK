package
{
    import unittest.TestRunner;
    import unittest.Assert;
    import loom.Application;
    import system.reflection.Assembly;
    
    /**
     * Simple usage of the unit test framework.
     */
    public class UnitTestExample extends Application
    {
        // Hides the function in the reported call stack of a failed test
        [UnitTestHideCall]
        override public function run():void
        {
            // Finds and runs all the tests in the currently running app
            TestRunner.runAll(getType().getAssembly());   
        }
        
        /**
         * A simple test.
         */
        [Test]
        public static function test() {
            Assert.isTrue(true);
        }
        
    }
}