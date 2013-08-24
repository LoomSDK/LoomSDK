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

class TestByteArray extends Test
{

    function writeByteArray(ba:ByteArray):void {

        ba.clear();        
        ba.writeInt(10000000);
        ba.writeDouble(1000.2);
        ba.writeString("Lalala");
        ba.writeFloat(2000.5);
        ba.writeUnsignedInt(0xbaadf00d);
        ba.writeBoolean(true);
        ba.writeBoolean(false);
        ba.writeBoolean(true);
        ba.writeByte(-10);
        ba.writeByte(10); 
        ba.writeUnsignedByte(255);
        ba.writeUnsignedByte(257); // overflow to 1
        ba.writeShort(-1000);
        ba.writeUnsignedShort(65535);
        
    }

    function dumpByteArray(ba:ByteArray):void {
        
        ba.setPosition(0);
        log(ba.readInt());
        log(ba.readDouble());
        log(ba.readString());
        log(ba.readFloat());
        log(ba.readUnsignedInt());
        log(ba.readBoolean());
        log(ba.readBoolean());
        log(ba.readBoolean());
        log(ba.readByte());
        log(ba.readByte());
        log(ba.readUnsignedByte());
        log(ba.readUnsignedByte());
        log(ba.readShort());
        log(ba.readUnsignedShort());
        
    }

    function test()
    {
                
        
        var ba = new ByteArray();
        writeByteArray(ba);
        dumpByteArray(ba);
        
        
        var bb = new ByteArray();
        bb.readBytes(ba);
        bb.setPosition(0);
        dumpByteArray(bb);        

        var bc = new ByteArray();
        bb.writeBytes(bc);
        dumpByteArray(bc);        

        
        ba.clear();
        ba.writeString("Why, hello there!");
        ba.setPosition(0);
        log(ba.readString());
        
        
        
        
    }
    
    function TestByteArray()
    {
        name = "TestByteArray";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = 
    "
10000000
1000.2
Lalala
2000.5
3131961357
true
false
true
-10
10
255
1
-1000
65535
10000000
1000.2
Lalala
2000.5
3131961357
true
false
true
-10
10
255
1
-1000
65535
10000000
1000.2
Lalala
2000.5
3131961357
true
false
true
-10
10
255
1
-1000
65535
Why, hello there!    
";    
}

}



