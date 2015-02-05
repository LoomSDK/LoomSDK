package {
    import system.reflection.MethodInfo;
    import system.reflection.Type;
    
    class Test {
        /**
         * Can be either a Type or an instance.
         */
        public var target:Object;
        public var name:String;
        public var method:MethodInfo;
        public var meta:MetaInfo;
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
        
        
        private static function lpad(s:String, c:String, l:int):String {
            while (s.length < l) {
                s = c+s;
            }
            return s;
        }
        
        private static function rpad(s:String, c:String, l:int):String {
            while (s.length < l) {
                s = s+c;
            }
            return s;
        }
        
        [UnitTestHideCall]
        public static function runAll(target:Object, shuffle:Boolean = true):Vector.<Test> {
            var type:Type = target is Type ? target as Type : target.getType();
            
            IO.write("Testing "+type.getFullName()+"  ");
            
            var tests:Vector.<Test> = getTests(target);
            
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
                IO.write(lpad(""+(i+1), " ", 4)+". "+rpad(test.name, " ", 20)+" ");
                var ret = test.run();
                var results = Assert.popResults();
                var passed = 0;
                for each (var result in results) {
                    if (result == Assert.RESULT_SUCCESS) passed++;
                }
                IO.write("   ");
                IO.write(lpad(""+passed, " ", 3) + " / " + rpad(""+results.length, " ", 3) + " passed");
                if (passed < results.length) {
                    IO.write(" "+lpad(""+(results.length-passed), " ", 3)+" failed");
                    test.results = results;
                }
                if (ret != null) IO.write("   "+ret);
                IO.write("\n");
            }
            
            IO.write("\n");
            
            report(tests);
            
            return tests;
        }
        
        public static function report(tests:Vector.<Test>, stackSkip:int = 2) {
            
            var failedTests:Vector.<Test> = tests.filter(function(item:Object, index:Number, vector:Vector.<Test>):Boolean {
                return (item as Test).results != null;
            });
            
            IO.write("Tests passed: " + (tests.length - failedTests.length) + " / " + tests.length);
            IO.write("\n\n");
            
            if (failedTests.length > 0) {
                IO.write("### FAILED TESTS ###\n\n");
                
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
                        
                        IO.write(lpad(""+(j+1), " ", 4)+" Assert."+result.info);
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
                var meta = m.getMetaInfo("Test");
                if (meta != null) {
                    var test = new Test();
                    test.name = m.getName();
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