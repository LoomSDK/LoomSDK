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

#include "zlib.h"

#include "utByteArray.h"
#include "utStreams.h"

// When uncompressing with an unknown uncompressed size
// the buffer is resized if it's not big enough.
// This defines the maximum number of bytes the buffer
// can be enlarged by to avoid resizing the buffer too much.
#define BUFFER_DELTA_MAX 10*1024*1024

void utByteArray::clear()
{
    _position = 0;
    _data.resize(0);
}


bool utByteArray::tryReadToArray(const utString& path, utByteArray& bytes, bool addNullTerminator)
{
    utFileStream fstream;

    fstream.open(path.c_str(), utStream::SM_READ);
    if (!fstream.isOpen())
    {
        return false;
    }

    UTsize sz = fstream.size();

    if (addNullTerminator)
    {
        sz += 1;
    }

    bytes._data.resize(sz);

    fstream.read(bytes._data.ptr(), addNullTerminator ? sz - 1 : sz);

    if (addNullTerminator)
    {
        bytes._data[sz - 1] = 0;
    }

    fstream.close();

    return true;
}

void utByteArray::compress()
{
    _position = 0;

    int ret = Z_OK;

    utByteArray dest;

    uLong size = getSize();
    uLong destSize = compressBound(size);
    dest.resize(destSize);

    ret = ::compress((Bytef *) dest.getDataPtr(), &destSize, (Bytef *) getDataPtr(), size);

    if (ret != Z_OK) {
        return;
    }

    _data = dest._data;
    resize(destSize);
    _position = destSize;
}

void utByteArray::uncompress(int uncompressedSize, int initialSize)
{
    _position = 0;
 
    int ret = Z_OK;

    int sz = uncompressedSize > 0 ? uncompressedSize : initialSize;
 
    utByteArray dest;
    dest.resize(sz);
 
    z_stream stream;   
    stream.zalloc = (alloc_func)0;
    stream.zfree = (free_func)0;
    stream.opaque = (voidpf)0;
 
    stream.next_in = (Bytef *) ( (unsigned char*) getDataPtr());
    stream.avail_in = (uLong) getSize();
    stream.next_out = (Bytef *) dest.getDataPtr();
    stream.avail_out = sz;
 
    ret = inflateInit2(&stream, 15 + 32); // zlib + gzip autodetection
    if (ret != Z_OK)
    {
        resize(0);
        return;
    }
    
    // Inflate while status is Z_OK, which means that
    // inflation is still in progress, but needs more space.
    while (true) {
        ret = inflate(&stream, Z_NO_FLUSH);
        if (ret == Z_OK) {
            // Resize the dest buffer
            int old = sz;
            sz += sz > BUFFER_DELTA_MAX ? BUFFER_DELTA_MAX : sz;
            dest.resize(sz);
            stream.avail_out = sz - old;
            stream.next_out = (Bytef *)((char*) dest.getDataPtr() + old);
            continue;
        }
        break;
    }
    
    if (ret != Z_STREAM_END)
    {
        inflateEnd(&stream);
        resize(0);
        return;
    }
 
    sz = sz - stream.avail_out;
    inflateEnd(&stream);
 
    _data = dest._data;
    resize(sz);
    _position = 0;
}
