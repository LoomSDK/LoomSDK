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

#include "loom/script/compiler/lsCompiler.h"
#include "loom/script/compiler/lsCompilerLog.h"
#include "loom/script/compiler/lsJitTypeCompiler.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"
#include "loom/script/common/lsLog.h"
#include "loom/script/runtime/lsRuntime.h"

extern "C" {
#include "lj_obj.h"
#include "lj_bcdump.h"
}

namespace LS {
void JitTypeCompiler::compile(ClassDeclaration *classDeclaration)
{
    JitTypeCompiler compiler;

    compiler.lineNumber = 0;
    compiler.cls        = classDeclaration;
    compiler._compile();
}


void JitTypeCompiler::initCodeState(CodeState *codeState, FuncState *funcState,
                                    const utString& source)
{
    memset(codeState, 0, sizeof(CodeState));
    memset(funcState, 0, sizeof(FuncState));

    codeState->L = vm->VM();
    utString chunkname = source;
    if (cls && currentMethod)
    {
        chunkname = source;
    }
    codeState->chunkname = lj_str_newz(vm->VM(), chunkname.c_str());
    setstrV(L, L->top, codeState->chunkname); /* Anchor chunkname string. */
    incr_top(L);

    lj_str_resizebuf(codeState->L, &codeState->sb, LJ_MIN_SBUF);

    codeState->lineNumber = lineNumber;
    BC::openFunction(codeState, funcState);

    funcState->flags |= PROTO_VARARG; /* Main chunk is always a vararg func. */

    bcemit_AD(funcState, BC_FUNCV, 0, 0);
    /* Placeholder. */
}


void JitTypeCompiler::closeCodeState(CodeState *codeState)
{
    BC::closeFunction(codeState, lineNumber);

    L->top--; // Drop chunkname.
    lua_assert(fs.prev == NULL);
    lua_assert(ls->fs == NULL);
    lua_assert(pt->sizeuv == 0);

    global_State *g = G(L);
    lj_mem_freevec(g, codeState->bcstack, codeState->sizebcstack, BCInsLine);
    lj_mem_freevec(g, codeState->vstack, codeState->sizevstack, VarInfo);
    lj_str_freebuf(g, &codeState->sb);

    lj_gc_check(L);
}


static int luaByteCodewriter(lua_State *L, const void *p, size_t size,
                             void *u)
{
    UNUSED(L);

    utArray<unsigned char> *bytecode = (utArray<unsigned char> *)u;

    unsigned char *data = (unsigned char *)p;
    for (size_t i = 0; i < size; i++, data++)
    {
        bytecode->push_back(*data);
    }

    return 0;
}


ByteCode *JitTypeCompiler::generateByteCode(GCproto *proto)
{
    utArray<unsigned char> bc;
    // always include debug info
    lj_bcwrite(L, proto, luaByteCodewriter, &bc, 0);

    return ByteCode::encode64(bc);
}


int JitTypeCompiler::parList(FunctionLiteral *literal, bool method)
{
    utArray<VariableDeclaration *> *parms = literal->parameters;

    if (!parms && !method)
    {
        return 0;
    }

    FuncState *fs = cs->fs;

    int nparams = 0;

    if (method)
    {
        BC::newLocalVar(cs, "this", nparams++);
    }

    if (parms)
    {
        for (unsigned int i = 0; i < parms->size(); i++)
        {
            Identifier *ident = parms->at(i)->identifier;
            BC::newLocalVar(cs, ident->string.c_str(), nparams++);
        }
    }

    if (nparams)
    {
        BC::adjustLocalVars(cs, nparams);
        fs->numparams = fs->nactvar;
        BC::regReserve(fs, fs->nactvar); /* reserve register for parameters */
    }

    return nparams;
}


void JitTypeCompiler::generateMethod(FunctionLiteral *function,
                                     MethodInfo      *method)
{
    currentMethod          = method;
    currentMethodCoroutine = function->isCoroutine;
    currentFunctionLiteral = function;

    CompilationUnit *cunit = cls->pkgDecl->compilationUnit;

    CodeState codeState;
    FuncState funcState;

    // update our line number as JIT compiler
    // needs to know this ahead of time
    if (function->statements)
    {
        for (UTsize i = 0; i < function->statements->size(); i++)
        {
            if (function->statements->at(i)->lineNumber)
            {
                lineNumber = function->statements->at(i)->lineNumber;
                break;
            }
        }
    }

    initCodeState(&codeState, &funcState, cunit->filename);

    cs = &codeState;

    parList(function, !function->isStatic);

    // we insert a yield to account for argument passing
    if (function->isCoroutine)
    {
        ExpDesc yield;
        insertYield(&yield);
    }

    declareLocalVariables(function);

    visitStatementArray(function->statements);

    closeCodeState(&codeState);

    method->setByteCode(generateByteCode(codeState.proto));

    currentMethod          = NULL;
    currentMethodCoroutine = false;
}


void JitTypeCompiler::generateConstructor(FunctionLiteral *function,
                                          ConstructorInfo *constructor)
{
    currentMethod          = constructor;
    currentFunctionLiteral = function;

    CompilationUnit *cunit = cls->pkgDecl->compilationUnit;

    CodeState codeState;
    FuncState funcState;

    initCodeState(&codeState, &funcState, cunit->filename);

    cs = &codeState;

    parList(function, true);

    declareLocalVariables(function);

    visitStatementArray(function->statements);

    closeCodeState(&codeState);

    constructor->setByteCode(generateByteCode(codeState.proto));

    currentMethod = NULL;
}


utArray<Statement *> *JitTypeCompiler::visitStatementArray(
    utArray<Statement *> *_statements)
{
    if (_statements != NULL)
    {
        utArray<Statement *>& statements = *_statements;

        for (unsigned int i = 0; i < statements.size(); i++)
        {
            statements[i] = visitStatement(statements[i]);
        }
    }

    return _statements;
}


Statement *JitTypeCompiler::visitStatement(Statement *statement)
{
    if (statement != NULL)
    {
        if (statement->lineNumber)
        {
            lineNumber = cs->lineNumber = BC::lineNumber = statement->lineNumber;
        }
        statement = statement->visitStatement(this);

        if (!cs->fs->bcbase[cs->fs->pc - 1].line)
        {
            cs->fs->bcbase[cs->fs->pc - 1].line = lineNumber;
        }

        cs->fs->freereg = cs->fs->nactvar; /* free registers */
    }

    return statement;
}


utArray<Expression *> *JitTypeCompiler::visitExpressionArray(
    utArray<Expression *> *_expressions)
{
    if (_expressions != NULL)
    {
        utArray<Expression *>& expressions = *_expressions;

        for (unsigned int i = 0; i < expressions.size(); i++)
        {
            expressions[i] = visitExpression(expressions[i]);
        }
    }

    return _expressions;
}


Expression *JitTypeCompiler::visitExpression(Expression *expression)
{
    if (expression != NULL)
    {
        expression = expression->visitExpression(this);
    }

    return expression;
}


//
// nodes
//

CompilationUnit *JitTypeCompiler::visit(CompilationUnit *cunit)
{
    return cunit;
}


//
// statements
//

Statement *JitTypeCompiler::visit(FunctionDeclaration *declaration)
{
    lmAssert(0, "FunctionDeclaration");

    return declaration;
}


Statement *JitTypeCompiler::visit(PropertyDeclaration *declaration)
{
    lmAssert(0, "PropertyDeclaration");

    return declaration;
}


void JitTypeCompiler::chunk(utArray<Statement *> *statements)
{
    if (!statements)
    {
        return;
    }

    BC::enterLevel(cs);

    for (unsigned int i = 0; i < statements->size(); i++)
    {
        Statement *statement = statements->at(i);

        lineNumber = cs->lineNumber = BC::lineNumber = statement->lineNumber;

        statement->visitStatement(this);

        if (!cs->fs->bcbase[cs->fs->pc - 1].line)
        {
            cs->fs->bcbase[cs->fs->pc - 1].line = lineNumber;
        }

        cs->fs->freereg = cs->fs->nactvar; /* free registers */
    }

    BC::leaveLevel(cs);
}


Statement *JitTypeCompiler::visit(BlockStatement *statement)
{
    chunk(statement->statements);

    return statement;
}


Statement *JitTypeCompiler::visit(BreakStatement *statement)
{
    FuncState *fs = cs->fs;
    FuncScope *bl;
    BCReg     savefr;
    int       upval = 0;

    // if we're in a for in loop, and using a non-local var
    // iterator we need to store off to temp var
    if (currentForInIteratorName && currentForInIteratorName[0])
    {
        // we need to store
        ExpDesc v;
        ExpDesc fv;

        // variable minus __ls_
        BC::singleVar(cs, &v, &currentForInIteratorName[5]);
        BC::singleVar(cs, &fv, currentForInIteratorName);
        BC::storeVar(fs, &fv, &v);
    }

    for (bl = fs->bl; bl && !bl->isbreakable; bl = bl->prev)
    {
        upval |= bl->upval; /* Collect upvalues in intervening scopes. */
    }
    if (!bl)                /* Error if no breakable scope found. */
    {
        LSCompilerLog::logError(cunit->filename.c_str(), statement->lineNumber, "break found outside of a loop!");
        return statement;
    }

    savefr      = fs->freereg;
    fs->freereg = bl->nactvar; /* Shrink slots to help data-flow analysis. */

    if (upval)
    {
        bcemit_AJ(fs, BC_UCLO, bl->nactvar, 0);
    }

    /* Close upvalues. */
    BC::jmpAppend(fs, &bl->breaklist, BC::emitJmp(fs));
    fs->freereg = savefr;

    return statement;
}


Statement *JitTypeCompiler::visit(ContinueStatement *statement)
{
    FuncState *fs = cs->fs;
    FuncScope *bl;
    BCReg     savefr;
    int       upval = 0;

    for (bl = fs->bl; bl && !bl->isbreakable; bl = bl->prev)
    {
        upval |= bl->upval; /* Collect upvalues in intervening scopes. */
    }
    if (!bl)                /* Error if no breakable scope found. */
    {
        LSCompilerLog::logError(cunit->filename.c_str(), statement->lineNumber, "continue found outside of a loop!");
        return statement;
    }
    savefr      = fs->freereg;
    fs->freereg = bl->nactvar; /* Shrink slots to help data-flow analysis. */
    if (upval)
    {
        bcemit_AJ(fs, BC_UCLO, bl->nactvar, 0);
    }
    /* Close upvalues. */
    BC::jmpAppend(fs, &bl->continuelist, BC::emitJmp(fs));
    fs->freereg = savefr;

    return statement;
}


Statement *JitTypeCompiler::visit(DoStatement *statement)
{
    FuncState *fs = cs->fs;

    FuncScope bl;

    int whileinit = BC::getLabel(fs);

    enterBlock(fs, &bl, 1);

    /* statements*/
    statement->statement->visitStatement(this);

    lua_assert(bl.breaklist == NO_JMP);

    //statement->expression->visitExpression(this);
    //ExpDesc c = statement->expression->e;

    int condexit = encodeCondition(statement->expression);

    //int condexit = BC::cond(cs, &c);

    BC::jmpPatch(fs, BC::emitJmp(fs), whileinit);

    leaveBlock(fs);

    BC::jmpToHere(fs, condexit); /* false conditions finish the loop */

    return statement;
}


Statement *JitTypeCompiler::visit(EmptyStatement *statement)
{
    return statement;
}


Statement *JitTypeCompiler::visit(ExpressionStatement *statement)
{
    statement->expression->visitExpression(this);

    return statement;
}


void JitTypeCompiler::enterBlock(FuncState *fs, FuncScope *bl,
                                 int isbreakable)
{
    bl->breaklist    = NO_JMP;
    bl->continuelist = NO_JMP;
    bl->isbreakable  = (uint8_t)isbreakable;
    bl->nactvar      = (uint8_t)fs->nactvar;
    bl->upval        = 0;
    bl->prev         = fs->bl;
    fs->bl           = bl;
    lua_assert(fs->freereg == fs->nactvar);
}


/* End a scope. */
void JitTypeCompiler::leaveBlock(FuncState *fs)
{
    FuncScope *bl = fs->bl;

    fs->bl = bl->prev;
    BC::varRemove(fs->cs, bl->nactvar);
    fs->freereg = fs->nactvar;
    lua_assert(bl->nactvar == fs->nactvar);
    /* A scope is either breakable or has upvalues. */
    lua_assert(!bl->isbreakable || !bl->upval);
    if (bl->upval)
    {
        bcemit_AJ(fs, BC_UCLO, bl->nactvar, 0);
    }
    else
    {
        /* Avoid in upval case, it clears lasttarget and kills UCLO+JMP join. */
        BC::jmpToHere(fs, bl->breaklist);
    }
}


Statement *JitTypeCompiler::visit(ForStatement *statement)
{
    FuncState *fs = cs->fs;
    int       whileinit;
    int       condexit;
    FuncScope bl;

    /* initial */
    if (statement->initial)
    {
        statement->initial->visitExpression(this);
        //BC::expToNextReg(fs, &statement->initial->e);
    }

    whileinit = BC::getLabel(fs);

    /* condition */
    if (statement->condition)
    {
        //statement->condition->visitExpression(this);
        //condexit = BC::cond(cs, &statement->condition->e);

        condexit = encodeCondition(statement->condition);
    }
    else
    {
        lmAssert(0, "For statement with no condition");
    }

    /* wrap as a statement */
    /* this is the pc of any continue statement in the block */
    ExpressionStatement *es = NULL;
    if (statement->increment) /*increment*/
    {
        /* FIXME: this should be done at parse time */
        es = new ExpressionStatement(statement->increment);
    }

    enterBlock(fs, &bl, 1);

    /* statements*/
    statement->statement->visitStatement(this);

    if (es)
    {
        BC::jmpToHere(fs, bl.continuelist);

        es->visitStatement(this);

        es->expression = NULL;
        delete es;

        es = NULL;
    }

    lua_assert(bl.breaklist == NO_JUMP);

    BC::jmpPatch(fs, BC::emitJmp(fs), whileinit);
    leaveBlock(fs);

    BC::jmpToHere(fs, condexit); /* false conditions finish the loop */

    return statement;
}


Statement *JitTypeCompiler::visit(ForInStatement *statement)
{
    FuncState *fs = cs->fs;

    char forIteratorName[256];

    // save off the previous iterator
    const char *prevForInIteratorName = currentForInIteratorName;

    // initially null, unless we need to use it due to
    // iterating with a variable external to block
    currentForInIteratorName = NULL;
    forIteratorName[0]       = 0;

    const char *vname = NULL;

    ExpDesc v;
    ExpDesc fv;

    if (statement->variable->astType == AST_VARDECL)
    {
        VariableDeclaration *vd = (VariableDeclaration *)statement->variable;
        vname = vd->identifier->string.c_str();
    }
    else if (statement->variable->astType == AST_IDENTIFIER)
    {
        vname = ((Identifier *)statement->variable)->string.c_str();

        // a little sanity
        lmAssert(strlen(vname) < 240, "For..In variable name > 240 characters");

        // we are using an external variable as the iterator for the loop
        // this means that we'll have to do a quick store to it when exiting the
        // loop (also via break)
        sprintf(forIteratorName, "__ls_%s", vname);
        currentForInIteratorName = forIteratorName;

        BC::newLocalVar(cs, forIteratorName, 0);
        BC::regReserve(fs, 1);
        BC::adjustLocalVars(cs, 1);
    }
    else
    {
        lmAssert(0, "Unknown variable statement in for..in initializer");
    }

    FuncScope forbl;
    enterBlock(fs, &forbl, 1); /* scope for loop and control variables */

    BCReg base = fs->freereg + 3;

    BCLine line = lineNumber;

    int nvars = 0;
    BC::newLocalVar(cs, "(for generator)", nvars++);
    BC::newLocalVar(cs, "(for state)", nvars++);
    BC::newLocalVar(cs, "(for control)", nvars++);

    bool isVector = false;

    if (statement->expression->type->getFullName() == "system.Vector")
    {
        isVector = true;
    }

    //TODO: It would be nice to have a way to iterate pairs
    if (statement->foreach)
    {
        BC::newLocalVar(cs, "__ls_key", nvars++);
    }

    /* create declared variables */
    BC::newLocalVar(cs, vname, nvars++);

    ExpDesc pairs;

    if (isVector)
    {
        BC::singleVar(cs, &pairs, "__lua_ipairs");
    }
    else
    {
        BC::singleVar(cs, &pairs, "__lua_pairs");
    }

    BC::expToNextReg(fs, &pairs);

    ExpDesc arg;

    statement->expression->visitExpression(this);
    arg = statement->expression->e;
    ExpDesc right;

    if (isVector)
    {
        // we pass the instance itself
    }
    else
    {
        BC::initExpDesc(&right, VKNUM, 0);
        setnumV(&right.u.nval, LSINDEXDICTPAIRS);

        BC::expToNextReg(fs, &arg);
        BC::expToNextReg(fs, &right);
        BC::expToVal(fs, &right);
        BC::indexed(fs, &arg, &right);
    }


    BCIns ins;
    BCReg cbase = pairs.u.s.info; /* Base register for call. */
    BC::expToNextReg(fs, &arg);
    ins = BCINS_ABC(BC_CALL, cbase, 2, fs->freereg - base);

    BC::initExpDesc(&pairs, VCALL, BC::emitINS(fs, ins));
    pairs.u.s.aux = cbase;
    fs->bcbase[fs->pc - 1].line = line;
    fs->freereg = cbase + 1; /* Leave one result by default. */

    BC::adjustAssign(cs, 3, 1, &pairs);

    BC::regBump(fs, 3);         /* The iterator needs another 3 slots (func + 2 args). */

    BC::adjustLocalVars(cs, 3); /* Hidden control variables. */

    FuncScope bl;

    BCPos loop = bcemit_AJ(fs, false ? BC_ISNEXT : BC_JMP, base, NO_JMP);
    enterBlock(fs, &bl, 0);
    BC::adjustLocalVars(cs, nvars - 3); /* Hidden control variables. */
    BC::regReserve(fs, nvars - 3);

    statement->statement->visitStatement(this);

    BC::jmpToHere(fs, forbl.continuelist);

    if (forIteratorName[0])
    {
        // we need to store
        BC::singleVar(cs, &v, vname);
        BC::singleVar(cs, &fv, forIteratorName);
        BC::storeVar(fs, &fv, &v);
    }

    leaveBlock(fs);
    /* Perform loop inversion. Loop control instructions are at the end. */
    BC::jmpPatchIns(fs, loop, fs->pc);
    bcemit_ABC(fs, false ? BC_ITERN : BC_ITERC, base, nvars - 3 + 1, 2 + 1);
    BCPos loopend = bcemit_AJ(fs, BC_ITERL, base, NO_JMP);

    fs->bcbase[loopend - 1].line = line; /* Fix line for control ins. */
    fs->bcbase[loopend].line     = line;
    BC::jmpPatchIns(fs, loopend, loop + 1);

    leaveBlock(fs);


    if (forIteratorName[0])
    {
        // we need to store to this block's var
        BC::singleVar(cs, &v, vname);
        BC::singleVar(cs, &fv, forIteratorName);
        BC::storeVar(fs, &v, &fv);
    }

    currentForInIteratorName = prevForInIteratorName;


    return statement;
}


Statement *JitTypeCompiler::visit(IfStatement *statement)
{
    FuncState *fs = cs->fs;
    BCPos     flist;
    BCPos     escapelist = NO_JMP;

    flist = encodeCondition(statement->expression);

    /*true statement*/
    block(cs, statement->trueStatement);

    Statement *i = statement->falseStatement;

    // else if
    while (i && i->astType == AST_IFSTATEMENT)
    {
        IfStatement *elif = (IfStatement *)i;
        BC::jmpAppend(fs, &escapelist, BC::emitJmp(fs));
        BC::jmpToHere(fs, flist);
        flist = encodeCondition(elif->expression);
        block(cs, elif->trueStatement);
        i = elif->falseStatement;
    }
    if (i)
    {
        BC::jmpAppend(fs, &escapelist, BC::emitJmp(fs));
        BC::jmpToHere(fs, flist);
        block(cs, i);
    }
    else
    {
        BC::jmpAppend(fs, &escapelist, flist);
    }

    BC::jmpToHere(fs, escapelist);

    return statement;
}


Statement *JitTypeCompiler::visit(LabelledStatement *statement)
{
    lmAssert(0, "LabelledStatement");

    return statement;
}


Statement *JitTypeCompiler::visit(ReturnStatement *statement)
{
    FuncState *fs = cs->fs;
    BCIns     ins;

    fs->flags |= PROTO_HAS_RETURN;

    if (!statement->result)
    {
        ins = BCINS_AD(BC_RET0, 0, 1);
    }
    else
    {
        ExpDesc e; // Receives the _last_ expression in the list.
        BCReg   nret = expList(&e, statement->result);
        if (nret == 1)
        {       // Return one result.
            if (e.k == VCALL)
            {
                // LOOM: No tail calls as they screw up profiling/debugging
                goto notailcall;

                /*
                 * // Check for tail call.
                 * BCIns *ip = bcptr(fs, &e);
                 * // It doesn't pay off to add BC_VARGT just for 'return ...'.
                 * if (bc_op(*ip) == BC_VARG)
                 *  goto notailcall;
                 *
                 * fs->pc--;
                 * ins = BCINS_AD(bc_op(*ip)-BC_CALL+BC_CALLT, bc_a(*ip), bc_c(*ip));
                 */
            }
            else
            {
                // Can return the result from any register.
                ins = BCINS_AD(BC_RET1, BC::expToAnyReg(fs, &e), 2);
            }
        }
        else
        {
            if (e.k == VCALL)
            {
                // Append all results from a call.
notailcall:
                setbc_b(bcptr(fs, &e), 0);
                ins = BCINS_AD(BC_RETM, fs->nactvar, e.u.s.aux - fs->nactvar);
            }
            else
            {
                BC::expToAnyReg(fs, &e); // Force contiguous registers.
                ins = BCINS_AD(BC_RET, fs->nactvar, nret + 1);
            }
        }
    }

    if (fs->flags & PROTO_CHILD)
    {
        bcemit_AJ(fs, BC_UCLO, 0, 0);
    }
    /* May need to close upvalues first. */
    BC::emitINS(fs, ins);

    return statement;
}


Statement *JitTypeCompiler::visit(CaseStatement *statement)
{
    FuncState *fs = cs->fs;

    int     flist;
    BCPos   escapelist = NO_JMP;
    ExpDesc swft;
    ExpDesc cexpr;

    if (statement->expression)
    {
        /* outer || switch fallthrough */
        BinOpr ftop = OPR_OR;

        BC::singleVar(cs, &swft, "__ls_swft");

        BC::emitBinOpLeft(fs, ftop, &swft);

        /* inner caseexpr == swexpr */
        BinOpr op = OPR_EQ;

        statement->expression->visitExpression(this);
        cexpr = statement->expression->e;

        BC::emitBinOpLeft(fs, op, &cexpr);

        ExpDesc swexpr;
        BC::singleVar(cs, &swexpr, "__ls_swexpr");

        BC::emitBinOp(cs->fs, op, &cexpr, &swexpr);

        BC::emitBinOp(cs->fs, ftop, &swft, &cexpr);

        if (cexpr.k == VKNIL)
        {
            cexpr.k = VKFALSE; /* `falses' are all equal here */
        }
        BC::emitBranchTrue(fs, &cexpr);
        flist = cexpr.f;
    }
    else
    {
        BC::initExpDesc(&cexpr, VKTRUE, 0);
        BC::emitBranchTrue(fs, &cexpr);
        flist = cexpr.f;
    }

    /*true block*/

    ExpDesc swv;
    BC::singleVar(cs, &swft, "__ls_swft");

    BC::initExpDesc(&swv, VKTRUE, 0);

    BC::expToNextReg(fs, &swv);

    BC::storeVar(fs, &swft, &swv);

    FuncScope bl;
    enterBlock(fs, &bl, 0);

    chunk(statement->statements);

    lua_assert(bl.breaklist == NO_JUMP);
    leaveBlock(fs);

    BC::jmpAppend(fs, &escapelist, flist);
    BC::jmpToHere(fs, escapelist);

    cs->fs->freereg = cs->fs->nactvar; /* free registers */

    return statement;
}


Statement *JitTypeCompiler::visit(SwitchStatement *statement)
{
    FuncState *fs = cs->fs;
    FuncScope bl;

    enterBlock(fs, &bl, 1);

    ExpDesc swv;

    statement->expression->visitExpression(this);
    swv = statement->expression->e;

    ExpDesc swexpr;
    BC::singleVar(cs, &swexpr, "__ls_swexpr");

    BC::expToNextReg(fs, &swv);

    BC::storeVar(fs, &swexpr, &swv);

    /* switch case fallthrough */
    ExpDesc swft;
    BC::singleVar(cs, &swft, "__ls_swft");

    BC::initExpDesc(&swv, VKFALSE, 0);

    BC::expToNextReg(fs, &swv);

    BC::storeVar(fs, &swft, &swv);

    cs->fs->freereg = cs->fs->nactvar; /* free registers */

    if (statement->clauses)
    {
        for (unsigned int i = 0; i < statement->clauses->size(); i++)
        {
            CaseStatement *cst = statement->clauses->at(i);
            cst->visitStatement(this);
        }
    }

    leaveBlock(fs);

    return statement;
}


Statement *JitTypeCompiler::visit(VariableStatement *statement)
{
    for (unsigned int i = 0; i < statement->declarations->size(); i++)
    {
        VariableDeclaration *d = statement->declarations->at(i);
        d->visitExpression(this);
    }

    return statement;
}


void JitTypeCompiler::block(CodeState *cs, Statement *fstat)
{
    FuncState *fs = cs->fs;
    FuncScope bl;

    enterBlock(fs, &bl, 0);

    // was chunk
    BC::lineNumber = fstat->lineNumber;
    fstat->visitStatement(this);

    //assert(bl.breaklist == NO_JUMP);
    leaveBlock(fs);
}


Statement *JitTypeCompiler::visit(WhileStatement *statement)
{
    FuncState *fs = cs->fs;
    BCPos     start, loop, condexit;
    FuncScope bl;

    start = fs->lasttarget = fs->pc;

    //statement->expression->visitExpression(this);

    //condexit = BC::cond(cs, &statement->expression->e);

    condexit = encodeCondition(statement->expression);

    enterBlock(fs, &bl, 1);

    loop = bcemit_AD(fs, BC_LOOP, fs->nactvar, 0);

    block(cs, statement->statement);

    BC::jmpToHere(fs, bl.continuelist);

    BC::jmpPatch(fs, BC::emitJmp(fs), start);

    leaveBlock(fs);
    BC::jmpToHere(fs, condexit);
    BC::jmpPatchIns(fs, loop, fs->pc);

    return statement;
}


Statement *JitTypeCompiler::visit(WithStatement *statement)
{
    lmAssert(0, "WithStatement");
    return statement;
}


Statement *JitTypeCompiler::visit(ClassDeclaration *statement)
{
    lmAssert(0, "ClassDeclaration");
    return statement;
}


Statement *JitTypeCompiler::visit(InterfaceDeclaration *statement)
{
    lmAssert(0, "InterfaceDeclaration");
    return statement;
}


Statement *JitTypeCompiler::visit(PackageDeclaration *statement)
{
    lmAssert(0, "PackageDeclaration");
    return statement;
}


Statement *JitTypeCompiler::visit(ImportStatement *statement)
{
    lmAssert(0, "ImportStatement");
    return statement;
}


//
// expressions
//

void JitTypeCompiler::generatePropertySet(ExpDesc *call, Expression *value,
                                          bool visit)
{
    FuncState *fs = cs->fs;

    int line = lineNumber;

    BC::expToNextReg(fs, call);

    lua_assert(call->k == VNONRELOC);
    BCReg base = call->u.s.info; /* base register for call */

    if (visit)
    {
        value->visitExpression(this);
        BC::expToNextReg(fs, &value->e);
    }
    else
    {
        BC::regReserve(fs, 1);
        BC::expToReg(fs, &value->e, fs->freereg - 1);
    }

    int nparams = fs->freereg - (base + 1);

    assert(nparams == 1);

    //BC::initExpDesc(call, VCALL,
    //        BC::codeABC(fs, OP_CALL, base, nparams + 1, 2));

    ExpDesc args = value->e;

    BCIns ins;
    if (args.k == VCALL)
    {
        ins = BCINS_ABC(BC_CALLM, base, 2, args.u.s.aux - base - 1);
    }
    else
    {
        if (args.k != VVOID)
        {
            BC::expToNextReg(fs, &args);
        }
        ins = BCINS_ABC(BC_CALL, base, 2, fs->freereg - base);
    }
    BC::initExpDesc(call, VCALL, BC::emitINS(fs, ins));
    call->u.s.aux = base;
    fs->bcbase[fs->pc - 1].line = line;
    fs->freereg = base + 1; /* Leave one result by default. */
}


Expression *JitTypeCompiler::visit(MultipleAssignmentExpression *expression)
{
    lmAssert(0, "MultipleAssignmentExpression");
    return expression;
}


static BinOpr getassignmentopr(const Token *t)
{
    Tokens *tok = Tokens::getSingletonPtr();

    if (t == &tok->OPERATOR_MULTIPLYASSIGNMENT)
    {
        return OPR_MUL;
    }

    if (t == &tok->OPERATOR_DIVIDEASSIGNMENT)
    {
        return OPR_DIV;
    }

    if (t == &tok->OPERATOR_PLUSASSIGNMENT)
    {
        return OPR_ADD;
    }

    if (t == &tok->OPERATOR_MINUSASSIGNMENT)
    {
        return OPR_SUB;
    }

    if (t == &tok->OPERATOR_MODULOASSIGNMENT)
    {
        return OPR_MOD;
    }

    return OPR_NOBINOPR;
}


static BitOpr getassignmentbitopr(const Token *t)
{
    Tokens *tok = Tokens::getSingletonPtr();

    if (t == &tok->OPERATOR_BITWISEANDASSIGNMENT)
    {
        return OPR_LOOM_BITAND;
    }

    if (t == &tok->OPERATOR_BITWISEORASSIGNMENT)
    {
        return OPR_LOOM_BITOR;
    }

    if (t == &tok->OPERATOR_BITWISEXORASSIGNMENT)
    {
        return OPR_LOOM_BITXOR;
    }

    if (t == &tok->OPERATOR_SHIFTLEFTASSIGNMENT)
    {
        return OPR_LOOM_BITLSHIFT;
    }

    if (t == &tok->OPERATOR_SHIFTRIGHTASSIGNMENT)
    {
        return OPR_LOOM_BITRSHIFT;
    }

    return OPR_NOBITOPR;
}


Expression *JitTypeCompiler::visit(AssignmentOperatorExpression *expression)
{
    Tokens *tok = Tokens::getSingletonPtr();
    BinOpr op   = getassignmentopr(expression->type);

    Expression *eleft  = expression->leftExpression;
    Expression *eright = expression->rightExpression;

    lmAssert(eleft->type,
             "Untyped left expression on assignment operator expression");

    const char *opmethod = tok->getOperatorMethodName(expression->type);
    if (opmethod)
    {
        MemberInfo *mi = eleft->type->findMember(opmethod);
        if (mi)
        {
            lmAssert(mi->isMethod(), "Non-method operator");
            MethodInfo *method = (MethodInfo *)mi;
            lmAssert(method->isOperator(), "Non-operator method");

            utArray<Expression *> args;
            args.push_back(eright);

            ExpDesc opcall;
            ExpDesc emethod;

            eleft->visitExpression(this);
            opcall = eleft->e;

            BC::initExpDesc(&emethod, VKNUM, 0);
            setnumV(&emethod.u.nval, method->getOrdinal());

            BC::expToNextReg(cs->fs, &opcall);
            BC::expToNextReg(cs->fs, &emethod);
            BC::expToVal(cs->fs, &emethod);
            BC::indexed(cs->fs, &opcall, &emethod);

            generateCall(&opcall, &args, method);

            expression->e = opcall;
            return expression;
        }
    }

    BitOpr bop = getassignmentbitopr(expression->type);

    ExpDesc right;

    if (bop != OPR_NOBITOPR)
    {
        eleft->assignment = false;

        const char *fname = getBitOpFunctionName(bop);
        ExpDesc    bitop;
        BC::singleVar(cs, &bitop, fname);

        utArray<Expression *> exprs;
        exprs.push_back(eleft);
        exprs.push_back(eright);

        generateCall(&bitop, &exprs, NULL);

        right = bitop;

        BC::expToNextReg(cs->fs, &right);
    }
    else
    {
        op = getassignmentopr(expression->type);

        if (op == OPR_NOBINOPR)
        {
            lmAssert(0, "Unknown Assignment Operator");
        }

        if (op == OPR_ADD)
        {
            lmAssert(eleft->type && eright->type, "Untyped add operaton %i",
                     lineNumber);

            if ((eleft->type->getFullName() != "system.Number") ||
                (eright->type->getFullName() != "system.Number"))
            {
                op = OPR_CONCAT;
            }
        }


        eleft->assignment = false;
        eleft->visitExpression(this);

        BC::emitBinOpLeft(cs->fs, op, &eleft->e);

        eright->visitExpression(this);
        BC::expToNextReg(cs->fs, &eright->e);

        BC::emitBinOp(cs->fs, op, &eleft->e, &eright->e);

        right = eleft->e;

        BC::expToNextReg(cs->fs, &right);
    }

    memset(&eleft->e, 0, sizeof(ExpDesc));
    eleft->assignment = true;
    eleft->visitExpression(this);
    ExpDesc left = eleft->e;

    if (eleft->memberInfo && eleft->memberInfo->isProperty())
    {
        eright->e = right;
        generatePropertySet(&eleft->e, eright, false);
    }
    else
    {
        BC::storeVar(cs->fs, &left, &right);
    }

    return expression;
}


static BinOpr getbinopr(const Token *t)
{
    Tokens *tok = Tokens::getSingletonPtr();

    if (t == &tok->OPERATOR_PLUS)
    {
        return OPR_ADD;
    }

    if (t == &tok->OPERATOR_MINUS)
    {
        return OPR_SUB;
    }

    if (t == &tok->OPERATOR_MULTIPLY)
    {
        return OPR_MUL;
    }

    if (t == &tok->OPERATOR_DIVIDE)
    {
        return OPR_DIV;
    }

    if (t == &tok->OPERATOR_MODULO)
    {
        return OPR_MOD;
    }

    if (t == &tok->OPERATOR_NOTEQUAL)
    {
        return OPR_NE;
    }

    if (t == &tok->OPERATOR_EQUALEQUAL)
    {
        return OPR_EQ;
    }

    if (t == &tok->OPERATOR_LESSTHAN)
    {
        return OPR_LT;
    }

    if (t == &tok->OPERATOR_LESSTHANOREQUAL)
    {
        return OPR_LE;
    }

    if (t == &tok->OPERATOR_GREATERTHAN)
    {
        return OPR_GT;
    }

    if (t == &tok->OPERATOR_GREATERTHANOREQUAL)
    {
        return OPR_GE;
    }

    if (t == &tok->OPERATOR_LOGICALAND)
    {
        return OPR_AND;
    }

    if (t == &tok->OPERATOR_LOGICALOR)
    {
        return OPR_OR;
    }

    if (t == &tok->OPERATOR_CONCAT)
    {
        return OPR_CONCAT;
    }

    /*case '^': return OPR_POW;
     * case TK_CONCAT: return OPR_CONCAT;*/
    return OPR_NOBINOPR;
}


static BitOpr getbitopr(const Token *t)
{
    Tokens *tok = Tokens::getSingletonPtr();

    if (t == &tok->OPERATOR_SHIFTLEFT)
    {
        return OPR_LOOM_BITLSHIFT;
    }

    if (t == &tok->OPERATOR_SHIFTRIGHT)
    {
        return OPR_LOOM_BITRSHIFT;
    }

    if (t == &tok->OPERATOR_BITWISEAND)
    {
        return OPR_LOOM_BITAND;
    }

    if (t == &tok->OPERATOR_BITWISEOR)
    {
        return OPR_LOOM_BITOR;
    }

    if (t == &tok->OPERATOR_BITWISEXOR)
    {
        return OPR_LOOM_BITXOR;
    }

    return OPR_NOBITOPR;
}


const char *JitTypeCompiler::getBitOpFunctionName(BitOpr b)
{
    switch (b)
    {
    case OPR_LOOM_BITLSHIFT:
        return "__ls_blshift";

        break;

    case OPR_LOOM_BITRSHIFT:
        return "__ls_brshift";

        break;

    case OPR_LOOM_BITAND:
        return "__ls_band";

        break;

    case OPR_LOOM_BITOR:
        return "__ls_bor";

        break;

    case OPR_LOOM_BITXOR:
        return "__ls_xor";

        break;

    default:
        lmAssert(0, "Unknown BitOp");
        break;
    }

    return NULL;
}


Expression *JitTypeCompiler::visit(BinaryOperatorExpression *expression)
{
    Tokens *tok = Tokens::getSingletonPtr();

    Expression *eleft  = expression->leftExpression;
    Expression *eright = expression->rightExpression;

    // operator overloads
    lmAssert(eleft->type && eright->type, "Untyped binary expression");

    const char *opmethod = tok->getOperatorMethodName(expression->op);
    if (opmethod)
    {
        MemberInfo *mi = eleft->type->findMember(opmethod);
        if (mi)
        {
            lmAssert(mi->isMethod(), "Non-method operator");
            MethodInfo *method = (MethodInfo *)mi;
            lmAssert(method->isOperator(), "Non-operator method");

            utArray<Expression *> args;
            args.push_back(eleft);
            args.push_back(eright);

            ExpDesc opcall;
            ExpDesc emethod;

            BC::singleVar(cs, &opcall, eleft->type->getName());
            BC::expString(cs, &emethod, method->getName());

            BC::expToNextReg(cs->fs, &opcall);
            BC::expToNextReg(cs->fs, &emethod);
            BC::expToVal(cs->fs, &emethod);
            BC::indexed(cs->fs, &opcall, &emethod);

            generateCall(&opcall, &args, method);

            expression->e = opcall;
            return expression;
        }
    }

    // dynamic cast
    if ((expression->op == &tok->KEYWORD_IS) ||
        (expression->op == &tok->KEYWORD_INSTANCEOF) ||
        (expression->op == &tok->KEYWORD_AS))
    {
        lmAssert(eleft->type && eright->type, "Untyped is/as/instanceof");

        FuncState *fs = cs->fs;

        ExpDesc object;
        BC::singleVar(cs, &object, "Object");

        ExpDesc method;

        if (expression->op == &tok->KEYWORD_IS)
        {
            BC::expString(cs, &method, "_is");
        }
        else if (expression->op == &tok->KEYWORD_AS)
        {
            BC::expString(cs, &method, "_as");
        }
        else
        {
            BC::expString(cs, &method, "_instanceof");
        }

        BC::expToNextReg(fs, &object);
        BC::expToNextReg(fs, &method);
        BC::expToVal(fs, &method);
        BC::indexed(fs, &object, &method);

        // when dynamic casting, we pass the expression to be cast,
        // the assembly name (which has been interned by the VM), and the typeID in that assembly
        // this greatly speeds up type resolution at runtime
        utArray<Expression *> args;
        args.push_back(eleft);
        args.push_back(new StringLiteral(eright->type->getAssembly()->getName().c_str()));
        args.push_back(new NumberLiteral(eright->type->getTypeID()));

        generateCall(&object, &args);

        expression->e = object;

        return expression;
    }

    BitOpr bop = getbitopr(expression->op);
    if (bop != OPR_NOBITOPR)
    {
        const char *fname = getBitOpFunctionName(bop);
        ExpDesc    bitop;
        BC::singleVar(cs, &bitop, fname);

        utArray<Expression *> exprs;
        exprs.push_back(eleft);
        exprs.push_back(eright);

        generateCall(&bitop, &exprs, NULL);

        expression->e = bitop;
        return expression;
    }

    BinOpr op = getbinopr(expression->op);

    if (op == OPR_ADD)
    {
        lmAssert(eleft->type && eright->type, "Untyped add operaton %i",
                 lineNumber);

        int ncheck = 0;
        if (eleft->type->isEnum() || (eleft->type->getFullName() == "system.Number"))
        {
            ncheck++;
        }

        if (eright->type->isEnum() || (eright->type->getFullName() == "system.Number"))
        {
            ncheck++;
        }

        if (ncheck != 2)
        {
            op = OPR_CONCAT;
        }
    }

    // If we're concat'ing arbitrary types with a string, we need to coerce them
    // to strings with Object._toString otherwise the Lua VM will error when
    // it can't concat (which has strict rules, for instance cannot concat nil)
    if ((op == OPR_CONCAT) && ((eleft->type->getFullName() == "system.String") || (eright->type->getFullName() == "system.String")))
    {
        // coerce left to string, must be done even for string types as they may be null
        coerceToString(eleft);

        BC::emitBinOpLeft(cs->fs, op, &eleft->e);

        // coerce right to string, must be done even for string types as they may be null
        coerceToString(eright);

        // and the binary op
        BC::emitBinOp(cs->fs, op, &eleft->e, &eright->e);

        // save off expression and return
        expression->e = eleft->e;

        return expression;
    }

    if ((op == OPR_AND) || (op == OPR_OR))
    {
        eleft->visitExpression(this);
        ExpDesc left = eleft->e;

        castBool(eleft, &left);

        BC::emitBinOpLeft(cs->fs, op, &left);

        eright->visitExpression(this);
        ExpDesc right = eright->e;

        castBool(eright, &right);

        BC::emitBinOp(cs->fs, op, &left, &right);

        expression->e = left;
    }
    else
    {
        eleft->visitExpression(this);

        BC::emitBinOpLeft(cs->fs, op, &eleft->e);

        eright->visitExpression(this);

        BC::emitBinOp(cs->fs, op, &eleft->e, &eright->e);

        expression->e = eleft->e;
    }

    // promote to register
    BC::expToNextReg(cs->fs, &expression->e);

    return expression;
}


Expression *JitTypeCompiler::visit(CallExpression *call)
{
    call->function->visitExpression(this);

    MethodBase *methodBase = call->methodBase;

    // check whether we're calling a methodbase
    if (methodBase)
    {
        lmAssert(methodBase->isMethod(), "Non-method called");

        MethodInfo *method = (MethodInfo *)methodBase;
        generateCall(&call->function->e, call->arguments, method);

        call->e = call->function->e;
    }
    else
    {
        lmAssert(call->function->type, "Untyped call");

        // if we're calling a delegate we need to load up the call method
        if (call->function->type->isDelegate())
        {
            MethodInfo *method = (MethodInfo *)call->function->type->findMember("call");

            lmAssert(method, "delegate with no call method");

            ExpDesc right;

            BC::initExpDesc(&right, VKNUM, 0);
            setnumV(&right.u.nval, method->getOrdinal());


            BC::expToNextReg(cs->fs, &call->function->e);
            BC::expToNextReg(cs->fs, &right);
            BC::expToVal(cs->fs, &right);
            BC::indexed(cs->fs, &call->function->e, &right);

            generateCall(&call->function->e, call->arguments, NULL);
            call->e = call->function->e;
        }
        else
        {
            // we're directly calling a local, instance (bound), or static method of type Function
            generateCall(&call->function->e, call->arguments, NULL);
            call->e = call->function->e;
        }
    }

    return call;
}


Expression *JitTypeCompiler::visit(ConditionalExpression *conditional)
{
    FuncState *fs = cs->fs;
    int       flist;
    BCPos     escapelist = NO_JMP;

    int reg = fs->freereg;

    Expression *expr      = conditional->expression;
    Expression *trueExpr  = conditional->trueExpression;
    Expression *falseExpr = conditional->falseExpression;

    flist = encodeCondition(expr);

    /*true statement*/

    FuncScope bl;
    enterBlock(fs, &bl, 0);
    BC::singleVar(cs, &conditional->e, "__ls_ternary");
    trueExpr->visitExpression(this);
    BC::storeVar(fs, &conditional->e, &trueExpr->e);
    lmAssert(bl.breaklist == NO_JMP, "Internal Compiler Error");
    leaveBlock(fs);

    fs->freereg = reg;

    /* false statement*/
    BC::jmpAppend(fs, &escapelist, BC::emitJmp(fs));
    BC::jmpToHere(fs, flist);

    FuncScope bl2;
    enterBlock(fs, &bl2, 0);
    BC::singleVar(cs, &conditional->e, "__ls_ternary");
    falseExpr->visitExpression(this);
    BC::storeVar(fs, &conditional->e, &falseExpr->e);
    lmAssert(bl.breaklist == NO_JMP, "Internal Compiler Error");
    leaveBlock(fs);

    BC::jmpToHere(fs, escapelist);

    fs->freereg = reg;

    BC::singleVar(cs, &conditional->e, "__ls_ternary");

    return conditional;
}


Expression *JitTypeCompiler::visit(DeleteExpression *expression)
{
    lmAssert(0, "DeleteExpression");
    return expression;
}


Expression *JitTypeCompiler::visit(LogicalAndExpression *expression)
{
    return visit((BinaryOperatorExpression *)expression);
}


Expression *JitTypeCompiler::visit(LogicalOrExpression *expression)
{
    return visit((BinaryOperatorExpression *)expression);
}


void JitTypeCompiler::createVarArg(ExpDesc *varg,
                                   utArray<Expression *> *arguments, int startIdx)
{
    char varargname[1024];

    sprintf(varargname, "__ls_vararg%i", currentFunctionLiteral->curVarArgCalls++);
    lmAssert(currentFunctionLiteral->numVarArgCalls > 0, "0 numVarArgs");
    currentFunctionLiteral->curVarArgCalls %= currentFunctionLiteral->numVarArgCalls;

    FuncState *fs = cs->fs;

    int reg = fs->freereg;

    ExpDesc nvector;
    createInstance(&nvector, "system.Vector", NULL);

    ExpDesc evector;
    BC::singleVar(cs, &evector, varargname);
    BC::storeVar(fs, &evector, &nvector);

    if (!arguments || !arguments->size())
    {
        *varg = evector;
        return;
    }

    // load the vector value table
    ExpDesc vtable;
    BC::singleVar(cs, &vtable, varargname);
    BC::expToNextReg(fs, &vtable);

    ExpDesc v;
    BC::initExpDesc(&v, VKNUM, 0);
    setnumV(&v.u.nval, LSINDEXVECTOR);


    BC::expToNextReg(fs, &v);
    BC::expToVal(fs, &v);
    BC::indexed(fs, &vtable, &v);

    BC::expToNextReg(fs, &vtable);

    utArray<Expression *> args;
    int length = 0;
    for (UTsize i = startIdx; i < arguments->size(); i++)
    {
        Expression *arg = arguments->at(i);

        int restore = fs->freereg;

        BC::initExpDesc(&v, VKNUM, 0);
        setnumV(&v.u.nval, length);

        BC::expToNextReg(fs, &v);
        BC::expToVal(fs, &v);

        BC::indexed(fs, &vtable, &v);

        arg->visitExpression(this);

        BC::storeVar(fs, &vtable, &arg->e);
        length++;

        fs->freereg = restore;
    }

    BC::singleVar(cs, &evector, varargname);
    BC::expToNextReg(fs, &evector);

    ExpDesc elength;
    BC::initExpDesc(&elength, VKNUM, 0);
    setnumV(&elength.u.nval, LSINDEXVECTORLENGTH);

    BC::expToNextReg(fs, &elength);
    BC::expToVal(fs, &elength);
    BC::indexed(fs, &evector, &elength);

    BC::initExpDesc(&elength, VKNUM, 0);

    setnumV(&elength.u.nval, length);

    BC::storeVar(fs, &evector, &elength);

    fs->freereg = reg;

    BC::singleVar(cs, varg, varargname);
}


int JitTypeCompiler::expList(ExpDesc *e, utArray<Expression *> *expressions,
                             MethodBase *methodBase)
{
    ParameterInfo *vararg = NULL;

    if (methodBase)
    {
        vararg = methodBase->getVarArgParameter();
    }

    if (!expressions && !vararg)
    {
        return 0;
    }

    if (!expressions && vararg)
    {
        lmAssert(vararg->position == 0, "Bad position on variable args");
        createVarArg(e, NULL, vararg->position);
        return 1;
    }

    int count = 0;

    if (expressions)
    {
        for (unsigned int i = 0; i < expressions->size(); i++)
        {
            Expression *ex = expressions->at(i);

            if (vararg && (vararg->position == i))
            {
                if (i)
                {
                    BC::expToNextReg(cs->fs, e);
                }

                createVarArg(e, expressions, vararg->position);
                count++;
                return count;
            }

            ex->visitExpression(this);

            if (i != expressions->size() - 1)
            {
                BC::expToNextReg(cs->fs, &ex->e);
            }

            *e = ex->e;
            count++;
        }
    }

    if (vararg)
    {
        if (expressions && expressions->size())
        {
            BC::expToNextReg(cs->fs, e);
        }

        createVarArg(e, expressions, vararg->position);
        count++;
    }

    return count;
}


void JitTypeCompiler::generateCall(ExpDesc *call,
                                   utArray<Expression *> *arguments, MethodBase *methodBase)
{
    FuncState *fs = cs->fs;

    int line = lineNumber;

    ParameterInfo *vararg = NULL;

    if (methodBase)
    {
        vararg = methodBase->getVarArgParameter();
    }

    BC::expToNextReg(fs, call);

    ExpDesc args;
    args.k = VVOID;

    int nparams = 0;

    if ((arguments && arguments->size()) || vararg)
    {
        nparams = expList(&args, arguments, methodBase);

        /* Pass on multiple results. */
        if (args.k == VCALL)
        {
            setbc_b(bcptr(fs, &args), 0);
        }
    }

    lua_assert(call->k == VNONRELOC);
    BCIns ins;
    BCReg base = call->u.s.info; /* Base register for call. */
    if (args.k == VCALL)
    {
        ins = BCINS_ABC(BC_CALLM, base, 2, args.u.s.aux - base - 1);
    }
    else
    {
        if (args.k != VVOID)
        {
            BC::expToNextReg(fs, &args);
        }
        ins = BCINS_ABC(BC_CALL, base, 2, fs->freereg - base);
    }
    BC::initExpDesc(call, VCALL, BC::emitINS(fs, ins));
    call->u.s.aux = base;
    fs->bcbase[fs->pc - 1].line = line;
    fs->freereg = base + 1; /* Leave one result by default. */
}


Expression *JitTypeCompiler::visit(NewExpression *expression)
{
    FuncState *fs = cs->fs;

    Type *type = expression->function->type;

    lmAssert(type, "Untyped new expression");

    ExpDesc e;
    createInstance(&e, type->getFullName(),
                   expression->arguments);

    if ((expression->function->astType == AST_VECTORLITERAL) || (expression->function->astType == AST_DICTIONARYLITERAL))
    {
        // assign new instance
        expression->function->e = e;

        BC::expToNextReg(fs, &e);

        int restore = fs->freereg;

        // visit literal
        expression->function->visitExpression(this);

        fs->freereg = restore;
    }

    expression->e = e;

    return expression;
}


Expression *JitTypeCompiler::visit(UnaryOperatorExpression *expression)
{
    int c = expression->op->value.str()[0];

    BCOp op;

    bool valid = true;

    if (c == '!')
    {
        op = BC_NOT;
    }
    else if (c == '-')
    {
        op = BC_UNM;
    }
    else
    {
        valid = false;
    }

    if (valid)
    {
        expression->subExpression->visitExpression(this);

        if (op == BC_NOT)
        {
            ExpDesc be;
            castBool(expression->subExpression, &be);
            BC::emitUnOp(cs->fs, op, &be);
            expression->e = be;
        }
        else
        {
            BC::emitUnOp(cs->fs, op, &expression->subExpression->e);
            expression->e = expression->subExpression->e;
        }
    }
    else
    {
        if (c == '~')
        {
            ExpDesc bitop;
            BC::singleVar(cs, &bitop, "__ls_bnot");

            utArray<Expression *> exprs;
            exprs.push_back(expression->subExpression);
            generateCall(&bitop, &exprs, NULL);

            expression->e = bitop;
            return expression;
        }
    }

    return expression;
}


Expression *JitTypeCompiler::visit(VariableExpression *expression)
{
    for (UTsize i = 0; i < expression->declarations->size(); i++)
    {
        VariableDeclaration *v = expression->declarations->at(i);
        v->visitExpression(this);
        //BC::expToNextReg(cs->fs, &v->identifier->e);
        expression->e = v->identifier->e;
    }

    return expression;
}


Expression *JitTypeCompiler::visit(SuperExpression *expression)
{
    lmAssert(currentMethod, "Super call outside of method");

    Type *type     = currentMethod->getDeclaringType();
    Type *baseType = type->getBaseType();

    //FIXME:  issue a warning
    if (!baseType)
    {
        return expression;
    }

    FuncState *fs = cs->fs;

    if (currentMethod->isConstructor())
    {
        ConstructorInfo *base = baseType->getConstructor();

        //FIXME: warn if no base constructor
        if (!base)
        {
            return expression;
        }

        // load up base class
        ExpDesc eclass;
        BC::singleVar(cs, &eclass, baseType->getFullName().c_str());

        // index with the __ls_constructor
        BC::expToNextReg(fs, &eclass);

        ExpDesc fname;
        BC::expString(cs, &fname, "__ls_constructor");

        BC::expToNextReg(fs, &fname);
        BC::expToVal(fs, &fname);
        BC::indexed(fs, &eclass, &fname);

        // call the LSMethod
        generateCall(&eclass, &expression->arguments);
    }
    else
    {
        utString name = currentMethod->getName();

        if (expression->method)
        {
            name = expression->method->string;
        }

        MemberInfo *mi = baseType->findMember(name.c_str());
        //FIXME: warn
        if (!mi)
        {
            return expression;
        }

        lmAssert(mi->isMethod(), "super call on non-method");

        MethodInfo *methodInfo = (MethodInfo *)mi;

        // load up declaring class
        ExpDesc eclass;
        BC::singleVar(cs, &eclass,
                      methodInfo->getDeclaringType()->getFullName().c_str());

        BC::expToNextReg(fs, &eclass);

        ExpDesc fname;
        BC::expString(cs, &fname, name.c_str());

        BC::expToNextReg(fs, &fname);
        BC::expToVal(fs, &fname);
        BC::indexed(fs, &eclass, &fname);

        // call the LSMethod
        generateCall(&eclass, &expression->arguments);

        expression->e = eclass;
    }

    return expression;
}


Expression *JitTypeCompiler::visit(VariableDeclaration *declaration)
{
    FuncState *fs = cs->fs;

    // local variable declaration
    lmAssert(!declaration->classDecl, "Local variable belongs to class");

    ExpDesc v;
    BC::singleVar(cs, &v, declaration->identifier->string.c_str());

    Type       *dt     = declaration->type;
    MethodInfo *method = NULL;
    method = (MethodInfo *)dt->findMember("__op_assignment");

    //TODO: assignment overload in default args?
    if (declaration->isParameter)
    {
        method = NULL;
    }

    if (method)
    {
        if (dt->isStruct())
        {
            generateVarDeclStruct(declaration);
        }
        else if (dt->isDelegate())
        {
            generateVarDeclDelegate(declaration);
        }
        else
        {
            lmAssert(0, "unexpected __op_assignment on non delegate or struct");
        }

        return declaration;
    }

    else
    {
        lmAssert(!dt->isDelegate() && !dt->isStruct(),
                 "unexpected delegate/struct");

        fs->freereg = fs->nactvar; /* free registers */
        declaration->identifier->visitExpression(this);
        declaration->initializer->visitExpression(this);
        BC::storeVar(fs, &declaration->identifier->e,
                     &declaration->initializer->e);
    }

    return declaration;
}


//
// literals
//

Expression *JitTypeCompiler::visit(ThisLiteral *literal)
{
    BC::singleVar(cs, &literal->e, "this");

    return literal;
}


Expression *JitTypeCompiler::visit(NullLiteral *literal)
{
    BC::initExpDesc(&literal->e, VKNIL, 0);

    return literal;
}


Expression *JitTypeCompiler::visit(BooleanLiteral *literal)
{
    if (literal->value)
    {
        BC::initExpDesc(&literal->e, VKTRUE, 0);
    }
    else
    {
        BC::initExpDesc(&literal->e, VKFALSE, 0);
    }

    return literal;
}


Expression *JitTypeCompiler::visit(NumberLiteral *literal)
{
    ExpDesc e;
    BC::initExpDesc(&e, VKNUM, 0);

    setnumV(&e.u.nval, literal->value);

    literal->e = e;

    return literal;
}


Expression *JitTypeCompiler::visit(ArrayLiteral *literal)
{
    lmAssert(0, "ArrayLiteral");
    return literal;
}


void JitTypeCompiler::functionBody(ExpDesc *e, FunctionLiteral *flit,
                                   int line)
{
    FuncState fs, *pfs = cs->fs;
    GCproto   *pt;
    ptrdiff_t oldbase = pfs->bcbase - cs->bcstack;

    BC::openFunction(cs, &fs);

    fs.linedefined = line;
    fs.numparams   = (uint8_t)parList(flit, false);
    fs.bcbase      = pfs->bcbase + pfs->pc;
    fs.bclim       = pfs->bclim - pfs->pc;
    bcemit_AD(&fs, BC_FUNCF, 0, 0);
    /* Placeholder. */

    // setup closure info here so it is captured as an upvalue
    char funcinfo[256];
    snprintf(funcinfo, 250, "__ls_funcinfo_numargs_%i", flit->childIndex);
    ExpDesc finfo;
    BC::singleVar(cs, &finfo, funcinfo);

    declareLocalVariables(flit);

    chunk(flit->statements);

    BC::closeFunction(cs, cs->lineNumber);

    pt = cs->proto;

    pfs->bcbase = cs->bcstack + oldbase; /* May have been reallocated. */
    pfs->bclim  = (BCPos)(cs->sizebcstack - oldbase);
    /* Store new prototype in the constant array of the parent. */
    BC::initExpDesc(e, VRELOCABLE,
                    bcemit_AD(pfs, BC_FNEW, 0, BC::constGC(pfs, obj2gco(pt), LJ_TPROTO)));

#if LJ_HASFFI
    pfs->flags |= (fs.flags & PROTO_FFI);
#endif
    if (!(pfs->flags & PROTO_CHILD))
    {
        if (pfs->flags & PROTO_HAS_RETURN)
        {
            pfs->flags |= PROTO_FIXUP_RETURN;
        }
        pfs->flags |= PROTO_CHILD;
    }
}


static int functioncount = 0;

Expression *JitTypeCompiler::visit(FunctionLiteral *literal)
{
    lmAssert(!literal->classDecl, "Local function belongs to class");

    FunctionLiteral *lastFunctionLiteral = currentFunctionLiteral;
    currentFunctionLiteral = literal;

    inLocalFunction++;

    char funcname[256];
    sprintf(funcname, "__ls_localfunction%i", functioncount++);

    ExpDesc   v, b;
    FuncState *fs = cs->fs;
    BC::newLocalVar(cs, funcname, 0);

    BC::initExpDesc(&v, VLOCAL, fs->freereg);
    BC::regReserve(fs, 1);
    BC::adjustLocalVars(cs, 1);

    // store funcinfo
    // setup closure info here so it is captured as an upvalue, must be unique
    char funcinfo[256];
    snprintf(funcinfo, 250, "__ls_funcinfo_numargs_%i", literal->childIndex);

    ExpDesc funcInfo;
    ExpDesc value;
    BC::singleVar(cs, &funcInfo, funcinfo);

    BC::initExpDesc(&value, VKNUM, 0);
    setnumV(&value.u.nval, 0);

    if (literal->parameters)
    {
        setnumV(&value.u.nval, (int)literal->parameters->size());
    }

    BC::storeVar(cs->fs, &funcInfo, &value);


    functionBody(&b, literal, cs->lineNumber);

    BC::emitStore(fs, &v, &b);
    //The upvalue is in scope, but the local is only valid after the store.
    var_get(cs, fs, fs->nactvar - 1).startpc = fs->pc;

    literal->e = v;

    inLocalFunction--;
    currentFunctionLiteral = lastFunctionLiteral;

    return literal;
}


Expression *JitTypeCompiler::visit(ObjectLiteral *literal)
{
    lmAssert(0, "ObjectLiteral");
    return literal;
}


Expression *JitTypeCompiler::visit(ObjectLiteralProperty *property)
{
    lmAssert(0, "ObjectLiteralProperty");
    return property;
}


Expression *JitTypeCompiler::visit(PropertyLiteral *property)
{
    lmAssert(0, "PropertyLiteral");
    return property;
}


Expression *JitTypeCompiler::visit(DictionaryLiteralPair *pair)
{
    return pair;
}


Expression *JitTypeCompiler::visit(DictionaryLiteral *literal)
{
    FuncState *fs = cs->fs;

    for (UTsize i = 0; i < literal->pairs.size(); i++)
    {
        DictionaryLiteralPair *pair = literal->pairs[i];

        // comes in from NewExpression visitor
        ExpDesc ethis = literal->e;

        BC::expToNextReg(fs, &ethis);

        pair->key->visitExpression(this);

        BC::expToNextReg(fs, &pair->key->e);
        BC::expToVal(fs, &pair->key->e);
        BC::indexed(fs, &ethis, &pair->key->e);

        pair->value->visitExpression(this);
        BC::storeVar(fs, &ethis, &pair->value->e);
    }

    return literal;
}


bool JitTypeCompiler::castBool(Expression *expr, ExpDesc *e)
{
    lmAssert(expr->type, "Untyped expression");

    *e = expr->e;

    // save off our restore register
    int restore = cs->fs->freereg;

    BCReg result = -1;

    if (e->k == VCALL)
    {
        result = cs->fs->freereg - 1;
    }
    else if (e->k == VINDEXED)
    {
        // discharge to register
        BC::expToNextReg(cs->fs, e);
        // result goes into this register
        result = cs->fs->freereg - 1;
        // and restore needs to shift
        restore = cs->fs->freereg;
    }
    else
    {
        BC::expToNextReg(cs->fs, e);
    }

    if (expr->type->getFullName() == "system.Number")
    {
        // (v) && (v != 0)

        // null and 0 are false!
        ExpDesc value = *e;
        BC::emitBinOpLeft(cs->fs, OPR_AND, &value);
        ExpDesc top = value;

        value = *e;
        BC::emitBinOpLeft(cs->fs, OPR_NE, &value);

        ExpDesc n;
        BC::initExpDesc(&n, VKNUM, 0);
        setnumV(&n.u.nval, 0.0);

        BC::emitBinOp(cs->fs, OPR_NE, &value, &n);
        BC::emitBinOp(cs->fs, OPR_AND, &top, &value);

        *e = top;

        if (result != -1)
        {
            BC::expFree(cs->fs, &expr->e);
            BC::expToReg(cs->fs, e, result);
            expr->e = *e;
        }

        cs->fs->freereg = restore;

        return true;
    }
    else if (expr->type->getFullName() == "system.String")
    {
        // (v) && (v != "")

        // null and empty string are false!
        ExpDesc value = *e;
        BC::emitBinOpLeft(cs->fs, OPR_AND, &value);
        ExpDesc top = value;

        value = *e;
        BC::emitBinOpLeft(cs->fs, OPR_NE, &value);

        ExpDesc emptyString;
        BC::expString(cs, &emptyString, "");

        BC::emitBinOp(cs->fs, OPR_NE, &value, &emptyString);
        BC::emitBinOp(cs->fs, OPR_AND, &top, &value);

        *e = top;

        if (result != -1)
        {
            BC::expFree(cs->fs, &expr->e);
            BC::expToReg(cs->fs, e, result);
            expr->e = *e;
        }

        cs->fs->freereg = restore;

        return true;
    }
    else if (expr->type->getFullName() == "system.Object")
    {
        // (v) && (v != 0) && (v != "")

        ExpDesc value = *e;
        BC::emitBinOpLeft(cs->fs, OPR_AND, &value);

        ExpDesc nvalue = *e;
        BC::emitBinOpLeft(cs->fs, OPR_NE, &nvalue);
        ExpDesc n;
        BC::initExpDesc(&n, VKNUM, 0);
        setnumV(&n.u.nval, 0.0);
        BC::emitBinOp(cs->fs, OPR_NE, &nvalue, &n);

        BC::emitBinOpLeft(cs->fs, OPR_AND, &nvalue);

        ExpDesc svalue = *e;
        BC::emitBinOpLeft(cs->fs, OPR_NE, &svalue);
        ExpDesc emptyString;
        BC::expString(cs, &emptyString, "");
        BC::emitBinOp(cs->fs, OPR_NE, &svalue, &emptyString);

        BC::emitBinOp(cs->fs, OPR_AND, &nvalue, &svalue);

        BC::emitBinOp(cs->fs, OPR_AND, &value, &nvalue);

        *e = value;

        if (result != -1)
        {
            BC::expFree(cs->fs, &expr->e);
            BC::expToReg(cs->fs, e, result);
            expr->e = *e;
        }

        cs->fs->freereg = restore;

        return true;
    }

    return false;
}


BCPos JitTypeCompiler::encodeCondition(Expression *expr)
{
    lmAssert(expr->type, "Untyped Condition");

    expr->visitExpression(this);

    ExpDesc e;
    castBool(expr, &e);

    BCPos pos = BC::cond(cs, &e);

    return pos;
}
}
#endif
