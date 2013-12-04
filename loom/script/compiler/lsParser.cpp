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

#include "loom/script/compiler/lsToken.h"
#include "loom/script/compiler/lsParser.h"
#include "loom/script/compiler/lsCompilerLog.h"
#include "loom/script/compiler/lsAlias.h"

#include "loom/script/common/lsError.h"
#include "loom/script/compiler/lsBuildInfo.h"

namespace LS {
Parser::Parser(const utString& input, const utString& filename)
{
    //initialze aliases
    Aliases::initialize();

    tokens = Tokens::getSingletonPtr();

    lexer.setInput(input);

    this->filename = filename;

    sawPublic    = false;
    sawFinal     = false;
    sawProtected = false;
    sawStatic    = false;
    sawOperator  = false;

    curClass = NULL;

    lastErrorLine = lastWarningLine = -1;

    readToken();
}


Identifier *Parser::parseIdentifier()
{
    Identifier *identifier = NULL;

    if (nextToken->type == TIDENTIFIER)
    {
        identifier = new Identifier(nextToken->value.str());
        identifier->preAliasString = nextToken->preAliasValue;
    }
    else if (nextToken == LSTOKEN(KEYWORD_GET))
    {
        identifier = new Identifier("get");
    }
    else if (nextToken == LSTOKEN(KEYWORD_SET))
    {
        identifier = new Identifier("set");
    }
    else
    {
        error("identifier or numeric literal expected");
    }

    readToken();

    return identifier;
}


Expression *Parser::parseDefaultArgument()
{
    readToken(LSTOKEN(OPERATOR_ASSIGNMENT));

    Expression *da = NULL;
    if (nextToken->isNumericLiteral())
    {
        da = parseNumericLiteral();
    }
    else if (nextToken->isStringLiteral())
    {
        da = parseStringLiteral();
    }
    else if (nextToken == LSTOKEN(KEYWORD_NULL))
    {
        readToken(LSTOKEN(KEYWORD_NULL));
        da = new NullLiteral();
    }
    else if (nextToken == LSTOKEN(KEYWORD_TRUE))
    {
        readToken(LSTOKEN(KEYWORD_TRUE));
        da = new BooleanLiteral(true);
    }
    else if (nextToken == LSTOKEN(KEYWORD_FALSE))
    {
        readToken(LSTOKEN(KEYWORD_FALSE));
        da = new BooleanLiteral(false);
    }

    if (!da)
    {
        error("unknown default argument assignment");
    }

    return da;
}


VariableDeclaration *Parser::parseVarArgDeclaration(bool inFlag)
{
    readToken(LSTOKEN(OPERATOR_DOT));
    readToken(LSTOKEN(OPERATOR_DOT));
    readToken(LSTOKEN(OPERATOR_DOT));

    Identifier *identifier = parseIdentifier();

    VariableDeclaration *vd = new VariableDeclaration(identifier, NULL, false,
                                                      false, false, false);

    
    ASTTemplateTypeInfo *templateInfo = ASTTemplateTypeInfo::createVectorInfo("system.Object");        

    vd->isVarArg        = true;
    vd->typeString      = "Vector";
    vd->isTemplate      = true;
    vd->astTemplateInfo = templateInfo;
    vd->lineNumber      = lexer.lineNumber;

    // If there is a type specification of Array, consume it and warn.
    if (nextToken == LSTOKEN(OPERATOR_COLON))
    {
        readToken(LSTOKEN(OPERATOR_COLON));

        // Peek the type.
        if ((nextToken->value == "Vector") || (nextToken->value == "Array"))
        {
            LSCompilerLog::logWarning(filename.c_str(), lexer.lineNumber, "type parameter for varargs of Array or Vector.<T> is ignored; type is always Vector.<Object>.");

            // Consume it.
            if (nextToken->value == "Vector")
            {
                readToken();
                parseTemplateType("Vector");
            }
            else if (nextToken->value == "Array")
            {
                readToken();
            }
        }
        else
        {
            LSCompilerLog::logError(filename.c_str(), lexer.lineNumber, "varag specified with non-Array, non-Vector.<T> type.");
        }
    }

    return vd;
}


FunctionLiteral *Parser::parseFunctionLiteral(bool nameFlag)
{
    FunctionLiteral *lit = new FunctionLiteral();

    lit->lineNumber = lexer.lineNumber;

    lit->metaTags = curTags;
    curTags.clear();

    // Support native function operator syntax
    if (nextToken == LSTOKEN(KEYWORD_OPERATOR))
    {
        readToken();
        sawOperator = true;
    }

    lit->isPublic    = sawPublic;
    lit->isProtected = sawProtected;
    lit->isStatic    = sawStatic;
    lit->isNative    = findMetaTag(lit->metaTags, "Native") != NULL;
    lit->isOperator  = sawOperator;

    if (nextToken == LSTOKEN(KEYWORD_GET))
    {
        readToken(LSTOKEN(KEYWORD_GET));
        lit->isGetter = true;
    }

    else if (nextToken == LSTOKEN(KEYWORD_SET))
    {
        readToken(LSTOKEN(KEYWORD_SET));
        lit->isSetter = true;
    }

    if (nameFlag || (nextToken != LSTOKEN(OPERATOR_OPENPAREN)))
    {
        if (sawOperator)
        {
            const char *opname = tokens->getOperatorMethodName(nextToken);
            if (!opname)
            {
                error("Unknown operator override");
            }

            /*
             * if (!curClass->isStruct && nextToken == LSTOKEN(OPERATOR_ASSIGNMENT)) {
             * error("non-struct type overloading assignment operator");
             * }
             */

            lit->toperator = nextToken;

            readToken();

            lit->name = new Identifier(opname);
        }

        else
        {
            lit->name = parseIdentifier();
        }
    }

    // function literals may have zero or more parameters.

    readToken(LSTOKEN(OPERATOR_OPENPAREN));

    bool sawDefaultArgument = false;
    bool sawVarArg          = false;

    if (nextToken != LSTOKEN(OPERATOR_CLOSEPAREN))
    {

        if (lit->isGetter)
        {
            utString errormsg = "Property get function specifies parameters: ";
            errormsg += lit->name->string;
            error(errormsg.c_str());            
        }

        if (!lit->parameters)
        {
            lit->parameters = new utArray<VariableDeclaration *>();
        }

        if (nextToken == LSTOKEN(OPERATOR_DOT))
        {
            lit->parameters->push_back(parseVarArgDeclaration(true));
            lit->defaultArguments.push_back(NULL);
            sawVarArg = true;
        }
        else
        {
            VariableDeclaration *parm = parseVariableDeclaration(true, true);
            lit->parameters->push_back(parm);

            if (parm->initializer)
            {
                sawDefaultArgument = true;

                lit->defaultArguments.push_back(parm->initializer);
                parm->initializer = NULL;
            }
            else
            {
                lit->defaultArguments.push_back(NULL);
            }
        }

        while (nextToken != LSTOKEN(OPERATOR_CLOSEPAREN))
        {
            readToken(LSTOKEN(OPERATOR_COMMA));

            if (nextToken == LSTOKEN(OPERATOR_DOT))
            {
                lit->parameters->push_back(parseVarArgDeclaration(true));
                lit->defaultArguments.push_back(NULL);
                sawVarArg = true;
            }
            else
            {
                if (sawVarArg)
                {
                    error("already saw var arg");
                }

                VariableDeclaration *parm = parseVariableDeclaration(true, true);

                for (UTsize pidx = 0; pidx < lit->parameters->size(); pidx++)
                {
                    if (parm->identifier->string == lit->parameters->at(pidx)->identifier->string)
                    {
                        utString errormsg = "Duplicate method parameter named: ";
                        errormsg += parm->identifier->string;
                        error(errormsg.c_str());
                    }
                }

                lit->parameters->push_back(parm);

                if (parm->initializer)
                {
                    sawDefaultArgument = true;

                    lit->defaultArguments.push_back(parm->initializer);
                    parm->initializer = NULL;
                }
                else if (sawDefaultArgument)
                {
                    error("missing default argument");
                }
                else
                {
                    lit->defaultArguments.push_back(NULL);
                }
            }
        }
    }

    readToken(LSTOKEN(OPERATOR_CLOSEPAREN));

    if (nextToken == LSTOKEN(OPERATOR_COLON))
    {
        // read colon
        readToken();

        // parse type
        if (nextToken == LSTOKEN(KEYWORD_VOID))
        {
            lit->retType = new Identifier("Void");
            readToken();
        }
        else
        {
            if ((nextToken->value == "Vector") || (nextToken->value == "Dictionary"))
            {
                Identifier *iname = NULL;

                if (nextToken->value == "Vector")
                {
                    iname = new Identifier("Vector");
                }
                else
                {
                    iname = new Identifier("Dictionary");
                }

                readToken();

                if (nextToken == LSTOKEN(OPERATOR_DOT))
                {
                    iname->astTemplateInfo = parseTemplateType(iname->string);
                }

                lit->retType = iname;
            }
            else
            {
                lit->retType = parseIdentifier();
            }
        }
    }
    else
    {
        // if no return type is specified, use Void
        lit->retType = new Identifier("Void");
    }


    if (!lit->isNative && !curClass->isInterface)
    {
        readToken(LSTOKEN(OPERATOR_OPENBRACE));

        while (nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
        {
            if (!lit->statements)
            {
                lit->statements = new utArray<Statement *>();
            }

            lit->statements->push_back(parseElement());
        }

        readToken(LSTOKEN(OPERATOR_CLOSEBRACE));
    }

    if (curClass->isInterface && (nextToken == LSTOKEN(OPERATOR_OPENBRACE)))
    {
        error("Interfaces must not have implementations");
    }

    return lit;
}


Statement *Parser::parsePropertyDeclaration()
{
    int lineNumber = lexer.lineNumber;

    assert(curClass);

    FunctionLiteral *function = parseFunctionLiteral(true);

    if (function->isGetter)
    {
        if (!function->retType)
        {
            error("property get missing return type");
        }

        if ( function->retType->string == "Dictionary" || function->retType->string == "system.Dictionary" )
        {
            if (!function->retType->astTemplateInfo)
                function->retType->astTemplateInfo = ASTTemplateTypeInfo::createDictionaryInfo("system.Object", "system.Object");
        }

        if ( function->retType->string == "Vector" || function->retType->string == "system.Vector" )
        {
            if (!function->retType->astTemplateInfo)
                function->retType->astTemplateInfo = ASTTemplateTypeInfo::createVectorInfo("system.Object");
        }

    }
    else
    {
        if (!function->parameters || !function->parameters->size())
        {
            error("property set missing parameter type");
        }
    }

    if (curClass->checkPropertyExists(function))
    {
        char msg[4096];
        snprintf(msg, 4095, "duplicate property %s for member %s:%s",
                 function->isGetter ? "getter" : "setter", curClass->name->string.c_str(),
                 function->name->string.c_str());

        LSCompilerLog::logError(filename.c_str(), function->lineNumber, msg);
    }

    bool            newProperty;
    PropertyLiteral *plit = curClass->addProperty(function, newProperty);

    if (newProperty)
    {
        PropertyDeclaration *decl = new PropertyDeclaration(plit);
        decl->lineNumber = lineNumber;
        return decl;
    }

    // already added in getter/setter
    return new EmptyStatement();
}


Statement *Parser::parseFunctionDeclaration()
{
    int lineNumber = lexer.lineNumber;

    FunctionDeclaration *decl = new FunctionDeclaration(
        parseFunctionLiteral(true));

    decl->lineNumber = lineNumber;
    return decl;
}


Statement *Parser::parseBlockStatement()
{
    BlockStatement *block = new BlockStatement();

    readToken(LSTOKEN(OPERATOR_OPENBRACE));

    while (nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
    {
        if (!block->statements)
        {
            block->statements = new utArray<Statement *>();
        }

        block->statements->push_back(parseStatement());
    }

    readToken(LSTOKEN(OPERATOR_CLOSEBRACE));

    return block;
}


Statement *Parser::parseBreakStatement()
{
    Identifier *identifier = NULL;

    readToken(LSTOKEN(KEYWORD_BREAK));

    if (nextToken != LSTOKEN(OPERATOR_SEMICOLON))
    {
        identifier = parseIdentifier();
    }

    return new BreakStatement(identifier);
}


Statement *Parser::parseContinueStatement()
{
    Identifier *identifier = NULL;

    readToken(LSTOKEN(KEYWORD_CONTINUE));

    if (nextToken != LSTOKEN(OPERATOR_SEMICOLON))
    {
        identifier = parseIdentifier();
    }

    return new ContinueStatement(identifier);
}


void Parser::parseArgumentList(utArray<Expression *> *args)
{
    readToken(LSTOKEN(OPERATOR_OPENPAREN));

    if (nextToken != LSTOKEN(OPERATOR_CLOSEPAREN))
    {
        args->push_back(parseAssignmentExpression(true));

        while (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
            readToken(LSTOKEN(OPERATOR_COMMA));
            args->push_back(parseAssignmentExpression(true));
        }
    }

    readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
}


ArrayLiteral *Parser::parseArrayLiteral()
{
    ArrayLiteral *array = new ArrayLiteral();

    readToken(LSTOKEN(OPERATOR_OPENSQUARE));

    while (nextToken != LSTOKEN(OPERATOR_CLOSESQUARE))
    {
        if (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
        }
        else
        {
            if (!array->elements)
            {
                array->elements = new utArray<Expression *>();
            }

            array->elements->push_back(parseAssignmentExpression(true));
        }

        if (nextToken != LSTOKEN(OPERATOR_CLOSESQUARE))
        {
            readToken(LSTOKEN(OPERATOR_COMMA));
        }
    }

    readToken(LSTOKEN(OPERATOR_CLOSESQUARE));

    return array;
}


StringLiteral *Parser::parseStringLiteral()
{
    utString string;

    if (nextToken->type == TSTRING)
    {
        string = nextToken->value.str();
    }
    else
    {
        error("string literal expected");
    }

    readToken();

    return new StringLiteral(string);
}


NumberLiteral *Parser::parseNumericLiteral()
{
    double value = 0.0;

    switch (nextToken->type)
    {
    case TFLOAT:
        value = strtod(nextToken->value.str().c_str(), NULL);
        break;

    case TDECIMAL:
        value = strtol(nextToken->value.str().c_str(), NULL, 10);
        break;

    case TOCTAL:
        value = strtol(&nextToken->value.str().c_str()[1], NULL, 8);
        break;

    case THEXADECIMAL:
        value = strtoul(&nextToken->value.str().c_str()[2], NULL, 16);
        break;

    default:
        error("numeric literal expected");
        break;
    }

    NumberLiteral *n = new NumberLiteral(value);
    n->svalue = nextToken->value.str();

    readToken();

    return n;
}


DictionaryLiteralPair *Parser::parseDictionaryLiteralPair()
{
    DictionaryLiteralPair *pair = new DictionaryLiteralPair();

    Expression *propertyKey   = NULL;
    Expression *propertyValue = NULL;

    // If it's a single identifier, ie, foo: bar, then consume it as
    // if it were "foo": bar
    bool isKeyLiteral = false;
    int  bookmark     = lexer.getBookmark();

    if (nextToken->isIdentifier())
    {
        Identifier *id = parseIdentifier();

        // Should get a colon next.
        if (nextToken == LSTOKEN(OPERATOR_COLON))
        {
            // If so it means we got a simple key pair.
            isKeyLiteral = true;
            propertyKey  = new StringLiteral(id->string);
        }
        else
        {
            // Something complex - backup and let normal parse occur.
            lexer.gotoBookmark(bookmark);
            unreadToken();
            readToken();
        }

        delete id;
    }

    if (!isKeyLiteral)
    {
        propertyKey = parseAssignmentExpression(true);
    }

    readToken(LSTOKEN(OPERATOR_COLON));

    propertyValue = parseAssignmentExpression(true);

    pair->key   = propertyKey;
    pair->value = propertyValue;

    return pair;
}


Expression *Parser::parseDictionaryLiteral(const utString& typeKey, const utString& typeValue, bool wrapInNew)
{
    DictionaryLiteral *v = new DictionaryLiteral();

    v->typeKeyString   = typeKey;
    v->typeValueString = typeValue;

    readToken(LSTOKEN(OPERATOR_OPENBRACE));

    while (nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
    {
        if (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
        }
        else
        {
            v->pairs.push_back(parseDictionaryLiteralPair());
        }

        if (nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
        {
            readToken(LSTOKEN(OPERATOR_COMMA));
        }
    }

    readToken(LSTOKEN(OPERATOR_CLOSEBRACE));

    v->astTemplateInfo = ASTTemplateTypeInfo::createDictionaryInfo(typeKey, typeValue);   

    if (wrapInNew)
    {
        NewExpression *n = new NewExpression();
        n->function        = v;
        n->astTemplateInfo = v->astTemplateInfo;
        return n;
    }

    return v;
}


Expression *Parser::parseVectorLiteral(const utString& type, bool wrapInNew)
{
    VectorLiteral *v = new VectorLiteral();

    v->typeString = type;

    readToken(LSTOKEN(OPERATOR_OPENSQUARE));

    while (nextToken != LSTOKEN(OPERATOR_CLOSESQUARE))
    {
        if (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
        }
        else
        {
            v->elements.push_back(parseAssignmentExpression(true));
        }

        if (nextToken != LSTOKEN(OPERATOR_CLOSESQUARE))
        {
            readToken(LSTOKEN(OPERATOR_COMMA));
        }
    }

    readToken(LSTOKEN(OPERATOR_CLOSESQUARE));
    
    v->astTemplateInfo = ASTTemplateTypeInfo::createVectorInfo(type);

    if (wrapInNew)
    {
        NewExpression *n = new NewExpression();
        n->function        = v;
        n->astTemplateInfo = v->astTemplateInfo;
        return n;
    }

    return v;
}


ObjectLiteral *Parser::parseObjectLiteral()
{
    ObjectLiteral *o = new ObjectLiteral();

    readToken(LSTOKEN(OPERATOR_OPENBRACE));

    while (nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
    {
        if (!o->properties)
        {
            o->properties = new utArray<ObjectLiteralProperty *>();
        }

        o->properties->push_back(parseObjectLiteralProperty());

        while (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
            readToken(LSTOKEN(OPERATOR_COMMA));
            o->properties->push_back(parseObjectLiteralProperty());
        }
    }

    readToken(LSTOKEN(OPERATOR_CLOSEBRACE));

    return o;
}


ObjectLiteralProperty *Parser::parseObjectLiteralProperty()
{
    ObjectLiteralProperty *op = new ObjectLiteralProperty();

    Expression *propertyName  = NULL;
    Expression *propertyValue = NULL;

    if (nextToken->isIdentifier())
    {
        Identifier *ident = parseIdentifier();
        propertyName = new StringLiteral(ident->string);
        delete ident;
    }
    else if (nextToken->isStringLiteral())
    {
        propertyName = parseStringLiteral();
    }
    else if (nextToken->isNumericLiteral())
    {
        propertyName = parseNumericLiteral();
    }
    else
    {
        error("identifier or numeric literal expected");
    }

    readToken(LSTOKEN(OPERATOR_COLON));

    propertyValue = parseAssignmentExpression(true);

    op->name  = propertyName;
    op->value = propertyValue;

    return op;
}


Expression *Parser::parseSuperExpression()
{
    Expression *expression = NULL;
    Identifier *identifier = NULL;

    readToken(LSTOKEN(KEYWORD_SUPER));

    if (nextToken == LSTOKEN(OPERATOR_DOT))
    {
        readToken(LSTOKEN(OPERATOR_DOT));

        if (nextToken->isIdentifier())
        {
            identifier = parseIdentifier();
        }
        else
        {
            error("Identifier expected");
        }
    }

    if (nextToken == LSTOKEN(OPERATOR_OPENPAREN))
    {
        // call to super method/constructor
        SuperExpression *super = new SuperExpression;
        expression    = super;
        super->method = identifier;
        parseArgumentList(&super->arguments);
    }
    else
    {
        identifier->superAccess = true;
        expression = identifier;
    }

    return expression;
}


Expression *Parser::parsePrimaryExpression()
{
    if (nextToken == LSTOKEN(KEYWORD_THIS))
    {
        readToken(LSTOKEN(KEYWORD_THIS));
        return new ThisLiteral();
    }
    else if (nextToken == LSTOKEN(KEYWORD_NULL))
    {
        readToken(LSTOKEN(KEYWORD_NULL));
        return new NullLiteral();
    }
    else if (nextToken == LSTOKEN(KEYWORD_TRUE))
    {
        readToken(LSTOKEN(KEYWORD_TRUE));
        return new BooleanLiteral(true);
    }
    else if (nextToken == LSTOKEN(KEYWORD_FALSE))
    {
        readToken(LSTOKEN(KEYWORD_FALSE));
        return new BooleanLiteral(false);
    }
    else if (nextToken == LSTOKEN(OPERATOR_OPENPAREN))
    {
        readToken(LSTOKEN(OPERATOR_OPENPAREN));
        Expression *expression = parseExpression(true);
        readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
        return expression;
    }
    else if (nextToken == LSTOKEN(OPERATOR_OPENBRACE))
    {
        return parseDictionaryLiteral("system.Object", "system.Object", true);
    }
    else if (nextToken == LSTOKEN(OPERATOR_OPENSQUARE))
    {
        return parseVectorLiteral("system.Object", true);
    }
    else if (nextToken->isIdentifier())
    {
        Identifier *identifier = parseIdentifier();
        identifier->primaryExpression = true;
        return identifier;
    }
    else if (nextToken->isStringLiteral())
    {
        return parseStringLiteral();
    }
    else if (nextToken->isNumericLiteral())
    {
        return parseNumericLiteral();
    }
    else
    {
        error("identifier or literal expected");
    }

    return NULL;
}


Expression *Parser::generatePropertyCall(const utString& object, const utString& member, Expression *argument)
{
    PropertyExpression *p    = new PropertyExpression(new Identifier(object), new StringLiteral(member));
    CallExpression     *call = new CallExpression();

    call->function  = p;
    call->arguments = new utArray<Expression *>();
    call->arguments->push_back(argument);
    return call;
}


/**
 * The grammar for the 'new' keyword is a little complicated. The keyword
 * 'new' can occur in either a NewExpression (where its not followed by
 * an argument list) or in MemberExpression (where it is followed by an
 * argument list). The intention seems to be that an argument list should
 * bind to any unmatched 'new' keyword to the left in the same expression
 * if possible, otherwise an argument list is taken as a call expression.
 *
 * Since the rest of the productions for NewExpressions and CallExpressions
 * are similar we roll these two into one routine with a parameter to
 * indicate whether we're currently parsing a 'new' expression or not.
 *
 * @param newFlag if we're currently parsing a 'new' expression
 * @return an expression
 */
Expression *Parser::parseMemberExpression(bool newFlag)
{
    Expression *expression;

    // new expressions are right associative
    if (nextToken == LSTOKEN(KEYWORD_NEW))
    {
        readToken(LSTOKEN(KEYWORD_NEW));

        bool       isVector = false, isDictionary = false;
        Expression *name    = NULL;
        Identifier *iname   = NULL;

        if ((nextToken->value == "Vector") || (nextToken->value == "Dictionary"))
        {
            if (nextToken->value == "Vector")
            {
                isVector = true;
                iname    = new Identifier("Vector");
            }
            else
            {
                isDictionary = true;
                iname        = new Identifier("Dictionary");
            }

            readToken();

            // new Vector() and new Dictionary() syntax
            if (nextToken == LSTOKEN(OPERATOR_OPENPAREN))
            {
                ASTTemplateTypeInfo *templateInfo = NULL;

                if (iname->string == "Dictionary")
                {
                    templateInfo = ASTTemplateTypeInfo::createDictionaryInfo("system.Object", "system.Object");
                }
                else
                {
                    templateInfo = ASTTemplateTypeInfo::createVectorInfo("system.Object");
                }

                iname->astTemplateInfo = templateInfo;
            }
            else
            {
                // new Vector.<Object> and new Dictionary.<Object, Object> syntax
                iname->astTemplateInfo = parseTemplateType(iname->string);
            }
        }
        else if (nextToken == LSTOKEN(OPERATOR_LESSTHAN))
        {
            // new <String> - shortcut for new Vector.<String>
            iname    = new Identifier("Vector");
            isVector = true;
            iname->astTemplateInfo = parseTemplateType(iname->string, NULL, true);
        }

        if (isVector || isDictionary)
        {
            name = iname;

            if (nextToken == LSTOKEN(OPERATOR_OPENSQUARE))
            {
                name = parseVectorLiteral(iname->astTemplateInfo->templateTypes[0]->typeString);
            }
            else if (nextToken == LSTOKEN(OPERATOR_OPENBRACE))
            {
                name = parseDictionaryLiteral(iname->astTemplateInfo->templateTypes[0]->typeString, iname->astTemplateInfo->templateTypes[1]->typeString);
            }
            else if (nextToken == LSTOKEN(OPERATOR_OPENSQUARE))
            {
                name = parseVectorLiteral("system.Object");
            }
        }
        else
        {
            name = parseMemberExpression(true);
        }

        NewExpression *n = new NewExpression();

        // make sure that we mark the identifier as not being a primary expression
        if (name->astType == AST_IDENTIFIER)
        {
            ((Identifier *)name)->primaryExpression = false;
        }
        n->function = name;
        expression  = n;

        if (nextToken == LSTOKEN(OPERATOR_OPENPAREN))
        {
            if (!n->arguments)
            {
                n->arguments = new utArray<Expression *>();
            }
            parseArgumentList(n->arguments);
        }
    }
    else if (nextToken == LSTOKEN(KEYWORD_FUNCTION))
    {
        readToken(LSTOKEN(KEYWORD_FUNCTION));
        expression = parseFunctionLiteral(false);
    }
    else if (nextToken == LSTOKEN(KEYWORD_SUPER))
    {
        expression = parseSuperExpression();
    }
    else if (nextToken == LSTOKEN(KEYWORD_YIELD))
    {
        readToken(LSTOKEN(KEYWORD_YIELD));
        YieldExpression *yield = new YieldExpression();
        yield->arguments = new utArray<Expression *>();
        parseArgumentList(yield->arguments);

        expression = yield;
    }
    else
    {
        expression = parsePrimaryExpression();
    }

    // call expressions are left associative
    while (true)
    {
        if (!newFlag && (nextToken == LSTOKEN(OPERATOR_OPENPAREN)))
        {
            if ((expression->astType == AST_IDENTIFIER) && (((Identifier *)expression)->string == "String"))
            {
                // transform String cast
                utArray<Expression *> *args = new utArray<Expression *>();
                parseArgumentList(args);
                if (args->size() != 1)
                {
                    error("String cast requires 1 argument");
                }

                expression = generatePropertyCall("Object", "_toString", args->at(0));

                delete args;
            }
            else if ((expression->astType == AST_IDENTIFIER) &&
                     (((Identifier *)expression)->string == "Number") &&
                     (((Identifier *)expression)->preAliasString == "int"))
            {
                // transform int cast
                utArray<Expression *> *args = new utArray<Expression *>();
                parseArgumentList(args);
                if (args->size() != 1)
                {
                    error("int cast requires 1 argument");
                }

                expression = generatePropertyCall("Object", "_toInt", args->at(0));

                delete args;
            }
            else
            {
                CallExpression *call = new CallExpression();

                call->function = expression;

                call->arguments = new utArray<Expression *>();
                parseArgumentList(call->arguments);

                expression = call;
            }
        }
        else if (nextToken == LSTOKEN(OPERATOR_OPENSQUARE))
        {
            readToken(LSTOKEN(OPERATOR_OPENSQUARE));

            Expression *property = parseExpression(true);

            readToken(LSTOKEN(OPERATOR_CLOSESQUARE));

            expression = new PropertyExpression(expression, property, true);
        }
        else if ((nextToken == LSTOKEN(OPERATOR_DOT)) ||
                 (nextToken == LSTOKEN(OPERATOR_COLON)))
        {
            if (nextToken == LSTOKEN(OPERATOR_COLON))
            {
                return expression;
            }

            // transform x.bar to x["bar"]

            readToken();

            Identifier *identifier = NULL;

            if (nextToken == LSTOKEN(OPERATOR_LESSTHAN))
            {
                if (expression->astType != AST_IDENTIFIER)
                {
                    error("identifier expected");
                }

                identifier = (Identifier *)expression;
                identifier->astTemplateInfo = parseTemplateType(identifier->string, NULL, true);
                return identifier;
            }

            identifier = parseIdentifier();

            // We need to catch Object instance calls here
            // as these may be called on instances and primitives (both of
            // which derive from system.Object

            if (identifier->string == "toString")
            {
                // transform this into a call to Object._toString
                expression = generatePropertyCall("Object", "_toString", expression);
                readToken(LSTOKEN(OPERATOR_OPENPAREN));
                readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
                continue;
            }

            if (identifier->string == "getTypeName")
            {
                // transform this into a call to Object._getTypeName
                expression = generatePropertyCall("Object", "_getTypeName", expression);
                readToken(LSTOKEN(OPERATOR_OPENPAREN));
                readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
                continue;
            }

            if (identifier->string == "getFullTypeName")
            {
                // transform this into a call to Object._getFullTypeName
                expression = generatePropertyCall("Object", "_getFullTypeName", expression);
                readToken(LSTOKEN(OPERATOR_OPENPAREN));
                readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
                continue;
            }

            if (identifier->string == "getType")
            {
                // transform this into a call to Object._getFullTypeName
                expression = generatePropertyCall("Object", "_getType", expression);
                readToken(LSTOKEN(OPERATOR_OPENPAREN));
                readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
                continue;
            }

            if (identifier->string == "nativeDeleted")
            {
                // transform this into a call to Object._nativeDeleted
                expression = generatePropertyCall("Object", "_nativeDeleted", expression);
                readToken(LSTOKEN(OPERATOR_OPENPAREN));
                readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
                continue;
            }


            PropertyExpression *p = new PropertyExpression(expression,
                                                           new StringLiteral(identifier->string));

            expression = p;
        }
        else
        {
            return expression;
        }
    }
}


Expression *Parser::parsePostfixExpression()
{
    // TODO this can be merged with parseUnary().

    Expression *expression = parseMemberExpression(false);

    // postfix expressions aren't associative
    if (nextToken == LSTOKEN(OPERATOR_PLUSPLUS))
    {
        readToken(LSTOKEN(OPERATOR_PLUSPLUS));
        return new IncrementExpression(expression, 1, true);
    }
    else if (nextToken == LSTOKEN(OPERATOR_MINUSMINUS))
    {
        readToken(LSTOKEN(OPERATOR_MINUSMINUS));
        return new IncrementExpression(expression, -1, true);
    }
    else
    {
        return expression;
    }
}


Expression *Parser::parseUnaryExpression()
{
    // TODO parse '-' numeric literal directly into literals,
    // to ensure that -0 keeps its proper value.

    // unary expressions are right associative
    if (nextToken == LSTOKEN(OPERATOR_PLUSPLUS))
    {
        readToken(LSTOKEN(OPERATOR_PLUSPLUS));
        return new IncrementExpression(parseUnaryExpression(), 1, false);
    }
    else if (nextToken == LSTOKEN(OPERATOR_MINUSMINUS))
    {
        readToken(LSTOKEN(OPERATOR_MINUSMINUS));
        return new IncrementExpression(parseUnaryExpression(), -1, false);
    }
    else if ((nextToken == LSTOKEN(OPERATOR_PLUS)) ||
             (nextToken == LSTOKEN(OPERATOR_MINUS)) ||
             (nextToken == LSTOKEN(OPERATOR_BITWISENOT)) ||
             (nextToken == LSTOKEN(OPERATOR_LOGICALNOT)) ||
             (nextToken == LSTOKEN(KEYWORD_VOID)) ||
             (nextToken == LSTOKEN(KEYWORD_TYPEOF)))
    {
        Token *token = nextToken;
        readToken();
        UnaryOperatorExpression *result = new UnaryOperatorExpression(
            parseUnaryExpression(), token);
        return result;
    }
    else if (nextToken == LSTOKEN(KEYWORD_DELETE))
    {
        readToken(LSTOKEN(KEYWORD_DELETE));
        return new DeleteExpression(parseUnaryExpression());
    }
    else
    {
        return parsePostfixExpression();
    }
}


Expression *Parser::parseMultiplyExpression()
{
    Expression *left  = parseUnaryExpression();
    Expression *right = NULL;

    // multiplicative expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_MULTIPLY))
        {
            readToken(LSTOKEN(OPERATOR_MULTIPLY));
            right = parseUnaryExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_MULTIPLY));
        }
        else if (nextToken == LSTOKEN(OPERATOR_DIVIDE))
        {
            readToken(LSTOKEN(OPERATOR_DIVIDE));
            right = parseUnaryExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_DIVIDE));
        }
        else if (nextToken == LSTOKEN(OPERATOR_MODULO))
        {
            readToken(LSTOKEN(OPERATOR_MODULO));
            right = parseUnaryExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_MODULO));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseConcatExpression()
{
    Expression *left  = parseMultiplyExpression();
    Expression *right = NULL;

    // addition expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_CONCAT))
        {
            readToken(LSTOKEN(OPERATOR_CONCAT));
            right = parseMultiplyExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_CONCAT));
        }
        else
        {
            break;
        }
    }

    return left;
}


Expression *Parser::parseAdditionExpression()
{
    Expression *left  = parseConcatExpression();
    Expression *right = NULL;

    // addition expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_PLUS))
        {
            readToken(LSTOKEN(OPERATOR_PLUS));
            right = parseConcatExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_PLUS));
        }
        else if (nextToken == LSTOKEN(OPERATOR_MINUS))
        {
            readToken(LSTOKEN(OPERATOR_MINUS));
            right = parseConcatExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_MINUS));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseShiftExpression()
{
    Expression *left  = parseAdditionExpression();
    Expression *right = NULL;

    // shift expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_SHIFTLEFT))
        {
            readToken(LSTOKEN(OPERATOR_SHIFTLEFT));
            right = parseAdditionExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_SHIFTLEFT));
        }
        else if (nextToken == LSTOKEN(OPERATOR_SHIFTRIGHT))
        {
            readToken(LSTOKEN(OPERATOR_SHIFTRIGHT));
            right = parseAdditionExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_SHIFTRIGHT));
        }
        else if (nextToken == LSTOKEN(OPERATOR_SHIFTRIGHTUNSIGNED))
        {
            readToken(LSTOKEN(OPERATOR_SHIFTRIGHTUNSIGNED));
            right = parseAdditionExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_SHIFTRIGHTUNSIGNED));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseRelationalExpression(bool inFlag)
{
    Expression *left  = parseShiftExpression();
    Expression *right = NULL;

    // relational expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_LESSTHAN))
        {
            readToken(LSTOKEN(OPERATOR_LESSTHAN));
            right = parseShiftExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_LESSTHAN));
        }
        else if (nextToken == LSTOKEN(OPERATOR_GREATERTHAN))
        {
            readToken(LSTOKEN(OPERATOR_GREATERTHAN));
            right = parseShiftExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_GREATERTHAN));
        }
        else if (nextToken == LSTOKEN(OPERATOR_LESSTHANOREQUAL))
        {
            readToken(LSTOKEN(OPERATOR_LESSTHANOREQUAL));
            right = parseShiftExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_LESSTHANOREQUAL));
        }
        else if (nextToken == LSTOKEN(OPERATOR_GREATERTHANOREQUAL))
        {
            readToken(LSTOKEN(OPERATOR_GREATERTHANOREQUAL));
            right = parseShiftExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_GREATERTHANOREQUAL));
        }
        else if (nextToken == LSTOKEN(KEYWORD_INSTANCEOF))
        {
            readToken(LSTOKEN(KEYWORD_INSTANCEOF));
            right = parseShiftExpression();
            // when doing type coercion as/is/instanceof we don't want
            // the expression treated as a primary expression as these
            // get transformed to a system.reflection.Type by the compiler
            right->primaryExpression = false;
            left = new BinaryOperatorExpression(left, right,
                                                LSTOKEN(KEYWORD_INSTANCEOF));
        }
        else if (nextToken == LSTOKEN(KEYWORD_IS))
        {
            readToken(LSTOKEN(KEYWORD_IS));
            right = parseShiftExpression();
            // see note on KEYWORD_INSTANCEOF above
            right->primaryExpression = false;
            left = new BinaryOperatorExpression(left, right,
                                                LSTOKEN(KEYWORD_IS));
        }
        else if (nextToken == LSTOKEN(KEYWORD_AS))
        {
            readToken(LSTOKEN(KEYWORD_AS));
            right = parseShiftExpression();
            // see note on KEYWORD_INSTANCEOF above
            right->primaryExpression = false;
            left = new BinaryOperatorExpression(left, right,
                                                LSTOKEN(KEYWORD_AS));
        }
        else if (inFlag && (nextToken == LSTOKEN(KEYWORD_IN)))
        {
            readToken(LSTOKEN(KEYWORD_IN));
            right = parseShiftExpression();
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(KEYWORD_IN));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseEqualityExpression(bool inFlag)
{
    Expression *left  = parseRelationalExpression(inFlag);
    Expression *right = NULL;

    // equality expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_EQUALEQUAL))
        {
            readToken(LSTOKEN(OPERATOR_EQUALEQUAL));
            right = parseRelationalExpression(inFlag);
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_EQUALEQUAL));
        }
        else if (nextToken == LSTOKEN(OPERATOR_NOTEQUAL))
        {
            readToken(LSTOKEN(OPERATOR_NOTEQUAL));
            right = parseRelationalExpression(inFlag);
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_NOTEQUAL));
        }
        else if (nextToken == LSTOKEN(OPERATOR_EQUALEQUALEQUAL))
        {
            readToken(LSTOKEN(OPERATOR_EQUALEQUALEQUAL));
            right = parseRelationalExpression(inFlag);
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_EQUALEQUALEQUAL));
        }
        else if (nextToken == LSTOKEN(OPERATOR_NOTEQUALEQUAL))
        {
            readToken(LSTOKEN(OPERATOR_NOTEQUALEQUAL));
            right = parseRelationalExpression(inFlag);
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_NOTEQUALEQUAL));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseBitwiseAndExpression(bool inFlag)
{
    Expression *left  = parseEqualityExpression(inFlag);
    Expression *right = NULL;

    // bitwise and expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_BITWISEAND))
        {
            readToken(LSTOKEN(OPERATOR_BITWISEAND));
            right = parseEqualityExpression(inFlag);
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_BITWISEAND));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseBitwiseXorExpression(bool inFlag)
{
    Expression *left  = parseBitwiseAndExpression(inFlag);
    Expression *right = NULL;

    // bitwise xor expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_BITWISEXOR))
        {
            readToken(LSTOKEN(OPERATOR_BITWISEXOR));
            right = parseBitwiseAndExpression(inFlag);
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_BITWISEXOR));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseBitwiseOrExpression(bool inFlag)
{
    Expression *left  = parseBitwiseXorExpression(inFlag);
    Expression *right = NULL;

    // bitwise or expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_BITWISEOR))
        {
            readToken(LSTOKEN(OPERATOR_BITWISEOR));
            right = parseBitwiseXorExpression(inFlag);
            left  = new BinaryOperatorExpression(left, right,
                                                 LSTOKEN(OPERATOR_BITWISEOR));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseLogicalAndExpression(bool inFlag)
{
    Expression *left  = parseBitwiseOrExpression(inFlag);
    Expression *right = NULL;

    // logical and expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_LOGICALAND))
        {
            readToken(LSTOKEN(OPERATOR_LOGICALAND));
            right = parseBitwiseOrExpression(inFlag);
            left  = new LogicalAndExpression(left, right,
                                             LSTOKEN(OPERATOR_LOGICALAND));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseLogicalOrExpression(bool inFlag)
{
    Expression *left  = parseLogicalAndExpression(inFlag);
    Expression *right = NULL;

    // logical or expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_LOGICALOR))
        {
            readToken(LSTOKEN(OPERATOR_LOGICALOR));
            right = parseLogicalAndExpression(inFlag);
            left  = new LogicalOrExpression(left, right,
                                            LSTOKEN(OPERATOR_LOGICALOR));
        }
        else
        {
            return left;
        }
    }
}


Expression *Parser::parseConditionalExpression(bool inFlag)
{
    Expression *expression = parseLogicalOrExpression(inFlag);

    // conditional expressions are right associative
    if (nextToken == LSTOKEN(OPERATOR_CONDITIONAL))
    {
        readToken(LSTOKEN(OPERATOR_CONDITIONAL));
        Expression *trueExpression = parseAssignmentExpression(inFlag);
        readToken(LSTOKEN(OPERATOR_COLON));
        Expression *falseExpression = parseAssignmentExpression(inFlag);

        return new ConditionalExpression(expression, trueExpression,
                                         falseExpression);
    }
    else
    {
        return expression;
    }
}


Expression *Parser::parseAssignmentExpression(bool inFlag, bool parseComma)
{
    Expression *left = parseConditionalExpression(inFlag);

    // assignment expressions are right associative
    if (nextToken == LSTOKEN(OPERATOR_ASSIGNMENT))
    {
        readToken();
        return new AssignmentExpression(left, parseAssignmentExpression(inFlag));
    }
    else if ((nextToken == LSTOKEN(OPERATOR_MULTIPLYASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_DIVIDEASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_MODULOASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_PLUSASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_MINUSASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_SHIFTLEFTASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_SHIFTRIGHTASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_SHIFTRIGHTUNSIGNEDASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_BITWISEANDASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_BITWISEORASSIGNMENT)) ||
             (nextToken == LSTOKEN(OPERATOR_BITWISEXORASSIGNMENT)))
    {
        Token *op = nextToken;
        readToken();
        return new AssignmentOperatorExpression(left,
                                                parseAssignmentExpression(inFlag), op);
    }
    else if (parseComma && (nextToken == LSTOKEN(OPERATOR_COMMA)))
    {
        // multiple assignment
        MultipleAssignmentExpression *ma = new MultipleAssignmentExpression();
        ma->left.push_back(left);

        while (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
            readToken(LSTOKEN(OPERATOR_COMMA));
            left = parseConditionalExpression(inFlag);
            if (left)
            {
                ma->left.push_back(left);
            }
        }

        if (nextToken == LSTOKEN(OPERATOR_ASSIGNMENT))
        {
            readToken();
            Expression *right = parseConditionalExpression(inFlag);
            if (right)
            {
                ma->right.push_back(right);

                while (nextToken == LSTOKEN(OPERATOR_COMMA))
                {
                    readToken(LSTOKEN(OPERATOR_COMMA));
                    right = parseConditionalExpression(inFlag);
                    if (right)
                    {
                        ma->right.push_back(right);
                    }
                }
            }
        }

        return ma;
    }
    else
    {
        return left;
    }
}


Expression *Parser::parseExpression(bool inFlag)
{
    Expression *left = parseAssignmentExpression(inFlag, true);

    // comma expressions are left associative
    while (true)
    {
        if (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
            readToken(LSTOKEN(OPERATOR_COMMA));
            Expression *right = parseAssignmentExpression(inFlag);
            left = new BinaryOperatorExpression(left, right,
                                                LSTOKEN(OPERATOR_COMMA));
        }
        else
        {
            return left;
        }
    }
}


Statement *Parser::parseDoStatement()
{
    Statement  *statement;
    Expression *expression;

    readToken(LSTOKEN(KEYWORD_DO));
    statement = parseStatement();
    readToken(LSTOKEN(KEYWORD_WHILE));
    readToken(LSTOKEN(OPERATOR_OPENPAREN));
    expression = parseExpression(true);
    readToken(LSTOKEN(OPERATOR_CLOSEPAREN));

    return new DoStatement(statement, expression);
}


VariableDeclaration *Parser::parseVariableDeclaration(bool inFlag,
                                                      bool inFunctionParameters)
{
    Identifier *identifier = parseIdentifier();

    Expression *initializer = NULL;

    utString typeString;

    ASTTemplateTypeInfo *templateInfo = NULL;

    if (nextToken == LSTOKEN(OPERATOR_COLON))
    {
        readToken(LSTOKEN(OPERATOR_COLON));

        typeString = nextToken->value.str();

        if (typeString == "Array")
        {
            warn("Rewriting Array to be Vector.<Object> for convenience when porting. Note that Array and Vector.<Object> aren't identical types.");
            typeString = "Vector";

            // Array is secretly a Vector.<Object>
            templateInfo = ASTTemplateTypeInfo::createVectorInfo("system.Object");
        }

        readToken();

        if (nextToken == LSTOKEN(OPERATOR_DOT))
        {
            if ((typeString == "Vector") || (typeString == "Dictionary"))
            {
                templateInfo = parseTemplateType(typeString);
            }
            else
            {
                // parse fully qualified type

                while (nextToken == LSTOKEN(OPERATOR_DOT))
                {
                    typeString += ".";

                    readToken(LSTOKEN(OPERATOR_DOT));

                    if (!nextToken->isIdentifier())
                    {
                        error("identifier expected");
                    }

                    typeString += nextToken->value.str();

                    readToken();
                }
            }
        }
    }

    if ((typeString == "Vector") && !templateInfo)
    {
        // create default Vector.<Object> from "Vector"
        templateInfo = ASTTemplateTypeInfo::createVectorInfo("system.Object");        
    }
    else if ((typeString == "Dictionary") && !templateInfo)
    {
        // create default Dictionary.<Object, Object> from "Dictionary"
        templateInfo = ASTTemplateTypeInfo::createDictionaryInfo("system.Object", "system.Object");        
    }

    bool defaultInitializer = false;

    if (nextToken == LSTOKEN(OPERATOR_ASSIGNMENT))
    {
        readToken(LSTOKEN(OPERATOR_ASSIGNMENT));
        initializer = parseAssignmentExpression(inFlag);
    }
    else if (!typeString.size())
    {
        if (nextToken != LSTOKEN(KEYWORD_IN))
        {
            error("untyped var requires initializer");
        }
    }
    else if (!inFunctionParameters)
    {
        if (findMetaTag(curTags, "Native") == NULL)
        {
            // default initializers
            if ((typeString == "system.Number") || (typeString == "Number"))
            {
                initializer = new NumberLiteral(0.0);
            }
            else if ((typeString == "system.Boolean") || (typeString == "Boolean"))
            {
                initializer = new BooleanLiteral(false);
            }
            else if ((typeString == "system.String") || (typeString == "String"))
            {
                initializer = new NullLiteral();
            }
            else
            {
                initializer = new NullLiteral();
            }

            defaultInitializer = true;
        }
    }

    VariableDeclaration *vd = new VariableDeclaration(identifier, initializer,
                                                      sawPublic, sawProtected, sawStatic, findMetaTag(curTags, "Native") != NULL);

    vd->defaultInitializer = defaultInitializer;
    vd->isParameter        = inFunctionParameters;
    vd->lineNumber         = lexer.lineNumber;

    if (!typeString.size())
    {
        vd->assignType = true;
        typeString     = "Object";
    }
    vd->typeString = typeString;

    if (templateInfo)
    {
        vd->astTemplateInfo = templateInfo;
        vd->isTemplate      = true;
    }

    vd->metaTags = curTags;
    curTags.clear();

    return vd;
}


Statement *Parser::parseForStatement()
{
    Expression         *declaration = NULL;
    Expression         *initial     = NULL;
    Expression         *condition   = NULL;
    Expression         *increment   = NULL;
    Expression         *variable    = NULL;
    Expression         *expression  = NULL;
    Statement          *statement   = NULL;
    VariableExpression *ve          = NULL;

    // 'for' statements can be one of the follow four productions:
    //
    // for ( ExpressionNoIn_opt; Expression_opt ; Expression_opt ) Statement
    // for ( var VariableDeclarationListNoIn; Expression_opt ; Expression_opt ) Statement
    // for ( LeftHandSideExpression in Expression ) Statement
    // for ( var VariableDeclarationNoIn in Expression ) Statement

    readToken(LSTOKEN(KEYWORD_FOR));

    bool foreach = false;
    if (nextToken->value.str() == "each")
    {
        foreach = true;
        readToken();
    }

    readToken(LSTOKEN(OPERATOR_OPENPAREN));

    int state = 0;
    while (statement == NULL)
    {
        switch (state)
        {
        case 0:
            // initial state
            if (nextToken == LSTOKEN(KEYWORD_VAR))
            {
                state = 1;
            }
            else if (nextToken != LSTOKEN(OPERATOR_SEMICOLON))
            {
                state = 2;
            }
            else
            {
                state = 5;
            }
            break;

        case 1:
            // 'for' '(' 'var'
            readToken(LSTOKEN(KEYWORD_VAR));
            declaration = parseVariableDeclaration(false);
            if (nextToken == LSTOKEN(KEYWORD_IN))
            {
                variable = declaration;
                state    = 3;
            }
            else
            {
                state = 4;
            }
            break;

        case 2:
            // 'for' '(' Expression
            initial = parseExpression(false);
            if (nextToken == LSTOKEN(KEYWORD_IN))
            {
                variable = initial;
                state    = 3;
            }
            else
            {
                state = 5;
            }
            break;

        case 3:
            // 'for' '(' ... 'in'
            readToken(LSTOKEN(KEYWORD_IN));
            expression = parseExpression(true);
            readToken(LSTOKEN(OPERATOR_CLOSEPAREN));

            // 'for' '(' ... 'in' ... ')' Statement
            statement = new ForInStatement(variable, expression,
                                           parseStatement(), foreach);
            break;

        case 4:
            // 'for' '(' 'var' VariableDeclarationList
            ve = new VariableExpression();

            if (!ve->declarations)
            {
                ve->declarations = new utArray<VariableDeclaration *>();
            }

            ve->declarations->push_back((VariableDeclaration *)declaration);
            while (nextToken == LSTOKEN(OPERATOR_COMMA))
            {
                readToken(LSTOKEN(OPERATOR_COMMA));
                ve->declarations->push_back(parseVariableDeclaration(false));
            }
            initial = ve;

        // fall through

        case 5:
            // 'for' '(' ... ';'
            readToken(LSTOKEN(OPERATOR_SEMICOLON));

            // 'for' '(' ... ';' ...
            if (nextToken != LSTOKEN(OPERATOR_SEMICOLON))
            {
                condition = parseExpression(true);
            }

            // 'for' '(' ... ';' ... ';'
            readToken(LSTOKEN(OPERATOR_SEMICOLON));

            // 'for' '(' ... ';' ... ';' ...
            if (nextToken != LSTOKEN(OPERATOR_CLOSEPAREN))
            {
                increment = parseExpression(true);
            }

            // 'for' '(' ... ';' ... ';' ... ')'
            readToken(LSTOKEN(OPERATOR_CLOSEPAREN));

            // 'for' '(' ... ';' ... ';' ... ')' Statement
            statement = new ForStatement(initial, condition, increment,
                                         parseStatement());
            break;
        }
    }

    return statement;
}


Statement *Parser::parseIfStatement()
{
    Expression *expression     = NULL;
    Statement  *trueStatement  = NULL;
    Statement  *falseStatement = NULL;

    readToken(LSTOKEN(KEYWORD_IF));
    readToken(LSTOKEN(OPERATOR_OPENPAREN));
    expression = parseExpression(true);
    readToken(LSTOKEN(OPERATOR_CLOSEPAREN));

    trueStatement = parseStatement();

    if (nextToken == LSTOKEN(KEYWORD_ELSE))
    {
        readToken(LSTOKEN(KEYWORD_ELSE));
        falseStatement = parseStatement();
    }

    return new IfStatement(expression, trueStatement, falseStatement);
}


Statement *Parser::parseReturnStatement()
{
    utArray<Expression *> *result = NULL;

    readToken(LSTOKEN(KEYWORD_RETURN));

    if (nextToken != LSTOKEN(OPERATOR_SEMICOLON))
    {
        result = new utArray<Expression *>();

        Expression *e = parseAssignmentExpression(true, false);
        if (e)
        {
            result->push_back(e);
        }

        while (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
            readToken();
            e = parseConditionalExpression(true);
            if (e)
            {
                result->push_back(e);
            }
        }
    }

    return new ReturnStatement(result);
}


Statement *Parser::parseSwitchStatement()
{
    SwitchStatement *ss         = new SwitchStatement();
    bool            defaultSeen = false;

    readToken(LSTOKEN(KEYWORD_SWITCH));
    readToken(LSTOKEN(OPERATOR_OPENPAREN));
    Expression *switchExpression = parseExpression(true);
    readToken(LSTOKEN(OPERATOR_CLOSEPAREN));

    readToken(LSTOKEN(OPERATOR_OPENBRACE));

    while (nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
    {
        Expression *caseExpression = NULL;

        utArray<Statement *> caseStatements;

        if (nextToken == LSTOKEN(KEYWORD_CASE))
        {
            readToken(LSTOKEN(KEYWORD_CASE));
            caseExpression = parseExpression(true);
            readToken(LSTOKEN(OPERATOR_COLON));
        }
        else
        {
            if (defaultSeen == false)
            {
                defaultSeen = true;
            }
            else
            {
                error("duplication default clause in switch statement");
            }

            readToken(LSTOKEN(KEYWORD_DEFAULT));
            caseExpression = NULL;
            readToken(LSTOKEN(OPERATOR_COLON));
        }

        while (nextToken != LSTOKEN(KEYWORD_CASE) &&
               nextToken != LSTOKEN(KEYWORD_DEFAULT) &&
               nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
        {
            caseStatements.push_back(parseStatement());
        }

        CaseStatement *cs = new CaseStatement();

        cs->expression = caseExpression;

        cs->statements = new utArray<Statement *>();

        *cs->statements = caseStatements;

        if (!ss->clauses)
        {
            ss->clauses = new utArray<CaseStatement *>();
        }

        ss->clauses->push_back(cs);
    }

    ss->expression = switchExpression;

    readToken(LSTOKEN(OPERATOR_CLOSEBRACE));

    // check for duplicate number clause expressions
    if (ss->clauses)
    {
        utArray<double> caseValues;
        for (UTsize i = 0; i < ss->clauses->size(); i++)
        {
            CaseStatement *cs = ss->clauses->at(i);
            if (cs->expression)
            {
                if (cs->expression->astType == AST_NUMBERLITERAL)
                {
                    double n = ((NumberLiteral *)cs->expression)->value;
                    if (caseValues.find(n) != UT_NPOS)
                    {
                        error("duplicate case found in switch");
                    }
                    caseValues.push_back(n);
                }
            }
        }
    }

    return ss;
}


Statement *Parser::parseThrowStatement()
{
    readToken(LSTOKEN(KEYWORD_THROW));

    warn("throw is currently not supported in LoomScript. For now, throw is rewritten to be Debug.assert!");

    return new ThrowStatement(parseExpression(true));
}


Statement *Parser::parseTryStatement()
{
    warn("try/catch is currently not supported; try is ignored and catch/finally blocks are never run!");

    Statement           *tryBlock     = NULL;
    VariableDeclaration *catchVar     = NULL;
    Statement           *catchBlock   = NULL;
    Statement           *finallyBlock = NULL;

    readToken(LSTOKEN(KEYWORD_TRY));
    tryBlock = parseBlockStatement();

    if ((nextToken != LSTOKEN(KEYWORD_CATCH)) &&
        (nextToken != LSTOKEN(KEYWORD_FINALLY)))
    {
        error("catch or finally expected after try");
    }

    if (nextToken == LSTOKEN(KEYWORD_CATCH))
    {
        readToken(LSTOKEN(KEYWORD_CATCH));
        readToken(LSTOKEN(OPERATOR_OPENPAREN));
        catchVar = parseVariableDeclaration(false);
        readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
        catchBlock = parseBlockStatement();
    }

    if (nextToken == LSTOKEN(KEYWORD_FINALLY))
    {
        readToken(LSTOKEN(KEYWORD_FINALLY));
        finallyBlock = parseBlockStatement();
    }

    return new TryStatement(tryBlock, catchVar, catchBlock, finallyBlock);
}


Statement *Parser::parseVariableStatement()
{
    utArray<VariableDeclaration *> *decls = new utArray<VariableDeclaration *>();

    bool isConst = false;
    if (nextToken == LSTOKEN(KEYWORD_CONST))
    {
        isConst = true;
    }

    // KEYWORD_VAR or KEYWORD_CONST
    readToken();

    // there must be at least one variable declaration
    decls->push_back(parseVariableDeclaration(true));
    decls->back()->isConst = isConst;

    while (nextToken == LSTOKEN(OPERATOR_COMMA))
    {
        readToken(LSTOKEN(OPERATOR_COMMA));
        decls->push_back(parseVariableDeclaration(true));
        decls->back()->isConst = isConst;
    }

    return new VariableStatement(decls);
}


Statement *Parser::parseWhileStatement()
{
    Statement  *statement;
    Expression *expression;

    readToken(LSTOKEN(KEYWORD_WHILE));
    readToken(LSTOKEN(OPERATOR_OPENPAREN));
    expression = parseExpression(true);
    readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
    statement = parseStatement();

    return new WhileStatement(expression, statement);
}


Statement *Parser::parseWithStatement()
{
    Statement  *statement;
    Expression *expression;

    readToken(LSTOKEN(KEYWORD_WITH));
    readToken(LSTOKEN(OPERATOR_OPENPAREN));
    expression = parseExpression(true);
    readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
    statement = parseStatement();

    return new WithStatement(expression, statement);
}


Statement *Parser::parseExpressionStatement()
{
    Expression *expression = parseExpression(true);

    if (expression->astType == AST_BINARYOPERATOREXPRESSION)
    {
        BinaryOperatorExpression *be = (BinaryOperatorExpression *)expression;
        if (be->op == LSTOKEN(OPERATOR_EQUALEQUAL))
        {
            warn("result of equality test is unused, assignment intended?");
        }
    }


    // TODO there are comments in the v8 code about wrapping a
    // labelled try statement in a block and applying the label to the outer
    // block. we should consider doing something similar here if handling a
    // labelled try block proves problematic.

    //TODO: I think this cast is right, emphasis on think...
    if (dynamic_cast<Identifier *>((Identifier *)expression) &&
        (nextToken == LSTOKEN(OPERATOR_COLON)))
    {
        readToken(LSTOKEN(OPERATOR_COLON));
        return new LabelledStatement((Identifier *)expression,
                                     parseStatement());
    }
    else
    {
        return new ExpressionStatement(expression);
    }
}


void Parser::parsePath(utArray<utString>& path)
{
    if (nextToken->isIdentifier())
    {
        path.push_back(nextToken->value.str());
    }
    else if (nextToken->isKeyword())
    {
        path.push_back(nextToken->value.str());
    }
    else
    {
        error("Unable to parse package path");
    }

    readToken();

    while (nextToken == LSTOKEN(OPERATOR_DOT))
    {
        readToken(LSTOKEN(OPERATOR_DOT));

        if (nextToken == LSTOKEN(OPERATOR_MULTIPLY))
        {
            path.push_back("*");
            readToken(LSTOKEN(OPERATOR_MULTIPLY));
        }
        else
        {
            if (nextToken->isIdentifier())
            {
                path.push_back(nextToken->value.str());
            }
            else if (nextToken->isKeyword())
            {
                path.push_back(nextToken->value.str());
            }
            else
            {
                error("Unable to parse package path");
            }

            readToken();
        }
    }
}


Statement *Parser::parseImportStatement()
{
    ImportStatement *import = new ImportStatement();

    readToken(LSTOKEN(KEYWORD_IMPORT));

    parsePath(import->path);

    import->classname = import->path.back();

    import->path.pop_back();

    utString pname;

    for (unsigned int i = 0; i < import->path.size(); i++)
    {
        pname += import->path[i];

        if (i < import->path.size() - 1)
        {
            pname += ".";
        }
    }

    import->spath = pname;

    import->fullPath  = pname;
    import->fullPath += ".";
    import->fullPath += import->classname;

    if (nextToken == LSTOKEN(KEYWORD_AS))
    {
        readToken(LSTOKEN(KEYWORD_AS));
        import->asIdentifier = parseIdentifier();
    }

    return import;
}


Statement *Parser::parsePackageDeclaration()
{
    PackageDeclaration *pkg = new PackageDeclaration();

    readToken(LSTOKEN(KEYWORD_PACKAGE));

    if (nextToken != LSTOKEN(OPERATOR_OPENBRACE))
    {
        parsePath(pkg->path);
    }

    utString pname;

    for (unsigned int i = 0; i < pkg->path.size(); i++)
    {
        pname += pkg->path[i];

        if (i < pkg->path.size() - 1)
        {
            pname += ".";
        }
    }

    pkg->spath = pname;

    readToken(LSTOKEN(OPERATOR_OPENBRACE));

    while (nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
    {
        if (!pkg->statements)
        {
            pkg->statements = new utArray<Statement *>();
        }

        pkg->statements->push_back(parseElement());
    }

    readToken(LSTOKEN(OPERATOR_CLOSEBRACE));

    return pkg;
}


void Parser::initNativeMetaTag(MetaTag *tag)
{
    tag->name = "Native";
}


void Parser::parseMetaTag()
{
    MetaTag *tag = new MetaTag();

    readToken(LSTOKEN(OPERATOR_OPENSQUARE));

    assert(nextToken->type == TIDENTIFIER);

    tag->name = nextToken->value.str();

    readToken();

    if (tag->name == "Native")
    {
        initNativeMetaTag(tag);
    }

    if (nextToken == LSTOKEN(OPERATOR_OPENPAREN))
    {
        readToken(LSTOKEN(OPERATOR_OPENPAREN));

        bool first = true;

        while (first || nextToken == LSTOKEN(OPERATOR_COMMA))
        {
            first = false;

            if (nextToken == LSTOKEN(OPERATOR_COMMA))
            {
                readToken();
            }

            if ((nextToken->type != TIDENTIFIER) && (nextToken->type != TKEYWORD))
            {
                break;
            }

            utString key = nextToken->value.str();
            readToken();

            utString value;

            if (nextToken == LSTOKEN(OPERATOR_ASSIGNMENT))
            {
                readToken(LSTOKEN(OPERATOR_ASSIGNMENT));
                assert(nextToken->type == TSTRING);
                value = nextToken->value.str();
                readToken();
            }

            tag->keys.insert(key, value);
        }

        readToken(LSTOKEN(OPERATOR_CLOSEPAREN));
    }

    readToken(LSTOKEN(OPERATOR_CLOSESQUARE));

    curTags.push_back(tag);
}


Statement *Parser::parseEnumStatement()
{
    ClassDeclaration *cls = new ClassDeclaration();

    cls->metaTags = curTags;
    curTags.clear();

    readToken(LSTOKEN(KEYWORD_ENUM));

    cls->name = parseIdentifier();

    cls->isPublic = sawPublic;
    cls->isEnum   = true;
    cls->extends  = new Identifier("system.Object");

    readToken(LSTOKEN(OPERATOR_OPENBRACE));

    int cvalue = 0;

    cls->statements = new utArray<Statement *>();

    while (nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
    {
        NumberLiteral *nliteral = NULL;
        Identifier    *ident    = parseIdentifier();
        if (nextToken == LSTOKEN(OPERATOR_ASSIGNMENT))
        {
            readToken();
            nliteral = parseNumericLiteral();
        }
        else
        {
            nliteral = new NumberLiteral(cvalue);
        }

        cvalue = (int)(nliteral->value + 1);

        VariableDeclaration *vd = new VariableDeclaration(ident, nliteral,
                                                          true, false, true, false);

        vd->defaultInitializer = false;
        vd->isParameter        = false;
        vd->typeString         = cls->name->string;

        utArray<VariableDeclaration *> *decls = new utArray<VariableDeclaration *>();
        decls->push_back(vd);
        VariableStatement *statement = new VariableStatement(decls);
        cls->statements->push_back(statement);

        if (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
            readToken();
        }
    }

    readToken(LSTOKEN(OPERATOR_CLOSEBRACE));

    return cls;
}


Statement *Parser::parseClassDeclaration()
{
    ClassDeclaration *cls = new ClassDeclaration();

    cls->metaTags = curTags;
    curTags.clear();

    if (currentMultilineComment.length())
    {
        cls->docString = currentMultilineComment;
    }
    currentMultilineComment = "";

    curClass = cls;

    if (nextToken == LSTOKEN(KEYWORD_INTERFACE))
    {
        curClass->isInterface = true;
    }

    if (nextToken == LSTOKEN(KEYWORD_STRUCT))
    {
        curClass->isStruct = true;
    }

    if (nextToken == LSTOKEN(KEYWORD_DELEGATE))
    {
        curClass->isDelegate = true;
    }

    // class, struct,  or interface
    readToken();

    cls->name = parseIdentifier();

    cls->isPublic = sawPublic;
    cls->isStatic = sawStatic;
    cls->isFinal  = sawFinal;

    // reset static/public
    sawPublic = false;
    sawStatic = false;
    sawFinal  = false;

    // parse delegate
    if (curClass->isDelegate)
    {
        //delegate MyDelegate(x:Number, y:Number):String;
        readToken(LSTOKEN(OPERATOR_OPENPAREN));
        if (nextToken != LSTOKEN(OPERATOR_CLOSEPAREN))
        {
            VariableDeclaration *parm = parseVariableDeclaration(true, true);
            cls->delegateParameters.push_back(parm);

            while (nextToken != LSTOKEN(OPERATOR_CLOSEPAREN))
            {
                readToken(LSTOKEN(OPERATOR_COMMA));

                parm = parseVariableDeclaration(true, true);
                cls->delegateParameters.push_back(parm);
            }
        }

        readToken(LSTOKEN(OPERATOR_CLOSEPAREN));

        if (nextToken == LSTOKEN(OPERATOR_COLON))
        {
            // parse type
            readToken();

            if (nextToken == LSTOKEN(KEYWORD_VOID))
            {
                cls->delegateReturnType = new Identifier("Void");
                readToken();
            }
            else
            {
                cls->delegateReturnType = parseIdentifier();
            }
        }
        else
        {
            cls->delegateReturnType = new Identifier("Void");
        }

        cls->extends = new Identifier("BaseDelegate");

        return cls;
    }

    if (nextToken == LSTOKEN(KEYWORD_EXTENDS))
    {
        readToken(LSTOKEN(KEYWORD_EXTENDS));

        cls->extends = parseIdentifier();
    }
    else
    {
        if (!cls->isInterface)
        {
            if (cls->name->string != "Object")
            {
                cls->extends = new Identifier("Object");
            }
        }
    }

    if (nextToken == LSTOKEN(KEYWORD_IMPLEMENTS))
    {
        readToken(LSTOKEN(KEYWORD_IMPLEMENTS));

        Identifier *iface = parseIdentifier();
        cls->implements.push_back(iface);
        while (nextToken == LSTOKEN(OPERATOR_COMMA))
        {
            readToken(LSTOKEN(OPERATOR_COMMA));
            iface = parseIdentifier();
            cls->implements.push_back(iface);
        }
    }

    readToken(LSTOKEN(OPERATOR_OPENBRACE));

    while (nextToken != LSTOKEN(OPERATOR_CLOSEBRACE))
    {
        if (!cls->statements)
        {
            cls->statements = new utArray<Statement *>();
        }

        utString doc = currentMultilineComment;
        currentMultilineComment = "";

        Statement *s = parseElement();

        cls->statements->push_back(s);

        // copy docstring
        if (s->astType == AST_VARSTATEMENT)
        {
            VariableStatement *vstatement = (VariableStatement *)s;
            for (UTsize i = 0; i < vstatement->declarations->size(); i++)
            {
                vstatement->declarations->at(i)->docString = doc;
            }
        }

        if (s->astType == AST_FUNCTIONDECL)
        {
            FunctionDeclaration *decl = (FunctionDeclaration *)s;
            decl->literal->docString = doc;
        }

        if (s->astType == AST_PROPERTYDECL)
        {
            PropertyDeclaration *pdecl = (PropertyDeclaration *)s;
            pdecl->literal->docString = doc;
        }

        if ((s->astType != AST_VARSTATEMENT) && (s->astType != AST_FUNCTIONDECL) &&
            (s->astType != AST_EMPTYSTATEMENT) &&
            (s->astType != AST_PROPERTYDECL))
        {
            Expression *e = NULL;
            if (s->astType == AST_EXPRESSIONSTATEMENT)
            {
                e = ((ExpressionStatement *)s)->expression;
            }

            if (!e || (e->astType != AST_FUNCTIONLITERAL))
            {
                error("Class statement is not a variable declaration or function declaration");
            }
        }
    }

    readToken(LSTOKEN(OPERATOR_CLOSEBRACE));

    return cls;
}


ASTTemplateTypeInfo *Parser::parseTemplateType(const utString& templateType, ASTTemplateTypeInfo *parent, bool skipDot)
{
    if ((templateType != "Vector") &&
        (templateType != "Dictionary"))
    {
        error(utStringFormat("Attempting to parse template of type %s - only Vector and Dictionary are supported.", templateType.c_str()).c_str());
    }

    ASTTemplateTypeInfo *templateInfo = new ASTTemplateTypeInfo;
    templateInfo->typeString = templateType;

    if (!skipDot)
    {
        readToken(LSTOKEN(OPERATOR_DOT));
    }

    readToken(LSTOKEN(OPERATOR_LESSTHAN));


    bool first = true;

    while (nextToken == LSTOKEN(OPERATOR_COMMA) || first)
    {
        if (!first)
        {
            readToken(); // read comma
        }
        utString stype = nextToken->value.str();
        readToken();

        if ((stype == "Vector") || (stype == "Dictionary"))
        {
            // recurse
            ASTTemplateTypeInfo *ti = parseTemplateType(stype, templateInfo);
            templateInfo->templateTypes.push_back(ti);
        }
        else if (stype == "Array")
        {
            warn("Rewriting Array to be Vector.<Object> for convenience when porting. Note that Array and Vector.<Object> aren't identical types.");

            // Array is secretly a Vector.<Object>
            ASTTemplateTypeInfo *ti = ASTTemplateTypeInfo::createVectorInfo("system.Object");        
            templateInfo->templateTypes.push_back(ti);
        }
        else
        {
            ASTTemplateTypeInfo *ti = new ASTTemplateTypeInfo;
            ti->typeString = stype;
            templateInfo->templateTypes.push_back(ti);
        }

        first = false;
    }

    // Allow template types to be nested without whitespace, ie,
    // Vector.<Vector.<Vector.<Vector.<Object>>>>
    if (nextToken == LSTOKEN(OPERATOR_SHIFTRIGHTUNSIGNED))
    {
        // Convert the >>> into a >> and let parsing continue.
        nextToken = LSTOKEN(OPERATOR_SHIFTRIGHT);
    }
    else if (nextToken == LSTOKEN(OPERATOR_SHIFTRIGHT))
    {
        // Convert the >> into a > and let parsing continue.
        nextToken = LSTOKEN(OPERATOR_GREATERTHAN);
    }
    else
    {
        // Advance normally.
        readToken(LSTOKEN(OPERATOR_GREATERTHAN));
    }

    return templateInfo;
}


Statement *Parser::parseStatement()
{
    Statement *statement = NULL;
    int       lineNumber = lexer.lineNumber;

    // metatags
    while (nextToken == LSTOKEN(OPERATOR_OPENSQUARE))
    {
        parseMetaTag();
    }

    // modifiers

    bool sawNative     = false;
    bool createdNative = false;
    bool skipSemiColon = false;

    while (nextToken->isModifier())
    {
        if ((nextToken == LSTOKEN(KEYWORD_PUBLIC)) ||
            (nextToken == LSTOKEN(KEYWORD_PRIVATE)) ||
            (nextToken == LSTOKEN(KEYWORD_PROTECTED)))
        {
            if (nextToken == LSTOKEN(KEYWORD_PUBLIC))
            {
                sawPublic = true;
            }

            if (nextToken == LSTOKEN(KEYWORD_PROTECTED))
            {
                sawProtected = true;
            }

            readToken();
        }

        if (nextToken == LSTOKEN(KEYWORD_STATIC))
        {
            readToken();
            sawStatic = true;
        }

        if (nextToken == LSTOKEN(KEYWORD_FINAL))
        {
            readToken();
            sawFinal = true;
        }

        if (nextToken == LSTOKEN(KEYWORD_OVERRIDE))
        {
            readToken();
        }

        if (nextToken == LSTOKEN(KEYWORD_NATIVE))
        {
            readToken();

            // if we don't already have a native metatag specified, add it
            if (!findMetaTag(curTags, "Native"))
            {
                createdNative = true;

                MetaTag *tag = new MetaTag();
                initNativeMetaTag(tag);
                curTags.push_back(tag);
            }

            sawNative = true;
        }

        if (nextToken == LSTOKEN(KEYWORD_OPERATOR))
        {
            readToken();
            sawOperator = true;
        }
    }

    MetaTag *nativeTag = findMetaTag(curTags, "Native");
    if (!sawNative && nativeTag)
    {
        error("[Native] metatag on non-native class or member, please specify the native keyword in the class declaration");
    }

    if (nativeTag && !createdNative && !nativeTag->keys.size())
    {
        warn("[Native] metatag does not specify any attributes and is unnecessary");
    }

    if (nextToken == LSTOKEN(OPERATOR_SEMICOLON))
    {
        readToken(LSTOKEN(OPERATOR_SEMICOLON));
        statement     = new EmptyStatement();
        skipSemiColon = true;
    }
    else if (nextToken == LSTOKEN(OPERATOR_OPENBRACE))
    {
        statement     = parseBlockStatement();
        skipSemiColon = true;
    }
    else if (nextToken == LSTOKEN(KEYWORD_BREAK))
    {
        statement = parseBreakStatement();
    }
    else if (nextToken == LSTOKEN(KEYWORD_CONTINUE))
    {
        statement = parseContinueStatement();
    }
    else if (nextToken == LSTOKEN(KEYWORD_DO))
    {
        statement     = parseDoStatement();
        skipSemiColon = true;
    }
    else if (nextToken == LSTOKEN(KEYWORD_FOR))
    {
        statement     = parseForStatement();
        skipSemiColon = true;
    }
    else if (nextToken == LSTOKEN(KEYWORD_IF))
    {
        statement     = parseIfStatement();
        skipSemiColon = true;
    }
    else if (nextToken == LSTOKEN(KEYWORD_RETURN))
    {
        statement = parseReturnStatement();
    }
    else if (nextToken == LSTOKEN(KEYWORD_THROW))
    {
        statement     = parseThrowStatement();
        skipSemiColon = true;
    }
    else if (nextToken == LSTOKEN(KEYWORD_TRY))
    {
        statement     = parseTryStatement();
        skipSemiColon = true;
    }
    else if (nextToken == LSTOKEN(KEYWORD_SWITCH))
    {
        statement     = parseSwitchStatement();
        skipSemiColon = true;
    }
    else if ((nextToken == LSTOKEN(KEYWORD_VAR)) ||
             (nextToken == LSTOKEN(KEYWORD_CONST)))
    {
        statement = parseVariableStatement();
    }
    else if (nextToken == LSTOKEN(KEYWORD_WHILE))
    {
        statement     = parseWhileStatement();
        skipSemiColon = true;
    }
    else if (nextToken == LSTOKEN(KEYWORD_WITH))
    {
        statement = parseWithStatement();
    }
    else if (nextToken == LSTOKEN(KEYWORD_PACKAGE))
    {
        skipSemiColon = true;
        statement     = parsePackageDeclaration();
    }
    else if (nextToken == LSTOKEN(KEYWORD_IMPORT))
    {
        statement = parseImportStatement();
    }
    else if (nextToken == LSTOKEN(KEYWORD_ENUM))
    {
        statement     = parseEnumStatement();
        skipSemiColon = true;
    }
    else if ((nextToken == LSTOKEN(KEYWORD_CLASS)) ||
             (nextToken == LSTOKEN(KEYWORD_INTERFACE)) ||
             (nextToken == LSTOKEN(KEYWORD_STRUCT)) ||
             (nextToken == LSTOKEN(KEYWORD_DELEGATE)))
    {
        skipSemiColon = true;
        statement     = parseClassDeclaration();
    }
    else if (nextToken == LSTOKEN(KEYWORD_FUNCTION))
    {
        if (!sawNative)
        {
            skipSemiColon = true;
        }

        readToken(LSTOKEN(KEYWORD_FUNCTION));

        if ((nextToken == LSTOKEN(KEYWORD_GET)) || (nextToken == LSTOKEN(KEYWORD_SET)))
        {
            // this can be empty statement if matching getter/setter
            statement = parsePropertyDeclaration();
        }
        else
        {
            statement = parseFunctionDeclaration();
        }
    }
    else
    {
        statement = parseExpressionStatement();
    }

    statement->lineNumber = lineNumber;

    if (!skipSemiColon)
    {
        readTokenSemicolon(statement);
    }

    sawPublic    = false;
    sawProtected = false;
    sawStatic    = false;
    sawOperator  = false;
    sawFinal     = false;

    return statement;
}


Statement *Parser::parseElement()
{
    if (nextToken == LSTOKEN(KEYWORD_FUNCTION))
    {
        readToken(LSTOKEN(KEYWORD_FUNCTION));

        if ((nextToken == LSTOKEN(KEYWORD_GET)) || (nextToken == LSTOKEN(KEYWORD_SET)))

        {
            return parsePropertyDeclaration();
        }

        return parseFunctionDeclaration();
    }
    else
    {
        return parseStatement();
    }
}


CompilationUnit *Parser::parseCompilationUnit(BuildInfo *buildInfo)
{
    CompilationUnit *cunit = new CompilationUnit();

    this->buildInfo  = buildInfo;
    cunit->buildInfo = buildInfo;

    cunit->filename = this->filename;

    cunit->statements = new utArray<Statement *>();

    try
    {
        while (nextToken != LSTOKEN(TOKEN_EOF))
        {
            cunit->statements->push_back(parseElement());
        }

        // report semicolon errors, NOW!
        for (UTsize i = 0; i < semicolonLineErrors.size(); i++)
        {
            error("statement must end with ;", semicolonLineErrors.at(i));
        }
    }
    catch (int e)
    {
        // TODO: LOOM-1183 more than one parser error per compilation unit.
        //       compiler log is setup to do this, however parser is fragile once
        //       it hits an error, we will get multiple parser errors across
        //       compilation units however

        // shhhh compiler
        (void)(e);
    }



    return cunit;
}


MetaTag *Parser::findMetaTag(utArray<MetaTag *>& tags, const utString& name)
{
    for (UTsize i = 0; i < tags.size(); i++)
    {
        MetaTag *tag = tags.at(i);
        if (tag->name == name)
        {
            return tag;
        }
    }

    return NULL;
}


void Parser::error(const char *message, int lineNumber)
{
    if (lineNumber == -1)
    {
        lineNumber = lexer.lineNumber;
    }

    if (lastErrorLine == lineNumber)
    {
        return;
    }

    lastErrorLine = lineNumber;

    LSCompilerLog::logError(filename, lineNumber, message, "Parser");

    // throw an exception see not about LOOM-1183 in handler
    throw -1;
}


void Parser::warn(const char *message)
{
    if (lastWarningLine == lexer.lineNumber)
    {
        return;
    }

    lastWarningLine = lexer.lineNumber;

    LSCompilerLog::logWarning(filename, lexer.lineNumber, message, "Parser");
}


void Parser::readToken(Token *token)
{
    if (nextToken == token)
    {
        readToken();
    }
    else
    {
        char errormsg[1024];
        sprintf(errormsg, "expected %s but got %s",
                token->value.str().c_str(),
                nextToken ? nextToken->value.str().c_str() : "(unknown)");
        error(errormsg);
    }
}


void Parser::readTokenSemicolon(Statement *statement)
{
    if (nextToken == LSTOKEN(OPERATOR_SEMICOLON))
    {
        readToken();
    }
    else
    {
        semicolonLineErrors.push_back(statement->lineNumber);
    }
}


void Parser::readToken()
{
    sawNewline = false;

    do
    {
        nextToken = lexer.nextToken();

        if (nextToken->type == TMULTILINECOMMENT)
        {
            currentMultilineComment = nextToken->value.str().c_str();
        }

        if (nextToken->isEOF() || nextToken->isNewLine())
        {
            sawNewline = true;
        }
    } while (nextToken->isWhitespace());
}


void Parser::unreadToken()
{
    lexer.unreadToken();
}
}
