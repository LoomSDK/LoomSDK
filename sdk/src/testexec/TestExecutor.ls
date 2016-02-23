package
{
    import system.platform.File;
    import system.reflection.Assembly;
    import unittest.TestResult;
    import unittest.TestRunner;
    
    public class TestExecutor
    {
        public var argOffset:int;
        
        private function getReferencedAssembly(asm:Assembly, name:String):Assembly
        {
            for (var i = 0; i < asm.getReferenceCount(); i++)
            {
                var ref = asm.getReference(i);
                if (ref.getName() == name)
                    return ref;
            }

            return null;
        }
        
        private function getArguments():String
        {
            var args = "";
            for (var i = 0; i < CommandLine.getArgCount(); i++) args += "  " + i + ": " + CommandLine.getArg(i) + "\n";
            return args;
        }

        [UnitTestHideCall]
        public function run():void
        {
            Debug.assert(CommandLine.getArgCount() > argOffset, "Assembly file argument missing:\n" + getArguments());

            var asmFile = CommandLine.getArg(argOffset);

            if (asmFile == "ProcessID") {
                argOffset += 2;
                Debug.assert(CommandLine.getArgCount() > argOffset, "Assembly file argument missing:\n" + getArguments());
                asmFile = CommandLine.getArg(argOffset);
            }

            Debug.assert(File.fileExists(asmFile), "Assembly file not found: "+asmFile);

            var asm = Assembly.load(asmFile);

            Debug.assert(asm != null, "Unable to load assembly");

            var unittestasm1 = getReferencedAssembly(asm, "UnitTest");
            Debug.assert(unittestasm1 != null, "Unable to get referenced assembly 'UnitTest' from loaded assembly");
            var unittestasm2 = getReferencedAssembly(this.getType().getAssembly(), "UnitTest");
            Debug.assert(unittestasm2 != null, "Unable to get referenced assembly 'UnitTest' from executing assembly");

            Debug.assert(unittestasm1.getUID() == unittestasm2.getUID(), "'UnitTest' referenced assemblies don't match. Please recompile your binaries.");

            TestRunner.onComplete += function(result:TestResult) {
                Process.exit(result.typeReport.successful ? 0 : 1);
            };

            var result:TestResult = TestRunner.runAll(asm, true);
        }
    }
}