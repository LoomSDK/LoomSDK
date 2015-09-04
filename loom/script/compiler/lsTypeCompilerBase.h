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

#ifndef _lstypecompilerbase_h
#define _lstypecompilerbase_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/compiler/lsVisitor.h"
#include "loom/script/compiler/lsAST.h"

#include "loom/script/runtime/lsLuaState.h"

#ifdef LOOM_ENABLE_JIT
#include "lsJitBC.h"
#else
#include "lsBC.h"
#endif

namespace LS {
class TypeCompilerBase : public Visitor {
protected:

    // the current class being compiled
    ClassDeclaration *cls;

    // the current compilation unit (source file)
    CompilationUnit *cunit;

    // the Lua VM used in compilation
    LSLuaState *vm;
    lua_State  *L;

    // the current line number
    int lineNumber;

    // the code state
    CodeState *cs;

    // the current method beding compiled
    MethodBase *currentMethod;

    // if the current method has a yield statement, this will be true
    bool currentMethodCoroutine;

    // This will be true when compiling a local/anonymous function to bytecode
    int inLocalFunction;

    // the current function being compiled
    FunctionLiteral *currentFunctionLiteral;

    // for..in loops use always use a local var to satisfy the Lua VM as
    // well as for performance reasons.  In the case of the loop using a var
    // from a parent code block this causes an issue when wanting to use the
    // the value of the iterator variable outside of the loop block
    // therefore, we store the current value of the iterator variable to this upon
    // break/loop exit and then copy the value into the parent blocks value
    const char *currentForInIteratorName;

    TypeCompilerBase() : cls(NULL), vm(NULL), L(NULL), cs(NULL), currentMethod(NULL),
                         currentMethodCoroutine(false), inLocalFunction(0), currentFunctionLiteral(NULL),
                         currentForInIteratorName(NULL)
    {
    }

    // Bytecode output helper
    static int luaByteCodewriter(lua_State *L, const void *p, size_t size,
                                 void *u);

    virtual void _compile();

    virtual void initCodeState(CodeState *codeState, FuncState *funcState, const utString& source) = 0;
    virtual void closeCodeState(CodeState *codeState) = 0;

    virtual void generateCall(ExpDesc *call, utArray<Expression *> *arguments, MethodBase *methodBase = NULL) = 0;


    virtual void generateConstructor(FunctionLiteral *function,
                                     ConstructorInfo *method) = 0;

    virtual void generateMethod(FunctionLiteral *function, MethodInfo *method) = 0;

    void createInstance(ExpDesc *expr, const utString& className, utArray<Expression *> *arguments);

    void generateIdentifierTypeConversion(Identifier *identifier);

    Expression *visit(PropertyExpression *expression);

    void insertYield(ExpDesc *yield, utArray<Expression *> *arguments = NULL);

    Expression *visit(YieldExpression *expression);
    Expression *visit(VectorLiteral *vector);
    Expression *visit(IncrementExpression *expression);

    // Visit an array of statements in order, calling visitStatement on each.
    utArray<Statement *> *visitStatementArray(utArray<Statement *> *_statements);
    virtual Statement *visitStatement(Statement *statement)=0;

    // Helpers to visit an array of expressions.
    utArray<Expression *> *visitExpressionArray(utArray<Expression *> *_expressions);
    Expression *visitExpression(Expression *expression);

    // Assorted common visit implementations. Most of these pass through or error
    // as they are syntactic elements that aren't important for us.
    CompilationUnit *visit(CompilationUnit *cunit);
    Statement *visit(FunctionDeclaration *declaration);
    Statement *visit(PropertyDeclaration *declaration);
    Statement *visit(BlockStatement *statement);
    Statement *visit(EmptyStatement *statement);
    Statement *visit(ExpressionStatement *statement);
    Statement *visit(LabelledStatement *statement);
    Statement *visit(VariableStatement *statement);
    Statement *visit(WithStatement *statement);
    Statement *visit(ClassDeclaration *statement);
    Statement *visit(InterfaceDeclaration *statement);
    Statement *visit(PackageDeclaration *statement);
    Statement *visit(ImportStatement *statement);
    Expression *visit(MultipleAssignmentExpression *expression);
    Expression *visit(DeleteExpression *expression);
    Expression *visit(LogicalAndExpression *expression);
    Expression *visit(LogicalOrExpression *expression);
    Expression *visit(ArrayLiteral *literal);
    Expression *visit(ObjectLiteral *literal);
    Expression *visit(ObjectLiteralProperty *property);
    Expression *visit(PropertyLiteral *property);
    Expression *visit(DictionaryLiteralPair *pair);

    // More substantial common visitors.
    Expression *visit(VariableExpression *expression);
    Expression *visit(SuperExpression *expression);
    Expression *visit(VariableDeclaration *declaration);
    Expression *visit(ThisLiteral *literal);
    Expression *visit(NullLiteral *literal);
    Expression *visit(BooleanLiteral *literal);
    Expression *visit(NumberLiteral *literal);
    Expression *visit(DictionaryLiteral *literal);
    Expression *visit(CallExpression *literal);
    Expression *visit(NewExpression *expression);
    virtual Expression *visit(BinaryOperatorExpression *expression)=0;

    // Common helpers
    void createVarArg(ExpDesc *varg, utArray<Expression *> *arguments,
                      int startIdx);
    int expList(ExpDesc *e, utArray<Expression *> *expressions, MethodBase *methodBase);

    // Visit a chunk of statements in order and emit bytecode for them.
    virtual void chunk(utArray<Statement *> *statements)=0;

    // struct
    void setupVarDecl(ExpDesc *out, VariableDeclaration *declaration);
    void generateVarDeclStruct(VariableDeclaration *declaration);
    void generateAssignmentOperatorCall(MethodInfo *method, Expression *eleft, Expression *eright);

    virtual void generatePropertySet(ExpDesc *call, Expression *value, bool visit) = 0;
    void generateVarDeclDelegate(VariableDeclaration *declaration);

    Expression *visit(AssignmentExpression *expression);
    Expression *visit(Identifier *literal);
    Expression *visit(StringLiteral *literal);
    Statement *visit(ThrowStatement *statement);
    Statement *visit(TryStatement *statement);
    Expression *visitSuperProperty(Identifier *identifier);

    // coerce an expression to a string, storing in its expression (e) field
    void coerceToString(Expression *expression);

    // convenience method to set an instance/static member info from an existing localVar
    void storeLocalToMember(MemberInfo *memberInfo, const char *localVar);

    // LoomScript local variables are "front loaded" at the beginning of a function/method
    // as to avoid issues running on the Lua VM as well as to keep compatibiity
    // with AS3's lack of block level scoping
    void declareLocalVariables(FunctionLiteral *literal);

    void generateStaticInitializer();
    void generateInstanceInitializer();

#if LOOM_ENABLE_JIT
    virtual ByteCode *generateByteCode(GCproto *proto, bool debug) = 0;

#else
    virtual ByteCode *generateByteCode(Proto *proto, bool debug) = 0;
#endif

public:
};
}
#endif
