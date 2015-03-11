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

package system
{
  /**
   *  The ByteArray class provides methods and properties to optimize reading, writing, and working with binary data.
   */
  native class ByteArray
  {
    
    /*
    // Compresses the byte array.
    public native function compress(algorithm:String):void;
    
    
    // Compresses the byte array using the deflate compression algorithm.
    public native function deflate():void;

    // Decompresses the byte array using the deflate compression algorithm.
    public native function inflate():void;   
    */
    
    /**
     * Return the length in bytes of this ByteArray.
     */
    public native var length:Number;
    
    /**
     * Get the number of bytes left until the end of the byte array.
     */
    public native function get bytesAvailable():int;
    
    /**
     * Set the current position of the byte array.
     */
    public native function set position(value:int);
    
    /**
     * Get the current position of the byte array.
     */
    public native function get position():int;
    
    /**
     *  Clears the contents of the byte array and resets the length and position properties to 0.
     */
    public native function clear():void;
    
    /**
     *  Reserves the number of bytes specified.
     * 
     *  This does not set the ByteArray's size, it just reserves the desired capacity
     *  to avoid memory thrashing when writing to the ByteArray.
     */
    public native function reserve(bytes:Number):void;
    
    /**
     *  Reads the number of data bytes, specified by the length parameter, from the byte stream. 
     *  The bytes are read into the ByteArray object specified by the bytes parameter, and the bytes 
     *  are written into the destination ByteArray starting at the position specified by offset.
     *
     *  @param bytes The ByteArray object to read data into.
     *  @param offset The offset (position) in bytes at which the read data should be written.
     *  @param length The number of bytes to read. The default value of 0 causes all available data to be read.
     */
    public native function readBytes(bytes:ByteArray, offset:int = 0, length:int = 0):int;
    
    /**
     *  Reads a signed byte from the byte stream.
     *
     *  The returned value is in the range -128 to 127.
     *
     *  @return An integer between -128 and 127.
     */
    public native function readByte():int;
    
    /**
     *  Reads a Boolean value from the byte stream.
     *
     *  A single byte is read, returning true for non-zero values, false otherwise.
     *
     *  @return Returns true if the byte is nonzero, false otherwise.
     */
    public native function readBoolean():Boolean;
    
    /**
     *  Reads an IEEE 754 double-precision (64-bit) floating-point number from the byte stream.
     *
     *  @return A double-precision (64-bit) floating-point number.
     */
    public native function readDouble():Number;
    
    /**
     *  Reads an IEEE 754 single-precision (32-bit) floating-point number from the byte stream.
     *
     *  @return A single-precision (32-bit) floating-point number.
     */
    public native function readFloat():Number;
    
    /**
     *  Reads a signed 32-bit integer from the byte stream.
     *
     *  The returned value is in the range -2147483648 to 2147483647.
     *
     *  @return A 32-bit signed integer between -2147483648 and 2147483647.
     */
    public native function readInt():int;
    
    /**
     *  Moves the current position of the file pointer (in bytes) into the ByteArray object. 
     *  
     *  This is the point at which the next call to a read method starts reading or a write method starts writing.
     */
    public native function setPosition(value:int):void;
    
    /**
     *  Reads a signed 16-bit integer from the byte stream.
     *
     *  The returned value is in the range -32768 to 32767.
     *
     *  @return A 16-bit signed integer between -32768 and 32767.
     */
    public native function readShort():int;
    
    /**
     *  Reads an unsigned byte from the byte stream.
     *
     *  The returned value is in the range 0 to 255.
     *
     *  @return A 32-bit unsigned integer between 0 and 255.
     */
    public native function readUnsignedByte():int;
    
    /**
     *  Reads an unsigned 32-bit integer from the byte stream.
     *
     *  The returned value is in the range 0 to 4294967295.
     *
     *  @return A 32-bit unsigned integer between 0 and 4294967295.
     */
    public native function readUnsignedInt():int;
    
    /**
     *  Reads a UTF-8 string from the byte stream. 
     *  The string is assumed to be prefixed with an unsigned int indicating the length in bytes.
     *
     *  @return UTF-8 encoded String.
     */
    public native function readString():String;
    
    /**
     *  Reads a UTF-8 string from the byte stream. 
     *  The string is assumed to be prefixed with an unsigned short indicating the length in bytes.
     *
     *  @return UTF-8 encoded String.
     */
    public native function readUTF():String;
    
    /**
     *  Reads a length amount of UTF-8 string bytes from the byte stream. 
     *
     *  @return UTF-8 encoded String.
     */
    public native function readUTFBytes(length:uint):String;
    
    /**
     *  Reads an unsigned 16-bit integer from the byte stream.
     *  
     *  The returned value is in the range 0 to 65535.
     *
     *  @return A 16-bit unsigned integer between 0 and 65535.
     */
    public native function readUnsignedShort():int;
    
    /**
     *  Converts the byte array to a string.
     *
     *  If the data in the array begins with a Unicode byte order mark, the application will honor that mark when converting to a string.
     */
    public native function toString():String;
    
    /**
     *  Writes a sequence of length bytes from the specified byte array, bytes, starting offset(zero-based index) bytes into the byte stream.
     *
     *  If the length parameter is omitted, the default length of 0 is used; the method writes the entire buffer starting at offset. If the offset parameter is also omitted, the entire buffer is written.
     *
     *  @param bytes The ByteArray object.
     *  @param offset A zero-based index indicating the position into the array to begin writing.
     *  @param length An integer indicating how far into the buffer to write.
     */
    public native function writeBytes(bytes:ByteArray, offset:int = 0, length:int = 0):void;
    
    /**
     *  Writes a byte to the byte stream.
     *  
     *  The low 8 bits of the parameter are used. The high 24 bits are ignored.
     *
     *  @param value A 32-bit integer. The low 8 bits are written to the byte stream.
     */
    public native function writeByte(value:int):void;
    
    /**
     *  Writes a byte to the byte stream.
     *
     *  @param value A 32-bit integer. The low 8 bits are written to the byte stream.
     */
    public native function writeUnsignedByte(value:int):void;
    
    /**
     *  Writes a Boolean value.
     *
     *  A single byte is written according to the value parameter, either 1 if true or 0 if false.
     *
     *  @param value A Boolean value determining which byte is written. If the parameter is true, the method writes a 1; if false, the method writes a 0.
     */
    public native function writeBoolean(value:Boolean):void;
    
    /**
     *  Writes an IEEE 754 double-precision (64-bit) floating-point number to the byte stream.
     *  
     *  @param value A double-precision (64-bit) floating-point number.
     */
    public native function writeDouble(value:Number):void;
        
    /**
     *  Writes an IEEE 754 single-precision (32-bit) floating-point number to the byte stream.
     *
     *  @param value A single-precision (32-bit) floating-point number.
     */
    public native function writeFloat(value:Number):void;

    /**
     *  Writes a 32-bit signed integer to the byte stream.
     *
     *  @param value An integer to write to the byte stream.
     */
    public native function writeInt(value:int):void;
            
    /**
     *  Writes a 16-bit integer to the byte stream.
     *
     *  @param value 32-bit integer, whose low 16 bits are written to the byte stream.
     */
    public native function writeShort(value:int):void;
    
    /**
     *  Writes a 16-bit integer to the byte stream.
     *
     *  @param value 32-bit integer, whose low 16 bits are written to the byte stream.
     */
    public native function writeUnsignedShort(value:int):void;
            
    /**
     *  Writes a 32-bit unsigned integer to the byte stream.
     *
     *  @param value An unsigned integer to write to the byte stream.
     */
    public native function writeUnsignedInt(value:int):void;
    
    /**
     *  Writes a UTF-8 string to the byte stream. 
     *  The length of the UTF-8 string in bytes is written first, as a 32-bit integer, 
     *  followed by the bytes representing the characters of the string
     *
     *  @param value The string value to be written.
     */
    public native function writeString(value:String):void;

    /**
     *  Writes a UTF-8 string to the byte stream. 
     *  The length of the UTF-8 string in bytes is written first, as a 16-bit integer, 
     *  followed by the bytes representing the characters of the string
     *
     *  @param value The string value to be written.
     */
    public native function writeUTF(value:String):void;
    
    /**
     *  Writes a UTF-8 string to the byte stream. 
     *  This function only writes the bytes representing the characters of the string.
     *
     *  @param value The string value to be written.
     */
    public native function writeUTFBytes(value:String):void;
    
    /**
     * Compress the ByteArray data with the zlib compression algorithm.
     * The ByteArray gets resized to the compressed size of the data.
     */
    public native function compress():void;
    
    /**
     * Uncompress zlib or gzip compressed data. uncompressedSize is equivalent to
     * initialSize due to legacy code. If not specified, initialSize will be used
     * and ByteArray will be truncated to the actual size of the data. If the
     * uncompressed data size doesn't fit in initialSize bytes, the buffer gets
     * resized until it does.
     */
    public native function uncompress(uncompressedSize:int = 0, maxBuffer:int = 262144):void;
        
	}


}