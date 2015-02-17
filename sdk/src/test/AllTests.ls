/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package {

    import system.reflection.Type;
    import unittest.Test;
    import unittest.TestRunner;
    import unittest.TestResult;
    
    /**
     * Runs all the tests in the current project (see the tests/ subdir) and exits with the proper error code.
     */
    public class AllTests {   
        public static function main() {
            var result:TestResult = TestRunner.runAll((AllTests as Type).getAssembly());
            
            Process.exit(result.typeReport.successful ? 0 : 1);
        }
    }
}