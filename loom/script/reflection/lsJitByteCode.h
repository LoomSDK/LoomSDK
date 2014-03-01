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

namespace LS {
class LSLuaState;

class ByteCode {
    // byte code encoded as base64
    utString bc64;

    // raw bytecode
    utArray<unsigned char> bc;

public:

    const utString& getBase64()
    {
        return bc64;
    }

    const utArray<unsigned char>& getByteCode()
    {
        return bc;
    }

    bool load(LSLuaState *ls, bool execute = false);

    void clear()
    {
        bc64 = "";
        bc.clear();
    }

    static ByteCode *decode64(const utString& code64);

    static ByteCode *encode64(const utArray<unsigned char>& bc);
};
}
#endif
