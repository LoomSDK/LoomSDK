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

#include <stdio.h>

#include "loom/script/common/lsError.h"

extern "C" {
#include "lua.h"

#include "ldebug.h"
#include "ldo.h"
#include "lfunc.h"
#include "lgc.h"
#include "lmem.h"
#include "lobject.h"
#include "lopcodes.h"
#include "lparser.h"
#include "lstate.h"
#include "lstring.h"
#include "ltable.h"
#include "ltm.h"
#include "lundump.h"
#include "lvm.h"
#include "lzio.h"
}

#include "loom/script/reflection/lsByteCode.h"
#include "loom/script/runtime/lsLuaState.h"


namespace LS {
ByteCode *ByteCode::decode64(const char *code64)
{
    ByteCode *byteCode = new ByteCode();

    byteCode->base64 = utBase64::decode64(code64);
    return byteCode;
}


ByteCode *ByteCode::encode64(const utArray<unsigned char>& bc)
{
    ByteCode *byteCode = new ByteCode();

    byteCode->base64 = utBase64::encode64(bc);
    return byteCode;
}


/*
** Execute a protected parser.
*/
struct SParser   /* data to `f_parser' */
{
    ZIO        *z;
    Mbuffer    buff; /* buffer to be used by the scanner */
    const char *name;
};

static void bytecode_parser(lua_State *L, void *ud)
{
    int            i;
    Proto          *tf;
    Closure        *cl;
    struct SParser *p = cast(struct SParser *, ud);
    int            c  = luaZ_lookahead(p->z);

    luaC_checkGC(L);

    if (c != LUA_SIGNATURE[0])
    {
        abort(); // ERROR!
    }
    tf = luaU_undump(L, p->z, &p->buff, p->name);

    cl      = luaF_newLclosure(L, tf->nups, hvalue(gt(L)));
    cl->l.p = tf;
    for (i = 0; i < tf->nups; i++) /* initialize eventual upvalues */
    {
        cl->l.upvals[i] = luaF_newupval(L);
    }
    setclvalue(L, L->top, cl);
    incr_top(L);
}


static int bytecode_protectedparser(lua_State *L, ZIO *z, const char *name)
{
    struct SParser p;
    int            status;

    p.z    = z;
    p.name = name;
    luaZ_initbuffer(L, &p.buff);
    status = luaD_pcall(L, bytecode_parser, &p, savestack(L, L->top),
                        L->errfunc);

    if (status != 0)
    {
        const char *error = lua_tostring(L, -1);
        LSError(error);
    }

    luaZ_freebuffer(L, &p.buff);
    return status;
}


static int bytecode_load(lua_State *L, lua_Reader reader, void *data,
                         const char *chunkname)
{
    ZIO z;
    int status;

    lua_lock(L);
    if (!chunkname)
    {
        chunkname = "?";
    }
    luaZ_init(L, &z, reader, data);
    status = bytecode_protectedparser(L, &z, chunkname);
    lua_unlock(L);
    return status;
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
    return bytecode_load(L, getS, &ls, name);
}


bool ByteCode::load(LSLuaState *ls, bool execute)
{
    const utArray<unsigned char>& bc = base64.getData();

    if (!bc.size())
    {
        return false;
    }

    lua_State *L = ls->VM();

    char *buffer = (char *)malloc(bc.size());

    for (UTsize i = 0; i < bc.size(); i++)
    {
        buffer[i] = (char)bc[i];
    }

    int status = bytecode_loadbuffer(L, buffer, bc.size(), LUA_SIGNATURE);

    if (status == 0)
    {
        if (execute)
        {
            lua_call(L, 0, LUA_MULTRET);
        }
    }

    free(buffer);

    if (status != 0)
    {
        return false;
    }

    return true;
}
}
#endif
