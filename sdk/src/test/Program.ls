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

package tests {

import unittest.Test;

import system.xml.XMLTest;

    public class Program {
            
        public static function main() {
        
            var xmlFile:String;
        
            for (var i = 0; i < CommandLine.getArgCount(); i++) {
            
                if (CommandLine.getArg(i) == "--xmlfile") {
                
                    Debug.assert(i + 1 < CommandLine.getArgCount(), "Please specify a filename, example: --xmlfile UnitTest.xml");
                    xmlFile = CommandLine.getArg(i + 1);
                    break;
                }
            }
        
            trace("Running Tests");
            
            new TestNativeClass().run();
            new TestManagedNativeClass().run();
                        
            new TestAssignment().run();
            new TestImportResolution().run();
            
            new TestJSON().run();
            new TestByteArray().run();
            
            new TestMath().run();
            
            new TestSuper().run();
            
            new TestImplicit().run();
            
            new TestStatic().run();
            new TestSwitch().run();
            new TestCoroutine().run();
            new TestInheritance().run();
            new TestBooleanExpr().run();
            new TestConditional().run();
            new TestWhile().run();
            new TestScope().run();
            new TestAdditionOperator().run();
            new TestDoWhile().run();
            new TestLoop().run();
            new TestLocal().run();
            new TestFib().run();
            new TestProperty().run();
            new TestCoercion().run();
            new TestDefaultArguments().run();
            new TestDictionary().run();
            new TestBitOps().run();
            new TestFunction().run();
            new TestInterface().run();
            new TestOperator().run();
            new TestStruct().run();
            new TestDelegate().run();
            new TestEnum().run();
            new TestVector().run();
            new TestVarArg().run();
            new TestReflection().run();
            
            new TestToString().run();
            new TestString().run();
            
            new TestPrimitiveTypes().run();
            
            new TestBlock().run();            
            new TestBlock2().run(); 
            
            new TestReturn().run();

            new TestWildcardImport().run();
            new TestFileIO().run();

            new TestPublicProtectedPrivate().run();

            new TestThrow().run();

            new TestIncrementExpression().run();
            
            trace("Tests Passed: " + Test.passed.length);
            trace("Tests Failed: " + Test.failed.length);
            
            if (xmlFile)
                Test.generateXML(xmlFile);
        }
    
    }

}