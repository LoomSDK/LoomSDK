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

#ifndef _lsvisitor_h
#define _lsvisitor_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"
#include "stdlib.h"
#include "stdio.h"

#include "loom/script/common/lsError.h"

namespace LS {
// forward declarations
// statements
class CompilationUnit;
class Statement;
class FunctionDeclaration;
class PropertyDeclaration;
class BlockStatement;
class BreakStatement;
class CaseStatement;
class ContinueStatement;
class DoStatement;
class EmptyStatement;
class ExpressionStatement;
class ForStatement;
class ForInStatement;
class IfStatement;
class LabelledStatement;
class ReturnStatement;
class SwitchStatement;
class ThrowStatement;
class TryStatement;
class VariableStatement;
class WhileStatement;
class WithStatement;
class ClassDeclaration;
class InterfaceDeclaration;
class PackageDeclaration;
class ImportStatement;

// expressions
class Expression;
class AssignmentExpression;
class MultipleAssignmentExpression;
class AssignmentOperatorExpression;
class BinaryOperatorExpression;
class CallExpression;
class YieldExpression;
class ConditionalExpression;
class DeleteExpression;
class IncrementExpression;
class LogicalAndExpression;
class LogicalOrExpression;
class NewExpression;
class PropertyExpression;
class UnaryOperatorExpression;
class VariableExpression;
class SuperExpression;
class VariableDeclaration;

// literals
class Identifier;
class ThisLiteral;
class NullLiteral;
class BooleanLiteral;
class NumberLiteral;
class StringLiteral;
class ArrayLiteral;
class FunctionLiteral;
class ObjectLiteral;
class ObjectLiteralProperty;
class PropertyLiteral;
class VectorLiteral;
class DictionaryLiteralPair;
class DictionaryLiteral;



class Visitor {
public:

    void error(utString message)
    {
        LSError(message.c_str());
    }

    //
    // nodes
    //

    virtual CompilationUnit *visit(CompilationUnit *cunit) = 0;

    //
    // statements
    //

    virtual Statement *visit(FunctionDeclaration *statement) = 0;
    virtual Statement *visit(PropertyDeclaration *statement) = 0;
    virtual Statement *visit(BlockStatement *statement)      = 0;
    virtual Statement *visit(BreakStatement *statement)      = 0;
    virtual Statement *visit(CaseStatement *statement)       = 0;
    virtual Statement *visit(ContinueStatement *statement)   = 0;
    virtual Statement *visit(DoStatement *statement)         = 0;
    virtual Statement *visit(EmptyStatement *statement)      = 0;
    virtual Statement *visit(ExpressionStatement *statement) = 0;
    virtual Statement *visit(ForStatement *statement)        = 0;
    virtual Statement *visit(ForInStatement *statement)      = 0;
    virtual Statement *visit(IfStatement *statement)         = 0;
    virtual Statement *visit(LabelledStatement *statement)   = 0;
    virtual Statement *visit(ReturnStatement *statement)     = 0;
    virtual Statement *visit(SwitchStatement *statement)     = 0;
    virtual Statement *visit(ThrowStatement *statement)      = 0;
    virtual Statement *visit(TryStatement *statement)        = 0;
    virtual Statement *visit(VariableStatement *statement)   = 0;
    virtual Statement *visit(WhileStatement *statement)      = 0;
    virtual Statement *visit(WithStatement *statement)       = 0;

    virtual Statement *visit(ClassDeclaration *statement)     = 0;
    virtual Statement *visit(InterfaceDeclaration *statement) = 0;
    virtual Statement *visit(PackageDeclaration *statement)   = 0;
    virtual Statement *visit(ImportStatement *statement)      = 0;

    //
    // expressions
    //

    virtual Expression *visit(AssignmentExpression *expression)         = 0;
    virtual Expression *visit(MultipleAssignmentExpression *expression) = 0;
    virtual Expression *visit(AssignmentOperatorExpression *expression) = 0;
    virtual Expression *visit(BinaryOperatorExpression *expression)     = 0;
    virtual Expression *visit(CallExpression *expression)          = 0;
    virtual Expression *visit(YieldExpression *expression)         = 0;
    virtual Expression *visit(ConditionalExpression *expression)   = 0;
    virtual Expression *visit(DeleteExpression *expression)        = 0;
    virtual Expression *visit(IncrementExpression *expression)     = 0;
    virtual Expression *visit(LogicalAndExpression *expression)    = 0;
    virtual Expression *visit(LogicalOrExpression *expression)     = 0;
    virtual Expression *visit(NewExpression *expression)           = 0;
    virtual Expression *visit(PropertyExpression *expression)      = 0;
    virtual Expression *visit(UnaryOperatorExpression *expression) = 0;
    virtual Expression *visit(VariableExpression *expression)      = 0;
    virtual Expression *visit(SuperExpression *expression)         = 0;
    virtual Expression *visit(VariableDeclaration *declaration)    = 0;

    //
    // literals
    //

    virtual Expression *visit(Identifier *identifier)             = 0;
    virtual Expression *visit(ThisLiteral *literal)               = 0;
    virtual Expression *visit(NullLiteral *literal)               = 0;
    virtual Expression *visit(BooleanLiteral *literal)            = 0;
    virtual Expression *visit(NumberLiteral *literal)             = 0;
    virtual Expression *visit(StringLiteral *literal)             = 0;
    virtual Expression *visit(ArrayLiteral *literal)              = 0;
    virtual Expression *visit(FunctionLiteral *literal)           = 0;
    virtual Expression *visit(ObjectLiteral *literal)             = 0;
    virtual Expression *visit(ObjectLiteralProperty *property)    = 0;
    virtual Expression *visit(PropertyLiteral *modifier)          = 0;
    virtual Expression *visit(VectorLiteral *literal)             = 0;
    virtual Expression *visit(DictionaryLiteralPair *literalPair) = 0;
    virtual Expression *visit(DictionaryLiteral *literal)         = 0;
};
}
#endif
