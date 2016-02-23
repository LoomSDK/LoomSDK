package
{
    import system.application.ConsoleApplication;
    
    public class TestExecConsole extends ConsoleApplication
    {
        public var testExecutor:TestExecutor;
        
        [UnitTestHideCall]
        override public function run():void
        {
            testExecutor = new TestExecutor();
            testExecutor.argOffset = 0;
            testExecutor.run();
        }
    }
}