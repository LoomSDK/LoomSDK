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

#ifndef _lstypecompiler_h
#define _lstypecompiler_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/compiler/lsTypeCompilerBase.h"
#include "loom/script/compiler/lsAST.h"

#include "loom/script/compiler/lsBC.h"

#include "loom/script/runtime/lsLuaState.h"

namespace LS {
class TypeCompiler : public TypeCompilerBase  {

    int parList(FunctionLiteral *function, bool method);

    void initCodeState(CodeState *codeState, FuncState *funcState,
                       const utString& source);
    void closeCodeState(CodeState *codeState);

    void enterBlock(FuncState *fs, BlockCnt *bl, lu_byte isbreakable);
    void block(CodeState *cs, Statement *fstat);
    void leaveBlock(FuncState *fs);
    void chunk(utArray<Statement *> *statements);

    void functionBody(ExpDesc *e, FunctionLiteral *flit, int line);

    ByteCode *generateByteCode(Proto *proto, bool debug);

    void createVarArg(ExpDesc *varg, utArray<Expression *> *arguments,
                      int startIdx);

    void generateCall(ExpDesc *call, utArray<Expression *> *arguments,
                      MethodBase *methodBase = NULL);
    void generatePropertySet(ExpDesc *call, Expression *value,
                             bool visit = true);

    void generateConstructor(FunctionLiteral *function,
                             ConstructorInfo *method);
    void generateMethod(FunctionLiteral *function, MethodInfo *method);

    TypeCompiler()
    {
    }

public:

    static void compile(ClassDeclaration *classDeclaration);

    Statement *visitStatement(Statement *statement);

    //
    // statements
    //

    Statement *visit(BreakStatement *statement);

    Statement *visit(CaseStatement *statement);

    Statement *visit(ContinueStatement *statement);

    Statement *visit(DoStatement *statement);

    Statement *visit(ForStatement *statement);

    Statement *visit(ForInStatement *statement);

    Statement *visit(IfStatement *statement);

    Statement *visit(ReturnStatement *statement);

    Statement *visit(SwitchStatement *statement);

    Statement *visit(WhileStatement *statement);

    //
    // expressions
    //

    Expression *visit(AssignmentOperatorExpression *expression);

    Expression *visit(BinaryOperatorExpression *expression);

    Expression *visit(ConditionalExpression *expression);

    Expression *visit(UnaryOperatorExpression *expression);

    //
    // literals
    //


    Expression *visit(FunctionLiteral *literal);
};
}
#endif //LOOM_ENABLE_JIT
#endif
