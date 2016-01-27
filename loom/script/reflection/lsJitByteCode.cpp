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

#ifdef LOOM_ENABLE_JIT

#include <stdio.h>

extern "C" {
#include "lua.h"
#include "lj_lex.h"
#include "lj_str.h"
#include "lj_vm.h"
#include "lj_gc.h"
#include "lj_frame.h"
#include "lj_bcdump.h"
#include "lj_func.h"
}

#include "loom/script/reflection/lsByteCode.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/common/core/allocator.h"
loom_allocator_t *gByteCodeAllocator = NULL;

// snippets from http://base64.sourceforge.net/b64.c

namespace LS {
// base64 encode/decode

/*
** Translation Table as described in RFC1113
*/
static const char cb64[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/*
** Translation Table to decode (created by author)
*/
static const char cd64[] =
    "|$$$}rstuvwxyz{$$$$$$$>?@ABCDEFGHIJKLMNOPQRSTUVW$$$$$$XYZ[\\]^_`abcdefghijklmnopq";

/*
** encodeblock
**
** encode 3 8-bit binary bytes as 4 '6-bit' characters
*/
static void encodeblock(unsigned char in[3], unsigned char out[4], int len)
{
    out[0] = cb64[in[0] >> 2];
    out[1] = cb64[((in[0] & 0x03) << 4) | ((in[1] & 0xf0) >> 4)];
    out[2] =
        (unsigned char)(
            len > 1 ?
            cb64[((in[1] & 0x0f) << 2) | ((in[2] & 0xc0) >> 6)] :
            '=');
    out[3] = (unsigned char)(len > 2 ? cb64[in[2] & 0x3f] : '=');
}


/*
** decodeblock
**
** decode 4 '6-bit' characters into 3 8-bit binary bytes
*/
static void decodeblock(unsigned char in[4], unsigned char out[3])
{
    out[0] = (unsigned char)(in[0] << 2 | in[1] >> 4);
    out[1] = (unsigned char)(in[1] << 4 | in[2] >> 2);
    out[2] = (unsigned char)(((in[2] << 6) & 0xc0) | in[3]);
}


utArray<unsigned char> ByteCode::base64ToBytes(utString bc64)
{
    utArray<unsigned char> bc;

    unsigned char in[4], out[3], v;
    int           i, len;

    UTsize c       = 0;
    UTsize counter = (UTsize)bc64.size() + 1;

    while (counter)
    {
        for (len = 0, i = 0; i < 4 && counter; i++)
        {
            v = 0;
            while (counter && v == 0)
            {
                v = (unsigned char)bc64[c++];
                counter--;
                v = (unsigned char)((v < 43 || v > 122) ? 0 : cd64[v - 43]);
                if (v)
                {
                    v = (unsigned char)((v == '$') ? 0 : v - 61);
                }
            }
            if (counter)
            {
                len++;
                if (v)
                {
                    in[i] = (unsigned char)(v - 1);
                }
            }
            else
            {
                in[i] = 0;
            }
        }
        if (len)
        {
            decodeblock(in, out);
            for (i = 0; i < len - 1; i++)
            {
                bc.push_back(out[i]);
            }
        }
    }

    return bc;
}

utString ByteCode::bytesToBase64(const utArray<unsigned char>& bc)
{
    unsigned char in[3], out[4];
    int           i, len;

    UTsize        counter = bc.size();
    int           c = 0;
    utArray<char> buffer;

    while (counter)
    {
        len = 0;
        for (i = 0; i < 3; i++)
        {
            if (counter)
            {
                in[i] = (unsigned char)bc[c++];
                len++;
                counter--;
            }
            else
            {
                in[i] = 0;
            }
        }
        if (len)
        {
            encodeblock(in, out, len);
            for (i = 0; i < 4; i++)
            {
                assert(out[i]);
                buffer.push_back(out[i]);
            }
        }
    }

    buffer.push_back('\0');

    return utString(buffer.ptr());
}

ByteCode *ByteCode::decode64(const utString& bc64)
{

    ByteCode *byteCode = lmNew(NULL) ByteCode();

    byteCode->setBase64(bc64);

    return byteCode;
}

ByteCode *ByteCode::encode64(const utArray<unsigned char>& bc)
{
    ByteCode *byteCode = lmNew(NULL) ByteCode();

    byteCode->setByteCode(bc);

    /*
     * ByteCode* check = decode64(byteCode->bc64);
     *
     * printf("%i %i\n", check->bc.size(), bc.size());
     *
     * assert(check->bc.size() == bc.size());
     * for (UTsize i = 0; i < bc.size(); i++) {
     * assert(check->bc[i] == bc[i]);
     * }
     */

    return byteCode;
}


typedef struct LoadS
{
    const char *s;
    size_t     size;
} LoadS;


static const char *getS(lua_State *L, void *ud, size_t *size)
{
    LoadS *ls = (LoadS *)ud;

    (void)L;
    if (ls->size == 0)
    {
        return NULL;
    }
    *size    = ls->size;
    ls->size = 0;
    return ls->s;
}


static int bytecode_loadbuffer(lua_State *L, const char *buff, size_t size,
                               const char *name)
{
    LoadS ls;

    ls.s    = buff;
    ls.size = size;
    return lua_load(L, getS, &ls, name);
}


bool ByteCode::load(LSLuaState *ls, bool execute)
{
    utArray<unsigned char> *byteCode;
#if LJ_FR2
    byteCode = &bc_fr2;
#else
    byteCode = &bc;
#endif

    if (!byteCode->size())
    {
        return false;
    }

    lua_State *L = ls->VM();

    int status = bytecode_loadbuffer(L, (const char*)byteCode->ptr(), byteCode->size(), LUA_SIGNATURE);

    if (execute && status == 0)
    {
        lua_call(L, 0, LUA_MULTRET);
    }

    if (status != 0)
    {
        this->error = lua_tostring(L,-1);
        return false;
    }

    return true;
}
}
#endif
