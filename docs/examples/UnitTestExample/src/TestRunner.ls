package {
    import system.reflection.Assembly;
    import system.reflection.MetaInfo;
    import system.reflection.MethodInfo;
    import system.reflection.Type;
    
    class StatusReport {
        public var total:int;
        public var passed:int;
        public var failed:int;
        public var skipped:int;
        
        public function operator+=(s:StatusReport) {
            total += s.total;
            passed += s.passed;
            failed += s.failed;
            skipped += s.skipped;
        }
        
        public function updateFailed() {
            failed = total - passed - skipped;
        }
        public function get successful():Boolean {
            return failed == 0;
        }
        public function reset() {
            total = 0;
            passed = 0;
            failed = 0;
            skipped = 0;
        }
        public function toString():String {
            var s = String.lpad(""+total, " ", 4)+" total" +
                    ", "+String.lpad(""+passed, " ", 4)+" passed" +
                    ", "+String.lpad(""+failed, " ", 4)+" failed" +
                    (skipped > 0 ? ", "+String.lpad(""+skipped, " ", 4)+" skipped" : "");
            Debug.assert(total == passed + failed + skipped, "Status report internal error: "+s);
            return s;
        }
    }
    
    class TypeTest {
        public var type:Type;
        public var tests:Vector.<Test>;
        
        public var skip:Boolean;
        
        public var report:StatusReport = new StatusReport();
        public var asserts:StatusReport = new StatusReport();
    }
    
    class Test {
        /**
         * Can be either a Type or an instance.
         */
        public var type:Type;
        public var target:Object;
        public var name:String;
        public var method:MethodInfo;
        public var meta:MetaInfo;
        
        public var skip:Boolean;
        
        public var report:StatusReport = new StatusReport();
        public var results:Vector.<AssertResult>;
        
        function Test() { };
        
        [UnitTestHideCall]
        public function run():Object {
            return method.invoke(target);
        }
        
        public function toString():String {
            return "[Test "+name+"]";
        }
    }
    
    public class TestRunner {
        
        public function TestRunner() {
            
        }
        
        
        public static function runAll(assembly:Assembly, shuffle:Boolean = true):Vector.<Test> {
            
            var typeCount = assembly.getTypeCount();
            
            IO.write("Scanning "+typeCount+" types\n");
            
            var typeTests = getTypeTests(assembly);
            var totalTests = 0;
            for each (var typeTest in typeTests) {
                totalTests += typeTest.tests.length;
            }
            
            IO.write("Found "+typeTests.length+" "+(typeTests.length == 1 ? "type" : "types"));
            IO.write(" with a total of "+totalTests+" "+(totalTests == 1 ? "test" : "tests")+"\n");
            
            IO.write("\n");
            
            var typeReport:StatusReport = new StatusReport();
            var testReport:StatusReport = new StatusReport();
            var assertReport:StatusReport = new StatusReport();
            
            runTypes(typeTests, shuffle, typeReport, testReport, assertReport);
            
            reportTypes(typeTests, typeReport, testReport, assertReport);
            
            return typeTests;
        }
        
        public static function runTypes(typeTests:Vector.<TypeTest>, shuffle:Boolean = true, typeReport:StatusReport = null, testReport:StatusReport = null, assertReport:StatusReport = null) {
            if (shuffle) typeTests.shuffle();
            
            var tests = new Vector.<Test>();
            
            var i:int;
            var tt:TypeTest;
            
            if (typeReport) typeReport.total += typeTests.length;
            
            for (i = 0; i < typeTests.length; i++) {
                tt = typeTests[i];
                tt.asserts.reset();
                
                IO.write((tt.skip ? "Skipping" : "Running")+" "+tt.type.getFullName()+"   "+(i+1)+" / "+typeTests.length+"\n");
                if (tt.skip) {
                    if (typeReport) typeReport.skipped++;
                    continue;
                }
                
                IO.write("\n");
                run(tt.tests, shuffle);
                
                tt.report.reset();
                tt.report.total = tt.tests.length;
                for (var j = 0; j < tt.tests.length; j++) {
                    var test:Test = tt.tests[j];
                    if (assertReport) assertReport += test.report;
                    tt.asserts += test.report;
                    if (test.skip) {
                        tt.report.skipped++;
                        continue;
                    }
                    if (test.report.successful) tt.report.passed++;
                }
                tt.report.updateFailed();
                
                if (testReport) testReport += tt.report;
                
                if (tt.report.successful && typeReport) typeReport.passed++;
                
                IO.write("\n\n");
                tests = tests.concat(tt.tests);
            }
            if (typeReport) typeReport.updateFailed();
            
        }
        
        public static function reportTypes(typeTests:Vector.<TypeTest>, typeReport:StatusReport, testReport:StatusReport = null, assertReport:StatusReport = null) {
            if (typeReport.successful) {
                IO.write("############# TEST SUCCESS #############\n\n");
            } else {
                IO.write("########################################\n\n");
                IO.write("############# FAILED TESTS #############\n\n");
                
                for (var i = 0; i < typeTests.length; i++) {
                    var tt = typeTests[i];
                    if (!tt.report.successful) {
                        IO.write("########################################\n\n");
                        IO.write("Failing type: "+tt.type.getFullName()+"\n");
                        IO.write("Tests:   " + tt.report+"\n");
                        IO.write("Asserts: " + tt.asserts+"\n");
                        IO.write("\n");
                        IO.write("########################################\n\n");
                        report(tt.tests);
                    }
                }
            }
            
            if (assertReport) IO.write("Asserts: "+assertReport+"\n");
            if (testReport) IO.write("Tests:   "+testReport+"\n");
            IO.write("Types:   "+typeReport+"\n");
            
            IO.write("\n");
        }
        
        public static function getTypeTests(assembly:Assembly):Vector.<TypeTest> {
            var typeCount = assembly.getTypeCount();
            var typeTests = new Vector.<TypeTest>();
            for (var i:int = 0; i < typeCount; i++) {
                var type:Type = assembly.getTypeAtIndex(i);
                var tests:Vector.<Test> = getTests(type);
                if (tests.length > 0) {
                    var tt = new TypeTest();
                    tt.type = type;
                    tt.tests = tests;
                    tt.skip = type.getMetaInfo("SkipTests") != null;
                    typeTests.push(tt);
                }
            }
            return typeTests;
        }
        
        [UnitTestHideCall]
        public static function run(tests:Vector.<Test>, shuffle:Boolean = true) {
            //var type:Type = target is Type ? target as Type : target.getType();
            
            //IO.write("Running "+type.getFullName()+"  ");
            
            //var tests:Vector.<Test> = getTests(target);
            
            var i:int;
            var test:Test;
            
            var instanceTests = 0;
            for (i in tests) {
                test = tests[i];
                if (!test.method.isStatic()) instanceTests++;
            }
            
            IO.write(tests.length+" tests ");
            IO.write("(");
            IO.write((tests.length-instanceTests)+" static");
            IO.write(", "+instanceTests+" non-static");
            IO.write(")");
            
            // Shuffle unit tests to increase the chances of side effects affecting tests
            if (shuffle) tests.shuffle();
            
            IO.write("\n");
            
            for (i in tests) {
                test = tests[i];
                IO.write(String.lpad(""+(i+1), " ", 4)+". "+String.rpad(test.name, " ", 20)+" ");
                IO.write("   ");
                if (test.skip) {
                    IO.write("   skipped\n");
                    continue;
                }
                var ret = test.run();
                var results = Assert.popResults();
                var passed = 0;
                for each (var result in results) {
                    if (result == Assert.RESULT_SUCCESS) passed++;
                }
                test.report.total = results.length;
                test.report.passed = passed;
                test.report.updateFailed();
                IO.write(String.lpad(""+test.report.total, " ", 4) + " total " + String.lpad(""+test.report.passed, " ", 4) + " passed");
                //IO.write(lpad(""+passed, " ", 3) + " / " + rpad(""+results.length, " ", 3) + " passed");
                if (passed < results.length) {
                    IO.write(" "+String.lpad(""+(results.length-passed), " ", 4)+" failed");
                    test.results = results;
                }
                if (ret != null) IO.write("   "+ret);
                IO.write("\n");
            }
            
            //IO.write("\n");
            
            //report(tests);
            
            //return tests;
        }
        
        public static function report(tests:Vector.<Test>, stackSkip:int = 2) {
            
            var failedTests:Vector.<Test> = tests.filter(function(item:Object, index:Number, vector:Vector.<Test>):Boolean {
                return (item as Test).results != null;
            });
            
            if (failedTests.length > 0) {
                for (var i in failedTests) {
                    var test:Test = failedTests[i];
                    var results = test.results;
                    var j:int;
                    var result:AssertResult;
                    var passed = 0;
                    for (j in results) {
                        result = results[j];
                        if (result == Assert.RESULT_SUCCESS) passed++;
                    }
                    IO.write(test.name);
                    IO.write("   "+passed+" / "+results.length+" asserts passed");
                    IO.write("\n");
                    var indent = "    ";
                    for (j in results) {
                        result = results[j];
                        if (result == Assert.RESULT_SUCCESS) continue;
                        //var msg = result.message == null ? result.info : result.message;
                        //IO.write(indent+"Assert #"+(j+1)+": "+msg);
                        IO.write("\n");
                        var msg:String = result.message;
                        var stack:Vector.<CallStackInfo> = result.callStack.filter(function(item:Object, index:Number, vector:Vector.<CallStackInfo>):Boolean {
                            return index < vector.length-stackSkip && (item as CallStackInfo).method.getMetaInfo("UnitTestHideCall") == null;
                        });
                        var skip:int = 0;
                        if (msg == null) {
                            skip = stack.length;
                        } else if (msg.substr(0, 2) == "//") {
                            var spaceIndex = msg.indexOf(" ", 2);
                            if (spaceIndex != -1) {
                                skip = Math.max(0, msg.substring(2, spaceIndex).toNumber());
                                if (skip > 0) {
                                    skip = Math.min(stack.length, skip);
                                    msg = msg.substr(spaceIndex+1);
                                }
                            }
                        }
                        
                        IO.write(String.lpad(""+(j+1), " ", 4)+" Assert."+result.info);
                        if (skip == 0) {
                            IO.write(" // "+msg);
                        }
                        IO.write("\n");
                        //if (result.message != null) {
                            //IO.write(indent+result.info+"\n");
                        //}
                        for (var k = 1; k < stack.length; k++) {
                            var info:CallStackInfo = stack[k];
                            IO.write(indent+" "+info.source+":"+info.method.getName()+":"+info.line);
                            if (skip == k) IO.write(" // "+msg);
                            IO.write("\n");
                        }
                    }
                    IO.write("\n\n");
                }
                
            }
        }
        
        public static function getTests(target:Object, createInstance:Boolean = true):Vector.<Test> {
            var type:Type = target is Type ? target as Type : target.getType();
            
            var instanceTests = 0;
            
            var mn = type.getMethodInfoCount();
            var tests = new Vector.<Test>();
            for (var i:int = 0; i < mn; i++) {
                var m:MethodInfo = type.getMethodInfo(i);
                var meta:MetaInfo = m.getMetaInfo("Test");
                if (meta != null) {
                    var test = new Test();
                    test.skip = meta.getAttribute("skip") != null;
                    test.name = m.getName();
                    test.type = type;
                    test.target = target;
                    test.method = m;
                    test.meta = meta;
                    tests.push(test);
                    if (!m.isStatic()) instanceTests++;
                }
            }
            
            // Create instance if none was provided for instance tests
            if (createInstance && instanceTests > 0 && target is Type) {
                //IO.write("Creating instance of "+type.getFullName()+" (it has instance tests, but only a Type was provided)\n");
                var instance = type.getConstructor().invoke();
                for each (var t:Test in tests) if (!t.method.isStatic()) t.target = instance;
            }
            
            return tests;
        }
        
    }
    
}