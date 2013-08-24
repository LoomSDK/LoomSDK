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

#ifndef _ls_token_h
#define _ls_token_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utSingleton.h"
#include "loom/common/utils/utString.h"

namespace LS {
enum TokenType
{
    TINVALID, TNEWLINE, TMULTILINECOMMENT, TSINGLELINECOMMENT, TWHITESPACE,

    TKEYWORD, TOPERATOR,

    TIDENTIFIER, TSTRING, TREGEX, TOCTAL, TDECIMAL, THEXADECIMAL, TFLOAT,

    TEOF, TUNKNOWN
};

#define LSTOKEN(x)    & tokens->x

class Token {
private:

    static utHashTable<utIntHashKey, Token *>        sKeywords;
    static utHashTable<utIntHashKey, utHashedString> sAllValues;

public:

    TokenType      type;
    utHashedString value;

    // if this token is a compiler alias, this will be the token
    // we are aliased from, for instance this would be "int" in the
    // case of the int -> Number compiler aliasing
    utString preAliasValue;

    void initKeyword(const char *value);
    void initOperator(const char *value);

    Token();
    Token(TokenType t, const char *value, const char *preAlias = NULL);
    Token(TokenType t, utString input, int start, int end);

    static Token *getKeyword(const char *t);

    /**
     * Return true is this token represents whitespace.
     */
    bool isWhitespace()
    {
        return type == TNEWLINE || type == TMULTILINECOMMENT ||
               type == TSINGLELINECOMMENT || type == TWHITESPACE;
    }

    /**
     * Return true is this token represents whitespace except newlines.
     */
    bool isWhitespaceNotNewline()
    {
        return type == TMULTILINECOMMENT || type == TSINGLELINECOMMENT ||
               type == TWHITESPACE;
    }

    /**
     * Return true is this token represents the EOF.
     */
    bool isEOF()
    {
        return type == TEOF;
    }

    /**
     * Return true is this token represents an identifier.
     */
    bool isIdentifier()
    {
        return type == TIDENTIFIER;
    }

    /**
     * Return true is this token represents a keyword.
     */
    bool isKeyword()
    {
        return type == TKEYWORD;
    }

    bool isModifier()
    {
        utString s = value.str();

        if (s == "public")
        {
            return true;
        }

        if (s == "private")
        {
            return true;
        }

        if (s == "protected")
        {
            return true;
        }

        if (s == "static")
        {
            return true;
        }

        if (s == "native")
        {
            return true;
        }

        if (s == "override")
        {
            return true;
        }

        if (s == "operator")
        {
            return true;
        }

        if (s == "final")
        {
            return true;
        }

        return false;
    }

    /**
     * Return true is this token represents a newline.
     */
    bool isNewLine()
    {
        return type == TNEWLINE;
    }

    /**
     * Return true is this token represents a numeric literal.
     */
    bool isNumericLiteral()
    {
        return type == TFLOAT || type == TOCTAL || type == TDECIMAL ||
               type == THEXADECIMAL;
    }

    /**
     * Return true is this token represents a regex literal.
     */
    bool isRegexLiteral()
    {
        return type == TREGEX;
    }

    /**
     * Return true is this token represents a string literal.
     */
    bool isStringLiteral()
    {
        return type == TSTRING;
    }
};

class Tokens : utSingleton<Tokens> {
public:

    UT_DECLARE_SINGLETON(Tokens)

    /* Whitespace */

    Token NEWLINE;
    Token SINGLELINECOMMENT;
    Token WHITESPACE;

    /* Keywords */

    Token KEYWORD_BREAK;
    Token KEYWORD_CASE;
    Token KEYWORD_CATCH;
    Token KEYWORD_CONTINUE;
    Token KEYWORD_DEFAULT;
    Token KEYWORD_DELETE;
    Token KEYWORD_DO;
    Token KEYWORD_ELSE;
    Token KEYWORD_FALSE;
    Token KEYWORD_FINALLY;
    Token KEYWORD_FOR;
    Token KEYWORD_FUNCTION;
    Token KEYWORD_IF;
    Token KEYWORD_IN;
    Token KEYWORD_NEW;
    Token KEYWORD_NULL;
    Token KEYWORD_RETURN;
    Token KEYWORD_SWITCH;
    Token KEYWORD_THIS;
    Token KEYWORD_THROW;
    Token KEYWORD_TRUE;
    Token KEYWORD_TRY;
    Token KEYWORD_TYPEOF;
    Token KEYWORD_VAR;
    Token KEYWORD_VOID;
    Token KEYWORD_WHILE;
    Token KEYWORD_WITH;

    /* Reserved Keywords */

    Token KEYWORD_ABSTRACT;
    Token KEYWORD_BOOLEAN;
    Token KEYWORD_CLASS;
    Token KEYWORD_CONST;
    Token KEYWORD_DEBUGGER;
    Token KEYWORD_DELEGATE;
    Token KEYWORD_ENUM;
    Token KEYWORD_EXPORT;
    Token KEYWORD_EXTENDS;
    Token KEYWORD_FINAL;
    Token KEYWORD_FLOAT;
    Token KEYWORD_GOTO;
    Token KEYWORD_IMPLEMENTS;
    Token KEYWORD_IMPORT;
    Token KEYWORD_INTERFACE;
    Token KEYWORD_NATIVE;
    Token KEYWORD_PACKAGE;
    Token KEYWORD_PRIVATE;
    Token KEYWORD_PROTECTED;
    Token KEYWORD_PUBLIC;
    Token KEYWORD_STATIC;
    //Token KEYWORD_STRING;
    Token KEYWORD_STRUCT;
    Token KEYWORD_SUPER;
    Token KEYWORD_SYNCHRONIZED;
    Token KEYWORD_THROWS;
    Token KEYWORD_TRANSIENT;
    Token KEYWORD_VOLATILE;
    Token KEYWORD_OVERRIDE;
    Token KEYWORD_IS;
    Token KEYWORD_AS;
    Token KEYWORD_INSTANCEOF;
    Token KEYWORD_GET;
    Token KEYWORD_SET;
    Token KEYWORD_OPERATOR;
    //Token KEYWORD_VECTOR;
    Token KEYWORD_YIELD;

    /* operators */

    Token OPERATOR_ASSIGNMENT;
    Token OPERATOR_BITWISEAND;
    Token OPERATOR_BITWISEANDASSIGNMENT;
    Token OPERATOR_BITWISENOT;
    Token OPERATOR_BITWISEOR;
    Token OPERATOR_BITWISEORASSIGNMENT;
    Token OPERATOR_BITWISEXOR;
    Token OPERATOR_BITWISEXORASSIGNMENT;
    Token OPERATOR_CLOSEBRACE;
    Token OPERATOR_CLOSEPAREN;
    Token OPERATOR_CLOSESQUARE;
    Token OPERATOR_COLON;
    Token OPERATOR_COMMA;
    Token OPERATOR_CONDITIONAL;
    Token OPERATOR_CONCAT;
    Token OPERATOR_DIVIDE;
    Token OPERATOR_DIVIDEASSIGNMENT;
    Token OPERATOR_DOT;
    Token OPERATOR_EQUALEQUAL;
    Token OPERATOR_EQUALEQUALEQUAL;
    Token OPERATOR_GREATERTHAN;
    Token OPERATOR_GREATERTHANOREQUAL;
    Token OPERATOR_LESSTHAN;
    Token OPERATOR_LESSTHANOREQUAL;
    Token OPERATOR_LOGICALAND;
    Token OPERATOR_LOGICALNOT;
    Token OPERATOR_LOGICALOR;
    Token OPERATOR_MINUS;
    Token OPERATOR_MINUSASSIGNMENT;
    Token OPERATOR_MINUSMINUS;
    Token OPERATOR_MODULO;
    Token OPERATOR_MODULOASSIGNMENT;
    Token OPERATOR_MULTIPLY;
    Token OPERATOR_MULTIPLYASSIGNMENT;
    Token OPERATOR_NOTEQUAL;
    Token OPERATOR_NOTEQUALEQUAL;
    Token OPERATOR_OPENBRACE;
    Token OPERATOR_OPENPAREN;
    Token OPERATOR_OPENSQUARE;
    Token OPERATOR_PLUS;
    Token OPERATOR_PLUSASSIGNMENT;
    Token OPERATOR_PLUSPLUS;
    Token OPERATOR_SEMICOLON;
    Token OPERATOR_SHIFTLEFT;
    Token OPERATOR_SHIFTLEFTASSIGNMENT;
    Token OPERATOR_SHIFTRIGHT;
    Token OPERATOR_SHIFTRIGHTASSIGNMENT;
    Token OPERATOR_SHIFTRIGHTUNSIGNED;
    Token OPERATOR_SHIFTRIGHTUNSIGNEDASSIGNMENT;

    Token OPERATOR_GLOBAL;

    /* Other Tokens */
    Token TOKEN_EOF;

    const char *getOperatorMethodName(Token *token);

    Tokens();
};
}
#endif
