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

#ifndef _lsjittypecompiler_h
#define _lsjittypecompiler_h


#include "loom/common/utils/utAssert.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/compiler/lsVisitor.h"
#include "loom/script/compiler/lsAST.h"

#include "loom/script/runtime/lsLuaState.h"

#include "loom/script/compiler/lsTypeCompilerBase.h"

namespace LS {
class JitTypeCompiler : public TypeCompilerBase {
    void initCodeState(CodeState *codeState, FuncState *funcState, const utString& source);

    void closeCodeState(CodeState *codeState);

    void block(CodeState *cs, Statement *fstat);
    void chunk(utArray<Statement *> *statements);

    void enterBlock(FuncState *fs, FuncScope *bl, int isbreakable);
    void leaveBlock(FuncState *fs);

    void createVarArg(ExpDesc *varg, utArray<Expression *> *arguments,
                      int startIdx);

    void generatePropertySet(ExpDesc *call, Expression *value, bool visit = true);

    const char *getBitOpFunctionName(BitOpr b);


    void functionBody(ExpDesc *e, FunctionLiteral *flit, int line);

    int parList(FunctionLiteral *literal, bool method);
    int expList(ExpDesc *e, utArray<Expression *> *expressions,
                MethodBase *methodBase = NULL);
    void generateCall(ExpDesc *call, utArray<Expression *> *arguments,
                      MethodBase *methodBase = NULL);

    virtual void generateConstructor(FunctionLiteral *function,
                                     ConstructorInfo *method);
    virtual void generateMethod(FunctionLiteral *function, MethodInfo *method);

    /*
     * The LuaJIT VM considers 0 and "" to be true.  As we do not want to modify the LuaJIT VM
     * we must implicitly convert cast boolean tests of Numbers, String, and Object so that
     * 0 == false, "" == false, and null == false.  Casting Object is necessary as this may hold
     * a number, string, or instance and we don't know which until runtime
     */
    bool castBool(Expression *expr, ExpDesc *e);

    /*
     * Encodes a conditional posiiton jump casting the expression to a bool if necessary
     */
    BCPos encodeCondition(Expression *expr);

    ByteCode *generateByteCode(GCproto *proto);

public:

    JitTypeCompiler()
    {
    }

    static void compile(ClassDeclaration *classDeclaration);

    utArray<Statement *> *visitStatementArray(
        utArray<Statement *> *_statements);

    Statement *visitStatement(Statement *statement);

    utArray<Expression *> *visitExpressionArray(
        utArray<Expression *> *_expressions);

    Expression *visitExpression(Expression *expression);

    //
    // nodes
    //

    CompilationUnit *visit(CompilationUnit *cunit);

    //
    // statements
    //

    Statement *visit(FunctionDeclaration *declaration);

    Statement *visit(PropertyDeclaration *declaration);

    Statement *visit(BlockStatement *statement);

    Statement *visit(BreakStatement *statement);

    Statement *visit(CaseStatement *statement);

    Statement *visit(ContinueStatement *statement);

    Statement *visit(DoStatement *statement);

    Statement *visit(EmptyStatement *statement);

    Statement *visit(ExpressionStatement *statement);

    Statement *visit(ForStatement *statement);

    Statement *visit(ForInStatement *statement);

    Statement *visit(IfStatement *statement);

    Statement *visit(LabelledStatement *statement);

    Statement *visit(ReturnStatement *statement);

    Statement *visit(SwitchStatement *statement);

    Statement *visit(VariableStatement *statement);

    Statement *visit(WhileStatement *statement);

    Statement *visit(WithStatement *statement);

    Statement *visit(ClassDeclaration *statement);

    Statement *visit(InterfaceDeclaration *statement);

    Statement *visit(PackageDeclaration *statement);

    Statement *visit(ImportStatement *statement);

    //
    // expressions
    //

    Expression *visit(MultipleAssignmentExpression *expression);

    Expression *visit(AssignmentOperatorExpression *expression);

    Expression *visit(BinaryOperatorExpression *expression);

    Expression *visit(CallExpression *expression);

    Expression *visit(ConditionalExpression *expression);

    Expression *visit(DeleteExpression *expression);

    Expression *visit(LogicalAndExpression *expression);

    Expression *visit(LogicalOrExpression *expression);

    Expression *visit(NewExpression *expression);

    Expression *visit(UnaryOperatorExpression *expression);

    Expression *visit(VariableExpression *expression);

    Expression *visit(SuperExpression *expression);

    Expression *visit(VariableDeclaration *declaration);

    //
    // literals
    //

    Expression *visit(ThisLiteral *literal);

    Expression *visit(NullLiteral *literal);

    Expression *visit(BooleanLiteral *literal);

    Expression *visit(NumberLiteral *literal);

    Expression *visit(ArrayLiteral *literal);

    Expression *visit(FunctionLiteral *literal);

    Expression *visit(ObjectLiteral *literal);

    Expression *visit(ObjectLiteralProperty *property);

    Expression *visit(PropertyLiteral *property);

    Expression *visit(DictionaryLiteralPair *pair);

    Expression *visit(DictionaryLiteral *literal);
};
}
#endif //LOOM_ENABLE_JIT
#endif
