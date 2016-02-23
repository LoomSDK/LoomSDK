package
{
    import loom.Application;
    
    public class TestExecApp extends Application
    {
        public var testExecutor:TestExecutor;
        
        [UnitTestHideCall]
        override public function run():void
        {
            testExecutor = new TestExecutor();
            testExecutor.argOffset = 1;
            testExecutor.run();
        }
    }
}