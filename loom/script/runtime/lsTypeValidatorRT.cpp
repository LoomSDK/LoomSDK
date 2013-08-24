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

#include "loom/script/runtime/lsTypeValidatorRT.h"

namespace LS {
bool TypeValidatorRT::conversionsInitialized = false;
utHashTable<utHashedString, bool> TypeValidatorRT::stringConversion;
utHashTable<utHashedString, bool> TypeValidatorRT::booleanConversion;
utHashTable<utHashedString, bool> TypeValidatorRT::numberConversion;
utHashTable<utHashedString, bool> TypeValidatorRT::voidConversion;

void TypeValidatorRT::initializeConversions()
{
    conversionsInitialized = true;

    // String conversions
    const char *_sconvert[] =
    {
        "char const*", "char*",              "utString",
        "std::string", "cocos2d::CCString*", "cocos2d::CCString const*","std::basic_string<char,struct std::char_traits<char>,class std::allocator<char> >"
    };

    // Number (and enum) conversions
    const char *_nconvert[] =
    {
        "int",         "unsigned int", "float",          "double", "char",
        "signed char", "short",        "unsigned short", "unsigned char"
    };

    // Boolean conversions
    const char *_bconvert[] = { "bool" };

    // Void conversions
    const char *_vconvert[] = { "void" };

    size_t i;
    for (i = 0; i < sizeof(_sconvert) / sizeof(const char *); i++)
    {
        stringConversion.insert(utHashedString(_sconvert[i]), true);
    }

    for (i = 0; i < sizeof(_nconvert) / sizeof(const char *); i++)
    {
        numberConversion.insert(utHashedString(_nconvert[i]), true);
    }

    for (i = 0; i < sizeof(_bconvert) / sizeof(const char *); i++)
    {
        booleanConversion.insert(utHashedString(_bconvert[i]), true);
    }

    for (i = 0; i < sizeof(_vconvert) / sizeof(const char *); i++)
    {
        voidConversion.insert(utHashedString(_vconvert[i]), true);
    }
}
}
