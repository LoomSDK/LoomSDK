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

class TestJSON extends Test
{

    var jsonString1:String = "{\"booleanvalue\":true,\"code\":200,\"message\":{\"user\":{\"rank\":0,\"score\":1.1,\"id\":\"502adb10793251463f000000\"},\"leaderboard\":[1, 2, 4, 5, 6]}}";

    function test()
    {
        var json = new JSON();
        
        if (!json.loadString(jsonString1)) {
            
            log(json.getError());
            
        }
        
        var code:int = json.getInteger("code");
        
        log(json.getBoolean("booleanvalue"));
                
        var message = json.getObject("message");
        
        var user = message.getObject("user");
        
        log(user.getString("id"));
        
        var leaderboard = message.getArray("leaderboard");
        
        for (var i = 0; i < leaderboard.getArrayCount(); i++)
            log(leaderboard.getArrayInteger(i));

         assert(user.getFloat("score") == 1.1);

         // Test JSON setting non-sequential array indexes
         
         var jsonArray = new JSON();
         jsonArray.loadString("[]");
         jsonArray.setArrayString( 0, "First!" );
         jsonArray.setArrayString( 4, "The 5th Element" );
         
         assert( jsonArray.serialize() == "[\"First!\", null, null, null, \"The 5th Element\"]" );
         
         // Test JSON setArray() functionality
         
         var jsonArray2 = new JSON();
         jsonArray2.loadString("[ 1, 2, 3 ]");
         
         var jsonArrayTestObject = new JSON();
         jsonArrayTestObject.loadString( "{}" );
         jsonArrayTestObject.setArray( "arrayValue", jsonArray2 );
         assert( jsonArrayTestObject.serialize() == "{\"arrayValue\": [1, 2, 3]}" );
    }
    
    function TestJSON()
    {
        name = "TestJSON";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
"
true
502adb10793251463f000000
1
2
4
5
6";    
}

}



