package
{
    import loom.Application;
    
    /**
     * Test Executor windowed application entry point.
     * See TestExecutor for more info.
     */
    public class TestExecApp extends Application
    {
        public var testExecutor:TestExecutor;
        
        [UnitTestHideCall]
        override public function run():void
        {
            testExecutor = new TestExecutor();
            testExecutor.run();
        }
    }
}