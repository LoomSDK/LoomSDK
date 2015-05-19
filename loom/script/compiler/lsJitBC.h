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

#ifndef _lsjitbc_h
#define _lsjitbc_h

#ifdef LOOM_ENABLE_JIT

extern "C" {
#include "lua.h"

#include "lj_obj.h"
#include "lj_gc.h"
#include "lj_err.h"
#include "lj_debug.h"
#include "lj_str.h"
#include "lj_tab.h"
#include "lj_func.h"
#include "lj_state.h"
#include "lj_bc.h"
#if LJ_HASFFI
#include "lj_ctype.h"
#endif
#include "lj_lex.h"
#include "lj_parse.h"
#include "lj_vm.h"
#include "lj_vmevent.h"

#include "lj_bc.h"
}

#include "loom/script/compiler/lsAST.h"

#include "loom/common/utils/utAssert.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

namespace LS {
/* Per-function linked list of scope blocks. */
typedef struct FuncScope
{
    struct FuncScope *prev;        /* Link to outer scope. */
    BCPos            breaklist;    /* Jump list for loop breaks. */
    BCPos            continuelist; /* Jump list for loop continues */
    uint8_t          nactvar;      /* Number of active vars outside the scope. */
    uint8_t          upval;        /* Some variable in the scope is an upvalue. */
    uint8_t          isbreakable;  /* Scope is a loop and allows a break. */
} FuncScope;

/* Index into variable stack. */
typedef uint16_t   VarIndex;
#define LJ_MAX_VSTACK    65536

/* Upvalue map. */
typedef struct UVMap
{
    VarIndex vidx; /* Varinfo index. */
    uint16_t slot; /* Slot or parent upvalue index. */
} UVMap;

/* Per-function state. */
typedef struct FuncState
{
    GCtab            *kt;                   /* Hash table for constants. */
    struct CodeState *cs;                   /* Lexer state. */
    lua_State        *L;                    /* Lua state. */
    FuncScope        *bl;                   /* Current scope. */
    struct FuncState *prev;                 /* Enclosing function. */
    BCPos            pc;                    /* Next bytecode position. */
    BCPos            lasttarget;            /* Bytecode position of last jump target. */
    BCPos            jpc;                   /* Pending jump list to next bytecode. */
    BCReg            freereg;               /* First free register. */
    BCReg            nactvar;               /* Number of active local variables. */
    BCReg            nkn, nkgc;             /* Number of lua_Number/GCobj constants */
    BCLine           linedefined;           /* First line of the function definition. */
    BCInsLine        *bcbase;               /* Base of bytecode stack. */
    BCPos            bclim;                 /* Limit of bytecode stack. */
    MSize            vbase;                 /* Base of variable stack for this function. */
    uint8_t          flags;                 /* Prototype flags. */
    uint8_t          numparams;             /* Number of parameters. */
    uint8_t          framesize;             /* Fixed frame size. */
    uint8_t          nuv;                   /* Number of upvalues */
    VarIndex         varmap[LJ_MAX_LOCVAR]; /* Map from register to variable idx. */
    UVMap            uvloc[LJ_MAX_UPVAL];   /* Map from upvalue to variable idx and slot. */
} FuncState;

typedef struct CodeState
{
    struct FuncState *fs;         /* Current FuncState. Defined in lj_parse.c. */
    struct lua_State *L;          /* Lua state. */
    GCstr            *chunkname;  /* Current chunk name (interned string). */
    const char       *chunkarg;   /* Chunk name argument. */
    VarInfo          *vstack;     /* Stack for names and extents of local variables. */
    MSize            sizevstack;  /* Size of variable stack. */
    MSize            vtop;        /* Top of variable stack. */
    BCInsLine        *bcstack;    /* Stack for bytecode instructions/line numbers. */
    MSize            sizebcstack; /* Size of bytecode stack. */
    uint32_t         level;       /* Syntactical nesting level. */
    int              lineNumber;
    GCproto          *proto;
    SBuf             sb; /* String buffer for tokens. */
} CodeState;

#define bcemit_ABC(fs, o, a, b, c)    BC::emitINS(fs, BCINS_ABC(o, a, b, c))
#define bcemit_AD(fs, o, a, d)        BC::emitINS(fs, BCINS_AD(o, a, d))
#define bcemit_AJ(fs, o, a, j)        BC::emitINS(fs, BCINS_AJ(o, a, j))

#define checklimit(fs, v, l, m)       lmAssert((v) < (l), m)
#define checklimitgt(fs, v, l, m)     lmAssert((v) <= (l), m)
#define checkcond(cs, c, em)         \
    { lmAssert(c, em); \
    }

#define var_get(cs, fs, i)            ((cs)->vstack[(fs)->varmap[(i)]])

/* Macros for expressions. */
#define expr_hasjump(e)               ((e)->t != (e)->f)

#define expr_isk(e)                   ((e)->k <= VKLAST)
#define expr_isk_nojump(e)            (expr_isk(e) && !expr_hasjump(e))
#define expr_isnumk(e)                ((e)->k == VKNUM)
#define expr_isnumk_nojump(e)         (expr_isnumk(e) && !expr_hasjump(e))
#define expr_isstrk(e)                ((e)->k == VKSTR)

#define expr_numtv(e)                 check_exp(expr_isnumk((e)), &(e)->u.nval)
#define expr_numberV(e)               numberVnum(expr_numtv((e)))

/* Return bytecode encoding for primitive constant. */
#define const_pri(e)                  check_exp((e)->k <= VKTRUE, (e)->k)

#define tvhaskslot(o)                 ((o)->u32.hi == 0)
#define tvkslot(o)                    ((o)->u32.lo)

#define bcptr(fs, e)                  (&(fs)->bcbase[(e)->u.s.info].ins)

/* Binary and unary operators. ORDER OPR */
typedef enum BinOpr
{
    OPR_ADD,
    OPR_SUB,
    OPR_MUL,
    OPR_DIV,
    OPR_MOD,
    OPR_POW, /* ORDER ARITH */
    OPR_CONCAT,
    OPR_NE,
    OPR_EQ,
    OPR_LT,
    OPR_GE,
    OPR_LE,
    OPR_GT,
    OPR_AND,
    OPR_OR,
    OPR_NOBINOPR
} BinOpr;

typedef enum BitOpr
{
    OPR_LOOM_BITAND,
    OPR_LOOM_BITOR,
    OPR_LOOM_BITXOR,
    OPR_LOOM_BITLSHIFT,
    OPR_LOOM_BITRSHIFT,
    //OPR_LOOM_BITNOT, /* this is a unary operator, valid but we catch with ~ */
    OPR_NOBITOPR
} BitOpr;

class BC {
public:

    static lua_State *L;
    static utString  currentFilename;
    static int       lineNumber;

    static BCPos emitAD(FuncState *fs, BCIns ins);
    static BCPos emitINS(FuncState *fs, BCIns ins);
    static void emitNil(FuncState *fs, BCReg from, BCReg n);
    static BCPos emitJmp(FuncState *fs);
    static void emitStore(FuncState *fs, ExpDesc *var, ExpDesc *e);

    static void storeVar(FuncState *fs, ExpDesc *var, ExpDesc *ex)
    {
        emitStore(fs, var, ex);
    }

    /* Emit conditional branch. */
    static BCPos emitBranch(FuncState *fs, ExpDesc *e, int cond)
    {
        BCPos pc;

        if (e->k == VRELOCABLE)
        {
            BCIns *ip = bcptr(fs, e);
            if (bc_op(*ip) == BC_NOT)
            {
                *ip = BCINS_AD(cond ? BC_ISF : BC_IST, 0, bc_d(*ip));
                return emitJmp(fs);
            }
        }
        if (e->k != VNONRELOC)
        {
            regReserve(fs, 1);
            expToRegNoBranch(fs, e, fs->freereg - 1);
        }
        bcemit_AD(fs, cond ? BC_ISTC : BC_ISFC, NO_REG, e->u.s.info);
        pc = emitJmp(fs);
        expFree(fs, e);
        return pc;
    }

    /* Manage syntactic levels to avoid blowing up the stack. */
    static void enterLevel(CodeState *ls)
    {
        if (++ls->level >= LJ_MAX_XLEVEL)
        {
            lmAssert(0, "LJ_ERR_XLEVELS");
        }
    }

    /* Manage syntactic levels to avoid blowing up the stack. */
    static void leaveLevel(CodeState *ls)
    {
        ls->level--;
    }

    /* Emit branch on true condition. */
    static void emitBranchTrue(FuncState *fs, ExpDesc *e)
    {
        BCPos pc;

        expDischarge(fs, e);
        if (/*e->k == VKSTR || e->k == VKNUM ||*/ e->k == VKTRUE)
        {
            pc = NO_JMP; /* Never jump. */
        }
        else if (e->k == VJMP)
        {
            invertCond(fs, e), pc = e->u.s.info;
        }
        else if ((e->k == VKFALSE) || (e->k == VKNIL))
        {
            expToRegNoBranch(fs, e, NO_REG), pc = emitJmp(fs);
        }
        else
        {
            pc = emitBranch(fs, e, 0);
        }
        jmpAppend(fs, &e->f, pc);
        jmpToHere(fs, e->t);
        e->t = NO_JMP;
    }

    /* Emit branch on false condition. */
    static void emitBranchFalse(FuncState *fs, ExpDesc *e)
    {
        BCPos pc;

        expDischarge(fs, e);
        if ((e->k == VKNIL) || (e->k == VKFALSE))
        {
            pc = NO_JMP; /* Never jump. */
        }
        else if (e->k == VJMP)
        {
            pc = e->u.s.info;
        }
        else if ((e->k == VKSTR) || (e->k == VKNUM) || (e->k == VKTRUE))
        {
            expToRegNoBranch(fs, e, NO_REG), pc = emitJmp(fs);
        }
        else
        {
            pc = emitBranch(fs, e, 1);
        }
        jmpAppend(fs, &e->t, pc);
        jmpToHere(fs, e->f);
        e->f = NO_JMP;
    }

    /* Check if bytecode op returns. */
    static int bcOpIsRet(BCOp op)
    {
        switch (op)
        {
        case BC_CALLMT:
        case BC_CALLT:
        case BC_RETM:
        case BC_RET:
        case BC_RET0:
        case BC_RET1:
            return 1;

        default:
            return 0;
        }
    }

    static int foldArith(BinOpr opr, ExpDesc *e1, ExpDesc *e2);

    /* Emit arithmetic operator. */
    static void emitArith(FuncState *fs, BinOpr opr, ExpDesc *e1, ExpDesc *e2);

    /* Emit comparison operator. */
    static void emitComp(FuncState *fs, BinOpr opr, ExpDesc *e1, ExpDesc *e2);

    static void emitBinOpLeft(FuncState *fs, BinOpr op, ExpDesc *e);

    static void emitBinOp(FuncState *fs, BinOpr op, ExpDesc *e1, ExpDesc *e2);

    static int jmpNoValue(FuncState *fs, BCPos list);
    static void jmpAppend(FuncState *fs, BCPos *l1, BCPos l2);
    static BCPos jmpNext(FuncState *fs, BCPos pc);
    static int jmpPatchTestReg(FuncState *fs, BCPos pc, BCReg reg);
    static void jmpPatchIns(FuncState *fs, BCPos pc, BCPos dest);
    static void jmpPatchVal(FuncState *fs, BCPos list, BCPos vtarget, BCReg reg,
                            BCPos dtarget);
    static void jmpPatch(FuncState *fs, BCPos list, BCPos target);

    /* Jump to following instruction. Append to list of pending jumps. */
    static void jmpToHere(FuncState *fs, BCPos list)
    {
        fs->lasttarget = fs->pc;
        jmpAppend(fs, &fs->jpc, list);
    }

    /* Drop values for all instructions on jump list. */
    static void jmpDropVal(FuncState *fs, BCPos list)
    {
        for ( ; list != NO_JMP; list = jmpNext(fs, list))
        {
            jmpPatchTestReg(fs, list, NO_REG);
        }
    }

    static void scopeUVMark(FuncState *fs, BCReg level);

    static void openFunction(CodeState *cs, FuncState *fs);
    static GCproto *closeFunction(CodeState *ls, BCLine line);
    static void fixupFunctionRet(FuncState *fs);
    static size_t functionPrepLine(FuncState *fs, BCLine numline);
    static size_t functionPrepVar(CodeState *ls, FuncState *fs, size_t *ofsvar);
    static void functionFixupBC(FuncState *fs, GCproto *pt, BCIns *bc, MSize n);
    static void functionFixupK(FuncState *fs, GCproto *pt, void *kptr);
    static void functionFixupUV(FuncState *fs, GCproto *pt, uint16_t *uv);
    static void functionFixupLine(FuncState *fs, GCproto *pt, void *lineinfo,
                                  BCLine numline);
    static void functionFixupVar(CodeState *ls, GCproto *pt, uint8_t *p,
                                 size_t ofsvar);

    /* Resize buffer if needed. */
    static void functionBufResize(CodeState *ls, MSize len);
    static void functionBufNeed(CodeState *ls, MSize len);

    /* Add string to buffer. */
    static void functionBufStr(CodeState *ls, const char *str, MSize len);

    /* Add ULEB128 value to buffer. */
    static void functionBufULEB128(CodeState *ls, uint32_t v);

    static void initExpDesc(ExpDesc *e, ExpKind k, uint32_t info)
    {
        e->k        = k;
        e->u.s.info = info;
        e->f        = e->t = NO_JMP;
    }

    /* Add a GC object constant. */
    static BCReg constGC(FuncState *fs, GCobj *gc, uint32_t itype)
    {
        lua_State *L = fs->L;
        TValue    key, *o;

        setgcV(L, &key, gc, itype);
        /* NOBARRIER: the key is new or kept alive. */
        o = lj_tab_set(L, fs->kt, &key);
        if (tvhaskslot(o))
        {
            return tvkslot(o);
        }
        o->u64 = fs->nkgc;
        return fs->nkgc++;
    }

    /* Add a number constant. */
    static BCReg constNum(FuncState *fs, ExpDesc *e)
    {
        lua_State *L = fs->L;
        TValue    *o;

        lua_assert(expr_isnumk(e));
        o = lj_tab_set(L, fs->kt, &e->u.nval);
        if (tvhaskslot(o))
        {
            return tvkslot(o);
        }
        o->u64 = fs->nkn;
        return fs->nkn++;
    }

    /* Add a string constant. */
    static BCReg constString(FuncState *fs, ExpDesc *e)
    {
        lmAssert(expr_isstrk(e) || e->k == VGLOBAL, "BC::constString");
        return constGC(fs, obj2gco(e->u.sval), LJ_TSTR);
    }

    static void allocString(CodeState *cs, const char *str, GCstr **s)
    {
        lua_State *L = cs->L;

        *s = lj_str_new(L, str, strlen(str));
        TValue *tv = lj_tab_setstr(L, cs->fs->kt, *s);
        if (tvisnil(tv))
        {
            setboolV(tv, 1);
        }
        lj_gc_check(L);
    }

    static void expString(CodeState *cs, ExpDesc *e, const char *str)
    {
        GCstr  *s = NULL;
        TValue tv;

        allocString(cs, str, &s);

        /* NOBARRIER: the key is new or kept alive. */
        initExpDesc(e, VKSTR, 0);
        setstrV(cs->L, &tv, s);
        e->u.sval = strV(&tv);
    }

    static void singleVar(CodeState *cs, ExpDesc *var, const char *sname)
    {
        GCstr *varname = NULL;

        allocString(cs, sname, &varname);

        FuncState *fs = cs->fs;
        varLookup(fs, varname, var, 1);
    }

    static void _newLocalVar(CodeState *ls, BCReg n, GCstr *name);

    static void newLocalVar(CodeState *cs, const char *sname, int n)
    {
        GCstr *name;

        allocString(cs, sname, &name);
        _newLocalVar(cs, n, name);
    }

    /* Add local variables. */
    static void adjustLocalVars(CodeState *ls, BCReg nvars)
    {
        FuncState *fs     = ls->fs;
        BCReg     nactvar = fs->nactvar;

        for ( ; nvars; nvars--)
        {
            VarInfo *v = &var_get(ls, fs, nactvar);
            v->startpc = fs->pc;
            v->slot    = nactvar++;
            v->info    = 0;
        }
        fs->nactvar = nactvar;
    }

    static MSize varLookupUV(FuncState *fs, MSize vidx, ExpDesc *e);
    static BCReg varLookupLocal(FuncState *fs, GCstr *n);
    static MSize varLookup(FuncState *fs, GCstr *name, ExpDesc *e, int first);
    static void varRemove(CodeState *cs, BCReg tolevel);

    static void expDischarge(FuncState *fs, ExpDesc *e);
    static void expToNextReg(FuncState *fs, ExpDesc *e);
    static void expToRegNoBranch(FuncState *fs, ExpDesc *e, BCReg reg);
    static void expToReg(FuncState *fs, ExpDesc *e, BCReg reg);
    static void expToVal(FuncState *fs, ExpDesc *e);
    static BCReg expToAnyReg(FuncState *fs, ExpDesc *e);

    /* Check number constant for +-0. */
    static int expNumIsZero(ExpDesc *e)
    {
        TValue *o = expr_numtv(e);

        return tvisint(o) ? (intV(o) == 0) : tviszero(o);
    }

    /* Free register for expression. */
    static void expFree(FuncState *fs, ExpDesc *e)
    {
        if (e->k == VNONRELOC)
        {
            regFree(fs, e->u.s.info);
        }
    }

    static void indexed(FuncState *fs, ExpDesc *t, ExpDesc *e);

    /* Bump frame size. */
    static void regBump(FuncState *fs, BCReg n)
    {
        BCReg sz = fs->freereg + n;

        if (sz > fs->framesize)
        {
            if (sz >= LJ_MAX_SLOTS)
            {
                lmAssert(0, "LJ_ERR_XSLOTS");
            }
            fs->framesize = (uint8_t)sz;
        }
    }

    /* Adjust LHS/RHS of an assignment. */
    static void adjustAssign(CodeState *ls, BCReg nvars, BCReg nexps,
                             ExpDesc *e)
    {
        FuncState *fs   = ls->fs;
        int32_t   extra = (int32_t)nvars - (int32_t)nexps;

        if (e->k == VCALL)
        {
            extra++; /* Compensate for the VCALL itself. */
            if (extra < 0)
            {
                extra = 0;
            }
            setbc_b(bcptr(fs, e), extra + 1);
            /* Fixup call results. */
            if (extra > 1)
            {
                regReserve(fs, (BCReg)extra - 1);
            }
        }
        else
        {
            if (e->k != VVOID)
            {
                expToNextReg(fs, e); /* Close last expression. */
            }
            if (extra > 0)           /* Leftover LHS are set to nil. */
            {
                BCReg reg = fs->freereg;
                regReserve(fs, (BCReg)extra);
                emitNil(fs, reg, (BCReg)extra);
            }
        }
    }

    /* Reserve registers. */
    static void regReserve(FuncState *fs, BCReg n)
    {
        regBump(fs, n);
        fs->freereg += n;
    }

    /* Free register. */
    static void regFree(FuncState *fs, BCReg reg)
    {
        if (reg >= fs->nactvar)
        {
            fs->freereg--;
            lua_assert(reg == fs->freereg);
        }
    }

    /*
    ** returns current `pc' and marks it as a jump target (to avoid wrong
    ** optimizations with consecutive instructions not in the same basic block).
    */
    static int getLabel(FuncState *fs)
    {
        fs->lasttarget = fs->pc;
        return fs->pc;
    }

    /* Invert branch condition of bytecode instruction. */
    static void invertCond(FuncState *fs, ExpDesc *e)
    {
        BCIns *ip = &fs->bcbase[e->u.s.info - 1].ins;

        setbc_op(ip, bc_op(*ip) ^ 1);
    }

    /* conditional expression. */
    static BCPos cond(CodeState *ls, ExpDesc *v)
    {
        if (v->k == VKNIL)
        {
            v->k = VKFALSE;
        }
        emitBranchTrue(ls->fs, v);
        return v->f;
    }

    static void emitUnOp(FuncState *fs, BCOp op, ExpDesc *e);
};
}
#endif
#endif
