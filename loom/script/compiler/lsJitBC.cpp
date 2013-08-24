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

#include "loom/script/compiler/lsJitBC.h"

namespace LS {
utString  BC::currentFilename;
int       BC::lineNumber = 0;
lua_State *BC::L         = NULL;

/* Initialize a new FuncState. */
void BC::openFunction(CodeState *cs, FuncState *fs)
{
    lua_State *L = cs->L;

    fs->linedefined = cs->lineNumber;
    fs->prev        = cs->fs;
    cs->fs          = fs; /* Append to list. */
    fs->cs          = cs;
    fs->vbase       = cs->vtop;
    fs->L           = L;
    fs->pc          = 0;
    fs->lasttarget  = 0;
    fs->jpc         = NO_JMP;
    fs->freereg     = 0;
    fs->nkgc        = 0;
    fs->nkn         = 0;
    fs->nactvar     = 0;
    fs->nuv         = 0;
    fs->bl          = NULL;
    fs->flags       = 0;
    fs->framesize   = 1; /* Minimum frame size. */
    fs->kt          = lj_tab_new(L, 0, 0);
    /* Anchor table of constants in stack to avoid being collected. */
    settabV(L, L->top, fs->kt);
    incr_top(L);
}


/* Fixup return instruction for prototype. */
void BC::fixupFunctionRet(FuncState *fs)
{
    BCPos lastpc = fs->pc;

    if ((lastpc <= fs->lasttarget) ||
        !bcOpIsRet(bc_op(fs->bcbase[lastpc - 1].ins)))
    {
        if (fs->flags & PROTO_CHILD)
        {
            bcemit_AJ(fs, BC_UCLO, 0, 0);
        }
        bcemit_AD(fs, BC_RET0, 0, 1);
        /* Need final return. */
    }
    /* May need to fixup returns encoded before first function was created. */
    if (fs->flags & PROTO_FIXUP_RETURN)
    {
        BCPos pc;
        for (pc = 0; pc < lastpc; pc++)
        {
            BCIns ins = fs->bcbase[pc].ins;
            BCPos offset;
            switch (bc_op(ins))
            {
            case BC_CALLMT:
            case BC_CALLT:
            case BC_RETM:
            case BC_RET:
            case BC_RET0:
            case BC_RET1:
                offset = emitINS(fs, ins) - (pc + 1) + BCBIAS_J; /* Copy return ins. */
                if (offset > BCMAX_D)
                {
                    lmAssert(0, "LJ_ERR_XFIXUP");
                }
                /* Replace with UCLO plus branch. */
                fs->bcbase[pc].ins = BCINS_AD(BC_UCLO, 0, offset);
                break;

            case BC_UCLO:
                return; /* We're done. */

            default:
                break;
            }
        }
    }
}


/* Resize buffer if needed. */
void BC::functionBufResize(CodeState *ls, MSize len)
{
    MSize sz = ls->sb.sz * 2;

    while (ls->sb.n + len > sz)
    {
        sz = sz * 2;
    }

    lj_str_resizebuf(ls->L, &ls->sb, sz);
}


void BC::functionBufNeed(CodeState *ls, MSize len)
{
    if (LJ_UNLIKELY(ls->sb.n + len > ls->sb.sz))
    {
        functionBufResize(ls, len);
    }
}


/* Add string to buffer. */
void BC::functionBufStr(CodeState *ls, const char *str, MSize len)
{
    char  *p = ls->sb.buf + ls->sb.n;
    MSize i;

    ls->sb.n += len;
    for (i = 0; i < len; i++)
    {
        p[i] = str[i];
    }
}


/* Add ULEB128 value to buffer. */
void BC::functionBufULEB128(CodeState *ls, uint32_t v)
{
    MSize   n  = ls->sb.n;
    uint8_t *p = (uint8_t *)ls->sb.buf;

    for ( ; v >= 0x80; v >>= 7)
    {
        p[n++] = (uint8_t)((v & 0x7f) | 0x80);
    }
    p[n++]   = (uint8_t)v;
    ls->sb.n = n;
}


/* Prepare variable info for prototype. */
size_t BC::functionPrepVar(CodeState *ls, FuncState *fs, size_t *ofsvar)
{
    VarInfo *vstack = fs->cs->vstack;
    MSize   i, n;
    BCPos   lastpc;

    lj_str_resetbuf(&ls->sb);
    // Copy to temp. string buffer.
    // Store upvalue names.
    for (i = 0, n = fs->nuv; i < n; i++)
    {
        GCstr *s  = strref(vstack[fs->uvloc[i].vidx].name);
        MSize len = s->len + 1;
        functionBufNeed(ls, len);
        functionBufStr(ls, strdata(s), len);
    }
    *ofsvar = ls->sb.n;
    vstack += fs->vbase;
    lastpc  = 0;
    // Store local variable names and compressed ranges.
    for (i = 0, n = ls->vtop - fs->vbase; i < n; i++)
    {
        GCstr *s      = strref(vstack[i].name);
        BCPos startpc = vstack[i].startpc, endpc = vstack[i].endpc;
        if ((uintptr_t)s < VARNAME__MAX)
        {
            functionBufNeed(ls, 1 + 2 * 5);
            ls->sb.buf[ls->sb.n++] = (uint8_t)(uintptr_t)s;
        }
        else
        {
            MSize len = s->len + 1;
            functionBufNeed(ls, len + 2 * 5);
            functionBufStr(ls, strdata(s), len);
        }
        functionBufULEB128(ls, startpc - lastpc);
        functionBufULEB128(ls, endpc - startpc);
        lastpc = startpc;
    }
    functionBufNeed(ls, 1);
    ls->sb.buf[ls->sb.n++] = '\0'; // Terminator for varinfo.
    return ls->sb.n;
}


/* Prepare lineinfo for prototype. */
size_t BC::functionPrepLine(FuncState *fs, BCLine numline)
{
    return (fs->pc - 1) << (numline < 256 ? 0 : numline < 65536 ? 1 : 2);
}


/* -- Function state management ------------------------------------------- */

/* Fixup bytecode for prototype. */
void BC::functionFixupBC(FuncState *fs, GCproto *pt, BCIns *bc, MSize n)
{
    BCInsLine *base = fs->bcbase;
    MSize     i;

    pt->sizebc = n;
    bc[0]      = BCINS_AD((fs->flags & PROTO_VARARG) ? BC_FUNCV : BC_FUNCF,
                          fs->framesize, 0);
    for (i = 1; i < n; i++)
    {
        bc[i] = base[i].ins;
    }
}


/* Fixup constants for prototype. */
void BC::functionFixupK(FuncState *fs, GCproto *pt, void *kptr)
{
    GCtab  *kt;
    TValue *array;
    Node   *node;
    MSize  i, hmask;

    checklimitgt(fs, fs->nkn, BCMAX_D + 1, "constants");
    checklimitgt(fs, fs->nkgc, BCMAX_D + 1, "constants");
    setmref(pt->k, kptr);
    pt->sizekn  = fs->nkn;
    pt->sizekgc = fs->nkgc;
    kt          = fs->kt;
    array       = tvref(kt->array);
    for (i = 0; i < kt->asize; i++)
    {
        if (tvhaskslot(&array[i]))
        {
            TValue *tv = &((TValue *)kptr)[tvkslot(&array[i])];
            if (LJ_DUALNUM)
            {
                setintV(tv, (int32_t)i);
            }
            else
            {
                setnumV(tv, (lua_Number)i);
            }
        }
    }
    node  = noderef(kt->node);
    hmask = kt->hmask;
    for (i = 0; i <= hmask; i++)
    {
        Node *n = &node[i];
        if (tvhaskslot(&n->val))
        {
            ptrdiff_t kidx = (ptrdiff_t)tvkslot(&n->val);
            lua_assert(!tvisint(&n->key));
            if (tvisnum(&n->key))
            {
                TValue *tv = &((TValue *)kptr)[kidx];
                if (LJ_DUALNUM)
                {
                    lua_Number nn = numV(&n->key);
                    int32_t    k  = lj_num2int(nn);
                    lua_assert(!tvismzero(&n->key));
                    if ((lua_Number)k == nn)
                    {
                        setintV(tv, k);
                    }
                    else
                    {
                        *tv = n->key;
                    }
                }
                else
                {
                    *tv = n->key;
                }
            }
            else
            {
                GCobj *o = gcV(&n->key);
                setgcref(((GCRef *)kptr)[~kidx], o);
                lj_gc_objbarrier(fs->L, pt, o);
            }
        }
    }
}


/* Fixup upvalues for prototype. */
void BC::functionFixupUV(FuncState *fs, GCproto *pt, uint16_t *uv)
{
    MSize i, n = fs->nuv;

    setmref(pt->uv, uv);
    pt->sizeuv = n;
    for (i = 0; i < n; i++)
    {
        uv[i] = fs->uvloc[i].slot;
    }
}


/* Fixup lineinfo for prototype. */
void BC::functionFixupLine(FuncState *fs, GCproto *pt, void *lineinfo,
                           BCLine numline)
{
    BCInsLine *base = fs->bcbase + 1;
    BCLine    first = fs->linedefined;
    MSize     i     = 0, n = fs->pc - 1;

    pt->firstline = fs->linedefined;
    pt->numline   = numline;
    setmref(pt->lineinfo, lineinfo);
    if (LJ_LIKELY(numline < 256))
    {
        uint8_t *li = (uint8_t *)lineinfo;
        do
        {
            BCLine delta = base[i].line - first;
            lua_assert(delta >= 0 && delta < 256);
            li[i] = (uint8_t)delta;
        } while (++i < n);
    }
    else if (LJ_LIKELY(numline < 65536))
    {
        uint16_t *li = (uint16_t *)lineinfo;
        do
        {
            BCLine delta = base[i].line - first;
            lua_assert(delta >= 0 && delta < 65536);
            li[i] = (uint16_t)delta;
        } while (++i < n);
    }
    else
    {
        uint32_t *li = (uint32_t *)lineinfo;
        do
        {
            BCLine delta = base[i].line - first;
            lua_assert(delta >= 0);
            li[i] = (uint32_t)delta;
        } while (++i < n);
    }
}


/* Fixup variable info for prototype. */
void BC::functionFixupVar(CodeState *ls, GCproto *pt, uint8_t *p,
                          size_t ofsvar)
{
    setmref(pt->uvinfo, p);
    setmref(pt->varinfo, (char *)p + ofsvar);

    memcpy(p, ls->sb.buf, ls->sb.n);  /* Copy from temp. string buffer. */
}


/* Finish a FuncState and return the new prototype. */
GCproto *BC::closeFunction(CodeState *ls, BCLine line)
{
    lua_State *L      = ls->L;
    FuncState *fs     = ls->fs;
    BCLine    numline = line - fs->linedefined;
    size_t    sizept, ofsk, ofsuv, ofsli, ofsdbg, ofsvar;
    GCproto   *pt;

    /* Apply final fixups. */
    lua_assert(fs->bl == NULL);
    fixupFunctionRet(fs);
    varRemove(ls, 0);

    /* Calculate total size of prototype including all colocated arrays. */
    sizept = sizeof(GCproto) + fs->pc * sizeof(BCIns)
             + fs->nkgc * sizeof(GCRef);
    sizept  = (sizept + sizeof(TValue) - 1) & ~(sizeof(TValue) - 1);
    ofsk    = sizept;
    sizept += fs->nkn * sizeof(TValue);
    ofsuv   = sizept;
    sizept += ((fs->nuv + 1) & ~1) * 2;
    ofsli   = sizept;
    sizept += functionPrepLine(fs, numline);
    ofsdbg  = sizept;
    sizept += functionPrepVar(ls, fs, &ofsvar);

    /* Allocate prototype and initialize its fields. */
    pt            = (GCproto *)lj_mem_newgco(L, (MSize)sizept);
    pt->gct       = ~LJ_TPROTO;
    pt->sizept    = (MSize)sizept;
    pt->trace     = 0;
    pt->flags     = (uint8_t)(fs->flags & ~(PROTO_HAS_RETURN | PROTO_FIXUP_RETURN));
    pt->numparams = fs->numparams;
    pt->framesize = fs->framesize;
    setgcref(pt->chunkname, obj2gco(ls->chunkname));

    /* Close potentially uninitialized gap between bc and kgc. */
    *(uint32_t *)((char *)pt + ofsk - sizeof(GCRef) * (fs->nkgc + 1)) = 0;
    functionFixupBC(fs, pt, (BCIns *)((char *)pt + sizeof(GCproto)), fs->pc);
    functionFixupK(fs, pt, (void *)((char *)pt + ofsk));
    functionFixupUV(fs, pt, (uint16_t *)((char *)pt + ofsuv));
    functionFixupLine(fs, pt, (void *)((char *)pt + ofsli), numline);
    functionFixupVar(ls, pt, (uint8_t *)((char *)pt + ofsdbg), ofsvar);

    lj_vmevent_send(L, BC, setprotoV(L, L->top++, pt);
                    );

    L->top--;             /* Pop table of constants. */
    ls->vtop = fs->vbase; /* Reset variable stack. */
    ls->fs   = fs->prev;
    lua_assert(ls->fs != NULL || ls->token == TK_eof);

    ls->proto = pt;

    return pt;
}


/* Check if any of the instructions on the jump list produce no value. */
int BC::jmpNoValue(FuncState *fs, BCPos list)
{
    for ( ; list != NO_JMP; list = jmpNext(fs, list))
    {
        BCIns p = fs->bcbase[list >= 1 ? list - 1 : list].ins;
        if (!((bc_op(p) == BC_ISTC) || (bc_op(p) == BC_ISFC) || (bc_a(p) == NO_REG)))
        {
            return 1;
        }
    }
    return 0;
}


/* Get next element in jump list. */
BCPos BC::jmpNext(FuncState *fs, BCPos pc)
{
    ptrdiff_t delta = bc_j(fs->bcbase[pc].ins);

    if ((BCPos)delta == NO_JMP)
    {
        return NO_JMP;
    }
    else
    {
        return (BCPos)(((ptrdiff_t)pc + 1) + delta);
    }
}


/* Patch register of test instructions. */
int BC::jmpPatchTestReg(FuncState *fs, BCPos pc, BCReg reg)
{
    BCInsLine *ilp = &fs->bcbase[pc >= 1 ? pc - 1 : pc];
    BCOp      op   = bc_op(ilp->ins);

    if ((op == BC_ISTC) || (op == BC_ISFC))
    {
        if ((reg != NO_REG) && (reg != bc_d(ilp->ins)))
        {
            setbc_a(&ilp->ins, reg);
        }
        else    /* Nothing to store or already in the right register. */
        {
            setbc_op(&ilp->ins, op + (BC_IST - BC_ISTC));
            setbc_a(&ilp->ins, 0);
        }
    }
    else if (bc_a(ilp->ins) == NO_REG)
    {
        if (reg == NO_REG)
        {
            ilp->ins = BCINS_AJ(BC_JMP, bc_a(fs->bcbase[pc].ins), 0);
        }
        else
        {
            setbc_a(&ilp->ins, reg);
            if (reg >= bc_a(ilp[1].ins))
            {
                setbc_a(&ilp[1].ins, reg + 1);
            }
        }
    }
    else
    {
        return 0; /* Cannot patch other instructions. */
    }
    return 1;
}


/* Append to jump list. */
void BC::jmpAppend(FuncState *fs, BCPos *l1, BCPos l2)
{
    if (l2 == NO_JMP)
    {
        return;
    }
    else if (*l1 == NO_JMP)
    {
        *l1 = l2;
    }
    else
    {
        BCPos list = *l1;
        BCPos next;
        while ((next = jmpNext(fs, list)) != NO_JMP) /* Find last element. */
        {
            list = next;
        }
        jmpPatchIns(fs, list, l2);
    }
}


/* Patch jump list to target. */
void BC::jmpPatch(FuncState *fs, BCPos list, BCPos target)
{
    if (target == fs->pc)
    {
        jmpToHere(fs, list);
    }
    else
    {
        lua_assert(target < fs->pc);
        jmpPatchVal(fs, list, target, NO_REG, target);
    }
}


/* Remove local variables. */
void BC::varRemove(CodeState *cs, BCReg tolevel)
{
    FuncState *fs = cs->fs;

    while (fs->nactvar > tolevel)
    {
        var_get(cs, fs, --fs->nactvar).endpc = fs->pc;
    }
}


/* Lookup or add upvalue index. */
MSize BC::varLookupUV(FuncState *fs, MSize vidx, ExpDesc *e)
{
    MSize i, n = fs->nuv;

    for (i = 0; i < n; i++)
    {
        if (fs->uvloc[i].vidx == vidx)
        {
            return i; /* Already exists. */
        }
    }
    /* Otherwise create a new one. */
    checklimit(fs, fs->nuv, LJ_MAX_UPVAL, "upvalues");
    lua_assert(e->k == VLOCAL || e->k == VUPVAL);
    fs->uvloc[n].vidx = (uint16_t)vidx;
    fs->uvloc[n].slot = (uint16_t)(e->u.s.info | (e->k == VLOCAL ? 0x8000 : 0));
    fs->nuv           = n + 1;
    return n;
}


/* Lookup local variable name. */
BCReg BC::varLookupLocal(FuncState *fs, GCstr *n)
{
    int i;

    for (i = fs->nactvar - 1; i >= 0; i--)
    {
        if (n == strref(var_get(fs->cs, fs, i).name))
        {
            return (BCReg)i;
        }
    }
    return (BCReg) - 1; /* Not found. */
}


/* Recursively lookup variables in enclosing functions. */
MSize BC::varLookup(FuncState *fs, GCstr *name, ExpDesc *e, int first)
{
    if (fs)
    {
        BCReg reg = varLookupLocal(fs, name);
        if ((int32_t)reg >= 0)    /* Local in this function? */
        {
            initExpDesc(e, VLOCAL, reg);
            if (!first)
            {
                scopeUVMark(fs, reg); /* Scope now has an upvalue. */
            }
            return (MSize)fs->varmap[reg];
        }
        else
        {
            MSize vidx = varLookup(fs->prev, name, e, 0); /* Var in outer func? */
            if ((int32_t)vidx >= 0)                       /* Yes, make it an upvalue here. */
            {
                e->u.s.info = (uint8_t)varLookupUV(fs, vidx, e);
                e->k        = VUPVAL;
                return vidx;
            }
        }
    }
    else     /* Not found in any function, must be a global. */
    {
        initExpDesc(e, VGLOBAL, 0);
        e->u.sval = name;
    }
    return (MSize) - 1; /* Global. */
}


/* Mark scope as having an upvalue. */
void BC::scopeUVMark(FuncState *fs, BCReg level)
{
    FuncScope *bl;

    for (bl = fs->bl; bl && bl->nactvar > level; bl = bl->prev)
    {
    }
    if (bl)
    {
        bl->upval = 1;
    }
}


/* Patch jump instruction to target. */
void BC::jmpPatchIns(FuncState *fs, BCPos pc, BCPos dest)
{
    BCIns *jmp   = &fs->bcbase[pc].ins;
    BCPos offset = dest - (pc + 1) + BCBIAS_J;

    lua_assert(dest != NO_JMP);
    if (offset > BCMAX_D)
    {
        lmAssert(0, "LJ_ERR_XJUMP");
    }
    setbc_d(jmp, offset);
}


/* Patch jump list and preserve produced values. */
void BC::jmpPatchVal(FuncState *fs, BCPos list, BCPos vtarget, BCReg reg,
                     BCPos dtarget)
{
    while (list != NO_JMP)
    {
        BCPos next = jmpNext(fs, list);
        if (jmpPatchTestReg(fs, list, reg))
        {
            jmpPatchIns(fs, list, vtarget); /* Jump to target with value. */
        }
        else
        {
            jmpPatchIns(fs, list, dtarget); /* Jump to default target. */
        }
        list = next;
    }
}


/* Emit store for LHS expression. */
void BC::emitStore(FuncState *fs, ExpDesc *var, ExpDesc *e)
{
    BCIns ins;

    if (var->k == VLOCAL)
    {
        expFree(fs, e);
        expToReg(fs, e, var->u.s.info);
        return;
    }
    else if (var->k == VUPVAL)
    {
        expToVal(fs, e);
        if (e->k <= VKTRUE)
        {
            ins = BCINS_AD(BC_USETP, var->u.s.info, const_pri(e));
        }
        else if (e->k == VKSTR)
        {
            ins = BCINS_AD(BC_USETS, var->u.s.info, constString(fs, e));
        }
        else if (e->k == VKNUM)
        {
            ins = BCINS_AD(BC_USETN, var->u.s.info, constNum(fs, e));
        }
        else
        {
            ins = BCINS_AD(BC_USETV, var->u.s.info, expToAnyReg(fs, e));
        }
    }
    else if (var->k == VGLOBAL)
    {
        BCReg ra = expToAnyReg(fs, e);
        ins = BCINS_AD(BC_GSET, ra, constString(fs, var));
    }
    else
    {
        BCReg ra, rc;
        lua_assert(var->k == VINDEXED);
        ra = expToAnyReg(fs, e);
        rc = var->u.s.aux;
        if ((int32_t)rc < 0)
        {
            ins = BCINS_ABC(BC_TSETS, ra, var->u.s.info, ~rc);
        }
        else if (rc > BCMAX_C)
        {
            ins = BCINS_ABC(BC_TSETB, ra, var->u.s.info, rc - (BCMAX_C + 1));
        }
        else
        {
            /* Free late alloced key reg to avoid assert on free of value reg. */
            /* This can only happen when called from expr_table(). */
            lua_assert(
                e->k != VNONRELOC || ra < fs->nactvar || rc < ra || (bcreg_free(fs, rc), 1));
            ins = BCINS_ABC(BC_TSETV, ra, var->u.s.info, rc);
        }
    }
    emitINS(fs, ins);
    expFree(fs, e);
}


/* Emit unconditional branch. */
BCPos BC::emitJmp(FuncState *fs)
{
    BCPos jpc = fs->jpc;
    BCPos j   = fs->pc - 1;
    BCIns *ip = &fs->bcbase[j].ins;

    fs->jpc = NO_JMP;
    if (((int32_t)j >= (int32_t)fs->lasttarget) && (bc_op(*ip) == BC_UCLO))
    {
        setbc_j(ip, NO_JMP);
    }
    else
    {
        j = bcemit_AJ(fs, BC_JMP, fs->freereg, NO_JMP);
    }
    jmpAppend(fs, &j, jpc);
    return j;
}


/* Emit bytecode to set a range of registers to nil. */
void BC::emitNil(FuncState *fs, BCReg from, BCReg n)
{
    if (fs->pc > fs->lasttarget)   /* No jumps to current position? */
    {
        BCIns *ip = &fs->bcbase[fs->pc - 1].ins;
        BCReg pto, pfrom = bc_a(*ip);
        switch (bc_op(*ip))   /* Try to merge with the previous instruction. */
        {
        case BC_KPRI:
            if (bc_d(*ip) != ~LJ_TNIL)
            {
                break;
            }
            if (from == pfrom)
            {
                if (n == 1)
                {
                    return;
                }
            }
            else if (from == pfrom + 1)
            {
                from = pfrom;
                n++;
            }
            else
            {
                break;
            }
            fs->pc--; /* Drop KPRI. */
            break;

        case BC_KNIL:
            pto = bc_d(*ip);
            if ((pfrom <= from) && (from <= pto + 1))   /* Can we connect both ranges? */
            {
                if (from + n - 1 > pto)
                {
                    setbc_d(ip, from + n - 1);
                }
                /* Patch previous instruction range. */
                return;
            }
            break;

        default:
            break;
        }
    }
    /* Emit new instruction or replace old instruction. */
    emitINS(fs,
            n == 1 ?
            BCINS_AD(BC_KPRI, from, VKNIL) :
            BCINS_AD(BC_KNIL, from, from + n - 1));
}


/* Emit bytecode instruction. */
BCPos BC::emitINS(FuncState *fs, BCIns ins)
{
    BCPos     pc  = fs->pc;
    CodeState *cs = fs->cs;

    jmpPatchVal(fs, fs->jpc, pc, NO_REG, pc);
    fs->jpc = NO_JMP;
    if (LJ_UNLIKELY(pc >= fs->bclim))
    {
        ptrdiff_t base = fs->bcbase - cs->bcstack;
        checklimit(fs, cs->sizebcstack, LJ_MAX_BCINS, "bytecode instructions");
        lj_mem_growvec(fs->L, cs->bcstack, cs->sizebcstack, LJ_MAX_BCINS,
                       BCInsLine);
        fs->bclim  = (BCPos)(cs->sizebcstack - base);
        fs->bcbase = cs->bcstack + base;
    }
    fs->bcbase[pc].ins  = ins;
    fs->bcbase[pc].line = cs->lineNumber;
    fs->pc = pc + 1;
    return pc;
}


/* Discharge non-constant expression to any register. */
void BC::expDischarge(FuncState *fs, ExpDesc *e)
{
    BCIns ins;

    if (e->k == VUPVAL)
    {
        ins = BCINS_AD(BC_UGET, 0, e->u.s.info);
    }
    else if (e->k == VGLOBAL)
    {
        ins = BCINS_AD(BC_GGET, 0, constString(fs, e));
    }
    else if (e->k == VINDEXED)
    {
        BCReg rc = e->u.s.aux;
        if ((int32_t)rc < 0)
        {
            ins = BCINS_ABC(BC_TGETS, 0, e->u.s.info, ~rc);
        }
        else if (rc > BCMAX_C)
        {
            ins = BCINS_ABC(BC_TGETB, 0, e->u.s.info, rc - (BCMAX_C + 1));
        }
        else
        {
            regFree(fs, rc);
            ins = BCINS_ABC(BC_TGETV, 0, e->u.s.info, rc);
        }
        regFree(fs, e->u.s.info);
    }
    else if (e->k == VCALL)
    {
        e->u.s.info = e->u.s.aux;
        e->k        = VNONRELOC;
        return;
    }
    else if (e->k == VLOCAL)
    {
        e->k = VNONRELOC;
        return;
    }
    else
    {
        return;
    }
    e->u.s.info = emitINS(fs, ins);
    e->k        = VRELOCABLE;
}


/* Discharge an expression to a specific register. Ignore branches. */
void BC::expToRegNoBranch(FuncState *fs, ExpDesc *e, BCReg reg)
{
    BCIns ins;

    expDischarge(fs, e);
    if (e->k == VKSTR)
    {
        ins = BCINS_AD(BC_KSTR, reg, constString(fs, e));
    }
    else if (e->k == VKNUM)
    {
#if LJ_DUALNUM
        cTValue *tv = expr_numtv(e);
        if (tvisint(tv) && checki16(intV(tv)))
        {
            ins = BCINS_AD(BC_KSHORT, reg, (BCReg)(uint16_t)intV(tv));
        }
        else
#else
        lua_Number n = expr_numberV(e);
        int32_t    k = lj_num2int(n);
        if (checki16(k) && (n == (lua_Number)k))
        {
            ins = BCINS_AD(BC_KSHORT, reg, (BCReg)(uint16_t)k);
        }
        else
#endif
        {
            ins = BCINS_AD(BC_KNUM, reg, constNum(fs, e));
        }
#if LJ_HASFFI
    }
    else if (e->k == VKCDATA)
    {
        fs->flags |= PROTO_FFI;
        ins        = BCINS_AD(BC_KCDATA, reg,
                              constGC(fs, obj2gco(cdataV(&e->u.nval)), LJ_TCDATA));
#endif
    }
    else if (e->k == VRELOCABLE)
    {
        setbc_a(bcptr(fs, e), reg);
        goto noins;
    }
    else if (e->k == VNONRELOC)
    {
        if (reg == e->u.s.info)
        {
            goto noins;
        }
        ins = BCINS_AD(BC_MOV, reg, e->u.s.info);
    }
    else if (e->k == VKNIL)
    {
        emitNil(fs, reg, 1);
        goto noins;
    }
    else if (e->k <= VKTRUE)
    {
        ins = BCINS_AD(BC_KPRI, reg, const_pri(e));
    }
    else
    {
        lua_assert(e->k == VVOID || e->k == VJMP);
        return;
    }
    emitINS(fs, ins);
noins: e->u.s.info = reg;
    e->k           = VNONRELOC;
}


/* Discharge an expression to a specific register. */
void BC::expToReg(FuncState *fs, ExpDesc *e, BCReg reg)
{
    expToRegNoBranch(fs, e, reg);
    if (e->k == VJMP)
    {
        jmpAppend(fs, &e->t, e->u.s.info); /* Add it to the true jump list. */
    }
    if (expr_hasjump(e))                   /* Discharge expression with branches. */
    {
        BCPos jend, jfalse = NO_JMP, jtrue = NO_JMP;
        if (jmpNoValue(fs, e->t) || jmpNoValue(fs, e->f))
        {
            BCPos jval = (e->k == VJMP) ? NO_JMP : emitJmp(fs);
            jfalse = bcemit_AD(fs, BC_KPRI, reg, VKFALSE);
            bcemit_AJ(fs, BC_JMP, fs->freereg, 1);
            jtrue = bcemit_AD(fs, BC_KPRI, reg, VKTRUE);
            jmpToHere(fs, jval);
        }
        jend           = fs->pc;
        fs->lasttarget = jend;
        jmpPatchVal(fs, e->f, jend, reg, jfalse);
        jmpPatchVal(fs, e->t, jend, reg, jtrue);
    }
    e->f        = e->t = NO_JMP;
    e->u.s.info = reg;
    e->k        = VNONRELOC;
}


/* Discharge an expression to any register. */
BCReg BC::expToAnyReg(FuncState *fs, ExpDesc *e)
{
    expDischarge(fs, e);
    if (e->k == VNONRELOC)
    {
        if (!expr_hasjump(e))
        {
            return e->u.s.info; /* Already in a register. */
        }
        if (e->u.s.info >= fs->nactvar)
        {
            expToReg(fs, e, e->u.s.info); /* Discharge to temp. register. */
            return e->u.s.info;
        }
    }
    expToNextReg(fs, e); /* Discharge to next register. */
    return e->u.s.info;
}


/* Discharge an expression to the next free register. */
void BC::expToNextReg(FuncState *fs, ExpDesc *e)
{
    expDischarge(fs, e);
    expFree(fs, e);
    regReserve(fs, 1);
    expToReg(fs, e, fs->freereg - 1);
}


/* Partially discharge expression to a value. */
void BC::expToVal(FuncState *fs, ExpDesc *e)
{
    if (expr_hasjump(e))
    {
        expToAnyReg(fs, e);
    }
    else
    {
        expDischarge(fs, e);
    }
}


/* Return index expression. */
void BC::indexed(FuncState *fs, ExpDesc *t, ExpDesc *e)
{
    /* Already called: expToVal(fs, e). */
    t->k = VINDEXED;
    if (expr_isnumk(e))
    {
#if LJ_DUALNUM
        if (tvisint(expr_numtv(e)))
        {
            int32_t k = intV(expr_numtv(e));
            if (checku8(k))
            {
                t->u.s.aux = BCMAX_C + 1 + (uint32_t)k; /* 256..511: const byte key */
                return;
            }
        }
#else
        lua_Number n = expr_numberV(e);
        int32_t    k = lj_num2int(n);
        if (checku8(k) && (n == (lua_Number)k))
        {
            t->u.s.aux = BCMAX_C + 1 + (uint32_t)k;  /* 256..511: const byte key */
            return;
        }
#endif
    }
    else if (expr_isstrk(e))
    {
        BCReg idx = constString(fs, e);
        if (idx <= BCMAX_C)
        {
            t->u.s.aux = ~idx; /* -256..-1: const string key */
            return;
        }
    }
    t->u.s.aux = expToAnyReg(fs, e); /* 0..255: register */
}


/* Define a new local variable. */
void BC::_newLocalVar(CodeState *ls, BCReg n, GCstr *name)
{
    FuncState *fs  = ls->fs;
    MSize     vtop = ls->vtop;

    checklimit(fs, fs->nactvar + n, LJ_MAX_LOCVAR, "local variables");
    if (LJ_UNLIKELY(vtop >= ls->sizevstack))
    {
        if (ls->sizevstack >= LJ_MAX_VSTACK)
        {
            lmAssert(0, "LJ_ERR_XLIMC LJ_MAX_VSTACK");
        }
        lj_mem_growvec(ls->L, ls->vstack, ls->sizevstack, LJ_MAX_VSTACK, VarInfo);
    }
    lua_assert((uintptr_t)name < VARNAME__MAX ||
               lj_tab_getstr(fs->kt, name) != NULL);
    /* NOBARRIER: name is anchored in fs->kt and ls->vstack is not a GCobj. */
    setgcref(ls->vstack[vtop].name, obj2gco(name));
    fs->varmap[fs->nactvar + n] = (uint16_t)vtop;
    ls->vtop = vtop + 1;
}


/* -- Bytecode emitter for operators -------------------------------------- */

/* Try constant-folding of arithmetic operators. */
int BC::foldArith(BinOpr opr, ExpDesc *e1, ExpDesc *e2)
{
    TValue     o;
    lua_Number n;

    if (!expr_isnumk_nojump(e1) || !expr_isnumk_nojump(e2))
    {
        return 0;
    }
    n = lj_vm_foldarith(expr_numberV(e1), expr_numberV(e2), (int)opr - OPR_ADD);
    setnumV(&o, n);
    if (tvisnan(&o) || tvismzero(&o))
    {
        return 0;                              /* Avoid NaN and -0 as consts. */
    }
    if (LJ_DUALNUM)
    {
        int32_t k = lj_num2int(n);
        if ((lua_Number)k == n)
        {
            setintV(&e1->u.nval, k);
            return 1;
        }
    }
    setnumV(&e1->u.nval, n);
    return 1;
}


/* Emit arithmetic operator. */
void BC::emitArith(FuncState *fs, BinOpr opr, ExpDesc *e1, ExpDesc *e2)
{
    BCReg    rb, rc, t;
    uint32_t op;

    if (BC::foldArith(opr, e1, e2))
    {
        return;
    }
    if (opr == OPR_POW)
    {
        op = BC_POW;
        rc = expToAnyReg(fs, e2);
        rb = expToAnyReg(fs, e1);
    }
    else
    {
        op = opr - OPR_ADD + BC_ADDVV;
        /* Must discharge 2nd operand first since VINDEXED might free regs. */
        expToVal(fs, e2);
        if (expr_isnumk(e2) && ((rc = constNum(fs, e2)) <= BCMAX_C))
        {
            op -= BC_ADDVV - BC_ADDVN;
        }
        else
        {
            rc = expToAnyReg(fs, e2);
        }
        /* 1st operand discharged by bcemit_binop_left, but need KNUM/KSHORT. */
        lua_assert(expr_isnumk(e1) || e1->k == VNONRELOC);
        expToVal(fs, e1);
        /* Avoid two consts to satisfy bytecode constraints. */
        if (expr_isnumk(e1) && !expr_isnumk(e2) &&
            ((t = constNum(fs, e1)) <= BCMAX_B))
        {
            rb  = rc;
            rc  = t;
            op -= BC_ADDVV - BC_ADDNV;
        }
        else
        {
            rb = expToAnyReg(fs, e1);
        }
    }
    /* Using expFree might cause asserts if the order is wrong. */
    if ((e1->k == VNONRELOC) && (e1->u.s.info >= fs->nactvar))
    {
        fs->freereg--;
    }
    if ((e2->k == VNONRELOC) && (e2->u.s.info >= fs->nactvar))
    {
        fs->freereg--;
    }
    e1->u.s.info = bcemit_ABC(fs, op, 0, rb, rc);
    e1->k        = VRELOCABLE;
}


/* Emit comparison operator. */
void BC::emitComp(FuncState *fs, BinOpr opr, ExpDesc *e1, ExpDesc *e2)
{
    ExpDesc *eret = e1;
    BCIns   ins;

    expToVal(fs, e1);
    if ((opr == OPR_EQ) || (opr == OPR_NE))
    {
        BCOp  op = opr == OPR_EQ ? BC_ISEQV : BC_ISNEV;
        BCReg ra;
        if (expr_isk(e1))
        {
            e1 = e2;
            e2 = eret;
        }                         /* Need constant in 2nd arg. */
        ra = expToAnyReg(fs, e1); /* First arg must be in a reg. */
        expToVal(fs, e2);
        switch (e2->k)
        {
        case VKNIL:
        case VKFALSE:
        case VKTRUE:
            ins = BCINS_AD(op + (BC_ISEQP - BC_ISEQV), ra, const_pri(e2));
            break;

        case VKSTR:
            ins = BCINS_AD(op + (BC_ISEQS - BC_ISEQV), ra, constString(fs, e2));
            break;

        case VKNUM:
            ins = BCINS_AD(op + (BC_ISEQN - BC_ISEQV), ra, constNum(fs, e2));
            break;

        default:
            ins = BCINS_AD(op, ra, expToAnyReg(fs, e2));
            break;
        }
    }
    else
    {
        uint32_t op = opr - OPR_LT + BC_ISLT;
        BCReg    ra, rd;
        if ((op - BC_ISLT) & 1) /* GT -> LT, GE -> LE */
        {
            e1 = e2;
            e2 = eret;     /* Swap operands. */
            op = ((op - BC_ISLT) ^ 3) + BC_ISLT;
        }
        rd  = expToAnyReg(fs, e2);
        ra  = expToAnyReg(fs, e1);
        ins = BCINS_AD(op, ra, rd);
    }
    /* Using expFree might cause asserts if the order is wrong. */
    if ((e1->k == VNONRELOC) && (e1->u.s.info >= fs->nactvar))
    {
        fs->freereg--;
    }
    if ((e2->k == VNONRELOC) && (e2->u.s.info >= fs->nactvar))
    {
        fs->freereg--;
    }
    emitINS(fs, ins);
    eret->u.s.info = emitJmp(fs);
    eret->k        = VJMP;
}


/* Fixup left side of binary operator. */
void BC::emitBinOpLeft(FuncState *fs, BinOpr op, ExpDesc *e)
{
    if (op == OPR_AND)
    {
        emitBranchTrue(fs, e);
    }
    else if (op == OPR_OR)
    {
        emitBranchFalse(fs, e);
    }
    else if (op == OPR_CONCAT)
    {
        expToNextReg(fs, e);
    }
    else if ((op == OPR_EQ) || (op == OPR_NE))
    {
        if (!expr_isk_nojump(e))
        {
            expToAnyReg(fs, e);
        }
    }
    else
    {
        if (!expr_isnumk_nojump(e))
        {
            expToAnyReg(fs, e);
        }
    }
}


/* Emit binary operator. */
void BC::emitBinOp(FuncState *fs, BinOpr op, ExpDesc *e1, ExpDesc *e2)
{
    if (op <= OPR_POW)
    {
        emitArith(fs, op, e1, e2);
    }
    else if (op == OPR_AND)
    {
        lua_assert(e1->t == NO_JMP); /* List must be closed. */
        expDischarge(fs, e2);
        jmpAppend(fs, &e2->f, e1->f);
        *e1 = *e2;
    }
    else if (op == OPR_OR)
    {
        lua_assert(e1->f == NO_JMP); /* List must be closed. */
        expDischarge(fs, e2);
        jmpAppend(fs, &e2->t, e1->t);
        *e1 = *e2;
    }
    else if (op == OPR_CONCAT)
    {
        expToVal(fs, e2);
        if ((e2->k == VRELOCABLE) && (bc_op(*bcptr(fs, e2)) == BC_CAT))
        {
            lua_assert(e1->u.s.info == bc_b(*bcptr(fs, e2)) - 1);
            expFree(fs, e1);
            setbc_b(bcptr(fs, e2), e1->u.s.info);
            e1->u.s.info = e2->u.s.info;
        }
        else
        {
            expToNextReg(fs, e2);
            expFree(fs, e2);
            expFree(fs, e1);
            e1->u.s.info = bcemit_ABC(fs, BC_CAT, 0, e1->u.s.info, e2->u.s.info);
        }
        e1->k = VRELOCABLE;
    }
    else
    {
        lua_assert(op == OPR_NE || op == OPR_EQ ||
                   op == OPR_LT || op == OPR_GE || op == OPR_LE || op == OPR_GT);
        emitComp(fs, op, e1, e2);
    }
}


/* Emit unary operator. */
void BC::emitUnOp(FuncState *fs, BCOp op, ExpDesc *e)
{
    if (op == BC_NOT)
    {
        /* Swap true and false lists. */
        {
            BCPos temp = e->f;
            e->f = e->t;
            e->t = temp;
        }
        jmpDropVal(fs, e->f);
        jmpDropVal(fs, e->t);
        expDischarge(fs, e);
        if ((e->k == VKNIL) || (e->k == VKFALSE))
        {
            e->k = VKTRUE;
            return;
        }
        else if (expr_isk(e) || (LJ_HASFFI && (e->k == VKCDATA)))
        {
            e->k = VKFALSE;
            return;
        }
        else if (e->k == VJMP)
        {
            invertCond(fs, e);
            return;
        }
        else if (e->k == VRELOCABLE)
        {
            regReserve(fs, 1);
            setbc_a(bcptr(fs, e), fs->freereg - 1);
            e->u.s.info = fs->freereg - 1;
            e->k        = VNONRELOC;
        }
        else
        {
            lua_assert(e->k == VNONRELOC);
        }
    }
    else
    {
        lua_assert(op == BC_UNM || op == BC_LEN);
        if ((op == BC_UNM) && !expr_hasjump(e)) /* Constant-fold negations. */
        {
#if LJ_HASFFI
            if (e->k == VKCDATA) /* Fold in-place since cdata is not interned. */
            {
                GCcdata *cd = cdataV(&e->u.nval);
                int64_t *p  = (int64_t *)cdataptr(cd);
                if (cd->ctypeid == CTID_COMPLEX_DOUBLE)
                {
                    p[1] ^= (int64_t)U64x(80000000, 00000000);
                }
                else
                {
                    *p = -*p;
                }
                return;
            }
            else
#endif
            if (expr_isnumk(e) && !expNumIsZero(e)) /* Avoid folding to -0. */
            {
                TValue *o = expr_numtv(e);
                if (tvisint(o))
                {
                    int32_t k = intV(o);
                    if (k == -k)
                    {
                        setnumV(o, -(lua_Number)k);
                    }
                    else
                    {
                        setintV(o, -k);
                    }
                    return;
                }
                else
                {
                    o->u64 ^= U64x(80000000, 00000000);
                    return;
                }
            }
        }
        expToAnyReg(fs, e);
    }
    expFree(fs, e);
    e->u.s.info = bcemit_AD(fs, op, 0, e->u.s.info);
    e->k        = VRELOCABLE;
}
}
#endif
