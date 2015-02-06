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

public class LegacyTest
{
    public static var verbose:Boolean = true;

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

    public static function assertEqual(a:Object, b:Object, msg:String = ""):void
    {
        if(a == b)
            handleAssertSuccess();
        else
            handleAssertFailure(msg + " (expected " + a + " to equal " + b + ")");
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
    protected var expected:String;
    protected static var actual:String;

    protected function pass()
    {
        Assert.isTrue(true);
    }

    protected function fail()
    {
        Assert.fail("Legacy test failed: "+name);
    }

    public function begin()
    {
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
    
    [Test]
    public function run()
    {
        name = this.getType().getFullName();
        begin();
        test();
        end();
    }
    
}

}
