/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#ifndef _UT_BYTEARRAY_H_
#define _UT_BYTEARRAY_H_

//#include "core/assert.h"
#include "utTypes.h"
#include "utString.h"

class utByteArray {
protected:
    // stored as little endian
    utArray<unsigned char> _data;
    int _position;

    template<typename T>
    T readValue()
    {
        if (_position > (int)_data.size() - (int)sizeof(T))
        {
            //lmAssert(0, "ByteArray out of data on read of size %u", sizeof(T));
            assert(0);
        }

        T *ptr  = (T *)&_data[_position];
        T value = *ptr;

        _position += sizeof(T);

        value = convertLEndianToHost(value);

        return value;
    }

    template<typename T>
    void writeValue(T value)
    {
        if (_data.size() < _position + sizeof(T))
        {
            _data.resize(_position + sizeof(T));
        }

        value = convertHostToLEndian(value);

        T *ptr = (T *)&_data[_position];
        *ptr = value;

        _position += sizeof(T);
    }

    static int readBytesInternal(utByteArray *dstByteArray, utByteArray *srcByteArray, int offset = 0, int length = 0, bool dstOffset = true)
    {
        if (!srcByteArray || !dstByteArray)
        {
            return 0;
        }

        unsigned char *src = srcByteArray->_data.ptr();

        if (!dstOffset)
        {
            srcByteArray->_position = offset;
        }

        if (!length)
        {
            length = srcByteArray->_data.size();
        }
        else if (length > (int)srcByteArray->_data.size())
        {
            length = srcByteArray->_data.size();
        }
        else
        {
            src = srcByteArray->_data.ptr() + srcByteArray->_position;
            if (src - srcByteArray->_data.ptr() > length)
            {
                length = src - srcByteArray->_data.ptr();
            }
        }

        // check whether offset is from src or dst
        if (dstOffset)
        {
            if ((int)dstByteArray->_data.size() < offset + length)
            {
                dstByteArray->_data.resize(offset + length);
            }

            dstByteArray->_position = offset;
        }
        else
        {
            if ((int)dstByteArray->_data.size() < dstByteArray->_position + length)
            {
                dstByteArray->_data.resize(dstByteArray->_position + length);
            }
        }

        unsigned char *out = dstByteArray->_data.ptr() + dstByteArray->_position;
        while (length-- > 0)
        {
            *out = *src;
            src++;
            out++;
            dstByteArray->_position++;
        }

        return length;
    }

public:
    utByteArray()
    {
        _position = 0;
    }

    void clear();

    void setPosition(int value)
    {
        _position = value;
    }

    int getPosition() const
    {
        return _position;
    }

    int bytesAvailable() const
    {
        int size = getSize();
        return size < _position ? 0 : size-_position;
    }

    bool readBoolean()
    {
        return readValue<bool>();
    }

    void writeBoolean(bool value)
    {
        writeValue<bool>(value);
    }

    signed char readByte()
    {
        return (int)readValue<signed char>();
    }

    void writeByte(signed char value)
    {
        writeValue<signed char>(value);
    }

    unsigned char readUnsignedByte()
    {
        return readValue<unsigned char>();
    }

    void writeUnsignedByte(unsigned char value)
    {
        writeValue<unsigned char>(value);
    }

    short readShort()
    {
        return readValue<short>();
    }

    void writeShort(short value)
    {
        writeValue<short>(value);
    }

    unsigned short readUnsignedShort()
    {
        return readValue<unsigned short>();
    }

    void writeUnsignedShort(unsigned short value)
    {
        writeValue<unsigned short>(value);
    }

    int readInt()
    {
        return readValue<int>();
    }

    void writeInt(int value)
    {
        writeValue<int>(value);
    }

    float readFloat()
    {
        return readValue<float>();
    }

    void writeFloat(float value)
    {
        writeValue<float>(value);
    }

    double readDouble()
    {
        return readValue<double>();
    }

    void writeDouble(double value)
    {
        writeValue<double>(value);
    }

    unsigned int readUnsignedInt()
    {
        return readValue<unsigned int>();
    }

    void writeUnsignedInt(unsigned int value)
    {
        writeValue<unsigned int>(value);
    }

    void writeString(const char *value)
    {
        if (!value)
        {
            writeValue<int>(0);
            return;
        }

        int length = strlen(value);

        if (!length)
        {
            writeValue<int>(0);
            return;
        }

        writeValue<int>(length);

        if ((int)_data.size() < _position + length)
        {
            _data.resize(_position + length);
        }

        char *ptr = (char *)&_data[_position];
        memcpy(ptr, value, length);

        _position += length;
    }

    // note that the string returned is only valid between reads
    const char *readString()
    {
        static utString svalue;

        int length = readValue<int>();

        if (!length)
        {
            return "";
        }

        char *value = new char[length + 1];

        value[length] = 0;
        memcpy(value, &_data[_position], length);
        _position += length;

        svalue = value;

        delete [] value;

        return svalue.c_str();
    }

    void writeBytes(utByteArray *byteArray, int offset = 0, int length = 0)
    {
        readBytesInternal(byteArray, this, offset, length, false);
    }

    int readBytes(utByteArray *byteArray, int offset = 0, int length = 0)
    {
        return readBytesInternal(this, byteArray, offset, length);
    }

    /*
     * Return the utByteArray as a string, please not that the string buffer
     * returned is only valid between calls
     */
    const char *toString()
    {
        static utString svalue;

        if (_data.ptr() != NULL)
        {
            svalue  = (const char *)_data.ptr();
            svalue += "\0"; // ensure null terminated
        }
        else
        {
            svalue = "";
        }

        return svalue.c_str();
    }

    /*
     * Given a source memory pointer and size, initialize the utByteArray with
     * the data and reset position to 0
     */
    void allocateAndCopy(void *src, int size)
    {
        _data.resize(size);
        memcpy(_data.ptr(), src, size);
        _position = 0;
    }

    /*
     * Direct access to the utByteArray's data
     */
    void *getDataPtr()
    {
        return _data.ptr();
    }

    /*
     * Direct access to the utByteArray's size
     */
    UTsize getSize() const
    {
        return _data.size();
    }

    /*
     * Reserve the specified amount of memory for the utByteArray, this does
     * not resize the array, it allocates enough memory to hold the specified
     * amount.  This is most useful to avoid memory thrashing when writing to
     * the array
     */
    void reserve(UTsize size)
    {
        return _data.reserve(size);
    }

    /*
     * Set the utByteArray's size directly
     */
    void resize(UTsize size)
    {
        return _data.resize(size);
    }

    /*
     * returns true if file open/read was successful
     * with file contents in the ByteArray, addNullTerminator is useful
     * for reading string files, which may not be null terminated
     */
    static bool tryReadToArray(const utString& path, utByteArray& bytes, bool addNullTerminator = true);

    /*
     * Retrieve the low level array to avoid copies/etc in special situation
     */

    utArray<unsigned char> *getInternalArray() { return &_data; }

    /*
     * Compress the ByteArray data with the zlib compression algorithm.
     * The ByteArray gets resized to the compressed size of the data.
     */
    void compress();

    /*
     * Uncompress zlib or gzip compressed data. uncompressedSize is equivalent to
     * initialSize due to legacy code. If not specified, initialSize will be used
     * and ByteArray will be truncated to the actual size of the data. If the
     * uncompressed data size doesn't fit in initialSize bytes, the buffer gets
     * resized until it does.
     */
    void uncompress(int uncompressedSize = 0, int initialSize = 32768);
};
#endif // _PLATFORM_BYTEARRAY_H_
