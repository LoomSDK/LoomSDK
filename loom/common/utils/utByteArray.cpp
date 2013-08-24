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


void utByteArray::uncompress(int uncompressedSize, int maxBuffer)
{
    _position = 0;

    int sz = uncompressedSize;

    if (!sz)
    {
        sz = maxBuffer;
    }

    utByteArray dest;
    dest.resize(sz);

    unsigned int readSZ = sz;

    int ok = ::uncompress((Bytef *)dest.getDataPtr(), (uLongf *)&readSZ, (const Bytef *)((unsigned char *)getDataPtr()), (uLong)getSize());

    if ((ok != Z_OK) || (uncompressedSize && (readSZ != uncompressedSize)))
    {
        resize(0);
        return;
    }

    _data = dest._data;
}
