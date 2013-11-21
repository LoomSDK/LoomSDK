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

// on msvc, necessry to include this before stdint.h which gets brought in through lua includes
#ifdef _MSC_VER
#undef _HAS_EXCEPTIONS
#include <typeinfo>
#include <new>
#endif

extern "C" {
#include "lstring.h"
#include "ldo.h"
#include "lfunc.h"
#include "ltable.h"
#include "lundump.h"
}

#include "loom/common/core/assert.h"
#include "loom/script/compiler/lsCompiler.h"
#include "loom/script/compiler/lsCompilerLog.h"
#include "loom/script/compiler/lsTypeCompiler.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"
#include "loom/script/runtime/lsRuntime.h"

namespace LS {
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


ByteCode *TypeCompiler::generateByteCode(Proto *proto)
{
    utArray<unsigned char> bc;
    // always include debug info
    luaU_dump(L, proto, luaByteCodewriter, &bc, 0);
    return ByteCode::encode64(bc);
}


void TypeCompiler::initCodeState(CodeState *codeState, FuncState *funcState,
                                 const utString& source)
{
    memset(codeState, 0, sizeof(CodeState));
    memset(funcState, 0, sizeof(FuncState));

    codeState->L      = vm->VM();
    codeState->source = luaS_new(vm->VM(), source.c_str());

    BC::openFunction(codeState, funcState);

    /* main func. is always vararg */
    funcState->f->is_vararg = VARARG_ISVARARG;
}


void TypeCompiler::closeCodeState(CodeState *codeState)
{
    BC::closeFunction(codeState);
}


void TypeCompiler::enterBlock(FuncState *fs, BlockCnt *bl,
                              lu_byte isbreakable)
{
    bl->breaklist    = NO_JUMP;
    bl->continuelist = NO_JUMP;
    bl->isbreakable  = isbreakable;
    bl->nactvar      = fs->nactvar;
    bl->upval        = 0;
    bl->previous     = fs->bl;
    fs->bl           = bl;
    lua_assert(fs->freereg == fs->nactvar);
}


void TypeCompiler::block(CodeState *cs, Statement *fstat)
{
    FuncState *fs = cs->fs;
    BlockCnt  bl;

    enterBlock(fs, &bl, 0);

    // was chunk
    BC::lineNumber = fstat->lineNumber;
    fstat->visitStatement(this);

    lmAssert(bl.breaklist == NO_JUMP, "Internal Compiler Error");
    leaveBlock(fs);
}


void TypeCompiler::leaveBlock(FuncState *fs)
{
    BlockCnt *bl = fs->bl;

    fs->bl = bl->previous;
    BC::removeVars(fs->cs, bl->nactvar);
    if (bl->upval)
    {
        BC::codeABC(fs, OP_CLOSE, bl->nactvar, 0, 0);
    }
    /* a block either controls scope or breaks (never both) */
    lmAssert(!bl->isbreakable || !bl->upval, "Internal Compiler Error");
    lmAssert(bl->nactvar == fs->nactvar, "Internal Compiler Error");
    fs->freereg = fs->nactvar; /* free registers */
    BC::patchToHere(fs, bl->breaklist);
}


void TypeCompiler::chunk(utArray<Statement *> *statements)
{
    if (!statements)
    {
        return;
    }

    BC::enterLevel(cs);

    for (unsigned int i = 0; i < statements->size(); i++)
    {
        Statement *statement = statements->at(i);

        BC::lineNumber = statement->lineNumber;

        statement->visitStatement(this);

        cs->fs->freereg = cs->fs->nactvar; /* free registers */
    }

    BC::leaveLevel(cs);
}


int TypeCompiler::parList(FunctionLiteral *literal, bool method)
{
    utArray<VariableDeclaration *> *parms = literal->parameters;

    if (!parms && !method)
    {
        return 0;
    }

    FuncState *fs = cs->fs;
    Proto     *f  = fs->f;

    int nparams = 0;
    f->is_vararg = 0;

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
        f->numparams = cast_byte(fs->nactvar);
        BC::reserveRegs(fs, fs->nactvar); /* reserve register for parameters */
    }

    return nparams;
}


void TypeCompiler::generateMethod(FunctionLiteral *function,
                                  MethodInfo      *method)
{
    currentMethod          = method;
    currentMethodCoroutine = function->isCoroutine;
    currentFunctionLiteral = function;

    CompilationUnit *cunit = cls->pkgDecl->compilationUnit;

    CodeState codeState;
    FuncState funcState;

    initCodeState(&codeState, &funcState, cunit->filename);

    cs = &codeState;

    parList(function, !function->isStatic);

    declareLocalVariables(function);

    // we insert a yield to account for argument passing
    if (function->isCoroutine)
    {
        ExpDesc yield;
        insertYield(&yield);
    }

    visitStatementArray(function->statements);

    closeCodeState(&codeState);

    method->setByteCode(generateByteCode(funcState.f));

    currentMethod          = NULL;
    currentMethodCoroutine = false;
}


void TypeCompiler::generateConstructor(FunctionLiteral *function,
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

    constructor->setByteCode(generateByteCode(funcState.f));

    currentMethod = NULL;
}


void TypeCompiler::compile(ClassDeclaration *classDeclaration)
{
    TypeCompiler compiler;

    compiler.cls = classDeclaration;
    compiler._compile();
}


utArray<Statement *> *TypeCompiler::visitStatementArray(
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


Statement *TypeCompiler::visitStatement(Statement *statement)
{
    if (statement != NULL)
    {
        if (statement->lineNumber)
        {
            lineNumber     = statement->lineNumber;
            BC::lineNumber = statement->lineNumber;
        }
        statement       = statement->visitStatement(this);
        cs->fs->freereg = cs->fs->nactvar; /* free registers */
    }

    return statement;
}


utArray<Expression *> *TypeCompiler::visitExpressionArray(
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


Expression *TypeCompiler::visitExpression(Expression *expression)
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

CompilationUnit *TypeCompiler::visit(CompilationUnit *cunit)
{
    return cunit;
}


//
// statements
//

Statement *TypeCompiler::visit(FunctionDeclaration *declaration)
{
    return declaration;
}


Statement *TypeCompiler::visit(PropertyDeclaration *declaration)
{
    return declaration;
}


Statement *TypeCompiler::visit(BlockStatement *statement)
{
    chunk(statement->statements);

    return statement;
}


Statement *TypeCompiler::visit(BreakStatement *statement)
{
    FuncState *fs   = cs->fs;
    BlockCnt  *bl   = fs->bl;
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

    while (bl && !bl->isbreakable)
    {
        upval |= bl->upval;
        bl     = bl->previous;
    }

    if (!bl)
    {
        LSCompilerLog::logError(cunit->filename.c_str(), statement->lineNumber, "break found outside of a loop!");
        return statement;
    }
    if (upval)
    {
        BC::codeABC(fs, OP_CLOSE, bl->nactvar, 0, 0);
    }

    BC::concat(fs, &bl->breaklist, BC::jump(fs));

    return statement;
}


Statement *TypeCompiler::visit(ContinueStatement *statement)
{
    FuncState *fs   = cs->fs;
    BlockCnt  *bl   = fs->bl;
    int       upval = 0;

    while (bl && !bl->isbreakable)
    {
        upval |= bl->upval;
        bl     = bl->previous;
    }

    if (!bl)
    {
        LSCompilerLog::logError(cunit->filename.c_str(), statement->lineNumber, "continue found outside of a loop!");
        return statement;
    }

    if (upval)
    {
        BC::codeABC(fs, OP_CLOSE, bl->nactvar, 0, 0);
    }

    BC::concat(fs, &bl->continuelist, BC::jump(fs));

    return statement;
}


Statement *TypeCompiler::visit(DoStatement *statement)
{
    FuncState *fs = cs->fs;

    BlockCnt bl;

    int whileinit = BC::getLabel(fs);

    enterBlock(fs, &bl, 1);

    /* statements*/
    statement->statement->visitStatement(this);

    lua_assert(bl.breaklist == NO_JUMP);

    statement->expression->visitExpression(this);
    ExpDesc c        = statement->expression->e;
    int     condexit = BC::cond(cs, &c);

    BC::patchList(fs, BC::jump(fs), whileinit);

    leaveBlock(fs);

    BC::patchToHere(fs, condexit); /* false conditions finish the loop */

    return statement;
}


Statement *TypeCompiler::visit(EmptyStatement *statement)
{
    return statement;
}


Statement *TypeCompiler::visit(ExpressionStatement *statement)
{
    statement->expression->visitExpression(this);

    return statement;
}


Statement *TypeCompiler::visit(ForStatement *statement)
{
    FuncState *fs = cs->fs;
    int       whileinit;
    int       condexit;
    BlockCnt  bl;

    /* initial */
    if (statement->initial)
    {
        statement->initial->visitExpression(this);
    }

    whileinit = BC::getLabel(fs);

    /* condition */
    if (statement->condition)
    {
        statement->condition->visitExpression(this);
    }
    else
    {
        lmAssert(0, "for statement has no condition");
    }


    condexit = BC::cond(cs, &statement->condition->e);

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
        BC::patchToHere(fs, bl.continuelist);

        es->visitStatement(this);

        es->expression = NULL;
        delete es;

        es = NULL;
    }

    lua_assert(bl.breaklist == NO_JUMP);

    BC::patchList(fs, BC::jump(fs), whileinit);
    leaveBlock(fs);

    BC::patchToHere(fs, condexit); /* false conditions finish the loop */

    return statement;
}


Statement *TypeCompiler::visit(ForInStatement *statement)
{
    FuncState *fs   = cs->fs;
    int       nvars = 0;
    int       line;

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
        BC::reserveRegs(fs, 1);
        BC::adjustLocalVars(cs, 1);
    }
    else
    {
        lmAssert(0, "Unknown variable statement in for..in initializer");
    }

    BlockCnt forbl;
    enterBlock(fs, &forbl, 1); /* scope for loop and control variables */

    int base = fs->freereg;

    /* create control variables */
    BC::newLocalVar(cs, "(for generator)", nvars++);
    BC::newLocalVar(cs, "(for state)", nvars++);
    BC::newLocalVar(cs, "(for control)", nvars++);

    //TODO: It would be nice to have a way to iterate pairs
    if (statement->foreach)
    {
        BC::newLocalVar(cs, "__ls_key", nvars++);
    }

    /* create declared variables */
    BC::newLocalVar(cs, vname, nvars++);

    line = lineNumber;

    bool isVector = false;

    if (statement->expression->type->getFullName() == "system.Vector")
    {
        isVector = true;
    }

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

    int cbase = pairs.u.s.info; /* base register for call */

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
        right.u.nval = LSINDEXDICTPAIRS;

        BC::expToNextReg(fs, &arg);
        BC::expToNextReg(fs, &right);
        BC::expToVal(fs, &right);
        BC::indexed(fs, &arg, &right);
    }

    BC::setMultRet(fs, &arg);

    int nparams = 0;

    if (hasmultret(arg.k))
    {
        nparams = LUA_MULTRET; /* open call */
    }
    else
    {
        if (arg.k != VVOID)
        {
            BC::expToNextReg(fs, &arg); /* close last argument */
        }
        nparams = fs->freereg - (cbase + 1);
    }

    BC::initExpDesc(&pairs, VCALL,
                    BC::codeABC(fs, OP_CALL, cbase, nparams + 1,
                                2 /* returns 1 values */));

    fs->freereg = cbase + 1; /* call remove function and arguments and leaves*/

    BC::adjustAssign(cs, 3, 1, &pairs);

    BC::checkStack(fs, 3); /* extra space to call generator */

    /* forbody -> DO block */
    BlockCnt bl;

    int prep, endfor;

    BC::adjustLocalVars(cs, 3); /* control variables */
    prep = BC::jump(fs);
    enterBlock(fs, &bl, 0);     /* scope for declared variables */
    BC::adjustLocalVars(cs, nvars - 3);
    BC::reserveRegs(fs, nvars - 3);
    block(cs, statement->statement);

    if (forIteratorName[0])
    {
        // we need to store
        BC::singleVar(cs, &v, vname);
        BC::singleVar(cs, &fv, forIteratorName);
        BC::storeVar(fs, &fv, &v);
    }

    leaveBlock(fs); /* end of scope for declared variables */

    BC::patchToHere(fs, prep);
    BC::patchToHere(fs, forbl.continuelist); /* patch in continue list for for .. in/ for .. each */

    endfor = BC::codeABC(fs, OP_TFORLOOP, base, 0, nvars - 3);

    BC::fixLine(fs, line); /* pretend that `OP_FOR' starts the loop */

    BC::patchList(fs, BC::jump(fs), prep + 1);

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


Statement *TypeCompiler::visit(IfStatement *statement)
{
    FuncState *fs = cs->fs;
    int       flist;
    int       escapelist = NO_JUMP;

    statement->expression->visitExpression(this);

    BC::expToNextReg(fs, &statement->expression->e);

    flist = BC::cond(cs, &statement->expression->e);

    /*true statement*/
    block(cs, statement->trueStatement);

    Statement *i = statement->falseStatement;

    // else if
    while (i && i->astType == AST_IFSTATEMENT)
    {
        IfStatement *elif = (IfStatement *)i;
        BC::concat(fs, &escapelist, BC::jump(fs));
        BC::patchToHere(fs, flist);
        elif->expression->visitExpression(this);
        BC::expToNextReg(fs, &elif->expression->e);
        flist = BC::cond(cs, &elif->expression->e);
        block(cs, elif->trueStatement);
        i = elif->falseStatement;
    }
    if (i)
    {
        BC::concat(fs, &escapelist, BC::jump(fs));
        BC::patchToHere(fs, flist);
        block(cs, i);
    }
    else
    {
        BC::concat(fs, &escapelist, flist);
    }

    BC::patchToHere(fs, escapelist);

    return statement;
}


Statement *TypeCompiler::visit(LabelledStatement *statement)
{
    return statement;
}


Statement *TypeCompiler::visit(ReturnStatement *statement)
{
    FuncState *fs = cs->fs;

    int first, nret; /* registers with returned values */

    if (!statement->result)
    {
        first = nret = 0; /* return no values */
    }
    else
    {
        ExpDesc e;
        nret = expList(&e, statement->result);

        if (hasmultret(e.k))
        {
            BC::setMultRet(fs, &e);

            // LOOM: No tail calls as they screw up profiling/debugging

            /*
             * if (e.k == VCALL && nret == 1) { // tail call?
             *  SET_OPCODE(getcode(fs,&e), OP_TAILCALL);
             *  lua_assert(GETARG_A(getcode(fs,&e)) == fs->nactvar);
             * }
             */

            first = fs->nactvar;
            nret  = LUA_MULTRET; /* return all values */
        }
        else
        {
            if (nret == 1) /* only one single value? */
            {
                first = BC::expToAnyReg(fs, &e);
            }
            else
            {
                BC::expToNextReg(fs, &e); /* values must go to the `stack' */
                first = fs->nactvar;      /* return all `active' values */
                lua_assert(nret == fs->freereg - first);
            }
        }
    }

    BC::ret(fs, first, nret);

    return statement;
}


Statement *TypeCompiler::visit(CaseStatement *statement)
{
    FuncState *fs = cs->fs;

    int     flist;
    int     escapelist = NO_JUMP;
    ExpDesc swft;
    ExpDesc cexpr;

    if (statement->expression)
    {
        /* outer || switch fallthrough */
        BinOpr ftop = OPR_OR;

        BC::singleVar(cs, &swft, "__ls_swft");

        BC::infix(fs, ftop, &swft);

        /* inner caseexpr == swexpr */
        BinOpr op = OPR_EQ;

        statement->expression->visitExpression(this);
        cexpr = statement->expression->e;

        BC::infix(fs, op, &cexpr);

        ExpDesc swexpr;
        BC::singleVar(cs, &swexpr, "__ls_swexpr");

        BC::posFix(cs->fs, op, &cexpr, &swexpr);

        BC::posFix(cs->fs, ftop, &swft, &cexpr);

        if (cexpr.k == VNIL)
        {
            cexpr.k = VFALSE; /* `falses' are all equal here */
        }
        BC::goIfTrue(fs, &cexpr);
        flist = cexpr.f;
    }
    else
    {
        BC::initExpDesc(&cexpr, VTRUE, 0);
        BC::goIfTrue(fs, &cexpr);
        flist = cexpr.f;
    }

    /*true block*/

    ExpDesc swv;
    BC::singleVar(cs, &swft, "__ls_swft");

    BC::initExpDesc(&swv, VTRUE, 0);

    BC::expToNextReg(fs, &swv);

    BC::storeVar(fs, &swft, &swv);

    BlockCnt bl;
    enterBlock(fs, &bl, 0);

    chunk(statement->statements);

    lua_assert(bl.breaklist == NO_JUMP);
    leaveBlock(fs);

    BC::concat(fs, &escapelist, flist);
    BC::patchToHere(fs, escapelist);

    cs->fs->freereg = cs->fs->nactvar; /* free registers */

    return statement;
}


Statement *TypeCompiler::visit(SwitchStatement *statement)
{
    FuncState *fs = cs->fs;
    BlockCnt  bl;

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

    BC::initExpDesc(&swv, VFALSE, 0);

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


Statement *TypeCompiler::visit(VariableStatement *statement)
{
    for (unsigned int i = 0; i < statement->declarations->size(); i++)
    {
        VariableDeclaration *d = statement->declarations->at(i);
        d->visitExpression(this);
    }

    return statement;
}


Statement *TypeCompiler::visit(WhileStatement *statement)
{
    FuncState *fs = cs->fs;
    int       whileinit;
    int       condexit;
    BlockCnt  bl;

    whileinit = BC::getLabel(fs);

    statement->expression->visitExpression(this);

    condexit = BC::cond(cs, &statement->expression->e);
    enterBlock(fs, &bl, 1);

    block(cs, statement->statement);

    BC::patchToHere(fs, bl.continuelist);

    BC::patchList(fs, BC::jump(fs), whileinit);
    leaveBlock(fs);
    BC::patchToHere(fs, condexit); /* false conditions finish the loop */

    return statement;
}


Statement *TypeCompiler::visit(WithStatement *statement)
{
    return statement;
}


Statement *TypeCompiler::visit(ClassDeclaration *statement)
{
    return statement;
}


Statement *TypeCompiler::visit(InterfaceDeclaration *statement)
{
    return statement;
}


Statement *TypeCompiler::visit(PackageDeclaration *statement)
{
    return statement;
}


Statement *TypeCompiler::visit(ImportStatement *statement)
{
    return statement;
}


//
// expressions
//

Expression *TypeCompiler::visit(MultipleAssignmentExpression *expression)
{
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
        return OPR_LOOM_ADD;
    }

    if (t == &tok->OPERATOR_MINUSASSIGNMENT)
    {
        return OPR_SUB;
    }

    if (t == &tok->OPERATOR_MODULOASSIGNMENT)
    {
        return OPR_MOD;
    }

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

    return OPR_NOBINOPR;
}


Expression *TypeCompiler::visit(AssignmentOperatorExpression *expression)
{
    Tokens *tok = Tokens::getSingletonPtr();
    BinOpr op   = getassignmentopr(expression->type);

    lmAssert(op != OPR_NOBINOPR, "Unknown bin op on AssignentOperatorExpression");

    Expression *eleft  = expression->leftExpression;
    Expression *eright = expression->rightExpression;

    lmAssert(eleft->type, "Untyped error on left expression");

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
            emethod.u.nval = method->getOrdinal();
            BC::expToNextReg(cs->fs, &opcall);
            BC::expToNextReg(cs->fs, &emethod);
            BC::expToVal(cs->fs, &emethod);
            BC::indexed(cs->fs, &opcall, &emethod);

            generateCall(&opcall, &args, method);

            expression->e = opcall;
            return expression;
        }
    }

    eleft->assignment = false;
    eleft->visitExpression(this);

    BC::infix(cs->fs, op, &eleft->e);

    eright->visitExpression(this);
    BC::expToNextReg(cs->fs, &eright->e);

    BC::posFix(cs->fs, op, &eleft->e, &eright->e);

    ExpDesc right = eleft->e;

    BC::expToNextReg(cs->fs, &right);

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
        return OPR_LOOM_ADD;
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

    /*case '^': return OPR_POW;
     * case TK_CONCAT: return OPR_CONCAT;*/
    return OPR_NOBINOPR;
}


// TODO: Unify this with the JIT bc generator binary expressions
// https://theengineco.atlassian.net/browse/LOOM-640
// https://theengineco.atlassian.net/browse/LOOM-641
Expression *TypeCompiler::visit(BinaryOperatorExpression *expression)
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
        lmAssert(eleft->type && eright->type, "Untype expression");

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

        utArray<Expression *> args;
        args.push_back(eleft);
        args.push_back(new StringLiteral(eright->type->getAssembly()->getName().c_str()));
        args.push_back(new NumberLiteral(eright->type->getTypeID()));

        generateCall(&object, &args);

        expression->e = object;

        return expression;
    }

    BinOpr op = getbinopr(expression->op);

    if (op == OPR_LOOM_ADD)
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

        BC::infix(cs->fs, op, &eleft->e);

        // coerce right to string, must be done even for string types as they may be null
        coerceToString(eright);

        // and the binary op
        BC::posFix(cs->fs, op, &eleft->e, &eright->e);
        // save off expression and return
        expression->e = eleft->e;

        return expression;
    }

    eleft->visitExpression(this);

    BC::infix(cs->fs, op, &eleft->e);

    eright->visitExpression(this);

    BC::posFix(cs->fs, op, &eleft->e, &eright->e);

    expression->e = eleft->e;

    // promote to register
    BC::expToNextReg(cs->fs, &expression->e);

    return expression;
}


void TypeCompiler::createVarArg(ExpDesc *varg, utArray<Expression *> *arguments,
                                int startIdx)
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
    v.u.nval = LSINDEXVECTOR;

    BC::expToNextReg(fs, &v);
    BC::expToVal(fs, &v);
    BC::indexed(fs, &vtable, &v);

    BC::expToNextReg(fs, &vtable);

    // store the length of the varargs vector
    ExpDesc elength;
    BC::initExpDesc(&elength, VKNUM, 0);
    elength.u.nval = LSINDEXVECTORLENGTH;

    BC::expToNextReg(fs, &elength);
    BC::expToVal(fs, &elength);
    BC::indexed(fs, &vtable, &elength);

    BC::initExpDesc(&elength, VKNUM, 0);
    elength.u.nval = arguments->size() - startIdx;

    // and store
    BC::storeVar(fs, &vtable, &elength);

    utArray<Expression *> args;
    int length = 0;
    for (UTsize i = startIdx; i < arguments->size(); i++)
    {
        Expression *arg = arguments->at(i);

        int restore = fs->freereg;

        BC::initExpDesc(&v, VKNUM, 0);
        v.u.nval = length;
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

    fs->freereg = reg;

    BC::singleVar(cs, varg, varargname);
}


int TypeCompiler::expList(ExpDesc *e, utArray<Expression *> *expressions,
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
        lmAssert(vararg->position == 0, "Internal Compiler Error");
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


void TypeCompiler::generateCall(ExpDesc *call, utArray<Expression *> *arguments,
                                MethodBase *methodBase)
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
        BC::setMultRet(fs, &args);
    }

    lua_assert(call->k == VNONRELOC);
    int base = call->u.s.info; /* base register for call */

    if (hasmultret(args.k))
    {
        nparams = LUA_MULTRET; /* open call */
    }
    else
    {
        if (args.k != VVOID)
        {
            BC::expToNextReg(fs, &args); /* close last argument */
        }
        nparams = fs->freereg - (base + 1);
    }

    BC::initExpDesc(call, VCALL,
                    BC::codeABC(fs, OP_CALL, base, nparams + 1, 2));

    BC::fixLine(fs, line);

    fs->freereg = base + 1;
}


void TypeCompiler::generatePropertySet(ExpDesc *call, Expression *value,
                                       bool visit)
{
    FuncState *fs = cs->fs;

    int line = lineNumber;

    BC::expToNextReg(fs, call);

    lua_assert(call->k == VNONRELOC);
    int base = call->u.s.info; /* base register for call */

    if (visit)
    {
        value->visitExpression(this);
        BC::expToNextReg(fs, &value->e);
    }
    else
    {
        BC::reserveRegs(fs, 1);
        BC::expToReg(fs, &value->e, fs->freereg - 1);
    }

    int nparams = fs->freereg - (base + 1);

    lmAssert(nparams == 1, "nparams != 1");

    BC::initExpDesc(call, VCALL,
                    BC::codeABC(fs, OP_CALL, base, nparams + 1, 2));

    BC::fixLine(fs, line);

    fs->freereg = base + 1;
}


Expression *TypeCompiler::visit(CallExpression *call)
{
    MethodBase *methodBase = call->methodBase;

    call->function->visitExpression(this);

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
            right.u.nval = method->getOrdinal();

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


Expression *TypeCompiler::visit(ConditionalExpression *conditional)
{
    FuncState *fs = cs->fs;
    int       flist;
    int       escapelist = NO_JUMP;

    int reg = fs->freereg;

    Expression *expr      = conditional->expression;
    Expression *trueExpr  = conditional->trueExpression;
    Expression *falseExpr = conditional->falseExpression;

    expr->visitExpression(this);

    flist = BC::cond(cs, &expr->e);

    /*true statement*/

    BlockCnt bl;
    enterBlock(fs, &bl, 0);
    BC::singleVar(cs, &conditional->e, "__ls_ternary");
    trueExpr->visitExpression(this);
    BC::storeVar(fs, &conditional->e, &trueExpr->e);
    lmAssert(bl.breaklist == NO_JUMP, "Internal Compiler Error");
    leaveBlock(fs);

    fs->freereg = reg;

    /* false statement*/
    BC::concat(fs, &escapelist, BC::jump(fs));
    BC::patchToHere(fs, flist);

    BlockCnt bl2;
    enterBlock(fs, &bl2, 0);
    BC::singleVar(cs, &conditional->e, "__ls_ternary");
    falseExpr->visitExpression(this);
    BC::storeVar(fs, &conditional->e, &falseExpr->e);
    lmAssert(bl.breaklist == NO_JUMP, "Internal Compiler Error");
    leaveBlock(fs);

    BC::patchToHere(fs, escapelist);

    fs->freereg = reg;

    BC::singleVar(cs, &conditional->e, "__ls_ternary");

    return conditional;
}


Expression *TypeCompiler::visit(DeleteExpression *expression)
{
    return expression;
}


Expression *TypeCompiler::visit(LogicalAndExpression *expression)
{
    return visit((BinaryOperatorExpression *)expression);
}


Expression *TypeCompiler::visit(LogicalOrExpression *expression)
{
    return visit((BinaryOperatorExpression *)expression);
}


Expression *TypeCompiler::visit(NewExpression *expression)
{
    FuncState *fs = cs->fs;

    Type *type = expression->function->type;

    lmAssert(type, "untyped new expression");

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


static UnOpr getunopr(int op)
{
    switch (op)
    {
    case '!':
        return OPR_NOT;

    case '-':
        return OPR_MINUS;

    case '~':
        return OPR_LOOM_BITNOT;

    default:
        return OPR_NOUNOPR;
    }
}


Expression *TypeCompiler::visit(UnaryOperatorExpression *expression)
{
    expression->subExpression->visitExpression(this);

    UnOpr op = getunopr(expression->op->value.str()[0]);

    if (op != OPR_NOUNOPR)
    {
        BC::prefix(cs->fs, op, &expression->subExpression->e);
    }

    expression->e = expression->subExpression->e;

    return expression;
}


Expression *TypeCompiler::visit(VariableExpression *expression)
{
    for (UTsize i = 0; i < expression->declarations->size(); i++)
    {
        VariableDeclaration *v = expression->declarations->at(i);
        v->visitExpression(this);
        expression->e = v->identifier->e;
    }

    return expression;
}


Expression *TypeCompiler::visit(SuperExpression *expression)
{
    lmAssert(currentMethod, "super outside of method");

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

        lmAssert(mi->isMethod(), "Non-method in super call");

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


Expression *TypeCompiler::visit(VariableDeclaration *declaration)
{
    FuncState *fs = cs->fs;

    // local variable declaration
    lmAssert(!declaration->classDecl, "local variable declaration belongs to a class");

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
            error("unexpected __op_assignment on non delegate or struct");
        }

        return declaration;
    }

    else
    {
        lmAssert(!dt->isDelegate() && !dt->isStruct(), "unexpected delegate/struct");

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

Expression *TypeCompiler::visit(ThisLiteral *literal)
{
    BC::singleVar(cs, &literal->e, "this");

    return literal;
}


Expression *TypeCompiler::visit(NullLiteral *literal)
{
    BC::initExpDesc(&literal->e, VNIL, 0);

    return literal;
}


Expression *TypeCompiler::visit(BooleanLiteral *literal)
{
    if (literal->value)
    {
        BC::initExpDesc(&literal->e, VTRUE, 0);
    }
    else
    {
        BC::initExpDesc(&literal->e, VFALSE, 0);
    }

    return literal;
}


Expression *TypeCompiler::visit(NumberLiteral *literal)
{
    ExpDesc e;
    BC::initExpDesc(&e, VKNUM, 0);

    e.u.nval = literal->value;

    literal->e = e;

    return literal;
}


Expression *TypeCompiler::visit(ArrayLiteral *literal)
{
    return literal;
}


static int functioncount = 0;

void TypeCompiler::functionBody(ExpDesc *e, FunctionLiteral *flit, int line)
{
    FuncState new_fs;

    BC::openFunction(cs, &new_fs);

    new_fs.f->linedefined = line;

    parList(flit, false);

    // setup closure info here so it is captured as an upvalue
    char funcinfo[256];
    snprintf(funcinfo, 250, "__ls_funcinfo_arginfo_%i", flit->childIndex);
    ExpDesc finfo;
    BC::singleVar(cs, &finfo, funcinfo);

    declareLocalVariables(flit);

    chunk(flit->statements);

    new_fs.f->lastlinedefined = flit->lineNumber;

    BC::closeFunction(cs);

    BC::pushClosure(cs, &new_fs, e);
}


Expression *TypeCompiler::visit(FunctionLiteral *literal)
{
    lmAssert(!literal->classDecl, "local function belongs to a class");

    inLocalFunction++;
    FunctionLiteral *lastFunctionLiteral = currentFunctionLiteral;
    currentFunctionLiteral = literal;

    char funcname[256];
    snprintf(funcname, 250, "__ls_localfunction%i", functioncount++);

    ExpDesc v;
    BC::newLocalVar(cs, funcname, 0);
    BC::initExpDesc(&v, VLOCAL, cs->fs->freereg);
    BC::reserveRegs(cs->fs, 1);
    BC::adjustLocalVars(cs, 1);

    // store funcinfo
    // setup closure info here so it is captured as upvalues, must be unique
    char funcinfo[256];
    snprintf(funcinfo, 250, "__ls_funcinfo_arginfo_%i", literal->childIndex);

    ExpDesc funcInfo;
    ExpDesc value;
    BC::singleVar(cs, &funcInfo, funcinfo);
    BC::initExpDesc(&value, VKNUM, 0);
    value.u.nval = 0;

    unsigned int nparams = 0;
    unsigned int varArgIdx = 0xFFFF;

    if (literal->parameters)
    {
        nparams = (unsigned int) literal->parameters->size();

        // run through parameters looking for varargs
        for (unsigned int i = 0; i < (unsigned int) literal->parameters->size(); i++)
        {
            VariableDeclaration *param = literal->parameters->at(i);
            if (param->isVarArg)
            {
                varArgIdx = i;
                break;
            }
        }

    }

    // compress number of parameters and varargs info into 32 bits
    value.u.nval = (nparams << 16) | varArgIdx;

    BC::storeVar(cs->fs, &funcInfo, &value);

    ExpDesc closure;
    functionBody(&closure, literal, literal->lineNumber);

    BC::storeVar(cs->fs, &v, &closure);

    literal->e = v;

    inLocalFunction--;
    currentFunctionLiteral = lastFunctionLiteral;

    return literal;
}


Expression *TypeCompiler::visit(ObjectLiteral *literal)
{
    return literal;
}


Expression *TypeCompiler::visit(ObjectLiteralProperty *property)
{
    return property;
}


Expression *TypeCompiler::visit(PropertyLiteral *property)
{
    return property;
}


Expression *TypeCompiler::visit(DictionaryLiteralPair *pair)
{
    return pair;
}


Expression *TypeCompiler::visit(DictionaryLiteral *literal)
{
    FuncState *fs = cs->fs;

    for (UTsize i = 0; i < literal->pairs.size(); i++)
    {
        int restore = fs->freereg;

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

        fs->freereg = restore;
    }

    return literal;
}
}
#endif
