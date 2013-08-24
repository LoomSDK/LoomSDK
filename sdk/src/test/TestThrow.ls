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

class TestThrow extends Test
{
    function TestThrow()
    {
        name = "TestThrow";
        expected = "1245";
    }    

    function test()
    {
        // Uncomment to test exceptions.
        // throw new Error("Oh no!");

        // Test execution of a try/catch block.
        log("1");

        try
        {
            log("2");
        }
        catch(e:Error)
        {
            // Should not run this block.
            log("3");
            throw new Error("Oh no!");
        }
        finally
        {
            // Should run this.
            log("4");
        }

        log("5");
    }
    
}

}



