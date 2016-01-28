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

class ByteCode {
    // byte code encoded as base64
    utString bc64;

    // raw bytecode
    utArray<unsigned char> bc;

    // two slot byte code encoded as base64
    utString bc64_fr2;

    // two slot raw bytecode
    utArray<unsigned char> bc_fr2;


    utString bytesToBase64(const utArray<unsigned char>& bc);
    utArray<unsigned char> base64ToBytes(utString bc64);

public:
    utString error;

    ~ByteCode()
    {
        clear();
    }

    const utString& getBase64()
    {
        return bc64;
    }

    const utArray<unsigned char>& getByteCode()
    {
        return bc;
    }

    const utString& getBase64FR2()
    {
        return bc64_fr2;
    }

    const utArray<unsigned char>& getByteCodeFR2()
    {
        return bc_fr2;
    }

    void setBase64(utString bc64)
    {
        this->bc64 = bc64;
        this->bc = base64ToBytes(this->bc64);
    }

    void setBase64FR2(utString bc64_fr2)
    {
        this->bc64_fr2 = bc64_fr2;
        this->bc_fr2 = base64ToBytes(this->bc64_fr2);
    }

    void setByteCode(const utArray<unsigned char>& bc)
    {
        this->bc = bc;
        this->bc64 = bytesToBase64(bc);
    }

    void setByteCodeFR2(const utArray<unsigned char>& bc_fr2)
    {
        this->bc_fr2 = bc_fr2;
        this->bc64_fr2 = bytesToBase64(bc_fr2);
    }

    bool load(LSLuaState *ls, bool execute = false);

    void clear()
    {
        bc64 = "";
        bc.clear();
    }

    void serialize(utByteArray *bytes) const;
    void deserialize(utByteArray *bytes);

    static ByteCode *decode64(const utString& code64);

    static ByteCode *encode64(const utArray<unsigned char>& bc);

};
}
#endif
