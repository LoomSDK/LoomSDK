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

#ifndef LOOM_ENABLE_JIT

#ifndef _lsbytecode_h
#define _lsbytecode_h

#include "loom/common/utils/utBase64.h"
#include "loom/common/utils/utByteArray.h"

#define LOOM_CLASSIC_BYTECODE_MAGIC 0x43
#define LOOM_CLASSIC_BYTECODE_VERSION 1

namespace LS {
class LSLuaState;

class ByteCode {
    utBase64 base64;

public:
    utString error;

    utString getBase64()
    {
        return base64.getBase64();
    }

    void setBase64(utString bc64)
    {
        base64 = utBase64::decode64(bc64);
    }

    const utArray<unsigned char>& getByteCode()
    {
        return base64.getData();
    }

    void clear()
    {
        base64.clear();
    }

    bool load(LSLuaState *ls, bool execute = false);

    static ByteCode *decode64(const char *code64);

    static ByteCode *encode64(const utArray<unsigned char>& bc);

    void serialize(utByteArray *bytes);
    void deserialize(utByteArray *bytes);
};
}
#endif
#endif
