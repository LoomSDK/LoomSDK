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
            //TestRunner.runAll(ByteArrayTest, false);
            //TestRunner.run(TestRunner.getTests(ByteArrayTest));
            //TestRunner.runAll(AssertTest, false);
            
            TestRunner.runAll(getType().getAssembly());
            
            //Assembly.loadBytes(File.loadBinaryFile("assets/Main.loom"));
            
        }
        
    }
}