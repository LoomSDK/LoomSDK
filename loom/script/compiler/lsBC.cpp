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

#include "loom/script/compiler/lsBC.h"

extern "C" {
#include "lstring.h"
#include "ldo.h"
#include "lfunc.h"
#include "ltable.h"
}

namespace LS {
utString  BC::currentFilename;
int       BC::lineNumber = 0;
lua_State *BC::L         = NULL;

void BC::openFunction(CodeState *cs, FuncState *fs)
{
    lua_State *L = cs->L;
    Proto     *f = luaF_newproto(L);

    fs->f           = f;
    fs->prev        = cs->fs; /* linked list of funcstates */
    fs->cs          = cs;
    fs->L           = L;
    cs->fs          = fs;
    fs->pc          = 0;
    fs->lasttarget  = -1;
    fs->jpc         = NO_JUMP;
    fs->freereg     = 0;
    fs->nk          = 0;
    fs->np          = 0;
    fs->nlocvars    = 0;
    fs->nactvar     = 0;
    fs->bl          = NULL;
    f->source       = cs->source;
    f->maxstacksize = 2; /* registers 0/1 are always valid */
    fs->h           = luaH_new(L, 0, 0);
    /* anchor table of constants and prototype (to avoid being collected) */ sethvalue2s(L, L->top, fs->h);
    incr_top(
        L);
    setptvalue2s(L, L->top, f);
    incr_top(L);
}


void BC::closeFunction(CodeState *cs)
{
    lua_State *L  = cs->L;
    FuncState *fs = cs->fs;
    Proto     *f  = fs->f;

    removeVars(cs, 0);

    BC::ret(fs, 0, 0); /* final return */

    luaM_reallocvector(L, f->code, f->sizecode, fs->pc, Instruction);
    f->sizecode = fs->pc;
    luaM_reallocvector(L, f->lineinfo, f->sizelineinfo, fs->pc, int);
    f->sizelineinfo = fs->pc;
    luaM_reallocvector(L, f->k, f->sizek, fs->nk, TValue);
    f->sizek = fs->nk;
    luaM_reallocvector(L, f->p, f->sizep, fs->np, Proto *);
    f->sizep = fs->np;
    luaM_reallocvector(L, f->locvars, f->sizelocvars, fs->nlocvars, LocVar);
    f->sizelocvars = fs->nlocvars;
    luaM_reallocvector(L, f->upvalues, f->sizeupvalues, f->nups, TString *);
    f->sizeupvalues = f->nups;
    lua_assert(luaG_checkcode(f));
    lua_assert(fs->bl == NULL);
    cs->fs  = fs->prev;
    L->top -= 2; /* remove table and prototype from the stack */

#if 0
    /* last token read was anchored in defunct function; must reanchor it */
    if (fs)
    {
        anchor_token(cs);
    }
#endif
}
}
#endif //LOOM_ENABLE_JIT
