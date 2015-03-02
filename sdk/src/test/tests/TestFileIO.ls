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

import unittest.LegacyTest;
import system.platform.File;
import system.platform.Path;


class TestFileIO extends LegacyTest
{
    var writePath = Path.getWritablePath() + "/Loom/Tests";

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

    function readByteArray(ba:ByteArray):void {
        
        ba.setPosition(0);
        assert(ba.readInt() == 10000000);
        assert(ba.readDouble() == 1000.2);
        assert(ba.readString() == "Lalala");
        assert(ba.readFloat() == 2000.5);
        assert(ba.readUnsignedInt() == 0xbaadf00d);
        assert(ba.readBoolean() == true);
        assert(ba.readBoolean() == false);
        assert(ba.readBoolean() == true);
        assert(ba.readByte() == -10);
        assert(ba.readByte() == 10);
        assert(ba.readUnsignedByte() == 255);
        assert(ba.readUnsignedByte() == 1);
        assert(ba.readShort() == -1000);
        assert(ba.readUnsignedShort() == 65535);
        
    }


    function testBinaryFile() {


        var bytes = new ByteArray();

        writeByteArray(bytes);

        var filename = writePath + "/TestBinaryFileIO.bin";

        assert(!File.fileExists(filename));

        File.writeBinaryFile(filename, bytes);

        assert(File.fileExists(filename));

        var readBytes = File.loadBinaryFile(filename);

        readByteArray(readBytes);

    }

    function testTextFile() {

        var textToWrite = "Hello this is some text";

        var filename = writePath + "/TestFileIO.txt";

        assert(!File.fileExists(filename));

        File.writeTextFile(filename, textToWrite);

        assert(File.fileExists(filename));

        var result = File.loadTextFile(filename);

        assert(result == textToWrite);

    }

    function test()
    {        

        if (Path.dirExists(writePath))
            Path.removeDir(writePath, true);

        assert(!Path.dirExists(writePath));

        Path.makeDir(writePath);

        assert(Path.dirExists(writePath));

        testTextFile();
        testBinaryFile();

        Path.removeDir(writePath, true);

        assert(!Path.dirExists(writePath));

    }
    
    function TestFileIO()
    {
        name = "TestFileIO";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "";
}

}



