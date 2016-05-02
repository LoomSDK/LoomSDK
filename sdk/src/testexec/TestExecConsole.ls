package
{
    import system.application.ConsoleApplication;
    
    /**
     * Test Executor console application entry point.
     * See TestExecutor for more info.
     */
    public class TestExecConsole extends ConsoleApplication
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