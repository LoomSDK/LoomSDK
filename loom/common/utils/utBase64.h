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

#ifndef _utbase64_h
#define _utbase64_h

#include "utString.h"
#include "utTypes.h"

class utBase64 {
    // byte code encoded as base64
    utString bc64;

    // raw bytecode
    utArray<unsigned char> bc;

public:

    utBase64& operator=(const utBase64& rhs)
    {
        bc64 = rhs.bc64;
        bc   = rhs.bc;
        return *this;
    }

    const utString& getBase64()
    {
        return bc64;
    }

    const utArray<unsigned char>& getData()
    {
        return bc;
    }

    void clear()
    {
        bc64 = NULL;
        bc.clear();
    }

    static utBase64 decode64(const utString& code64);

    static utBase64 encode64(const utArray<unsigned char>& bc);
};
#endif
