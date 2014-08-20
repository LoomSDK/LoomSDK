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

#ifndef _ls_lexer_h
#define _ls_lexer_h

#include "loom/common/utils/utString.h"
#include "loom/common/utils/utTypes.h"

#include "loom/script/compiler/lsToken.h"

namespace LS {
class Lexer {
    enum NumericBase
    {
        BASE_HEXADECIMAL = 16, BASE_OCTAL = 8
    };

    enum Numeric
    {
        NUMERIC_ENTRY_POINT,
        NUMERIC_LEADING_ZERO,
        NUMERIC_LEADING_DECIMAL,
        NUMERIC_OCTAL_LITERAL,
        NUMERIC_LEADING_OX,
        NUMERIC_HEXADECIMAL_LITERAL,
        NUMERIC_DECIMAL_LITERAL,
        NUMERIC_DECIMAL_POINT,
        NUMERIC_FRACTIONAL_PART,
        NUMERIC_EXPONENT_SYMBOL,
        NUMERIC_EXPONENT_SIGN,
        NUMERIC_EXPONENT_PART,
        NUMERIC_UNREAD_TWO,
        NUMERIC_UNREAD_ONE,
        NUMERIC_RETURN_FLOAT,
        NUMERIC_RETURN_DECIMAL,
        NUMERIC_RETURN_OCTAL,
        NUMERIC_RETURN_HEXADECIMAL,
        NUMERIC_RETURN_OPERATOR_DOT
    };

    utString input;

    int maxPosition;
    int curPosition;
    int oldPosition;
    int c;

    utStack<int> tokenStack;

    Tokens *tokens;

    bool isEOF();
    bool isLineTerminator();
    bool isWhitespace();
    bool isOctalDigit();
    bool isDecimalDigit();
    bool isHexadecimalDigit();
    bool isIdentifierStart();
    bool isIdentifierPart();

    Token *tokenizeLineTerminator();
    Token *tokenizeWhitespace();

    Token *tokenizeSingleLineComment();
    Token *tokenizeMultilineComment();
    Token *tokenizeSlash();

    Token *tokenizeNumeric();

    Token *tokenizeMultilineString();

    Token *tokenizeIdentifier();
    Token *tokenizeOperator();

    Token *tokenizeUnknown();

    void readOctalEscapeSequence();
    void readHexEscapeSequence(int count);
    void readStringEscapeSequence();
    void readIdentifierEscapeSequence();

    void skipLineTerminator();
    void readChar();
    void unreadChar();

    void error(const char *message);

public:

    Lexer();
    ~Lexer();

    void setInput(const utString& input, const utString& filename);

    Token *nextToken();
    void unreadToken();

    /**
     * Returns an ID identifying the start of the current token.
     */
    int getBookmark();

    /**
     * Given an ID from getBookmark, restores parse state to that point; this
     * allows stepping back arbitraryily many tokens without complicated
     * book-keeping.
     */
    void gotoBookmark(int mark);

    int lineNumber;
    utString filename;
};
}
#endif
