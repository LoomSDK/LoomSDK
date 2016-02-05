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

    void bytesToBase64(utByteArray* bc, utString *bc64);
    void base64ToBytes(utString* bc64, utByteArray *bc);

public:

    ByteCodeVariant();

    void clear();

    utString* getBase64();
    utByteArray* getByteCode();

    void setBase64(utString bc64);
    void setByteCode(utByteArray bc);

    void serialize(utByteArray *stream);
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

    utString& getBase64();
    utArray<unsigned char>& getByteCode();
    utString& getBase64FR2();
    utArray<unsigned char>& getByteCodeFR2();

    void setBase64(utString bc64);
    void setBase64FR2(utString bc64_fr2);
    void setByteCode(const utArray<unsigned char>& bc);
    void setByteCodeFR2(const utArray<unsigned char>& bc_fr2);

    bool load(LSLuaState *ls, bool execute = false);

    void clear();

    void serialize(utByteArray *bytes);
    void deserialize(utByteArray *bytes);

};
}
#endif
