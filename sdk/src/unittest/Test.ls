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

package unittest
{

import system.xml.XMLDocument;

public class Test
{
    public static var verbose:Boolean = true;
    public static var passed:Vector.<Test> = [];
    public static var failed:Vector.<Test> = [];
    
    public static var currentTest:String = "UNKNOWN";
    public static var currentTestSuccessCount:int = 0;
    public static var currentTestFailureCount:int = 0;
    public static var currentTestErrors:Vector.<String> = new Vector.<String>();

    protected static function handleAssertFailure(msg:String):void
    {
        currentTestFailureCount ++;

        if (msg)
            currentTestErrors.pushSingle(msg);
    }

    protected static function handleAssertSuccess():void
    {
        currentTestSuccessCount++;
    }

    public static function assertEqual(a:Object, b:Object, msg:String = null):void
    {
        if(a == b)
            handleAssertSuccess();
        else
            handleAssertFailure(msg);
    }

    public static function assert(value:Object, msg:String = null):void 
    {        
        if(value)
            handleAssertSuccess();
        else
            handleAssertFailure(msg);
    }

    public static function log(value:Object):void
    {
        Debug.assert(actual != null);
        actual += value.toString();
    }

    protected var name:String;
    protected static var expected:String;
    protected static var actual:String;
    
    protected function pass() 
    {
        passed.pushSingle(this);
    }
    
    protected function fail() 
    {
        Console.print(currentTest + " FAILED " + currentTestFailureCount + "/" + (currentTestFailureCount + currentTestSuccessCount) + "!");
        Console.print("  " +currentTestErrors.join("\n  "));

        failed.pushSingle(this);
    }
    
    public function begin()
    {
        if (verbose)
            Console.print("Running Test " + name);

        // Reset state.
        currentTest = name;
        currentTestErrors = new Vector.<String>();
        currentTestFailureCount = 0;
        currentTestSuccessCount = 0;
        actual = "";
    }
    
    public function isWhitespace(c:String):Boolean
    {
        if(c == " ") return true;
        if(c == "\t") return true;
        if(c == "\n") return true;
        if(c == "\r") return true;
        return false;
    }

    public function areExpectedActualWithoutWhitespaceEqual():Boolean
    {
        var walkActual:int = 0;
        var walkExpected:int = 0;

        var mismatch:Boolean = false;
        while(walkActual < actual.length && walkExpected < expected.length)
        {
            var actualChar:String = actual.charAt(walkActual);
            var expectedChar:String = expected.charAt(walkExpected);

            if(isWhitespace(actualChar))
            {
                walkActual++;
            }
            else if(isWhitespace(expectedChar))
            {
                walkExpected++;
            }
            else
            {
                if(actualChar != expectedChar)
                    return false;

                walkActual++;
                walkExpected++;
            }
        }

        // TODO: Deal with case where one is exact prefix of other.

        return true;
    }

    public function end()
    {
        if(currentTestFailureCount > 0)
        {
            fail();
        }
        else if(actual != "" && !areExpectedActualWithoutWhitespaceEqual())
        {
            Console.print("EXPECTED");
            Console.print(expected);
            Console.print("ACTUAL");
            Console.print(actual);
            fail();
        }
        else
        {
            pass();
        }
    }
    
    function test()
    {
        Debug.assert(false, "You should never create a Test class without overriding test()!");
    }
    
    public function run()
    {
        name = this.getType().getFullName();
        begin();
        test();
        end();        
    }
    
    public static function generateXML(xmlFile:String) {
    
        var xml:String = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        
        var total = passed.length + failed.length;
        
        xml += "\n<!-- LoomScript Test Suite -->\n";
        
        xml += "\n<testsuite name=\"LoomScript Tests\" tests=\"" + total +"\" errors=\"" + failed.length + "\" failures=\"0\" skip=\"0\">\n";
        
        xml += "\n<!-- PASSED -->\n";
        
        var i:int;
        for (i = 0; i < passed.length; i++) {
        
            var test = passed[i];
            xml += "\n<testcase name=\"" + test.name +"\" /> ";    
            
        }
        
        xml += "\n\n<!-- FAILED -->\n";
        
        for (i = 0; i < failed.length; i++) {
        
            var fail = failed[i];
            xml += "\n<testcase name=\"" + fail.name + "\" > <error /> </testcase>\n";    
            
        }
        
        xml += "\n</testsuite>\n";
        
        // Save it.
        var doc = new XMLDocument;
        doc.parse(xml);
        doc.saveFile(xmlFile);
    }
}

}


