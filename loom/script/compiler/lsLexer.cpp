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

#include <string.h>
#include "stdlib.h"
#include "stdio.h"

#include "loom/script/compiler/lsLexer.h"
#include "loom/script/compiler/lsAlias.h"


namespace LS {
#define LEXER_MAX_TOKEN    65536
static char ctoken[LEXER_MAX_TOKEN];

Lexer::Lexer()
{
    lineNumber  = 1;
    maxPosition = 0;
    oldPosition = 0;
    curPosition = 0;

    c      = -1;
    tokens = Tokens::getSingletonPtr();
}


void Lexer::setInput(const utString& input)
{
    int length = (int)input.size();

    this->input = input;

    lineNumber  = 1;
    maxPosition = length;
    oldPosition = 0;
    curPosition = 0;

    c = curPosition < maxPosition ? this->input[0] : -1;
}


Lexer::~Lexer()
{
}


void Lexer::error(const char *message)
{
}


bool Lexer::isLineTerminator()
{
    return c == '\n' || c == '\r';

    // TODO: unicode

    /*
    || c == '\u2028'
    || c == '\u2029';
    */
}


void Lexer::readChar()
{
    curPosition++;

    if ((curPosition < maxPosition) && (curPosition >= 0))
    {
        c = input[curPosition];
    }
    else
    {
        c = -1;
    }
}


/**
 * Unread the current character.  This MUST NOT be used to unread past a
 * line terminator character.
 */
void Lexer::unreadChar()
{
    if (curPosition > 0)
    {
        if (isLineTerminator())
        {
            error("current character must not be a line terminator");
        }
        curPosition--;
        c = input[curPosition];
    }
    else
    {
        c = -1;
    }
}


void Lexer::skipLineTerminator()
{
    /* This is not mentioned in the JavaScript specification, but "\r\n" is
     * usually recognised as a single newline and not as two separate newline
     * characters. */

    if (c == '\r')
    {
        readChar();
        if (c == '\n')
        {
            readChar();
        }
    }
    else
    {
        readChar();
    }

    lineNumber++;
}


Token *Lexer::tokenizeLineTerminator()
{
    do
    {
        skipLineTerminator();
    } while (isLineTerminator());

    return &tokens->NEWLINE;
}


/**
 * Tokenizes whitespace.
 */
Token *Lexer::tokenizeWhitespace()
{
    do
    {
        readChar();
    } while (isWhitespace());

    return &tokens->WHITESPACE;
}


bool Lexer::isEOF()
{
    return c == -1;
}


bool Lexer::isWhitespace()
{
    /**
     * Returns true if the current character is a whitespace character.
     */
    /* todo, unicode*/
    return c == 0x09 || c == 0x0B || c == 0x0C || c == 0x20 || c == 0xA0;
}


/**
 * Tokenizes a single line comment.
 */
Token *Lexer::tokenizeSingleLineComment()
{
    do
    {
        readChar();
    } while (!isEOF() && !isLineTerminator());

    return &tokens->SINGLELINECOMMENT;
}


/**
 * Tokenizes a multi line comment.
 */
Token *Lexer::tokenizeMultilineComment()
{
    readChar();

    // skip * in case of first /**
    if (c == '*')
    {
        readChar();
    }

    // multiline comment/doc string parse state
    // the current length of the parsed docstring/comment
    int count = 0;

    // whether or not we should keep the lead asterisk
    bool keepLeadAstertisk = false;
    // are we on the first line?
    bool firstline = true;
    // are we eating white space
    bool eatWhitespace = false;
    // once we see an asterick, any whitespace will trigger the following asterisks on the line to be kept
    bool keepAsterisks = false;
    // true if we have seen an asterisk on a given line
    bool sawAsterisk = false;

    while (1)
    {
        if (isEOF())
        {
            break;
        }
        else if (isLineTerminator())
        {
            firstline = false;
            // never start with a \n
            if (count)
            {
                ctoken[count++] = '\n';
            }

            eatWhitespace = true;
            keepAsterisks = false;
            sawAsterisk   = false;

            skipLineTerminator();
        }
        else if (c == '*')
        {
            if (keepAsterisks)
            {
                eatWhitespace = false;
            }

            sawAsterisk = true;
            readChar();

            if (c == '/')
            {
                if (count && (ctoken[count - 1] == '*'))
                {
                    count--;
                    ctoken[count] = 0;
                }
                readChar();
                break;
            }

            if (keepAsterisks || (keepLeadAstertisk || !eatWhitespace) && (c != '/'))
            {
                ctoken[count++] = '*';
            }
            else
            {
                firstline = true;
            }
        }
        else
        {
            if (eatWhitespace)
            {
                if (isWhitespace())
                {
                    // we keep asterisks separated from lead astericks by whitespace
                    if (sawAsterisk)
                    {
                        keepAsterisks = true;
                    }

                    readChar();
                    continue;
                }

                if (!keepLeadAstertisk && !firstline)
                {
                    keepLeadAstertisk = true;
                }
            }

            eatWhitespace   = false;
            ctoken[count++] = c;
            readChar();
        }
    }

    ctoken[count] = 0;


    // never end with a \n
    if (count && (ctoken[count - 1] == '\n'))
    {
        ctoken[count - 1] = 0;
    }

    return new Token(TMULTILINECOMMENT, ctoken);
}


/**
 * Tokenizes tokens that start with a forward slash.
 */
Token *Lexer::tokenizeSlash()
{
    readChar();

    if (c == '/')
    {
        return tokenizeSingleLineComment();
    }
    else if (c == '*')
    {
        return tokenizeMultilineComment();
    }
    else if (c == '=')
    {
        readChar();
        return &tokens->OPERATOR_DIVIDEASSIGNMENT;
    }
    else
    {
        return &tokens->OPERATOR_DIVIDE;
    }
}


/**
 * Returns true if the current character is an octal digit.
 */
bool Lexer::isOctalDigit()
{
    return c == '0' || c == '1' || c == '2' || c == '3' || c == '4' || c == '5' ||
           c == '6' || c == '7';
}


/**
 * Returns true if the current character is a decimal digit.
 */
bool Lexer::isDecimalDigit()
{
    return c == '0' || c == '1' || c == '2' || c == '3' || c == '4' || c == '5' ||
           c == '6' || c == '7' || c == '8' || c == '9';
}


/**
 * Returns true if the current character is a hexadecimal digit.
 */
bool Lexer::isHexadecimalDigit()
{
    return c == '0' || c == '1' || c == '2' || c == '3' || c == '4' || c == '5' ||
           c == '6' || c == '7' || c == '8' || c == '9' || c == 'a' ||
           c == 'b' || c == 'c' || c == 'd' || c == 'e' || c == 'f' ||
           c == 'A' || c == 'B' || c == 'C' || c == 'D' || c == 'E' ||
           c == 'F';
}


/**
 * Returns true if the current character is a valid identifier start
 * character.
 */
bool Lexer::isIdentifierStart()
{
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '$' ||
           c == '_';
}


/**
 * Returns true if the current character is a valid as part of an identifier.
 */
bool Lexer::isIdentifierPart()
{
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
           (c >= '0' && c <= '9') || c == '$' || c == '_';
}


/**
 * Tokenizes a numeric literal.
 *
 * <p>Older versions of the JavaScript(TM) and ECMAScript specifications
 * included support for octal numeric literals.  Although the latest
 * version of the the specification (3rd edition, ECMA-262, 3rd December
 * 1999) doesn't provide support for them we do for compatibility reasons.
 *
 * <p>As a special case, numbers that start with "08" or "09" are treated
 * as decimal.  Strictly speaking such literals should be interpreted as
 * two numeric literals, a zero followed by a decimal whose leading digit
 * is 8 or 9.  However two consecutive integers are not legal according to
 * the ECMAScript grammar.
 */
Token *Lexer::tokenizeNumeric()
{
    Numeric state = NUMERIC_ENTRY_POINT;

    while (1)
    {
        switch (state)
        {
        /* entry point */
        case NUMERIC_ENTRY_POINT:
            if (c == '.')
            {
                state = NUMERIC_LEADING_ZERO;
            }
            else if (c == '0')
            {
                state = NUMERIC_LEADING_DECIMAL;
            }
            else
            {
                state = NUMERIC_DECIMAL_LITERAL;
            }
            break;

        /* leading decimal point*/
        case NUMERIC_LEADING_ZERO:
            readChar();
            if (isDecimalDigit())
            {
                state = NUMERIC_DECIMAL_POINT;
            }
            else
            {
                state = NUMERIC_RETURN_OPERATOR_DOT;
            }
            break;

        /* leading zero*/
        case NUMERIC_LEADING_DECIMAL:
            readChar();
            if (isOctalDigit())
            {
                state = NUMERIC_OCTAL_LITERAL;
            }
            else if ((c == 'x') || (c == 'X'))
            {
                state = NUMERIC_LEADING_OX;
            }
            else if (isDecimalDigit())
            {
                state = NUMERIC_DECIMAL_LITERAL;
            }
            else if (c == '.')
            {
                state = NUMERIC_DECIMAL_POINT;
            }
            else if ((c == 'e') || (c == 'E'))
            {
                state = NUMERIC_EXPONENT_SYMBOL;
            }
            else
            {
                state = NUMERIC_RETURN_DECIMAL;
            }
            break;

        /* octal literal */
        case NUMERIC_OCTAL_LITERAL:
            readChar();
            if (isOctalDigit())
            {
                /* loop */
            }
            else
            {
                state = NUMERIC_RETURN_OCTAL;
            }
            break;

        /* leading '0x' or '0X' */
        case NUMERIC_LEADING_OX:
            readChar();
            if (isHexadecimalDigit())
            {
                state = NUMERIC_HEXADECIMAL_LITERAL;
            }
            else
            {
                error("Invalid hexadecimal literal");
            }
            break;

        /* hexadecimal literal */
        case NUMERIC_HEXADECIMAL_LITERAL:
            readChar();
            if (isHexadecimalDigit())
            {
                /* loop */
            }
            else
            {
                state = NUMERIC_RETURN_HEXADECIMAL;
            }
            break;

        /* decimal literal */
        case NUMERIC_DECIMAL_LITERAL:
            readChar();
            if (isDecimalDigit())
            {
                /* loop */
            }
            else if (c == '.')
            {
                state = NUMERIC_DECIMAL_POINT;
            }
            else if ((c == 'e') || (c == 'E'))
            {
                state = NUMERIC_EXPONENT_SYMBOL;
            }
            else
            {
                state = NUMERIC_RETURN_DECIMAL;
            }
            break;

        /* decimal point */
        case NUMERIC_DECIMAL_POINT:
            readChar();
            if (isDecimalDigit())
            {
                state = NUMERIC_FRACTIONAL_PART;
            }
            else if ((c == 'e') || (c == 'E'))
            {
                state = NUMERIC_EXPONENT_SYMBOL;
            }
            else
            {
                state = NUMERIC_RETURN_FLOAT;
            }
            break;

        /* fractional part */
        case NUMERIC_FRACTIONAL_PART:
            readChar();
            if (isDecimalDigit())
            {
                /* loop */
            }
            else if ((c == 'e') || (c == 'E'))
            {
                state = NUMERIC_EXPONENT_SYMBOL;
            }
            else
            {
                state = NUMERIC_RETURN_FLOAT;
            }
            break;

        /* exponent symbol */
        case NUMERIC_EXPONENT_SYMBOL:
            readChar();
            if ((c == '+') || (c == '-'))
            {
                state = NUMERIC_EXPONENT_SIGN;
            }
            else if (isDecimalDigit())
            {
                state = NUMERIC_EXPONENT_PART;
            }
            else
            {
                state = NUMERIC_UNREAD_ONE;
            }
            break;

        /* exponent sign */
        case NUMERIC_EXPONENT_SIGN:
            readChar();
            if (isDecimalDigit())
            {
                state = NUMERIC_EXPONENT_PART;
            }
            else
            {
                state = NUMERIC_UNREAD_TWO;
            }
            break;

        /* exponent part */
        case NUMERIC_EXPONENT_PART:
            readChar();
            if (isDecimalDigit())
            {
                /* loop */
            }
            else
            {
                state = NUMERIC_RETURN_FLOAT;
            }
            break;

        /* unread two characters */
        case NUMERIC_UNREAD_TWO:
            unreadChar();
            state = NUMERIC_UNREAD_ONE;
            break;

        /* unread one character */
        case NUMERIC_UNREAD_ONE:
            unreadChar();
            state = NUMERIC_RETURN_FLOAT;
            break;

        /* floating literal */
        case NUMERIC_RETURN_FLOAT:
            return new Token(TFLOAT, input, oldPosition, curPosition);

        /* decimal literal */
        case NUMERIC_RETURN_DECIMAL:
            return new Token(TDECIMAL, input, oldPosition, curPosition);

        /* octal literal */
        case NUMERIC_RETURN_OCTAL:
            return new Token(TOCTAL, input, oldPosition, curPosition);

        /* hexadecimal literal */
        case NUMERIC_RETURN_HEXADECIMAL:
            return new Token(THEXADECIMAL, input, oldPosition, curPosition);

        /* '.' operator */
        case NUMERIC_RETURN_OPERATOR_DOT:
            return &tokens->OPERATOR_DOT;
        }
    }
}


/**
 * Reads a hexadecimal escape sequence.
 *
 * @param count number of characters to read
 * @throws CompilerException if the escape sequence was malformed
 */
void Lexer::readHexEscapeSequence(int count)
{
    int  value;
    char v[2];
    char *p;

    v[0] = c;
    v[1] = 0;

    value = strtol(v, &p, BASE_HEXADECIMAL);

    while (--count > 0)
    {
        readChar();

        if (!isHexadecimalDigit())
        {
            error("Bad escape sequence");
        }
        else
        {
            v[0]  = c;
            value = (value << 4) + strtol(v, &p, BASE_HEXADECIMAL);
        }
    }

    c = value;
}


/**
 * Reads an octal escape sequence of up to 3 octal digits.
 */
void Lexer::readOctalEscapeSequence()
{
    int  value;
    char v[2];
    char *p;

    v[0] = c;
    v[1] = 0;

    value = strtol(v, &p, BASE_OCTAL);

    readChar();
    if (isOctalDigit())
    {
        v[0]  = c;
        value = (value << 3) + strtol(v, &p, BASE_OCTAL);
        readChar();
        if (isOctalDigit())
        {
            v[0]  = c;
            value = (value << 3) + strtol(v, &p, BASE_OCTAL);
        }
        else
        {
            unreadChar();
        }
    }
    else
    {
        unreadChar();
    }

    c = value;
}


/**
 * Reads an string escape sequence.
 */
void Lexer::readStringEscapeSequence()
{
    readChar();

    if (isEOF())
    {
        error("EOF in escape sequence");
    }
    else if (isLineTerminator() || isWhitespace())
    {
        /*error("Line terminator in escape sequence");*/
        /* span */

        if (isWhitespace())
        {
            while (isWhitespace())
            {
                readChar();
            }

            unreadChar();
        }

        if (isLineTerminator())
        {
            while (isLineTerminator())
            {
                readChar();
            }

            unreadChar();
        }
        else
        {
            error("Line terminator in escape sequence");
        }
    }
    else if (c == 'b')
    {
        c = 0x0008;
    }
    else if (c == 't')
    {
        c = 0x0009;
    }
    else if (c == 'n')
    {
        c = 0x000a;
    }
    else if (c == 'v')
    {
        c = 0x000b;
    }
    else if (c == 'f')
    {
        c = 0x000c;
    }
    else if (c == 'r')
    {
        c = 0x000d;
    }
    else if (c == 'u')
    {
        readChar();
        if (isHexadecimalDigit())
        {
            readHexEscapeSequence(4);
        }
        else
        {
            unreadChar();
        }
    }
    else if (c == 'x')
    {
        readChar();
        if (isHexadecimalDigit())
        {
            readHexEscapeSequence(2);
        }
        else
        {
            unreadChar();
        }
    }
    else if (isOctalDigit())
    {
        readOctalEscapeSequence();
    }
    else
    {
        /* other characters escape themselves */
    }
}


/**
 * Tokenizes a multiline string.  The current character is used as the
 * quote character. (ECMAScript doesn't have multiline strings but they are nice!)
 */
Token *Lexer::tokenizeMultilineString()
{
    char quote = c;

    if ((quote != '\'') && (quote != '"'))
    {
        error("No quote following multiline string literal");
    }

    /* skip the leading quote */
    readChar();

    int count = 0;

    while (1)
    {
        if (c == quote)
        {
            break;
        }
        else if (isEOF())
        {
            error("EOF in string literal");
        }
        else if (c == '\\')
        {
            readStringEscapeSequence();
            ctoken[count++] = c;
        }
        else if (isLineTerminator())
        {
            //nada, allow multiline strings
        }
        else
        {
            ctoken[count++] = c;
        }

        if (count >= LEXER_MAX_TOKEN - 1)
        {
            error("Overflowed ctoken");
        }

        readChar();
    }

    /* skip the trailing quote*/
    readChar();

    ctoken[count] = 0;

    return new Token(TSTRING, ctoken);
}


/**
 * Reads an identifier escape sequence.
 */
void Lexer::readIdentifierEscapeSequence()
{
    readChar();

    if (isEOF())
    {
        error("EOF in escape sequence");
    }
    else if (isLineTerminator())
    {
        error("Line terminator in escape sequence");
    }
    else if (c == 'u')
    {
        readChar();
        if (isHexadecimalDigit())
        {
            readHexEscapeSequence(4);
        }
        else
        {
            error("Invalid escape sequence");
        }
    }
    else
    {
        error("Invalid escape sequence");
    }
}


/**
 * Tokenizes a ECMAScript identifier.  On entry the current character must
 * be a valid identifier start character.
 */
Token *Lexer::tokenizeIdentifier()
{
    /* identifier start */
    int count = 0;

    ctoken[count++] = c;

    readChar();

    /* identifier part */
    while (1)
    {
        if (isIdentifierPart())
        {
            ctoken[count++] = c;
        }
        else if (c == '\\')
        {
            readIdentifierEscapeSequence();
            if (isIdentifierPart())
            {
                ctoken[count++] = c;
            }
            else
            {
                error("Invalid escaped character in identifier");
            }
        }
        else
        {
            break;
        }

        if (count == LEXER_MAX_TOKEN)
        {
            error("Overflowed ctoken");
        }

        readChar();
    }

    ctoken[count] = 0;

    /* If this identifier matches a keyword we need to return that keyword
     * token. */

    utString alias = Aliases::getAlias(ctoken);
    utString preAlias;

    if (alias.length())
    {
        preAlias = ctoken;
        strcpy(ctoken, alias.c_str());
    }

    Token *token = Token::getKeyword(ctoken);

    if (token != NULL)
    {
        return token;
    }
    else
    {
        return new Token(TIDENTIFIER, ctoken, preAlias.c_str());
    }
}


/**
 * Tokenizes an unknown character.
 */
Token *Lexer::tokenizeUnknown()
{
    readChar();

    return new Token(TUNKNOWN, input, oldPosition, curPosition);
}


/**
 * Tokenizes an operator.
 */
Token *Lexer::tokenizeOperator()
{
    if (c == ';')
    {
        readChar();
        return &tokens->OPERATOR_SEMICOLON;
    }
    else if (c == ',')
    {
        readChar();
        return &tokens->OPERATOR_COMMA;
    }
    else if (c == '(')
    {
        readChar();
        return &tokens->OPERATOR_OPENPAREN;
    }
    else if (c == ')')
    {
        readChar();
        return &tokens->OPERATOR_CLOSEPAREN;
    }
    else if (c == '{')
    {
        readChar();
        return &tokens->OPERATOR_OPENBRACE;
    }
    else if (c == '}')
    {
        readChar();
        return &tokens->OPERATOR_CLOSEBRACE;
    }
    else if (c == '[')
    {
        readChar();
        return &tokens->OPERATOR_OPENSQUARE;
    }
    else if (c == ']')
    {
        readChar();
        return &tokens->OPERATOR_CLOSESQUARE;
    }
    else if (c == '?')
    {
        readChar();
        return &tokens->OPERATOR_CONDITIONAL;
    }
    else if (c == ':')
    {
        readChar();
        return &tokens->OPERATOR_COLON;
    }
    else if (c == '#')
    {
        readChar();
        return &tokens->OPERATOR_CONCAT;
    }
    else if (c == '+')
    {
        readChar();
        if (c == '+')
        {
            readChar();
            return &tokens->OPERATOR_PLUSPLUS;
        }
        else if (c == '=')
        {
            readChar();
            return &tokens->OPERATOR_PLUSASSIGNMENT;
        }
        else
        {
            return &tokens->OPERATOR_PLUS;
        }
    }
    else if (c == '-')
    {
        readChar();
        if (c == '-')
        {
            readChar();
            return &tokens->OPERATOR_MINUSMINUS;
        }
        else if (c == '=')
        {
            readChar();
            return &tokens->OPERATOR_MINUSASSIGNMENT;
        }
        else
        {
            return &tokens->OPERATOR_MINUS;
        }
    }
    else if (c == '*')
    {
        readChar();
        if (c == '=')
        {
            readChar();
            return &tokens->OPERATOR_MULTIPLYASSIGNMENT;
        }
        else
        {
            return &tokens->OPERATOR_MULTIPLY;
        }
    }
    else if (c == '%')
    {
        readChar();
        if (c == '=')
        {
            readChar();
            return &tokens->OPERATOR_MODULOASSIGNMENT;
        }
        else
        {
            return &tokens->OPERATOR_MODULO;
        }
    }
    else if (c == '=')
    {
        readChar();
        if (c == '=')
        {
            readChar();
            if (c == '=')
            {
                readChar();
                return &tokens->OPERATOR_EQUALEQUALEQUAL;
            }
            else
            {
                return &tokens->OPERATOR_EQUALEQUAL;
            }
        }
        else
        {
            return &tokens->OPERATOR_ASSIGNMENT;
        }
    }
    else if (c == '!')
    {
        readChar();
        if (c == '=')
        {
            readChar();
            if (c == '=')
            {
                readChar();
                return &tokens->OPERATOR_NOTEQUALEQUAL;
            }
            else
            {
                return &tokens->OPERATOR_NOTEQUAL;
            }
        }
        else
        {
            return &tokens->OPERATOR_LOGICALNOT;
        }
    }
    else if (c == '&')
    {
        readChar();
        if (c == '&')
        {
            readChar();
            return &tokens->OPERATOR_LOGICALAND;
        }
        else if (c == '=')
        {
            readChar();
            return &tokens->OPERATOR_BITWISEANDASSIGNMENT;
        }
        else
        {
            return &tokens->OPERATOR_BITWISEAND;
        }
    }
    else if (c == '|')
    {
        readChar();
        if (c == '|')
        {
            readChar();
            return &tokens->OPERATOR_LOGICALOR;
        }
        else if (c == '=')
        {
            readChar();
            return &tokens->OPERATOR_BITWISEORASSIGNMENT;
        }
        else
        {
            return &tokens->OPERATOR_BITWISEOR;
        }
    }
    else if (c == '^')
    {
        readChar();
        if (c == '=')
        {
            readChar();
            return &tokens->OPERATOR_BITWISEXORASSIGNMENT;
        }
        else
        {
            return &tokens->OPERATOR_BITWISEXOR;
        }
    }
    else if (c == '~')
    {
        readChar();
        return &tokens->OPERATOR_BITWISENOT;
    }
    else if (c == '<')
    {
        readChar();
        if (c == '<')
        {
            readChar();
            if (c == '=')
            {
                readChar();
                return &tokens->OPERATOR_SHIFTLEFTASSIGNMENT;
            }
            else
            {
                return &tokens->OPERATOR_SHIFTLEFT;
            }
        }
        else if (c == '=')
        {
            readChar();
            return &tokens->OPERATOR_LESSTHANOREQUAL;
        }
        else
        {
            return &tokens->OPERATOR_LESSTHAN;
        }
    }
    else if (c == '>')
    {
        readChar();
        if (c == '>')
        {
            readChar();
            if (c == '>')
            {
                readChar();
                if (c == '=')
                {
                    readChar();
                    return &tokens->OPERATOR_SHIFTRIGHTUNSIGNEDASSIGNMENT;
                }
                else
                {
                    return &tokens->OPERATOR_SHIFTRIGHTUNSIGNED;
                }
            }
            else if (c == '=')
            {
                readChar();
                return &tokens->OPERATOR_SHIFTRIGHTASSIGNMENT;
            }
            else
            {
                return &tokens->OPERATOR_SHIFTRIGHT;
            }
        }
        else if (c == '=')
        {
            readChar();
            return &tokens->OPERATOR_GREATERTHANOREQUAL;
        }
        else
        {
            return &tokens->OPERATOR_GREATERTHAN;
        }
    }
    else if (c == '\\')
    {
        /* Although not an operator we check for this symbol last since its
         * probably the least likely input.  A '\' indicates an identifier that
         * starts with an escaped character.*/

        readIdentifierEscapeSequence();
        if (isIdentifierStart())
        {
            return tokenizeIdentifier();
        }
        else
        {
            error("Invalid escaped character in identifier");
        }
    }

    /* Give up */
    return tokenizeUnknown();
}


void Lexer::unreadToken()
{
    if (tokenStack.size() > 1)
    {
        oldPosition = curPosition = tokenStack.pop();
        c           = input[curPosition];
    }
}


int Lexer::getBookmark()
{
    return tokenStack.size();
}


void Lexer::gotoBookmark(int bookmark)
{
    while (tokenStack.size() > (UTsize)bookmark)
    {
        unreadToken();
    }
}


Token *Lexer::nextToken()
{
    oldPosition = curPosition;

    tokenStack.push(curPosition);

    if (isEOF())
    {
        return &tokens->TOKEN_EOF;
    }

    if (isLineTerminator())
    {
        return tokenizeLineTerminator();
    }

    if (isWhitespace())
    {
        return tokenizeWhitespace();
    }

    if (c == '/')
    {
        return tokenizeSlash();
    }

    if ((c == '.') || isDecimalDigit())
    {
        return tokenizeNumeric();
    }

    if ((c == '\'') || (c == '\"'))
    {
        return tokenizeMultilineString();
    }

    if (isIdentifierStart())
    {
        return tokenizeIdentifier();
    }

    return tokenizeOperator();
}
}
