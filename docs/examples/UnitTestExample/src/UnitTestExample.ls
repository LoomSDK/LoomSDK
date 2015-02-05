package
{
    import loom.Application;
    import system.platform.File;
    import system.reflection.Assembly;
    
    public class UnitTestExample extends Application
    {
        [UnitTestHideCall]
        override public function run():void
        {
            //trace(TestRunner.getTests(new ByteArrayTest()));
            TestRunner.runAll(ByteArrayTest, false);
            //TestRunner.runAll(AssertTest, false);
            
            //Assembly.loadBytes(File.loadBinaryFile("assets/Main.loom"));
            
        }
        
    }
}