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

UT_IMPLEMENT_SINGLETON(LS::Tokens);

namespace LS {
utHashTable<utIntHashKey, utHashedString> Token::sAllValues;
utHashTable<utIntHashKey, Token *>        Token::sKeywords;

Token::Token()
{
}


Token::Token(TokenType t, const char *value, const char *preAlias)
{
    preAliasValue = preAlias ? preAlias : "";

    type = t;

    //utHashedString svalue(value);

    //if (sAllValues.find(svalue.hash()) == UT_NPOS)
    //    sAllValues.insert(svalue.hash(), svalue);

    this->value = value; //*sAllValues.get(svalue.hash());

}

Token::Token(TokenType t, const utString &input, int start, int end) 
{
    type = t;

    //utHashedString svalue(input.substr(start, end - start));
    
    //if (sAllValues.find(svalue.hash()) == UT_NPOS)
    //    sAllValues.insert(svalue.hash(), svalue);

    value = input.substr(start, end - start); //*sAllValues.get(svalue.hash());
}


void Token::initKeyword(const char *value)
{
    type = TKEYWORD;

    utHashedString svalue(value);

    if (sAllValues.find(svalue.hash()) == UT_NPOS)
    {
        sAllValues.insert(svalue.hash(), svalue);
    }

    this->value = *sAllValues.get(svalue.hash());

    sKeywords.insert(svalue.hash(), this);
}


Token *Token::getKeyword(const char *t)
{
    utHashedString svalue(t);

    Token **tt = sKeywords.get(svalue.hash());

    if (tt)
    {
        return *tt;
    }

    return 0;
}


void Token::initOperator(const char *value)
{
    type = TOPERATOR;

    utHashedString svalue(value);

    if (sAllValues.find(svalue.hash()) == UT_NPOS)
    {
        sAllValues.insert(svalue.hash(), svalue);
    }

    this->value = *sAllValues.get(svalue.hash());
}


static Tokens sTokens;

Tokens::Tokens()
{
    /* Whitespace Tokens */
    NEWLINE.type           = TNEWLINE;
    SINGLELINECOMMENT.type = TSINGLELINECOMMENT;
    WHITESPACE.type        = TWHITESPACE;

    /* keywords*/
    KEYWORD_BREAK.initKeyword("break");
    KEYWORD_CASE.initKeyword("case");
    KEYWORD_CATCH.initKeyword("catch");
    KEYWORD_CONTINUE.initKeyword("continue");
    KEYWORD_DEFAULT.initKeyword("default");
    KEYWORD_DELETE.initKeyword("delete");
    KEYWORD_DO.initKeyword("do");
    KEYWORD_ELSE.initKeyword("else");
    KEYWORD_FALSE.initKeyword("false");
    KEYWORD_FINALLY.initKeyword("finally");
    KEYWORD_FOR.initKeyword("for");
    KEYWORD_FUNCTION.initKeyword("function");
    KEYWORD_IF.initKeyword("if");
    KEYWORD_FOR.initKeyword("for");
    KEYWORD_IN.initKeyword("in");
    KEYWORD_NEW.initKeyword("new");
    KEYWORD_NULL.initKeyword("null");
    KEYWORD_RETURN.initKeyword("return");
    KEYWORD_SWITCH.initKeyword("switch");
    KEYWORD_THIS.initKeyword("this");
    KEYWORD_THROW.initKeyword("throw");
    KEYWORD_TRUE.initKeyword("true");
    KEYWORD_TRY.initKeyword("try");
    KEYWORD_TYPEOF.initKeyword("typeof");
    KEYWORD_VAR.initKeyword("var");
    KEYWORD_VOID.initKeyword("void");
    KEYWORD_WHILE.initKeyword("while");
    KEYWORD_WITH.initKeyword("with");

    /* reserved keywords */
    KEYWORD_ABSTRACT.initKeyword("abstract");
    KEYWORD_BOOLEAN.initKeyword("boolean");
    KEYWORD_CLASS.initKeyword("class");
    KEYWORD_CONST.initKeyword("const");
    KEYWORD_DEBUGGER.initKeyword("debugger");
    KEYWORD_DELEGATE.initKeyword("delegate");
    KEYWORD_ENUM.initKeyword("enum");
    KEYWORD_EXPORT.initKeyword("export");
    KEYWORD_EXTENDS.initKeyword("extends");
    KEYWORD_FINAL.initKeyword("final");
    KEYWORD_FLOAT.initKeyword("float");
    KEYWORD_GOTO.initKeyword("goto");
    KEYWORD_IMPLEMENTS.initKeyword("implements");
    KEYWORD_IMPORT.initKeyword("import");
    KEYWORD_INTERFACE.initKeyword("interface");
    KEYWORD_OPERATOR.initKeyword("operator");
    KEYWORD_NATIVE.initKeyword("native");
    KEYWORD_PACKAGE.initKeyword("package");
    KEYWORD_PRIVATE.initKeyword("private");
    KEYWORD_PROTECTED.initKeyword("protected");
    KEYWORD_PUBLIC.initKeyword("public");
    KEYWORD_STATIC.initKeyword("static");
    //KEYWORD_STRING.initKeyword("string");
    KEYWORD_STRUCT.initKeyword("struct");
    KEYWORD_VOID.initKeyword("void");
    KEYWORD_SUPER.initKeyword("super");
    KEYWORD_SYNCHRONIZED.initKeyword("syncronized");
    KEYWORD_THROWS.initKeyword("throws");
    KEYWORD_TRANSIENT.initKeyword("transient");
    KEYWORD_OVERRIDE.initKeyword("override");
    //KEYWORD_VECTOR.initKeyword("Vector");
    KEYWORD_YIELD.initKeyword("yield");
    KEYWORD_VOLATILE.initKeyword("volatile");

    KEYWORD_IS.initKeyword("is");
    KEYWORD_AS.initKeyword("as");
    KEYWORD_INSTANCEOF.initKeyword("instanceof");
    KEYWORD_GET.initKeyword("get");
    KEYWORD_SET.initKeyword("set");

    OPERATOR_ASSIGNMENT.initOperator("=");
    OPERATOR_BITWISEAND.initOperator("&");
    OPERATOR_BITWISEANDASSIGNMENT.initOperator("&=");
    OPERATOR_BITWISENOT.initOperator("~");
    OPERATOR_BITWISEOR.initOperator("|");
    OPERATOR_BITWISEORASSIGNMENT.initOperator("|=");
    OPERATOR_BITWISEXOR.initOperator("^");
    OPERATOR_BITWISEXORASSIGNMENT.initOperator("^=");
    OPERATOR_CLOSEBRACE.initOperator("}");
    OPERATOR_CLOSEPAREN.initOperator(")");
    OPERATOR_CLOSESQUARE.initOperator("]");
    OPERATOR_COLON.initOperator(":");
    OPERATOR_COMMA.initOperator(".(");
    OPERATOR_CONDITIONAL.initOperator("?");
    OPERATOR_DIVIDE.initOperator("/");
    OPERATOR_DIVIDEASSIGNMENT.initOperator("/=");
    OPERATOR_DOT.initOperator(".");
    OPERATOR_EQUALEQUAL.initOperator("==");
    OPERATOR_EQUALEQUALEQUAL.initOperator("===");
    OPERATOR_GREATERTHAN.initOperator(">");
    OPERATOR_GREATERTHANOREQUAL.initOperator(">=");
    OPERATOR_LESSTHAN.initOperator("<");
    OPERATOR_LESSTHANOREQUAL.initOperator("<=");
    OPERATOR_LOGICALAND.initOperator("&&");
    OPERATOR_LOGICALNOT.initOperator("!");
    OPERATOR_LOGICALOR.initOperator("||");
    OPERATOR_MINUS.initOperator("-");
    OPERATOR_MINUSASSIGNMENT.initOperator("-=");
    OPERATOR_MINUSMINUS.initOperator("--");
    OPERATOR_MODULO.initOperator("%");
    OPERATOR_MODULOASSIGNMENT.initOperator("%=");
    OPERATOR_MULTIPLY.initOperator("*");
    OPERATOR_MULTIPLYASSIGNMENT.initOperator("*=");
    OPERATOR_NOTEQUAL.initOperator("!=");
    OPERATOR_NOTEQUALEQUAL.initOperator("!==");
    OPERATOR_OPENBRACE.initOperator("{");
    OPERATOR_OPENPAREN.initOperator("(");
    OPERATOR_OPENSQUARE.initOperator("[");
    OPERATOR_PLUS.initOperator("+");
    OPERATOR_PLUSASSIGNMENT.initOperator("+=");
    OPERATOR_PLUSPLUS.initOperator("++");
    OPERATOR_CONCAT.initOperator("#");
    OPERATOR_SEMICOLON.initOperator(";");
    OPERATOR_SHIFTLEFT.initOperator("<<");
    OPERATOR_SHIFTLEFTASSIGNMENT.initOperator("<<=");
    OPERATOR_SHIFTRIGHT.initOperator(">>");
    OPERATOR_SHIFTRIGHTASSIGNMENT.initOperator(">>=");
    OPERATOR_SHIFTRIGHTUNSIGNED.initOperator(">>>");
    OPERATOR_SHIFTRIGHTUNSIGNEDASSIGNMENT.initOperator(">>>=");

    /* others */
    TOKEN_EOF.type = TEOF;
}


const char *Tokens::getOperatorMethodName(Token *token)
{
    if (token == &OPERATOR_PLUS)
    {
        return "__op_plus";
    }

    if (token == &OPERATOR_MULTIPLY)
    {
        return "__op_multiply";
    }

    if (token == &OPERATOR_MULTIPLYASSIGNMENT)
    {
        return "__op_multiplyassignment";
    }

    if (token == &OPERATOR_DIVIDE)
    {
        return "__op_divide";
    }

    if (token == &OPERATOR_DIVIDEASSIGNMENT)
    {
        return "__op_divideassignment";
    }

    if (token == &OPERATOR_MINUS)
    {
        return "__op_minus";
    }

    if (token == &OPERATOR_LOGICALNOT)
    {
        return "__op_logicalnot";
    }

    if (token == &OPERATOR_ASSIGNMENT)
    {
        return "__op_assignment";
    }

    if (token == &OPERATOR_PLUSASSIGNMENT)
    {
        return "__op_plusassignment";
    }

    if (token == &OPERATOR_MINUSASSIGNMENT)
    {
        return "__op_minusassignment";
    }

    return NULL;
}
}
