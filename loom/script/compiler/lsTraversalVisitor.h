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

#ifndef _lstraversalvisitor_h
#define _lstraversalvisitor_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/compiler/lsVisitor.h"
#include "loom/script/compiler/lsAST.h"
#include "loom/script/compiler/lsScope.h"

namespace LS {
class TraversalVisitor : public Visitor {
protected:
    Visitor         *visitor;
    ASTNode         *lastVisited;
    CompilationUnit *cunit;
    int             lineNumber;

    // if a traversal error has happened, this will be true
    bool errorFlag;

public:

    TraversalVisitor()
    {
        this->visitor     = NULL;
        this->lastVisited = NULL;
        this->cunit       = NULL;
        this->lineNumber  = 0;
        this->errorFlag   = false;
    }

    TraversalVisitor(Visitor *visitor)
    {
        this->visitor = visitor;
    }

    void error(const char *format, ...);

    void warning(const char *format, ...);

    // Recursively, process a TemplateInfo from an AST representation
    TemplateInfo *processTemplateInfo(ASTTemplateTypeInfo *templateInfo)
    {
        Type *type = Scope::resolveType(templateInfo->typeString);

        if (!type)
        {
            error("unable to resolve template type: %s", templateInfo->typeString.c_str());
            return NULL;
        }

        TemplateInfo *out = new TemplateInfo;

        out->type = type;

        for (UTsize i = 0; i < templateInfo->templateTypes.size(); i++)
        {
            TemplateInfo *tinfo = processTemplateInfo(templateInfo->templateTypes.at(i));
            if (tinfo)
            {
                out->types.push_back(tinfo);
            }
            else
            {
                return NULL;
            }
        }

        return out;
    }

    //
    // utilities
    //

    // retrieve the last visited AST node
    // in the case of a compound AST node this
    // is the root node
    ASTNode *getLastVisited()
    {
        return lastVisited;
    }

    // clear the last visited node
    void clearLastVisited()
    {
        lastVisited = NULL;
    }

    utArray<Statement *> *visitStatementArray(utArray<Statement *> *statements)
    {
        if (statements != NULL)
        {
            errorFlag = false;
            for (unsigned int i = 0; i < statements->size(); i++)
            {
                (*statements)[i] = visitStatement(statements->at(i));

                // only report first error in a block to reduce spam
                // and avoid reporting "false positive" errors causes by
                // the first error state
                if (errorFlag)
                {
                    errorFlag = false;
                    return statements;
                }
            }
        }

        return statements;
    }

    virtual Statement *visitStatement(Statement *statement)
    {
        if (statement != NULL)
        {
            lastVisited = statement;

            statement = statement->visitStatement(visitor);
        }

        return statement;
    }

    utArray<Expression *> *visitExpressionArray(
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

    Expression *visitExpression(Expression *expression)
    {
        if (expression != NULL)
        {
            lastVisited = expression;
            expression  = expression->visitExpression(visitor);
        }

        return expression;
    }

    Expression *visitBinaryExpression(BinaryExpression *expression)
    {
        lastVisited = expression;
        expression->leftExpression = visitExpression(
            expression->leftExpression);
        expression->rightExpression = visitExpression(
            expression->rightExpression);

        return expression;
    }

    Expression *visitUnaryExpression(UnaryExpression *expression)
    {
        lastVisited = expression;
        expression->subExpression = visitExpression(expression->subExpression);
        return expression;
    }

    utArray<Identifier *> *visitIdentifierArray(
        utArray<Identifier *> *_identifiers)
    {
        if (_identifiers != NULL)
        {
            utArray<Identifier *>& identifiers = *_identifiers;
            for (unsigned int i = 0; i < identifiers.size(); i++)
            {
                identifiers[i] = visitIdentifier(identifiers[i]);
            }
        }
        return _identifiers;
    }

    Identifier *visitIdentifier(Identifier *identifier)
    {
        if (identifier != NULL)
        {
            lastVisited = identifier;
            identifier  = (Identifier *)identifier->visitExpression(visitor);
        }

        return identifier;
    }

    //
    // nodes
    //

    virtual CompilationUnit *visit(CompilationUnit *cunit)
    {
        cunit->functions  = visitStatementArray(cunit->functions);
        cunit->statements = visitStatementArray(cunit->statements);

        return cunit;
    }

    //
    // statements
    //

    Statement *visit(FunctionDeclaration *functionDeclaration)
    {
        lastVisited = functionDeclaration;

        functionDeclaration->literal = (FunctionLiteral *)visitExpression(
            functionDeclaration->literal);

        return functionDeclaration;
    }

    Statement *visit(PropertyDeclaration *propertyDeclaration)
    {
        lastVisited = propertyDeclaration;

        propertyDeclaration->literal = (PropertyLiteral *)visitExpression(
            propertyDeclaration->literal);

        return propertyDeclaration;
    }

    Statement *visit(BlockStatement *blockStatement)
    {
        blockStatement->statements = visitStatementArray(
            blockStatement->statements);

        return blockStatement;
    }

    Statement *visit(BreakStatement *breakStatement)
    {
        lastVisited = breakStatement;

        breakStatement->identifier = visitIdentifier(
            breakStatement->identifier);

        return breakStatement;
    }

    Statement *visit(CaseStatement *caseStatement)
    {
        lastVisited = caseStatement;

        caseStatement->expression = visitExpression(caseStatement->expression);
        caseStatement->statements = visitStatementArray(
            caseStatement->statements);

        return caseStatement;
    }

    Statement *visit(ContinueStatement *continueStatement)
    {
        lastVisited = continueStatement;

        continueStatement->identifier = visitIdentifier(
            continueStatement->identifier);

        return continueStatement;
    }

    Statement *visit(DoStatement *doStatement)
    {
        lastVisited = doStatement;

        doStatement->statement  = visitStatement(doStatement->statement);
        doStatement->expression = visitExpression(doStatement->expression);

        return doStatement;
    }

    Statement *visit(EmptyStatement *emptyStatement)
    {
        return emptyStatement;
    }

    Statement *visit(ExpressionStatement *expressionStatement)
    {
        lastVisited = expressionStatement;

        expressionStatement->expression = visitExpression(
            expressionStatement->expression);
        return expressionStatement;
    }

    Statement *visit(ForStatement *forStatement)
    {
        lastVisited = forStatement;

        forStatement->initial   = visitExpression(forStatement->initial);
        forStatement->condition = visitExpression(forStatement->condition);
        forStatement->increment = visitExpression(forStatement->increment);
        forStatement->statement = visitStatement(forStatement->statement);

        return forStatement;
    }

    Statement *visit(ForInStatement *forInStatement)
    {
        lastVisited = forInStatement;

        forInStatement->variable   = visitExpression(forInStatement->variable);
        forInStatement->expression = visitExpression(
            forInStatement->expression);
        forInStatement->statement = visitStatement(forInStatement->statement);

        return forInStatement;
    }

    Statement *visit(IfStatement *ifStatement)
    {
        lastVisited = ifStatement;
        ifStatement->expression     = visitExpression(ifStatement->expression);
        ifStatement->trueStatement  = visitStatement(ifStatement->trueStatement);
        ifStatement->falseStatement = visitStatement(ifStatement->falseStatement);            
        return ifStatement;
    }

    Statement *visit(LabelledStatement *labelledStatement)
    {
        lastVisited = labelledStatement;

        labelledStatement->identifier = visitIdentifier(
            labelledStatement->identifier);
        labelledStatement->statement = visitStatement(
            labelledStatement->statement);

        return labelledStatement;
    }

    Statement *visit(ReturnStatement *returnStatement)
    {
        visitExpressionArray(returnStatement->result);

        lastVisited = returnStatement;

        return returnStatement;
    }

    Statement *visit(SwitchStatement *switchStatement)
    {
        switchStatement->expression = visitExpression(
            switchStatement->expression);
        switchStatement->clauses =
            (utArray<CaseStatement *> *)visitStatementArray(
                (utArray<Statement *> *)switchStatement->clauses);

        lastVisited = switchStatement;

        return switchStatement;
    }

    Statement *visit(ThrowStatement *throwStatement)
    {
        lastVisited = throwStatement;

        throwStatement->expression = visitExpression(
            throwStatement->expression);

        return throwStatement;
    }

    Statement *visit(TryStatement *tryStatement)
    {
        tryStatement->tryBlock        = visitStatement(tryStatement->tryBlock);
        tryStatement->catchIdentifier = visitExpression(tryStatement->catchIdentifier);
        tryStatement->catchBlock      = visitStatement(tryStatement->catchBlock);
        tryStatement->finallyBlock    = visitStatement(tryStatement->finallyBlock);

        lastVisited = tryStatement;

        return tryStatement;
    }

    Statement *visit(VariableStatement *variableStatement)
    {
        lastVisited = variableStatement;

        variableStatement->declarations =
            (utArray<VariableDeclaration *> *)visitExpressionArray(
                (utArray<Expression *> *)variableStatement->declarations);

        return variableStatement;
    }

    Statement *visit(WhileStatement *whileStatement)
    {
        lastVisited = whileStatement;

        whileStatement->expression = visitExpression(
            whileStatement->expression);
        whileStatement->statement = visitStatement(whileStatement->statement);

        return whileStatement;
    }

    Statement *visit(WithStatement *withStatement)
    {
        lastVisited = withStatement;

        withStatement->expression = visitExpression(withStatement->expression);
        withStatement->statement  = visitStatement(withStatement->statement);

        return withStatement;
    }

    Statement *visit(PackageDeclaration *pkg)
    {
        lastVisited = pkg;

        // pkg->name = visitIdentifier(pkg->name);
        pkg->statements = visitStatementArray(pkg->statements);

        return pkg;
    }

    Statement *visit(ClassDeclaration *cls)
    {
        cls->name = visitIdentifier(cls->name);

        cls->statements = visitStatementArray(cls->statements);

        lastVisited = cls;

        return cls;
    }

    virtual Statement *visit(ImportStatement *import)
    {
        lastVisited = import;
        return import;
    }

    Statement *visit(InterfaceDeclaration *_interface)
    {
        lastVisited = _interface;
        return _interface;
    }

    //
    // Expressions
    //

    Expression *visit(AssignmentExpression *expression)
    {
        lastVisited = expression;
        return visitBinaryExpression(expression);
    }

    Expression *visit(MultipleAssignmentExpression *expression)
    {
        lastVisited = expression;

        for (unsigned int i = 0; i < expression->left.size(); i++)
        {
            visitExpression(expression->left[i]);
        }

        for (unsigned int i = 0; i < expression->right.size(); i++)
        {
            visitExpression(expression->right[i]);
        }

        return expression;
    }

    Expression *visit(AssignmentOperatorExpression *expression)
    {
        lastVisited = expression;

        return visitBinaryExpression(expression);
    }

    Expression *visit(BinaryOperatorExpression *expression)
    {
        lastVisited = expression;
        return visitBinaryExpression(expression);
    }

    Expression *visit(CallExpression *callExpression)
    {
        callExpression->function  = visitExpression(callExpression->function);
        callExpression->arguments = visitExpressionArray(
            callExpression->arguments);

        lastVisited = callExpression;

        return callExpression;
    }

    Expression *visit(YieldExpression *yieldExpression)
    {
        yieldExpression->arguments = visitExpressionArray(
            yieldExpression->arguments);

        lastVisited = yieldExpression;

        return yieldExpression;
    }

    Expression *visit(ConditionalExpression *conditionalExpression)
    {
        conditionalExpression->expression = visitExpression(conditionalExpression->expression);            
        conditionalExpression->trueExpression = visitExpression(conditionalExpression->trueExpression);        
        conditionalExpression->falseExpression = visitExpression(conditionalExpression->falseExpression);

        lastVisited = conditionalExpression;

        return conditionalExpression;
    }

    Expression *visit(DeleteExpression *expression)
    {
        lastVisited = expression;

        return visitUnaryExpression(expression);
    }

    Expression *visit(IncrementExpression *expression)
    {
        lastVisited = expression;

        return visitUnaryExpression(expression);
    }

    Expression *visit(LogicalAndExpression *expression)
    {
        lastVisited = expression;

        return visitBinaryExpression(expression);
    }

    Expression *visit(LogicalOrExpression *expression)
    {
        lastVisited = expression;

        return visitBinaryExpression(expression);
    }

    Expression *visit(NewExpression *newExpression)
    {
        lastVisited = newExpression;

        newExpression->function  = visitExpression(newExpression->function);
        newExpression->arguments = visitExpressionArray(
            newExpression->arguments);

        return newExpression;
    }

    Expression *visit(PropertyExpression *expression)
    {
        lastVisited = expression;
        return visitBinaryExpression(expression);
    }

    Expression *visit(UnaryOperatorExpression *expression)
    {
        lastVisited = expression;
        return visitUnaryExpression(expression);
    }

    Expression *visit(VariableExpression *variableExpression)
    {
        variableExpression->declarations =
            (utArray<VariableDeclaration *> *)visitExpressionArray(
                (utArray<Expression *> *)variableExpression->declarations);

        lastVisited = variableExpression;

        return variableExpression;
    }

    Expression *visit(SuperExpression *expression)
    {
        visitExpressionArray(&expression->arguments);

        lastVisited = expression;

        return expression;
    }

    Expression *visit(VariableDeclaration *variableDeclaration)
    {
        variableDeclaration->identifier = visitIdentifier(
            variableDeclaration->identifier);
        variableDeclaration->initializer = visitExpression(
            variableDeclaration->initializer);

        lastVisited = variableDeclaration;

        return variableDeclaration;
    }

    //
    // literals
    //

    Expression *visit(Identifier *identifier)
    {
        lastVisited = identifier;
        return identifier;
    }

    Expression *visit(ThisLiteral *thisLiteral)
    {
        lastVisited = thisLiteral;
        return thisLiteral;
    }

    Expression *visit(NullLiteral *nullLiteral)
    {
        lastVisited = nullLiteral;
        return nullLiteral;
    }

    Expression *visit(BooleanLiteral *booleanLiteral)
    {
        lastVisited = booleanLiteral;
        return booleanLiteral;
    }

    Expression *visit(NumberLiteral *numberLiteral)
    {
        lastVisited = numberLiteral;
        return numberLiteral;
    }

    Expression *visit(StringLiteral *stringLiteral)
    {
        lastVisited = stringLiteral;
        return stringLiteral;
    }

    Expression *visit(ArrayLiteral *arrayLiteral)
    {
        arrayLiteral->elements = visitExpressionArray(arrayLiteral->elements);

        lastVisited = arrayLiteral;

        return arrayLiteral;
    }

    Expression *visit(FunctionLiteral *functionLiteral)
    {
        functionLiteral->name = visitIdentifier(functionLiteral->name);

        if (functionLiteral->parameters)
        {
            for (UTsize i = 0; i < functionLiteral->parameters->size(); i++)
            {
                VariableDeclaration *vd = functionLiteral->parameters->at(i);
                visit(vd);
            }
        }

        functionLiteral->retType = visitIdentifier(functionLiteral->retType);

        functionLiteral->functions = visitStatementArray(
            functionLiteral->functions);

        functionLiteral->statements = visitStatementArray(
            functionLiteral->statements);

        // note that we do not set lastVisited here, as we don't want the functionLiteral
        // but the last AST of the functionLiteral (we should already know we are traversing
        // a functionLiteral as this is a high level construct
        return functionLiteral;
    }

    Expression *visit(ObjectLiteral *objectLiteral)
    {
        objectLiteral->properties =
            (utArray<ObjectLiteralProperty *> *)visitExpressionArray(
                (utArray<Expression *> *)objectLiteral->properties);

        lastVisited = objectLiteral;

        return objectLiteral;
    }

    Expression *visit(VectorLiteral *vector)
    {
        visitExpressionArray(&vector->elements);

        lastVisited = vector;

        return vector;
    }

    Expression *visit(ObjectLiteralProperty *objectLiteralProperty)
    {
        objectLiteralProperty->name = visitExpression(
            objectLiteralProperty->name);
        objectLiteralProperty->value = visitExpression(
            objectLiteralProperty->value);

        lastVisited = objectLiteralProperty;

        return objectLiteralProperty;
    }

    Expression *visit(PropertyLiteral *property)
    {
        if (property->getter)
        {
            visitExpression(property->getter);
        }

        if (property->setter)
        {
            visitExpression(property->setter);
        }

        lastVisited = property;

        return property;
    }

    Expression *visit(DictionaryLiteralPair *pair)
    {
        visitExpression(pair->key);
        visitExpression(pair->value);

        return pair;
    }

    Expression *visit(DictionaryLiteral *literal)
    {
        for (UTsize i = 0; i < literal->pairs.size(); i++)
        {
            visitExpression(literal->pairs.at(i));
        }

        return literal;
    }
};
}
#endif
