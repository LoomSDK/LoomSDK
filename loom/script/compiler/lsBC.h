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

#ifndef _lsbc_h
#define _lsbc_h

#ifndef LOOM_ENABLE_JIT

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

extern "C" {
// from luaconf.h (only defined for LUA_CORE

#include <math.h>
#define luai_numadd(a, b)    ((a) + (b))
#define luai_numsub(a, b)    ((a) - (b))
#define luai_nummul(a, b)    ((a) * (b))
#define luai_numdiv(a, b)    ((a) / (b))
#define luai_nummod(a, b)    ((a) - floor((a) / (b)) * (b))
#define luai_numpow(a, b)    (pow(a, b))
#define luai_numunm(a)       (-(a))
#define luai_numeq(a, b)     ((a) == (b))
#define luai_numlt(a, b)     ((a) < (b))
#define luai_numle(a, b)     ((a) <= (b))
#define luai_numisnan(a)     (!luai_numeq((a), (a)))

#include "lua.h"
#include "lstate.h"
#include "lcode.h"
#include "ldebug.h"
#include "ldo.h"
#include "lgc.h"
#include "lmem.h"
#include "lobject.h"
#include "lopcodes.h"
#include "ltable.h"
#include "lstring.h"
#include "lfunc.h"
}

#include "loom/script/compiler/lsAST.h"

namespace LS {
/*
** Marks the end of a patch list. It is an invalid value both as an absolute
** address, and as a list link (would link an element to itself).
*/

#define NO_JUMP    (-1)

#define hasjumps(e)                     ((e)->t != (e)->f)

#define getLocVar(fs, i)                ((fs)->f->locvars[(fs)->actvar[i]])

#define hasmultret(k)                   ((k) == VCALL || (k) == VVARARG)

#define luaY_checklimit(fs, v, l, m)    if ((v) > (l)) errorLimit(fs, l, m)

#define getCode(fs, e)                  ((fs)->f->code[(e)->u.s.info])

#define codeAsBx(fs, o, A, sBx)         codeABx(fs, o, A, (sBx) + MAXARG_sBx)

//#define setMultRet(fs,e)    setReturns(fs, e, LUA_MULTRET)

/*
** grep "ORDER OPR" if you change these enums
*/
enum BinOpr
{
    OPR_ADD,
    OPR_LOOM_ADD,
    OPR_SUB,
    OPR_MUL,
    OPR_DIV,
    OPR_MOD,
    OPR_POW,
    OPR_CONCAT,
    OPR_NE,
    OPR_EQ,
    OPR_LT,
    OPR_LE,
    OPR_GT,
    OPR_GE,
    OPR_AND,
    OPR_OR,
    OPR_LOOM_BITLSHIFT,
    OPR_LOOM_BITRSHIFT,
    OPR_LOOM_BITOR,
    OPR_LOOM_BITAND,
    OPR_LOOM_BITXOR,
    OPR_NOBINOPR
};

enum UnOpr
{
    OPR_MINUS, OPR_NOT, OPR_LEN, OPR_LOOM_BITNOT, OPR_NOUNOPR
};

struct upvaldesc
{
    lu_byte k;
    lu_byte info;
};

struct BlockCnt;
struct CodeState;

/* state needed to generate code for a given function */
struct FuncState
{
    Proto            *f;                         /* current function header */
    Table            *h;                         /* table to find (and reuse) elements in `k' */
    struct FuncState *prev;                      /* enclosing function */
    struct lua_State *L;                         /* copy of the Lua state */
    struct BlockCnt  *bl;                        /* chain of current blocks */
    struct CodeState *cs;
    int              pc;                         /* next position to code (equivalent to `ncode') */
    int              lasttarget;                 /* `pc' of last `jump target' */
    int              jpc;                        /* list of pending jumps to `pc' */
    int              freereg;                    /* first free register */
    int              nk;                         /* number of elements in `k' */
    int              np;                         /* number of elements in `p' */
    short            nlocvars;                   /* number of elements in `locvars' */
    lu_byte          nactvar;                    /* number of active local variables */
    upvaldesc        upvalues[LUAI_MAXUPVALUES]; /* upvalues */
    unsigned short   actvar[LUAI_MAXVARS];       /* declared-variable stack */
};

struct CodeState
{
    FuncState *fs;
    lua_State *L;
    TString   *source; /* current source name */
};

/*
** nodes for block list (list of active blocks)
*/
struct BlockCnt
{
    struct BlockCnt *previous;    /* chain */
    int             breaklist;    /* list of jumps out of this loop */
    int             continuelist; /* list of continue jumps in this loop */
    lu_byte         nactvar;      /* # active locals outside the breakable structure */
    lu_byte         upval;        /* true if some variable in the block is an upvalue */
    lu_byte         isbreakable;  /* true if `block' is a loop */
};

struct ConsControl
{
    ExpDesc v;       /* last list item read */
    ExpDesc *t;      /* table descriptor */
    int     nh;      /* total number of `record' elements */
    int     na;      /* total number of array elements */
    int     tostore; /* number of array elements pending to be stored */
};

class BC {
public:

    static lua_State *L;
    static utString  currentFilename;
    static int       lineNumber;

    static void error(utString message)
    {
        luaO_pushfstring(L,
                         "\n---------\nByteCode Error\n%s:%d\nerror:  %s\n---------\n",
                         currentFilename.c_str(), lineNumber, message.c_str());
        luaD_throw(L, LUA_ERRSYNTAX);
    }

    static void fixJump(FuncState *fs, int pc, int dest)
    {
        Instruction *jmp   = &fs->f->code[pc];
        int         offset = dest - (pc + 1);

        lua_assert(dest != NO_JUMP);
        if (abs(offset) > MAXARG_sBx)
        {
            error("control structure too long");
        }
        SETARG_sBx(*jmp, offset);
    }

    static int getJump(FuncState *fs, int pc)
    {
        int offset = GETARG_sBx(fs->f->code[pc]);

        if (offset == NO_JUMP) /* point to itself represents end of list */
        {
            return NO_JUMP;    /* end of list */
        }
        else
        {
            return (pc + 1) + offset; /* turn offset into absolute position */
        }
    }

    static Instruction *getJumpControl(FuncState *fs, int pc)
    {
        Instruction *pi = &fs->f->code[pc];

        if ((pc >= 1) && testTMode(GET_OPCODE(*(pi - 1))))
        {
            return pi - 1;
        }
        else
        {
            return pi;
        }
    }

    static int patchTestReg(FuncState *fs, int node, int reg)
    {
        Instruction *i = getJumpControl(fs, node);

        if (GET_OPCODE(*i) != OP_LOOM_TESTSET)
        {
            return 0; /* cannot patch other instructions */
        }
        if ((reg != NO_REG) && (reg != GETARG_B(*i)))
        {
            SETARG_A(*i, reg);
        }
        else
        {
            /* no register to put value or register already has the value */
            *i = CREATE_ABC(OP_LOOM_TEST, GETARG_B(*i), 0, GETARG_C(*i));
        }

        return 1;
    }

    static void patchListAux(FuncState *fs, int list, int vtarget, int reg,
                             int dtarget)
    {
        while (list != NO_JUMP)
        {
            int next = getJump(fs, list);
            if (patchTestReg(fs, list, reg))
            {
                fixJump(fs, list, vtarget);
            }
            else
            {
                fixJump(fs, list, dtarget); /* jump to default target */
            }
            list = next;
        }
    }

    static void dischargeJPC(FuncState *fs)
    {
        patchListAux(fs, fs->jpc, fs->pc, NO_REG, fs->pc);
        fs->jpc = NO_JUMP;
    }

    static int code(FuncState *fs, Instruction i, int line)
    {
        Proto *f = fs->f;

        dischargeJPC(fs); /* `pc' will change */
        /* put new instruction in code array */
        luaM_growvector(fs->L, f->code, fs->pc, f->sizecode, Instruction,
                        MAX_INT, "code size overflow");
        f->code[fs->pc] = i;
        /* save corresponding line information */
        luaM_growvector(fs->L, f->lineinfo, fs->pc, f->sizelineinfo, int,
                        MAX_INT, "code size overflow");
        f->lineinfo[fs->pc] = line;
        return fs->pc++;
    }

    static int codeABC(FuncState *fs, OpCode o, int a, int b, int c)
    {
        lua_assert(getOpMode(o) == iABC);
        lua_assert(getBMode(o) != OpArgN || b == 0);
        lua_assert(getCMode(o) != OpArgN || c == 0);
        return code(fs, CREATE_ABC(o, a, b, c), lineNumber);
    }

    static int codeABx(FuncState *fs, OpCode o, int a, unsigned int bc)
    {
        lua_assert(getOpMode(o) == iABx || getOpMode(o) == iAsBx);
        lua_assert(getCMode(o) == OpArgN);
        return code(fs, CREATE_ABx(o, a, bc), lineNumber);
    }

    static void ret(FuncState *fs, int first, int nret)
    {
        codeABC(fs, OP_RETURN, first, nret + 1, 0);
    }

    // lcode

    static int addk(FuncState *fs, TValue *k, TValue *v)
    {
        lua_State *L      = fs->L;
        TValue    *idx    = luaH_set(L, fs->h, k);
        Proto     *f      = fs->f;
        int       oldsize = f->sizek;

        if (ttisnumber(idx))
        {
            lua_assert(luaO_rawequalObj(&fs->f->k[cast_int(nvalue(idx))], v));
            return cast_int(nvalue(idx));
        }
        else     /* constant not found; create a new entry */
        {
            setnvalue(idx, cast_num(fs->nk));
            luaM_growvector(L, f->k, fs->nk, f->sizek, TValue, MAXARG_Bx,
                            "constant table overflow");
            while (oldsize < f->sizek)
            {
                setnilvalue(&f->k[oldsize++]);
            }
            setobj(L, &f->k[fs->nk], v);
            luaC_barrier(L, f, v);
            return fs->nk++;
        }
    }

    static int numberK(FuncState *fs, lua_Number r)
    {
        TValue o;

        setnvalue(&o, r);
        return addk(fs, &o, &o);
    }

    static int stringK(FuncState *fs, TString *s)
    {
        TValue o;

        setsvalue(fs->L, &o, s);
        return addk(fs, &o, &o);
    }

    static int boolK(FuncState *fs, int b)
    {
        TValue o;

        setbvalue(&o, b);
        return addk(fs, &o, &o);
    }

    static int nilK(FuncState *fs)
    {
        TValue k, v;

        setnilvalue(&v);
        /* cannot use nil as key; instead use table itself to represent nil */
        sethvalue(fs->L, &k, fs->h);
        return addk(fs, &k, &v);
    }

    // ---- end lcode

    static void nil(FuncState *fs, int from, int n)
    {
        Instruction *previous;

        if (fs->pc > fs->lasttarget) /* no jumps to current position? */
        {
            if (fs->pc == 0)         /* function start? */
            {
                if (from >= fs->nactvar)
                {
                    return; /* positions are already clean */
                }
            }
            else
            {
                previous = &fs->f->code[fs->pc - 1];
                if (GET_OPCODE(*previous) == OP_LOADNIL)
                {
                    int pfrom = GETARG_A(*previous);
                    int pto   = GETARG_B(*previous);
                    if ((pfrom <= from) && (from <= pto + 1))   /* can connect both? */
                    {
                        if (from + n - 1 > pto)
                        {
                            SETARG_B(*previous, from + n - 1);
                        }
                        return;
                    }
                }
            }
        }
        codeABC(fs, OP_LOADNIL, from, from + n - 1, 0); /* else no optimization */
    }

    static void freeReg(FuncState *fs, int reg)
    {
        if (!ISK(reg) && (reg >= fs->nactvar))
        {
            fs->freereg--;
            lua_assert(reg == fs->freereg);
        }
    }

    static void freeExp(FuncState *fs, ExpDesc *e)
    {
        if (e->k == VNONRELOC)
        {
            freeReg(fs, e->u.s.info);
        }
    }

    static void setOneRet(FuncState *fs, ExpDesc *e)
    {
        if (e->k == VCALL)   /* expression is an open function call? */
        {
            e->k        = VNONRELOC;
            e->u.s.info = GETARG_A(getcode(fs, e));
        }
        else if (e->k == VVARARG)
        {
            SETARG_B(getcode(fs, e), 2);
            e->k = VRELOCABLE; /* can relocate its simple result */
        }
    }

    static void dischargeVars(FuncState *fs, ExpDesc *e)
    {
        switch (e->k)
        {
        case VLOCAL:
            e->k = VNONRELOC;
            break;

        case VUPVAL:
            e->u.s.info = codeABC(fs, OP_GETUPVAL, 0, e->u.s.info, 0);
            e->k        = VRELOCABLE;
            break;

        case VGLOBAL:
            e->u.s.info = codeABx(fs, OP_GETGLOBAL, 0, e->u.s.info);
            e->k        = VRELOCABLE;
            break;

        case VINDEXED:
            freeReg(fs, e->u.s.aux);
            freeReg(fs, e->u.s.info);
            e->u.s.info = codeABC(fs, OP_GETTABLE, 0, e->u.s.info, e->u.s.aux);
            e->k        = VRELOCABLE;
            break;

        case VVARARG:
        case VCALL:
            setOneRet(fs, e);
            break;

        default:
            break; /* there is one value available (somewhere) */
        }
    }

    static void checkStack(FuncState *fs, int n)
    {
        int newstack = fs->freereg + n;

        if (newstack > fs->f->maxstacksize)
        {
            if (newstack >= MAXSTACK)
            {
                error("function or expression too complex");
            }
            fs->f->maxstacksize = cast_byte(newstack);
        }
    }

    static void reserveRegs(FuncState *fs, int n)
    {
        checkStack(fs, n);
        fs->freereg += n;
    }

    static void dischargeToReg(FuncState *fs, ExpDesc *e, int reg)
    {
        dischargeVars(fs, e);
        switch (e->k)
        {
        case VNIL:
            nil(fs, reg, 1);
            break;

        case VFALSE:
        case VTRUE:
            codeABC(fs, OP_LOADBOOL, reg, e->k == VTRUE, 0);
            break;

        case VK:
            codeABx(fs, OP_LOADK, reg, e->u.s.info);
            break;

        case VKNUM:
            codeABx(fs, OP_LOADK, reg, numberK(fs, e->u.nval));
            break;

        case VRELOCABLE:
           {
               Instruction *pc = &getcode(fs, e);
               SETARG_A(*pc, reg);
               break;
           }

        case VNONRELOC:
            if (reg != e->u.s.info)
            {
                codeABC(fs, OP_MOVE, reg, e->u.s.info, 0);
            }
            break;

        default:
            lua_assert(e->k == VVOID || e->k == VJMP);
            return; /* nothing to do... */
        }
        e->u.s.info = reg;
        e->k        = VNONRELOC;
    }

    static void dischargeToAnyReg(FuncState *fs, ExpDesc *e)
    {
        if (e->k != VNONRELOC)
        {
            reserveRegs(fs, 1);
            dischargeToReg(fs, e, fs->freereg - 1);
        }
    }

    static void concat(FuncState *fs, int *l1, int l2)
    {
        if (l2 == NO_JUMP)
        {
            return;
        }
        else if (*l1 == NO_JUMP)
        {
            *l1 = l2;
        }
        else
        {
            int list = *l1;
            int next;
            while ((next = getJump(fs, list)) != NO_JUMP) /* find last element */
            {
                list = next;
            }
            fixJump(fs, list, l2);
        }
    }

    /*
    ** check whether list has any jump that do not produce a value
    ** (or produce an inverted value)
    */
    static int needValue(FuncState *fs, int list)
    {
        for ( ; list != NO_JUMP; list = getJump(fs, list))
        {
            Instruction i = *getJumpControl(fs, list);
            if (GET_OPCODE(i) != OP_LOOM_TESTSET)
            {
                return 1;
            }
        }
        return 0; /* not found */
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

    static int codeLabel(FuncState *fs, int A, int b, int jump)
    {
        getLabel(fs); /* those instructions may be jump targets */
        return codeABC(fs, OP_LOADBOOL, A, b, jump);
    }

    static int jump(FuncState *fs)
    {
        int jpc = fs->jpc; /* save list of jumps to here */
        int j;

        fs->jpc = NO_JUMP;
        j       = codeAsBx(fs, OP_JMP, 0, NO_JUMP);
        concat(fs, &j, jpc); /* keep them on hold */
        return j;
    }

    static void patchToHere(FuncState *fs, int list)
    {
        getLabel(fs);
        concat(fs, &fs->jpc, list);
    }

    static void patchList(FuncState *fs, int list, int target)
    {
        if (target == fs->pc)
        {
            patchToHere(fs, list);
        }
        else
        {
            lua_assert(target < fs->pc);
            patchListAux(fs, list, target, NO_REG, target);
        }
    }

    static void expToReg(FuncState *fs, ExpDesc *e, int reg)
    {
        dischargeToReg(fs, e, reg);
        if (e->k == VJMP)
        {
            concat(fs, &e->t, e->u.s.info); /* put this jump in `t' list */
        }
        if (hasjumps(e))
        {
            int final;         /* position after whole expression */
            int p_f = NO_JUMP; /* position of an eventual LOAD false */
            int p_t = NO_JUMP; /* position of an eventual LOAD true */
            if (needValue(fs, e->t) || needValue(fs, e->f))
            {
                int fj = (e->k == VJMP) ? NO_JUMP : jump(fs);
                p_f = codeLabel(fs, reg, 0, 1);
                p_t = codeLabel(fs, reg, 1, 0);
                patchToHere(fs, fj);
            }
            final = getLabel(fs);
            patchListAux(fs, e->f, final, reg, p_f);
            patchListAux(fs, e->t, final, reg, p_t);
        }
        e->f        = e->t = NO_JUMP;
        e->u.s.info = reg;
        e->k        = VNONRELOC;
    }

    static void expToNextReg(FuncState *fs, ExpDesc *e)
    {
        dischargeVars(fs, e);
        freeExp(fs, e);
        reserveRegs(fs, 1);
        expToReg(fs, e, fs->freereg - 1);
    }

    static int expToAnyReg(FuncState *fs, ExpDesc *e)
    {
        dischargeVars(fs, e);
        if (e->k == VNONRELOC)
        {
            if (!hasjumps(e))
            {
                return e->u.s.info;           /* exp is already in a register */
            }
            if (e->u.s.info >= fs->nactvar)   /* reg. is not a local? */
            {
                expToReg(fs, e, e->u.s.info); /* put value on it */
                return e->u.s.info;
            }
        }
        expToNextReg(fs, e); /* default */
        return e->u.s.info;
    }

    static void expToVal(FuncState *fs, ExpDesc *e)
    {
        if (hasjumps(e))
        {
            expToAnyReg(fs, e);
        }
        else
        {
            dischargeVars(fs, e);
        }
    }

    static int expToRK(FuncState *fs, ExpDesc *e)
    {
        expToVal(fs, e);
        switch (e->k)
        {
        case VKNUM:
        case VTRUE:
        case VFALSE:
        case VNIL:
            if (fs->nk <= MAXINDEXRK)   /* constant fit in RK operand? */
            {
                e->u.s.info =
                    (e->k == VNIL) ? nilK(fs) :
                    (e->k == VKNUM) ?
                    numberK(fs, e->u.nval) :
                    boolK(fs, (e->k == VTRUE));
                e->k = VK;
                return RKASK(e->u.s.info);
            }
            else
            {
                break;
            }

        case VK:
            if (e->u.s.info <= MAXINDEXRK) /* constant fit in argC? */
            {
                return RKASK(e->u.s.info);
            }
            else
            {
                break;
            }

        default:
            break;
        }
        /* not a constant in the right range: put it in a register */
        return expToAnyReg(fs, e);
    }

    static void storeVar(FuncState *fs, ExpDesc *var, ExpDesc *ex)
    {
        switch (var->k)
        {
        case VLOCAL:
            freeExp(fs, ex);
            expToReg(fs, ex, var->u.s.info);
            return;

        case VUPVAL:
           {
               int e = expToAnyReg(fs, ex);
               codeABC(fs, OP_SETUPVAL, e, var->u.s.info, 0);
               break;
           }

        case VGLOBAL:
           {
               int e = expToAnyReg(fs, ex);
               codeABx(fs, OP_SETGLOBAL, e, var->u.s.info);
               break;
           }

        case VINDEXED:
           {
               int e = expToRK(fs, ex);
               codeABC(fs, OP_SETTABLE, var->u.s.info, var->u.s.aux, e);
               break;
           }

        default:
            lua_assert(0); /* invalid var kind to store */
            break;
        }
        freeExp(fs, ex);
    }

    static void indexed(FuncState *fs, ExpDesc *t, ExpDesc *k)
    {
        t->u.s.aux = expToRK(fs, k);
        t->k       = VINDEXED;
    }

    static void fixLine(FuncState *fs, int line)
    {
        fs->f->lineinfo[fs->pc - 1] = line;
    }

    static void setReturns(FuncState *fs, ExpDesc *e, int nresults)
    {
        if (e->k == VCALL)   /* expression is an open function call? */
        {
            SETARG_C(getcode(fs, e), nresults + 1);
        }
        else if (e->k == VVARARG)
        {
            SETARG_B(getcode(fs, e), nresults + 1);
            SETARG_A(getcode(fs, e), fs->freereg);
            reserveRegs(fs, 1);
        }
    }

    static void errorLimit(FuncState *fs, int limit, const char *what)
    {
        const char *msg =
            (fs->f->linedefined == 0) ?
            luaO_pushfstring(fs->L,
                             "main function has more than %d %s", limit,
                             what) :
            luaO_pushfstring(fs->L,
                             "function at line %d has more than %d %s",
                             fs->f->linedefined, limit, what);

        //luaX_lexerror(fs->ls, msg, 0);

        error(msg);

        abort();
    }

    static void enterLevel(CodeState *cs)
    {
        if (++cs->L->nCcalls > LUAI_MAXCCALLS)
        {
            error("chunk has too many syntax levels");
        }
    }

    static void leaveLevel(CodeState *cs)
    {
        cs->L->nCcalls--;
    }

    static void initExpDesc(ExpDesc *e, ExpKind k, int i)
    {
        e->f        = e->t = NO_JUMP;
        e->k        = k;
        e->u.s.info = i;
    }

    static void removeVars(CodeState *cs, int tolevel)
    {
        FuncState *fs = cs->fs;

        while (fs->nactvar > tolevel)
        {
            getLocVar(fs, --fs->nactvar).endpc = fs->pc;
        }
    }

    static int searchVar(FuncState *fs, TString *n)
    {
        int i;

        for (i = fs->nactvar - 1; i >= 0; i--)
        {
            if (n == getLocVar(fs, i).varname)
            {
                return i;
            }
        }
        return -1; /* not found */
    }

    static int indexUpValue(FuncState *fs, TString *name, ExpDesc *v)
    {
        int   i;
        Proto *f      = fs->f;
        int   oldsize = f->sizeupvalues;

        for (i = 0; i < f->nups; i++)
        {
            if ((fs->upvalues[i].k == v->k) &&
                (fs->upvalues[i].info == v->u.s.info))
            {
                lua_assert(f->upvalues[i] == name);
                return i;
            }
        }
        /* new one */
        luaY_checklimit(fs, f->nups + 1, LUAI_MAXUPVALUES, "upvalues");
        luaM_growvector(fs->L, f->upvalues, f->nups, f->sizeupvalues, TString *,
                        MAX_INT, "");
        while (oldsize < f->sizeupvalues)
        {
            f->upvalues[oldsize++] = NULL;
        }
        f->upvalues[f->nups] = name;
        luaC_objbarrier(fs->L, f, name);
        lua_assert(v->k == VLOCAL || v->k == VUPVAL);
        fs->upvalues[f->nups].k    = cast_byte(v->k);
        fs->upvalues[f->nups].info = cast_byte(v->u.s.info);
        return f->nups++;
    }

    static void markUpValue(FuncState *fs, int level)
    {
        BlockCnt *bl = fs->bl;

        while (bl && bl->nactvar > level)
        {
            bl = bl->previous;
        }
        if (bl)
        {
            bl->upval = 1;
        }
    }

    static int singleVarAux(FuncState *fs, TString *n, ExpDesc *var, int base)
    {
        if (fs == NULL)                        /* no more levels? */
        {
            initExpDesc(var, VGLOBAL, NO_REG); /* default is global variable */
            return VGLOBAL;
        }
        else
        {
            int v = searchVar(fs, n); /* look up at current level */
            if (v >= 0)
            {
                initExpDesc(var, VLOCAL, v);
                if (!base)
                {
                    markUpValue(fs, v); /* local will be used as an upval */
                }
                return VLOCAL;
            }
            else     /* not found at current level; try upper one */
            {
                if (singleVarAux(fs->prev, n, var, 0) == VGLOBAL)
                {
                    return VGLOBAL;
                }
                var->u.s.info = indexUpValue(fs, n, var); /* else was LOCAL or UPVAL */
                var->k        = VUPVAL;                   /* upvalue in this level */
                return VUPVAL;
            }
        }
    }

    // TODO: cache these
    static TString *allocString(CodeState *cs, const char *str)
    {
        int length = (int)strlen(str);

        lua_State *L = cs->L;

        TString *ts = luaS_newlstr(L, str, length);

        TValue *o = luaH_setstr(L, cs->fs->h, ts); /* entry for `str' */

        if (ttisnil(o))
        {
            setbvalue(o, 1);
        }
        /* make sure `str' will not be collected */

        return ts;
    }

    static void codeString(CodeState *cs, ExpDesc *e, TString *s)
    {
        initExpDesc(e, VK, stringK(cs->fs, s));
    }

    static void expString(CodeState *cs, ExpDesc *e, const char *s)
    {
        codeString(cs, e, allocString(cs, s));
    }

    static void singleVar(CodeState *cs, ExpDesc *var, const char *sname)
    {
        TString   *varname = allocString(cs, sname);
        FuncState *fs      = cs->fs;

        if (singleVarAux(fs, varname, var, 1) == VGLOBAL)
        {
            var->u.s.info = stringK(fs, varname); /* info points to global name */
        }
    }

    static void pushClosure(CodeState *cs, FuncState *func, ExpDesc *v)
    {
        FuncState *fs     = cs->fs;
        Proto     *f      = fs->f;
        int       oldsize = f->sizep;
        int       i;

        luaM_growvector(cs->L, f->p, fs->np, f->sizep, Proto *, MAXARG_Bx,
                        "constant table overflow");
        while (oldsize < f->sizep)
        {
            f->p[oldsize++] = NULL;
        }
        f->p[fs->np++] = func->f;
        luaC_objbarrier(cs->L, f, func->f);
        initExpDesc(v, VRELOCABLE, codeABx(fs, OP_CLOSURE, 0, fs->np - 1));
        for (i = 0; i < func->f->nups; i++)
        {
            OpCode o = (func->upvalues[i].k == VLOCAL) ? OP_MOVE : OP_GETUPVAL;
            codeABC(fs, o, 0, func->upvalues[i].info, 0);
        }
    }

    // assignment

    /*
    ** structure to chain all variables in the left-hand side of an
    ** assignment
    */
    struct LHSAssign
    {
        struct LHSAssign *prev;
        ExpDesc          v; /* variable (global, local, upvalue, or indexed) */
    };

    /*
    ** check whether, in an assignment to a local variable, the local variable
    ** is needed in a previous assignment (to a table). If so, save original
    ** local value in a safe place and use this safe copy in the previous
    ** assignment.
    */
    static void checkConflict(CodeState *cs, struct LHSAssign *lh, ExpDesc *v)
    {
        FuncState *fs      = cs->fs;
        int       extra    = fs->freereg; /* eventual position to save local variable */
        int       conflict = 0;

        for ( ; lh; lh = lh->prev)
        {
            if (lh->v.k == VINDEXED)
            {
                if (lh->v.u.s.info == v->u.s.info)   /* conflict? */
                {
                    conflict       = 1;
                    lh->v.u.s.info = extra;       /* previous assignment will use safe copy */
                }
                if (lh->v.u.s.aux == v->u.s.info) /* conflict? */
                {
                    conflict      = 1;
                    lh->v.u.s.aux = extra; /* previous assignment will use safe copy */
                }
            }
        }
        if (conflict)
        {
            codeABC(fs, OP_MOVE, fs->freereg, v->u.s.info, 0); /* make copy */
            reserveRegs(fs, 1);
        }
    }

    static void adjustAssign(CodeState *cs, int nvars, int nexps, ExpDesc *e)
    {
        FuncState *fs   = cs->fs;
        int       extra = nvars - nexps;

        if (hasmultret(e->k))
        {
            extra++; /* includes call itself */
            if (extra < 0)
            {
                extra = 0;
            }
            setReturns(fs, e, extra); /* last exp. provides the difference */
            if (extra > 1)
            {
                reserveRegs(fs, extra - 1);
            }
        }
        else
        {
            if (e->k != VVOID)
            {
                expToNextReg(fs, e); /* close last expression */
            }
            if (extra > 0)
            {
                int reg = fs->freereg;
                reserveRegs(fs, extra);
                nil(fs, reg, extra);
            }
        }
    }

    static int registerLocalVar(CodeState *cs, TString *varname)
    {
        FuncState *fs     = cs->fs;
        Proto     *f      = fs->f;
        int       oldsize = f->sizelocvars;

        luaM_growvector(cs->L, f->locvars, fs->nlocvars, f->sizelocvars, LocVar,
                        SHRT_MAX, "too many local variables");
        while (oldsize < f->sizelocvars)
        {
            f->locvars[oldsize++].varname = NULL;
        }
        f->locvars[fs->nlocvars].varname = varname;
        luaC_objbarrier(cs->L, f, varname);
        return fs->nlocvars++;
    }

    static void newLocalVar(CodeState *cs, const char *sname, int n)
    {
        TString   *name = allocString(cs, sname);
        FuncState *fs   = cs->fs;

        luaY_checklimit(fs, fs->nactvar + n + 1, LUAI_MAXVARS, "local variables");
        fs->actvar[fs->nactvar + n] =
            cast(unsigned short, registerLocalVar(cs, name));
    }

    static void adjustLocalVars(CodeState *cs, int nvars)
    {
        FuncState *fs = cs->fs;

        fs->nactvar = cast_byte(fs->nactvar + nvars);
        for ( ; nvars; nvars--)
        {
            getLocVar(fs, fs->nactvar - nvars).startpc = fs->pc;
        }
    }

    static bool isNumeral(ExpDesc *e)
    {
        return(e->k == VKNUM && e->t == NO_JUMP && e->f == NO_JUMP);
    }

    static int constFolding(OpCode op, ExpDesc *e1, ExpDesc *e2)
    {
        lua_Number v1, v2, r;

        if (!isNumeral(e1) || !isNumeral(e2))
        {
            return 0;
        }
        v1 = e1->u.nval;
        v2 = e2->u.nval;
        switch (op)
        {
        // these cannot be (easily) folded as require double/unsigned casting
        case OP_LOOM_BITOR:
        case OP_LOOM_BITAND:
        case OP_LOOM_BITXOR:
        case OP_LOOM_BITLSHIFT:
        case OP_LOOM_BITRSHIFT:
            return 0;

            break;

        case OP_ADD:
            r = luai_numadd(v1, v2);
            break;

        case OP_LOOM_ADD:
            r = luai_numadd(v1, v2);
            break;

        case OP_SUB:
            r = luai_numsub(v1, v2);
            break;

        case OP_MUL:
            r = luai_nummul(v1, v2);
            break;

        case OP_DIV:
            if (v2 == 0)
            {
                return 0; /* do not attempt to divide by 0 */
            }
            r = luai_numdiv(v1, v2);
            break;

        case OP_MOD:
            if (v2 == 0)
            {
                return 0; /* do not attempt to divide by 0 */
            }
            r = luai_nummod(v1, v2);
            break;

        case OP_POW:
            r = luai_numpow(v1, v2);
            break;

        case OP_UNM:
            r = luai_numunm(v1);
            break;

        case OP_LEN:
            return 0; /* no constant folding for 'len' */

        default:
            lua_assert(0);
            r = 0;
            break;
        }
        if (luai_numisnan(r))
        {
            return 0; /* do not attempt to produce NaN */
        }
        e1->u.nval = r;
        return 1;
    }

    static void codeArith(FuncState *fs, OpCode op, ExpDesc *e1, ExpDesc *e2)
    {
        if (constFolding(op, e1, e2))
        {
            return;
        }
        else
        {
            int o2 = (op != OP_UNM && op != OP_LEN && op != OP_LOOM_BITNOT) ? expToRK(fs, e2) : 0;
            int o1 = expToRK(fs, e1);
            if (o1 > o2)
            {
                freeExp(fs, e1);
                freeExp(fs, e2);
            }
            else
            {
                freeExp(fs, e2);
                freeExp(fs, e1);
            }
            e1->u.s.info = codeABC(fs, op, 0, o1, o2);
            e1->k        = VRELOCABLE;
        }
    }

    static int cond(CodeState *cs, ExpDesc *v)
    {
        if (v->k == VNIL)
        {
            v->k = VFALSE; /* `falses' are all equal here */
        }
        goIfTrue(cs->fs, v);
        return v->f;
    }

    static int condJump(FuncState *fs, OpCode op, int A, int B, int C)
    {
        codeABC(fs, op, A, B, C);
        return jump(fs);
    }

    static void codeComp(FuncState *fs, OpCode op, int cond, ExpDesc *e1,
                         ExpDesc *e2)
    {
        int o1 = expToRK(fs, e1);
        int o2 = expToRK(fs, e2);

        freeExp(fs, e2);
        freeExp(fs, e1);
        if ((cond == 0) && (op != OP_EQ))
        {
            int temp; /* exchange args to replace by `<' or `<=' */
            temp = o1;
            o1   = o2;
            o2   = temp; /* o1 <==> o2 */
            cond = 1;
        }
        e1->u.s.info = condJump(fs, op, cond, o1, o2);
        e1->k        = VJMP;
    }

    static void removeValues(FuncState *fs, int list)
    {
        for ( ; list != NO_JUMP; list = getJump(fs, list))
        {
            patchTestReg(fs, list, NO_REG);
        }
    }

    static void invertJump(FuncState *fs, ExpDesc *e)
    {
        Instruction *pc = getJumpControl(fs, e->u.s.info);

        lua_assert(
            testTMode(GET_OPCODE(*pc)) && GET_OPCODE(*pc) != OP_LOOM_TESTSET &&
            GET_OPCODE(*pc) != OP_LOOM_TEST);
        SETARG_A(*pc, !(GETARG_A(*pc)));
    }

    static void codeNot(FuncState *fs, ExpDesc *e)
    {
        dischargeVars(fs, e);
        switch (e->k)
        {
        case VNIL:
        case VFALSE:
            e->k = VTRUE;
            break;

        case VK:
        case VKNUM:
        case VTRUE:
            e->k = VFALSE;
            break;

        case VJMP:
            invertJump(fs, e);
            break;

        case VRELOCABLE:
        case VNONRELOC:
            dischargeToAnyReg(fs, e);
            freeExp(fs, e);
            e->u.s.info = codeABC(fs, OP_LOOM_NOT, 0, e->u.s.info, 0);
            e->k        = VRELOCABLE;
            break;

        default:
            lua_assert(0); /* cannot happen */
            break;
        }
        /* interchange true and false lists */
        {
            int temp = e->f;
            e->f = e->t;
            e->t = temp;
        }
        removeValues(fs, e->f);
        removeValues(fs, e->t);
    }

    static void prefix(FuncState *fs, UnOpr op, ExpDesc *e)
    {
        ExpDesc e2;

        e2.t      = e2.f = NO_JUMP;
        e2.k      = VKNUM;
        e2.u.nval = 0;
        switch (op)
        {
        case OPR_LOOM_BITNOT:
            if (!isNumeral(e))
            {
                expToAnyReg(fs, e); /* cannot operate on non-numeric constants */
            }
            codeArith(fs, OP_LOOM_BITNOT, e, &e2);
            break;

        case OPR_MINUS:
            if (!isNumeral(e))
            {
                expToAnyReg(fs, e); /* cannot operate on non-numeric constants */
            }
            codeArith(fs, OP_UNM, e, &e2);
            break;

        case OPR_NOT:
            codeNot(fs, e);
            break;

        case OPR_LEN:
            expToAnyReg(fs, e); /* cannot operate on constants */
            codeArith(fs, OP_LEN, e, &e2);
            break;

        default:
            lua_assert(0);
        }
    }

    static int jumpOnCond(FuncState *fs, ExpDesc *e, int cond)
    {
        if (e->k == VRELOCABLE)
        {
            Instruction ie = getCode(fs, e);
            if (GET_OPCODE(ie) == OP_NOT)
            {
                fs->pc--; /* remove previous OP_NOT */
                return condJump(fs, OP_LOOM_TEST, GETARG_B(ie), 0, !cond);
            }
            /* else go through */
        }
        dischargeToAnyReg(fs, e);
        freeExp(fs, e);
        return condJump(fs, OP_LOOM_TESTSET, NO_REG, e->u.s.info, cond);
    }

    static void goIfTrue(FuncState *fs, ExpDesc *e)
    {
        int pc; /* pc of last jump */

        dischargeVars(fs, e);
        switch (e->k)
        {
        case VK:
        case VKNUM:
        case VTRUE:
            pc = NO_JUMP; /* always true; do nothing */
            break;

        case VFALSE:
            pc = jump(fs); /* always jump */
            break;

        case VJMP:
            invertJump(fs, e);
            pc = e->u.s.info;
            break;

        default:
            pc = jumpOnCond(fs, e, 0);
            break;
        }
        concat(fs, &e->f, pc); /* insert last jump in `f' list */
        patchToHere(fs, e->t);
        e->t = NO_JUMP;
    }

    static void goIfFalse(FuncState *fs, ExpDesc *e)
    {
        int pc; /* pc of last jump */

        dischargeVars(fs, e);
        switch (e->k)
        {
        case VNIL:
        case VFALSE:
            pc = NO_JUMP; /* always false; do nothing */
            break;

        case VTRUE:
            pc = jump(fs); /* always jump */
            break;

        case VJMP:
            pc = e->u.s.info;
            break;

        default:
            pc = jumpOnCond(fs, e, 1);
            break;
        }
        concat(fs, &e->t, pc); /* insert last jump in `t' list */
        patchToHere(fs, e->f);
        e->f = NO_JUMP;
    }

    static void infix(FuncState *fs, BinOpr op, ExpDesc *v)
    {
        switch (op)
        {
        case OPR_AND:
            goIfTrue(fs, v);
            break;

        case OPR_OR:
            goIfFalse(fs, v);
            break;

        case OPR_CONCAT:
        case OPR_LOOM_ADD:
            expToNextReg(fs, v); /* operand must be on the `stack' */
            break;

        case OPR_LOOM_BITLSHIFT:
        case OPR_LOOM_BITRSHIFT:
        case OPR_ADD:
        case OPR_SUB:
        case OPR_MUL:
        case OPR_DIV:
        case OPR_MOD:
        case OPR_POW:
            if (!isNumeral(v))
            {
                expToRK(fs, v);
            }
            break;

        default:
            expToRK(fs, v);
            break;
        }
    }

    static void posFix(FuncState *fs, BinOpr op, ExpDesc *e1, ExpDesc *e2)
    {
        switch (op)
        {
        case OPR_AND:
            lua_assert(e1->t == NO_JUMP); /* list must be closed */
            dischargeVars(fs, e2);
            concat(fs, &e2->f, e1->f);
            *e1 = *e2;
            break;

        case OPR_OR:
            lua_assert(e1->f == NO_JUMP); /* list must be closed */
            dischargeVars(fs, e2);
            concat(fs, &e2->t, e1->t);
            *e1 = *e2;
            break;

        case OPR_CONCAT:
            expToVal(fs, e2);
            if ((e2->k == VRELOCABLE) &&
                (GET_OPCODE(getCode(fs, e2)) == OP_CONCAT))
            {
                lua_assert(e1->u.s.info == GETARG_B(getCode(fs, e2)) - 1);
                freeExp(fs, e1);
                SETARG_B(getcode(fs, e2), e1->u.s.info);
                e1->k        = VRELOCABLE;
                e1->u.s.info = e2->u.s.info;
            }
            else
            {
                expToNextReg(fs, e2); /* operand must be on the 'stack' */
                codeArith(fs, OP_CONCAT, e1, e2);
            }
            break;

        case OPR_LOOM_ADD:
            expToVal(fs, e2);
            if ((e2->k == VRELOCABLE) &&
                (GET_OPCODE(getCode(fs, e2)) == OP_LOOM_ADD))
            {
                lua_assert(e1->u.s.info == GETARG_B(getCode(fs, e2)) - 1);
                freeExp(fs, e1);
                SETARG_B(getcode(fs, e2), e1->u.s.info);
                e1->k        = VRELOCABLE;
                e1->u.s.info = e2->u.s.info;
            }
            else
            {
                expToNextReg(fs, e2); /* operand must be on the 'stack' */
                codeArith(fs, OP_LOOM_ADD, e1, e2);
            }
            break;

        case OPR_LOOM_BITLSHIFT:
            codeArith(fs, OP_LOOM_BITLSHIFT, e1, e2);
            break;

        case OPR_LOOM_BITRSHIFT:
            codeArith(fs, OP_LOOM_BITRSHIFT, e1, e2);
            break;

        case OPR_LOOM_BITOR:
            codeArith(fs, OP_LOOM_BITOR, e1, e2);
            break;

        case OPR_LOOM_BITAND:
            codeArith(fs, OP_LOOM_BITAND, e1, e2);
            break;

        case OPR_LOOM_BITXOR:
            codeArith(fs, OP_LOOM_BITXOR, e1, e2);
            break;

        case OPR_ADD:
            codeArith(fs, OP_ADD, e1, e2);
            break;

        case OPR_SUB:
            codeArith(fs, OP_SUB, e1, e2);
            break;

        case OPR_MUL:
            codeArith(fs, OP_MUL, e1, e2);
            break;

        case OPR_DIV:
            codeArith(fs, OP_DIV, e1, e2);
            break;

        case OPR_MOD:
            codeArith(fs, OP_MOD, e1, e2);
            break;

        case OPR_POW:
            codeArith(fs, OP_POW, e1, e2);
            break;

        case OPR_EQ:
            codeComp(fs, OP_EQ, 1, e1, e2);
            break;

        case OPR_NE:
            codeComp(fs, OP_EQ, 0, e1, e2);
            break;

        case OPR_LT:
            codeComp(fs, OP_LT, 1, e1, e2);
            break;

        case OPR_LE:
            codeComp(fs, OP_LE, 1, e1, e2);
            break;

        case OPR_GT:
            codeComp(fs, OP_LT, 0, e1, e2);
            break;

        case OPR_GE:
            codeComp(fs, OP_LE, 0, e1, e2);
            break;

        default:
            lua_assert(0);
        }
    }

    static void self(FuncState *fs, ExpDesc *e, ExpDesc *key)
    {
        int func;

        expToAnyReg(fs, e);
        freeExp(fs, e);
        func = fs->freereg;
        reserveRegs(fs, 2);
        codeABC(fs, OP_SELF, func, e->u.s.info, expToRK(fs, key));
        freeExp(fs, key);
        e->u.s.info = func;
        e->k        = VNONRELOC;
    }

    static void setMultRet(FuncState *fs, ExpDesc *e)
    {
        setReturns(fs, e, LUA_MULTRET);
    }

    static void openFunction(CodeState *cs, FuncState *fs);
    static void closeFunction(CodeState *cs);
};
}
#endif //LOOM_ENABLE_JIT
#endif
