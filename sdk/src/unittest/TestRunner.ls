package unittest {
    import system.reflection.Assembly;
    import system.reflection.MetaInfo;
    import system.reflection.MethodInfo;
    import system.reflection.Type;
    
    /**
     * Generic stats value object holding the number of
     * passed/failed/skipped events.
     */
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
    
    /**
     * TypeTest groups all the tests found in a specific Type.
     */
    class TypeTest {
        public var type:Type;
        public var tests:Vector.<Test>;
        
        public var skip:Boolean;
        public var async:Boolean;
        
        public var report:StatusReport = new StatusReport();
        public var asserts:StatusReport = new StatusReport();
    }
    
    /**
     * Represents an individual test case. Each test can have several
     * assertions, the results of which are saved in the results Vector after
     * running the test.
     */
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
        public var async:Boolean;
        
        public var report:StatusReport = new StatusReport();
        public var results:Vector.<AssertResult>;
        
        function Test() { };
        
        [UnitTestHideCall]
        public function run(c:TestComplete = null):Object {
            if (this.async) {
                method.invokeSingle(target, c);
                return null;
            }
            else {
                return method.invoke(target);
            }
        }
        
        public function toString():String {
            return "[Test "+name+"]";
        }
    }
    
    /**
     * TestResult groups all the TypeTests and accumulates their reports.
     */
    public class TestResult {
        /**
         * The total number of scanned types in the test run.
         */
        public var scannedTypes:int;
        public var typeTests:Vector.<TypeTest>;
        
        public var typeReport:StatusReport = new StatusReport();
        public var testReport:StatusReport = new StatusReport();
        public var assertReport:StatusReport = new StatusReport();
    }
    
    /**
     * TestRunner is the main entry point of the framework. It contains several
     * static modular methods for better flexibility, while still providing a
     * quick and easy way to run and report on all the tests of an Assembly (see runAll).
     */
    public class TestRunner {
        
        // The result that will be returned when everything is done
        private static var result:TestResult;
        
        // Various reports from the result variable
        private static var typeReport:StatusReport;
        private static var testReport:StatusReport;
        private static var assertReport:StatusReport;
        
        // If there is at least one async test in the test suite
        private static var foundAsync:Boolean;
        
        // Variables used by the run test functionality
        public static var runTests:Vector.<Test>;
        public static var runIndex:Number;
        public static var runComplete:Function;
        
        public function TestRunner() {}
        
        /**
         * Run and report on all the tests in the specified assembly.
         * @param assembly  The assembly from which to run the tests.
         *                  Use Type.getAssembly() or getType().getAssembly() for an easy way to run tests in the currently running application.
         * @param shuffle   Whether to shuffle the tests or not, defaults to true to allow for faster failure of tests that depend on side effects.
         * @return  A TestResult containing the run TypeTests and their accumulated results.
         */
        [UnitTestHideCall]
        public static function runAll(assembly:Assembly, shuffle:Boolean = true, complete:Function = null):TestResult {
            result = new TestResult();
            
            typeReport = result.typeReport;
            testReport = result.testReport;
            assertReport = result.assertReport;
            
            foundAsync = false;
            
            result.scannedTypes = assembly.getTypeCount();
            
            IO.write("Scanning "+result.scannedTypes+" "+(result.scannedTypes == 1 ? "type" : "types")+"\n");
            
            result.typeTests = getTypeTests(assembly);
            var totalTests = 0;
            for each (var typeTest in result.typeTests) {
                totalTests += typeTest.tests.length;
            }
            
            IO.write("Found "+result.typeTests.length+" "+(result.typeTests.length == 1 ? "type" : "types"));
            IO.write(" with a total of "+totalTests+" "+(totalTests == 1 ? "test" : "tests")+"\n");
            
            IO.write("\n");
            
            runTypes(result.typeTests, shuffle, function() {
                reportTypes(result.typeTests, result.typeReport, result.testReport, result.assertReport);
                
                if (complete) {
                    complete.call(null, result);
                }
            });
            
            return null;
        }
        
        /**
         * Runs all the provided TypeTests and optionally updates the provided reports.
         * @param typeTests The TypeTests to run.
         * @param shuffle   If true, shuffles the types first.
         * @param typeReport    Accumulated report on types.
         * @param testReport    Accumulated report on tests.
         * @param assertReport  Accumulated report on assertions.
         */
        [UnitTestHideCall]
        public static function runTypes(typeTests:Vector.<TypeTest>, shuffle:Boolean = true, complete:Function = null) {
            if (shuffle) typeTests.shuffle();
            
            var tests = new Vector.<Test>();
            
            var i:int;
            var tt:TypeTest;
            
            if (typeReport) typeReport.total += typeTests.length;
            
            runTypesCallback(typeTests, shuffle, 0, tests, complete);
        }
        
        private static function runTypesCallback(typeTests:Vector.<TypeTest>, shuffle:Boolean, index:Number, tests:Vector.<Test>, complete:Function = null) {
            if (index >= typeTests.length) {
                if (typeReport) typeReport.updateFailed();
                complete.call();
                return;
            }
            var tt:TypeTest = typeTests[index];
            tt.asserts.reset();
            
            // Different styles of output
            //IO.write((tt.skip ? "Skipping" : "Running")+" "+tt.type.getFullName()+"   "+(i+1)+" / "+typeTests.length+"\n");
            //IO.write((i+1)+"/"+typeTests.length+"  "+(tt.skip ? "Skipping" : "Running")+" "+tt.type.getFullName()+"\n");
            IO.write((index+1)+"/"+typeTests.length+" "+tt.type.getFullName()+(tt.skip ? "(skipped)" : "")+"\n");
            if (tt.skip) {
                if (typeReport) typeReport.skipped++;
                runTypesCallback(typeTests, shuffle, ++index, tests, complete);
                return;
            }
            
            IO.write("\n");
            run(tt.tests, shuffle, function() {
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
                runTypesCallback(typeTests, shuffle, ++index, tests, complete);
            });
        }
        
        /**
         * Report on all the tests contained in the provided TypeTests.
         * @param typeTests The TypeTests to report on.
         * @param typeReport    The status report containing the results of the run.
         * @param testReport    Optional status report on tests.
         * @param assertReport  Optional status report on assertions.
         */
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
        
        /**
         * Iterate over the provided assembly and retrieve all the types that contain tests in the form of TypeTests.
         * @param assembly  The assembly to iterate over.
         * @return  A Vector of TypeTests for each type containing at least one test.
         */
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
                    
                    // Determine if this test type contains async tests
                    tt.async = false;
                    if (foundAsync) { // Only need to run this loop if there is at least one async test in the entire suite so far
                        for (var t in tests) {
                            if (tests[t].async) {
                                tt.async = true;
                                break;
                            }
                        }
                    }
                    
                    typeTests.push(tt);
                }
            }
            return typeTests;
        }
        
        /**
         * Run all the provided tests. The tests are updated with the results.
         * @param tests The tests to run.
         * @param shuffle   If true, shuffle the tests to fail fast for tests that depend on side effects and specific execution order.
         * @param complete Function that will be called when the operation is complete
         */
        [UnitTestHideCall]
        public static function run(tests:Vector.<Test>, shuffle:Boolean = true, complete:Function = null) {
            var i:int;
            var test:Test;
            
            var instanceTests = 0;
            for (i in tests) {
                test = tests[i];
                if (!test.method.isStatic()) instanceTests++;
            }
            
            IO.write(tests.length+" "+(tests.length == 1 ? "test" : "tests")+" ");
            IO.write("(");
            IO.write((tests.length-instanceTests)+" static");
            IO.write(", "+instanceTests+" non-static");
            IO.write(")");
            
            // Shuffle unit tests to increase the chances of side effects affecting tests
            if (shuffle) tests.shuffle();
            
            IO.write("\n");
            
            // Set variables
            runTests = tests;
            runIndex = 0;
            runComplete = complete;
            
            runCallback();
        }
        
        /**
         * @private
         * 
         * Function that is used in "run()" to support async testing
         */
        private static function runCallback() {
            
            while (true) {
                if (runIndex >= runTests.length) {
                    runComplete.call();
                    return;
                }
                var test:Test = runTests[runIndex];
                IO.write(String.lpad(""+(runIndex+1), " ", 4)+". "+String.rpad(test.name, " ", 20)+" ");
                IO.write("   ");
                if (test.skip) {
                    IO.write("   skipped\n");
                    runIndex++;
                    runCallback();
                    return;
                }
                
                if (!test.async) {
                    var ret:Object = test.run();
                    runHandleTest(ret, false);
                    runIndex++;
                }
                else {
                    test.run(new TestComplete(runHandleTest));
                    break;
                }
            }
        }
        
        /**
         * @private
         * 
         * Used as the callback for asynchronous tests, as well as in synchronous tests
         * 
         * @param ret
         * @param recurse
         */
        private static function runHandleTest(ret:Object = null, recurse:Boolean = true) {
            var test:Test = runTests[runIndex];
            var results = Assert.popResults();
            var passed = 0;
            for each (var result in results) {
                if (result == Assert.RESULT_SUCCESS) passed++;
            }
            test.report.total = results.length;
            test.report.passed = passed;
            test.report.updateFailed();
            IO.write(String.lpad(""+test.report.total, " ", 4) + " total " + String.lpad(""+test.report.passed, " ", 4) + " passed");
            if (passed < results.length) {
                IO.write(" "+String.lpad(""+(results.length-passed), " ", 4)+" failed");
                test.results = results;
            }
            if (ret != null) IO.write("   "+ret);
            IO.write("\n");
            
            if (recurse) {
                runIndex++;
                runCallback();
            }
        }
        
        /**
         * Output a detailed report on the tests. It is assumed that the tests have already been ran.
         * @param tests The tests to report on.
         * @param stackSkip The number of calls to skip from the bottom of the call stack.
         */
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
        
        /**
         * Scans the provided target and returns all the found tests.
         * A test is a method marked with the [Test] metadata.
         * 
         * @param target    It can be either an instance of a class or a Type object.
         * @param createInstance    If the provided target was not an instance and the type
         *                          contains instance tests, create an instance of the type.
         * @return  All the found test methods in the provided target.
         */
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
                    
                    // Determine if the test is async
                    if (m.getNumParameters() > 0 && m.getParameter(0).getParameterType().getFullName() == "unittest.TestComplete") {
                        foundAsync = true;
                        test.async = true;
                    }
                    else
                        test.async = false;
                    
                    tests.push(test);
                    if (!m.isStatic()) instanceTests++;
                }
            }
            
            // Create instance if none was provided for instance tests
            if (createInstance && instanceTests > 0 && target is Type) {
                var instance = type.getConstructor().invoke();
                for each (var t:Test in tests) if (!t.method.isStatic()) t.target = instance;
            }
            
            return tests;
        }
        
    }
    
    /**
     * Special class to be used when making asynchronous tests. Simply add a parameter with this type to your testing
     * function, and call the done() function when your asynchronous test is complete
     */
    public class TestComplete {
        private var doneFunction:Function;
        private var hasBeenCalled:Boolean;
        
        
        public function TestComplete(d:Function) {
            hasBeenCalled = false;
            
            doneFunction = d;
        }
        
        /**
         * Call this function when your test is complete!
         * 
         * @param msg An object that will be logged in the test
         */
        public function done(msg:Object = null):void {
            if (hasBeenCalled) {
                Assert.fail("ERROR: complete() called more than once for a single asynchronous test!");
                return;
            }
            
            hasBeenCalled = true;
            doneFunction.call(null, [msg]);
        }
    }
}































