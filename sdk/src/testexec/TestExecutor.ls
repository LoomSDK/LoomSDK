package
{
    import loom.Application;
    import system.platform.File;
    import system.reflection.Assembly;
    import unittest.TestResult;
    import unittest.TestRunner;
    
    public class TestExecutor extends Application
    {
        [UnitTestHideCall]
        override public function run():void
        {
            
            //IO.write("count: "+CommandLine.getArgCount()+"\n");
            
            //trace(CommandLine.getArg(0));
            //trace(CommandLine.getArg(1));
            //trace(CommandLine.getArg(2));
            //trace(CommandLine.getArg(3));
            //trace(CommandLine.getArg(4));
            
            //Process.exit(0);
            
            //IO.write("test");
            
            Debug.assert(CommandLine.getArgCount() > 1, "Assembly file argument missing");
            
            var asmFile = CommandLine.getArg(1);
            
            if (asmFile == "ProcessID") {
                Debug.assert(CommandLine.getArgCount() > 3, "Assembly file argument missing");
                asmFile = CommandLine.getArg(3);
            }
            
            Debug.assert(File.fileExists(asmFile), "Assembly file not found: "+asmFile);
            
            var bytes = File.loadBinaryFile(asmFile);
            
            Debug.assert(bytes != null, "Unable to load assembly file bytes");
            
            var asm = Assembly.loadBytes(bytes);
            
            Debug.assert(asm != null, "Unable to load assembly");
            
            var result:TestResult = TestRunner.runAll(asm);
            trace(result.typeReport);
            Process.exit(result.typeReport.successful ? 0 : 1);
        }
        
    }
}