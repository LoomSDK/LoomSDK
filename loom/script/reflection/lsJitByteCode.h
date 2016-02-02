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

#ifndef _lsjitbytecode_h
#define _lsjitbytecode_h

#include "loom/common/utils/utString.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utByteArray.h"

#define LOOM_JIT_BYTECODE_VERSION 1

namespace LS {
class LSLuaState;

enum ByteCodeVariantFlags
{
    NONE         = 0,
    BASE64_DIRTY = 1 << 0,
    BYTES_DIRTY  = 1 << 1
};

class ByteCodeVariant
{

    int flags;

    utString base64;
    utByteArray bytes;

    utString bytesToBase64(const utArray<unsigned char>& bc);
    utArray<unsigned char> base64ToBytes(utString bc64);

public:

    ByteCodeVariant();

    void clear();

    const utString& getBase64();
    const utArray<unsigned char>& getByteCode();

    void setBase64(utString bc64);
    void setByteCode(const utArray<unsigned char>& bc);

    void serialize(utByteArray *stream) const;
    void deserialize(utByteArray *stream);
};

class ByteCode {
    ByteCodeVariant std;
    ByteCodeVariant fr2;

public:
    utString error;

    ~ByteCode()
    {
        clear();
    }

    const utString& getBase64();
    const utArray<unsigned char>& getByteCode();
    const utString& getBase64FR2();
    const utArray<unsigned char>& getByteCodeFR2();

    void setBase64(utString bc64);
    void setBase64FR2(utString bc64_fr2);
    void setByteCode(const utArray<unsigned char>& bc);
    void setByteCodeFR2(const utArray<unsigned char>& bc_fr2);

    bool load(LSLuaState *ls, bool execute = false);

    void clear();

    void serialize(utByteArray *bytes) const;
    void deserialize(utByteArray *bytes);

};
}
#endif
