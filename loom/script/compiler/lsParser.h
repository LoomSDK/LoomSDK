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

#ifndef _ls_parser_h
#define _ls_parser_h

extern "C" {
#include "lua.h"
}

#include "loom/script/compiler/lsLexer.h"
#include "loom/script/compiler/lsAST.h"

namespace LS {
class BuildInfo;
class Parser {
private:

    Lexer lexer;

    Token *nextToken;

    int lastErrorLine;
    int lastWarningLine;

    bool sawNewline;

    bool sawPublic;
    bool sawProtected;
    bool sawStatic;
    bool sawOperator;
    bool sawFinal;

    utArray<MetaTag *> curTags;

    // an array of line numbers which need a semicolon
    // we store these like this so we can report them at the end
    // and note hide other errors
    utArray<int> semicolonLineErrors;

    utString filename;
    Tokens   *tokens;

    utString currentMultilineComment;

    ClassDeclaration *curClass;

    void error(const char *message, int lineNumber = -1);
    void warn(const char *message);

    void readToken();
    void readToken(Token *token);
    void readTokenSemicolon(Statement *statement);

    void unreadToken();

    void initNativeMetaTag(MetaTag *tag);
    void parseMetaTag();
    void parseMetaTags();

    Expression *parseDefaultArgument();

    Identifier *parseIdentifier();

    Statement *parseStatement();
    Statement *parseBlockStatement();
    Statement *parseBreakStatement();
    Statement *parseContinueStatement();
    Statement *parseDoStatement();
    Statement *parseForStatement();
    Statement *parseIfStatement();
    Statement *parseReturnStatement();
    Statement *parseSwitchStatement();
    Statement *parseThrowStatement();
    Statement *parseTryStatement();
    Statement *parseVariableStatement();
    Statement *parseWhileStatement();
    Statement *parseWithStatement();
    Statement *parseExpressionStatement();

    NumberLiteral *parseNumericLiteral();
    StringLiteral *parseStringLiteral();
    ObjectLiteralProperty *parseObjectLiteralProperty();
    ObjectLiteral *parseObjectLiteral();
    ArrayLiteral *parseArrayLiteral();

    DictionaryLiteralPair *parseDictionaryLiteralPair();
    Expression *parseDictionaryLiteral(const utString& typeKey, const utString& typeValue, bool wrapInNew = false);
    Expression *parseVectorLiteral(const utString& type, bool wrapInNew = false);

    Expression *parsePrimaryExpression();

    void parseArgumentList(utArray<Expression *> *args);

    Expression *parseMemberExpression(bool newFlag);

    Expression *parseSuperExpression();

    Expression *parsePostfixExpression();

    Expression *parseUnaryExpression();
    Expression *parseConcatExpression();

    Expression *parseMultiplyExpression();
    Expression *parseAdditionExpression();
    Expression *parseShiftExpression();
    Expression *parseRelationalExpression(bool inFlag);
    Expression *parseEqualityExpression(bool inFlag);

    Expression *parseBitwiseAndExpression(bool inFlag);
    Expression *parseBitwiseXorExpression(bool inFlag);
    Expression *parseBitwiseOrExpression(bool inFlag);
    Expression *parseLogicalAndExpression(bool inFlag);
    Expression *parseLogicalOrExpression(bool inFlag);
    Expression *parseConditionalExpression(bool inFlag);
    Expression *parseAssignmentExpression(bool inFlag, bool parseComma = false);
    Expression *parseExpression(bool inFlag);

    FunctionLiteral *parseFunctionLiteral(bool nameFlag);
    Statement *parseFunctionDeclaration();
    Statement *parsePropertyDeclaration();
    VariableDeclaration *parseVariableDeclaration(bool inFlag, bool inFunctionParameters = false);
    VariableDeclaration *parseVarArgDeclaration(bool inFlag);

    Statement *parseImportStatement();
    Statement *parsePackageDeclaration();
    Statement *parseEnumStatement();
    Statement *parseClassDeclaration();

    ASTTemplateTypeInfo *parseTemplateType(const utString& templateType, ASTTemplateTypeInfo *parent = NULL, bool skipDot = false);

    Statement *parseTopLevelElement();
    Statement *parseElement();

    void parsePath(utArray<utString>& path);

    Expression *generatePropertyCall(const utString& object, const utString& member, Expression *argument);

    MetaTag *findMetaTag(utArray<MetaTag *>& tags, const utString& name);

    BuildInfo *buildInfo;

public:

    Parser(const utString& input, const utString& filename);
    CompilationUnit *parseCompilationUnit(BuildInfo *buildInfo);
};
}
#endif
