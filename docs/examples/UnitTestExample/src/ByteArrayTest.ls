package {
    
    public class ByteArrayTest {
        
        public function ByteArrayTest() {
            
        }
        
        static function staticTestA() {
            Assert.isTrue(true, "staticTestA ran!");
        }
        
        static function staticTestB() {
            Assert.isTrue(true, "staticTestB ran!");
        }
        
        static function staticTestC() {
            Assert.isTrue(true, "staticTestC ran!");
        }
        
        function nonstaticTestA() {
            Assert.isTrue(true, "nonstaticTestA ran!");
        }
        
        function nonstaticTestB() {
            Assert.isTrue(true, "nonstaticTestB ran!");
        }
        
        function nonstaticTestC() {
            Assert.isTrue(true, "nonstaticTestC ran!");
        }
        
        var ba:ByteArray = new ByteArray();
        
        
        [Test]
        function length() {
            ba.clear();
            ba.writeUnsignedShort(0x1234); Assert.compare(2, ba.length);
            ba.writeUnsignedShort(0x5678); Assert.compare(4, ba.length);
            checkBytes(ba, [0x34, 0x12, 0x78, 0x56]);
            
            ba.length = 2;
            Assert.compare(2, ba.length);
            Assert.compare(2, ba.position);
            
            checkBytes(ba, [0x34, 0x12]);
        }
        
        [Test]
        function bytesAvailable() {
            ba.clear(); Assert.compare(0, ba.position); Assert.compare(0, ba.bytesAvailable);
            ba.writeInt(5); Assert.compare(4, ba.position); Assert.compare(0, ba.bytesAvailable);
            ba.position = 3; Assert.compare(1, ba.bytesAvailable);
            ba.position = 0; Assert.compare(4, ba.bytesAvailable);
            ba.position = 100; Assert.compare(0, ba.bytesAvailable);
            ba.position = -10; Assert.compare(0, ba.bytesAvailable);
        }
        
        [Test]
        function writeInt() {
            ba.clear();
            ba.writeInt(0x00000000); checkBytes(ba, [0x00, 0x00, 0x00, 0x00]);
            ba.writeInt(0x7FFFFFFF); checkBytes(ba, [0xFF, 0xFF, 0xFF, 0x7F]);
            
            ba.writeInt(2147483647); checkBytes(ba, [0xFF, 0xFF, 0xFF, 0x7F]);
            ba.writeInt(2147483646); checkBytes(ba, [0xFE, 0xFF, 0xFF, 0x7F]);
            ba.writeInt(-2147483648.0); checkBytes(ba, [0, 0, 0, 0x80]);
            ba.writeInt(-2147483647); checkBytes(ba, [1, 0, 0, 0x80]);
            
            ba.writeInt(0x12345678); checkBytes(ba, [0x78, 0x56, 0x34, 0x12]);
            ba.writeInt(-0x12345678); checkBytes(ba, [0x88, 0xa9, 0xcb, 0xed]);
        }
        
        [Test]
        function writeUnsignedInt() {
            ba.clear();
            ba.writeUnsignedInt(0xbaadf00d); checkBytes(ba, [0x0d, 0xf0, 0xad, 0xba]);
        }
        
        [Test]
        function writeFloat() {
            ba.clear();
            
            ba.writeFloat(123456789123456789.123456789123456789); checkBytes(ba, [0xa6, 0x4d, 0xdb, 0x5b]);
            
            // TODO: all edge cases, ditto for float
            ba.writeDouble(123456789123456789.123456789123456789); checkBytes(ba, [0xf1, 0x05, 0xcd, 0xba, 0xb4, 0x69, 0x7b, 0x43]);
        }
        
        [Test]
        function writeString() {
            ba.clear();
            ba.writeString("TEST"); checkBytes(ba, [4, 0, 0, 0, 0x54, 0x45, 0x53, 0x54]);
            ba.writeString(" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~");
            checkBytes(ba, [
                16*6-1, 0, 0, 0, // Length
                0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
                0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F,
                0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F,
                0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F,
                0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F,
                0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E
            ]);
        }
        
        [Test]
        function writeBoolean() {
            ba.clear();
            ba.writeBoolean(true);
            ba.writeBoolean(false);
            ba.writeBoolean(false);
            ba.writeBoolean(true);
            ba.writeBoolean(false);
            checkBytes(ba, [1, 0, 0, 1, 0]);
        }
        
        [Test]
        function writeByte() {
            ba.clear();
            ba.writeByte(-10);
            ba.writeByte(10); 
            ba.writeByte(0xFF);
            ba.writeByte(-0xFF);
            ba.writeByte(0xFFFF);
            ba.writeByte(-0xFFFF);
            ba.writeByte(0x10AB);
            ba.writeByte(-0x10AB);
            checkBytes(ba, [0x100-10, 10, 0xFF, 1, 0xFF, 1, 0xAB, 0x100-0xAB]);
        }
        
        [Test]
        function writeUnsignedByte() {
            ba.clear();
            ba.writeUnsignedByte(0);
            ba.writeUnsignedByte(1);
            ba.writeUnsignedByte(10);
            ba.writeUnsignedByte(128);
            ba.writeUnsignedByte(255);
            ba.writeUnsignedByte(256);
            ba.writeUnsignedByte(257); // overflow to 1
            ba.writeUnsignedByte(-1);
            ba.writeUnsignedByte(-255);
            ba.writeUnsignedByte(-256);
            checkBytes(ba, [0, 1, 10, 128, 255, 0, 1, 255, 1, 0]);
        }
        
        [Test]
        function writeShort() {
            ba.clear();
            ba.writeShort(0); checkBytes(ba, [0, 0]);
            ba.writeShort(1); checkBytes(ba, [1, 0]);
            ba.writeShort(2); checkBytes(ba, [2, 0]);
            ba.writeShort(3); checkBytes(ba, [3, 0]);
            ba.writeShort(-0); checkBytes(ba, [0, 0]);
            ba.writeShort(-1); checkBytes(ba, [0xFF, 0xFF]);
            ba.writeShort(-2); checkBytes(ba, [0xFF-1, 0xFF]);
            ba.writeShort(-3); checkBytes(ba, [0xFF-2, 0xFF]);
            ba.writeShort(123); checkBytes(ba, [123, 0]);
            ba.writeShort(1234); checkBytes(ba, [0xd2, 0x04]);
            ba.writeShort(12345); checkBytes(ba, [0x39, 0x30]);
            //ba.writeShort(123456); checkBytes(ba, [0x40, 0x62]);
            ba.writeShort(32767); checkBytes(ba, [0xFF, 0x7F]);
            ba.writeShort(-32768); checkBytes(ba, [0x00, 0x80]);
            ba.writeShort(32768); checkBytes(ba, [0x00, 0x80]);
            ba.writeShort(0x1ABCD); checkBytes(ba, [0xCD, 0xAB]);
        }
        
        [Test]
        function writeUnsignedShort() {
            ba.clear();
            ba.writeUnsignedShort(0x0000); checkBytes(ba, [0x00, 0x00]);
            ba.writeUnsignedShort(0x0001); checkBytes(ba, [0x01, 0x00]);
            ba.writeUnsignedShort(0x0002); checkBytes(ba, [0x02, 0x00]);
            ba.writeUnsignedShort(0x1234); checkBytes(ba, [0x34, 0x12]);
            ba.writeUnsignedShort(0xffff); checkBytes(ba, [0xff, 0xff]);
            ba.writeUnsignedShort(-0x0001); checkBytes(ba, [0xff, 0xff]);
            ba.writeUnsignedShort(-0x0002); checkBytes(ba, [0xfe, 0xff]);
            ba.writeUnsignedShort(-0x1234); checkBytes(ba, [0x100-0x34, 0xff-0x12]);
        }
        
        [Test]
        function writeBytes() {
            var bb = new ByteArray();
            bb.writeByte(12);
            bb.writeByte(34);
            bb.writeByte(156);
            bb.writeByte(178);
            bb.writeByte(190);
            
            ba.clear();
            
            bb.position = 3;
            Assert.compare(3, bb.position);
            Assert.compare(0, ba.position);
            
            ba.writeBytes(bb, 2, 2);
            Assert.compare(3, bb.position, "Position of the array being written from should be unchanged");
            Assert.compare(2, ba.position, "Position of the array being written to should increment");
            
            
            ba.clear();
            
            ba.writeBytes(bb); checkBytes(ba, [12, 34, 156, 178, 190]);
            ba.writeBytes(bb, 2); checkBytes(ba, [156, 178, 190]);
            ba.writeBytes(bb, -2); checkBytes(ba, [12, 34, 156, 178, 190]);
            ba.writeBytes(bb, 0, 2); checkBytes(ba, [12, 34]);
            ba.writeBytes(bb, -2, -2); checkBytes(ba, [12, 34, 156, 178, 190, 12, 34]); // depends on previous results
            ba.writeBytes(bb, 0, 10); checkBytes(ba, [12, 34, 156, 178, 190]);
            ba.writeBytes(bb, 1, 2); checkBytes(ba, [34, 156]);
            ba.writeBytes(bb, 3, 1); checkBytes(ba, [178]);
            ba.writeBytes(bb, 3, 10); checkBytes(ba, [178, 190]);
            ba.writeBytes(bb, 0, 5); checkBytes(ba, [12, 34, 156, 178, 190]);
        }
        
        [Test]
        function position() {
            ba.clear(); Assert.compare(0, ba.position);
            ba.writeByte(1); Assert.compare(1, ba.position);
            ba.writeByte(2); Assert.compare(2, ba.position);
            ba.writeByte(3); Assert.compare(3, ba.position);
            ba.writeByte(4); Assert.compare(4, ba.position);
            ba.writeByte(5); Assert.compare(5, ba.position);
            
            checkBytes(ba, [1, 2, 3, 4, 5]);
            
            ba.position = 2; Assert.compare(2, ba.position);
            checkBytes(ba, [1, 2]);
            
            ba.position = 3; Assert.compare(3, ba.position);
            checkBytes(ba, [1, 2, 3]);
            
            ba.position = 4; Assert.compare(4, ba.position);
            checkBytes(ba, [1, 2, 3, 4]);
            
            ba.position = 1; Assert.compare(1, ba.position);
            checkBytes(ba, [1]);
            
            ba.position = -5; Assert.compare(4294967291.0, ba.position);
            ba.position = 100; Assert.compare(100, ba.position);
            
            ba.position = 2; Assert.compare(2, ba.position);
            ba.writeByte(30); Assert.compare(3, ba.position);
            ba.position = 4; Assert.compare(4, ba.position);
            ba.writeByte(50); Assert.compare(5, ba.position);
            checkBytes(ba, [1, 2, 30, 4, 50]);
            
            ba.position = 0;
            ba.writeByte(10);
            ba.writeByte(20);
            ba.position = 3;
            ba.writeByte(40);
            ba.position = ba.length;
            checkBytes(ba, [10, 20, 30, 40, 50]);
            
            ba.clear(); Assert.compare(0, ba.position);
            var cmds = [
                // Function, argument, sizeof
                ba.writeByte, 5, 1,
                ba.writeBoolean, true, 1,
                ba.writeDouble, 123.456, 8,
                ba.writeFloat, 123.456, 4,
                ba.writeInt, 5, 4,
                ba.writeShort, 5, 2,
                ba.writeString, "testy", 9,
                ba.writeUnsignedByte, 5, 1,
                ba.writeUnsignedInt, 5, 4,
                ba.writeUnsignedShort, 5, 2
            ];
            
            var pos = 0;
            for (var i = 0; i < cmds.length; i += 3) {
                var f:Function = cmds[i] as Function;
                var arg:Object = cmds[i+1];
                var size:int   = cmds[i+2] as int;
                f.apply(ba, [arg]);
                pos += size;
                Assert.compare(pos, ba.position, "Position changed by an unexpected amount for line index "+(i/3));
            }
        }
        
        
        
        [Test]
        function readInt() {
            ba.clear();
            fillBytes(ba, [0x00, 0x00, 0x00, 0x00]); Assert.compare(0x00000000, ba.readInt());
            fillBytes(ba, [0xFF, 0xFF, 0xFF, 0x7F]); Assert.compare(0x7FFFFFFF, ba.readInt());
            
            fillBytes(ba, [0xFF, 0xFF, 0xFF, 0x7F]); Assert.compare(2147483647, ba.readInt());
            fillBytes(ba, [0xFE, 0xFF, 0xFF, 0x7F]); Assert.compare(2147483646, ba.readInt());
            fillBytes(ba, [0, 0, 0, 0x80]); Assert.compare(-2147483648.0, ba.readInt());
            fillBytes(ba, [1, 0, 0, 0x80]); Assert.compare(-2147483647, ba.readInt());
            
            fillBytes(ba, [0x78, 0x56, 0x34, 0x12]); Assert.compare(0x12345678, ba.readInt());
            fillBytes(ba, [0x88, 0xa9, 0xcb, 0xed]); Assert.compare(-0x12345678, ba.readInt());
        }
        
        [Test]
        function readUnsignedInt() {
            ba.clear();
            fillBytes(ba, [0x0d, 0xf0, 0xad, 0xba]); Assert.compare(0xbaadf00d, ba.readUnsignedInt());
        }
        
        [Test]
        function readFloat() {
            ba.clear();
            
            fillBytes(ba, [0xa6, 0x4d, 0xdb, 0x5b]); Assert.compareNumber(1.23456789123456789e+017, ba.readFloat());
            
            // TODO: all edge cases, ditto for float
            fillBytes(ba, [0xf1, 0x05, 0xcd, 0xba, 0xb4, 0x69, 0x7b, 0x43]); Assert.compare(123456789123456789.123456789123456789, ba.readDouble());
        }
        
        [Test]
        function readString() {
            ba.clear();
            fillBytes(ba, [4, 0, 0, 0, 0x54, 0x45, 0x53, 0x54]); Assert.compare("TEST", ba.readString());
            fillBytes(ba, [
                16*6-1, 0, 0, 0, // Length
                0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
                0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F,
                0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F,
                0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F,
                0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F,
                0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E
            ]);
            Assert.compare(" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~", ba.readString());
        }
        
        [Test]
        function readBoolean() {
            ba.clear();
            fillBytes(ba, [1, 0, 0, 1, 0]);
            Assert.compare(true, ba.readBoolean());
            Assert.compare(false, ba.readBoolean());
            Assert.compare(false, ba.readBoolean());
            Assert.compare(true, ba.readBoolean());
            Assert.compare(false, ba.readBoolean());
        }
        
        [Test]
        function readByte() {
            ba.clear();
            fillBytes(ba, [-10, 10, 0xFF, -0xFF, 0xFFFF, -0xFFFF, 0x10AB, -0x10AB], false);
            checkBytes(ba, [0x100-10, 10, 0xFF, 1, 0xFF, 1, 0xAB, 0x100-0xAB]);
        }
        
        [Test]
        function readUnsignedByte() {
            ba.clear();
            fillBytes(ba, [0, 1, 10, 128, 255, 256, 257, -1, -255, -256], false);
            checkBytes(ba, [0, 1, 10, 128, 255, 0, 1, 255, 1, 0]);
        }
        
        [Test]
        function readShort() {
            ba.clear();
            fillBytes(ba, [0, 0]); Assert.compare(0, ba.readShort());
            fillBytes(ba, [1, 0]); Assert.compare(1, ba.readShort());
            fillBytes(ba, [2, 0]); Assert.compare(2, ba.readShort());
            fillBytes(ba, [3, 0]); Assert.compare(3, ba.readShort());
            fillBytes(ba, [0, 0]); Assert.compare(-0, ba.readShort());
            fillBytes(ba, [0xFF, 0xFF]); Assert.compare(-1, ba.readShort());
            fillBytes(ba, [0xFF-1, 0xFF]); Assert.compare(-2, ba.readShort());
            fillBytes(ba, [0xFF-2, 0xFF]); Assert.compare(-3, ba.readShort());
            fillBytes(ba, [123, 0]); Assert.compare(123, ba.readShort());
            fillBytes(ba, [0xd2, 0x04]); Assert.compare(1234, ba.readShort());
            fillBytes(ba, [0x39, 0x30]); Assert.compare(12345, ba.readShort());
            fillBytes(ba, [0xFF, 0x7F]); Assert.compare(32767, ba.readShort());
            fillBytes(ba, [0x00, 0x80]); Assert.compare(-32768, ba.readShort());
            fillBytes(ba, [0xCD, 0xAB]); Assert.compare(-21555, ba.readShort());
        }
        
        [Test]
        function readUnsignedShort() {
            ba.clear();
            fillBytes(ba, [0x00, 0x00]); Assert.compare(0x0000, ba.readUnsignedShort());
            fillBytes(ba, [0x01, 0x00]); Assert.compare(0x0001, ba.readUnsignedShort());
            fillBytes(ba, [0x02, 0x00]); Assert.compare(0x0002, ba.readUnsignedShort());
            fillBytes(ba, [0x34, 0x12]); Assert.compare(0x1234, ba.readUnsignedShort());
            fillBytes(ba, [0xff, 0xff]); Assert.compare(0xffff, ba.readUnsignedShort());
            fillBytes(ba, [0xfe, 0xff]); Assert.compare(0xfffe, ba.readUnsignedShort());
            fillBytes(ba, [0x100-0x34, 0xff-0x12]); Assert.compare(0x10000-0x1234, ba.readUnsignedShort());
        }
        
        [Test]
        function readBytes() {
            ba.clear();
            
            var bb = new ByteArray();
            fillBytes(ba, [ 12,  34, 156, 178, 190]);
            fillBytes(bb, [111, 111, 111, 111, 111]);
            
            ba.position = 2;
            bb.position = 1;
            Assert.compare(2, ba.position);
            Assert.compare(1, bb.position);
            
            ba.readBytes(bb, 4, 2);
            Assert.compare(4, ba.position, "Position of the array being read from should increment");
            Assert.compare(1, bb.position, "Position of the array being read to should be unchanged");
            
            Assert.compare(5, ba.length);
            Assert.compare(6, bb.length);
            
            ba.position = 0; checkBytes(ba, [ 12,  34, 156, 178, 190], false);
            bb.position = 0; checkBytes(bb, [111, 111, 111, 111, 156, 178], false);
            
            
            ba.clear();
            bb.clear();
            
            fillBytes(ba, [ 12,  34, 156, 178, 190]);
            fillBytes(bb, [111, 111, 111, 111, 111]);
            
            bb.position = 0;
            
            ba.position = 0; ba.readBytes(bb, 1, 3); checkBytes(bb, [111, 12, 34, 156, 111], false);
            ba.position = 0; ba.readBytes(bb      ); checkBytes(bb, [12, 34, 156, 178, 190], false);
            
            bb.clear(); fillBytes(bb, [111, 111, 111, 111, 111]);
            ba.position = 2; ba.readBytes(bb, 1, 2); checkBytes(bb, [111, 156, 178, 111, 111], false);
            
            bb.clear(); fillBytes(bb, [111, 111, 111, 111, 111]);
            ba.position = 4; ba.readBytes(bb, -1, 2); checkBytes(bb, [190, 111, 111, 111, 111], false);
            
            bb.clear(); fillBytes(bb, [111, 111, 111, 111, 111]);
            ba.position = 6; ba.readBytes(bb, 10, 10); checkBytes(bb, [111, 111, 111, 111, 111], false);
        }
        
        
        private static function fillBytes(ba:ByteArray, bytes:Vector.<int>, reset:Boolean = true) {
            var pos = ba.position;
            for (var i in bytes) {
                var byte:int = bytes[i];
                ba.writeByte(byte);
            }
            Assert.compare(pos + bytes.length, ba.position, "Position mismatch after filling with bytes");
            if (reset) ba.position = pos;
        }
        
        private static function checkBytes(ba:ByteArray, bytes:Vector.<int>, rewind:Boolean = true) {
            if (rewind) ba.position -= bytes.length;
            Assert.isTrue(ba.position >= 0, "//2 Invalid test with checkBytes, the amount of provided check bytes exceeds the currently written bytes.");
            for (var i in bytes) {
                var checkByte = bytes[i];
                var readByte = ba.readUnsignedByte();
                Assert.compare(checkByte, readByte, "//2 Bytes are not equal at index "+i);
            }
            if (!rewind) ba.position -= bytes.length;
        }
        
    }
    
}