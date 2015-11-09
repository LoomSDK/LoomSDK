/*
 * -------------------------------------------------------------------------------
 * General Purpose Utility Library, should be kept dependency free.
 * Unless the dependency can be compiled along with this library.
 *
 * Copyright (c) 2009-2010 Charlie C.
 * -------------------------------------------------------------------------------
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 * claim that you wrote the original software. If you use this software
 * in a product, an acknowledgment in the product documentation would be
 * appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 * misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 * -------------------------------------------------------------------------------
 */
//#include "core/allocator.h"
#include "utString.h"

#include <string.h> // strlen
#include <stdio.h>
#include <stdarg.h>

#include "loom/common/core/allocator.h"

const utString::size_type utString::npos = static_cast<size_t>(-1);
const char *EMPTY_STRING = "";

/*
 * Like new, we want to guarantee that we NEVER
 * return NULL.  Loop until there is free memory.
 *
 */
static char* malloc_never_null(const size_t b) {
    char *p = NULL;

    do {
        p = static_cast<char*>(lmAlloc(NULL, b));
    } while (p == NULL);

    return p;
}


static char *strdup_never_null(const char *s)
{
    const size_t bufferSize = (s == NULL ? 0 : strlen(s)) + 1;
    if (bufferSize <= 1) {
        return (char*) EMPTY_STRING;
    }

    char *p  = malloc_never_null(bufferSize);

    memcpy(p, s, bufferSize);
    p[bufferSize-1] = 0;
    return p;
}


utString::utString() :
    p(NULL)
{
    clear();
}

utString::~utString() {
    clear();
}


utString::utString(const utString& s) :
    p(strdup_never_null(s.p))
{
}


utString::utString(const char *s) :
    p(strdup_never_null(s))
{
}


void utString::replace(char from, char to)
{
    for (UTsize i = 0; i < strlen(p); i++)
    {
        if (p[i] == from)
        {
            p[i] = to;
        }
    }
}


void utString::fromBytes(const void *bytes, int len)
{
    // Free old value if any.
    clear();

    // Copy the bytes into p.
    p = (char*)lmAlloc(NULL, len+1);
    memcpy(p, bytes, len);

    p[len] = 0; // Make sure we are NULL terminated.
}

void utString::assign(const char* bytes, int len)
{
    fromBytes((const void*)bytes, len);
}


utString& utString::operator=(const char *s)
{
    if (p != s)
    {
        // this should work with overlapping memory
        char *copy = strdup_never_null(s);
        clear();
        p = copy;
    }

    return *this;
}


utString& utString::operator=(const utString& s)
{
    return operator=(s.p);
}


utString& utString::operator+=(const utString& s)
{
    if (p == EMPTY_STRING)
    {
        operator=(s);
    }
    else
    {
        const size_type lenp = strlen(p);
        const size_type lens = strlen(s.p) + 1;
        p = static_cast<char*>(lmRealloc(NULL, p, lenp + lens)); // could return NULL
        memmove(p + lenp, s.p, lens); // p and s.p MAY overlap
    }
    return *this;
}


bool utString::operator==(const char *s) const
{
    return !strcmp(p, s);
}


bool utString::operator==(const utString& s) const
{
    return !strcmp(p, s.p);
}


bool utString::operator!=(const char *s) const
{
    return strcmp(p, s) != 0;
}


bool utString::operator!=(const utString& s) const
{
    return strcmp(p, s.p) != 0;
}

void utString::clear() {
    if (p != EMPTY_STRING) {
        lmSafeFree(NULL, p);
        p = (char*) EMPTY_STRING;
    }
}


utString operator+(const utString& lhs, const utString& rhs)
{
    return utString(lhs) += rhs;
}


utString::size_type utString::size() const
{
    return strlen(p);
}


utString::size_type utString::find(char c, size_type start)
{
    size_type len = strlen(p);

    for (size_type i = start; i < len; i++)
    {
        if (p[i] == c)
        {
            return i;
        }
    }

    return npos;
}


utString::size_type utString::length() const
{
    return strlen(p);
}


bool utString::empty() const
{
    return *p == '\0';
}


utString utString::substr(const size_type start,
                          size_type       len_orig) const
{
    utString  s;
    size_type len = strlen(p);

    if (len_orig == npos)
    {
        len_orig = len - start;
    }

    if (start > len)
    {
        abort();
    }

    if (len > len_orig)
    {
        len = len_orig;
    }

    s.clear();
    s.p = malloc_never_null(len + 1);
    memcpy(s.p, p + start, len);
    s.p[len] = '\0';

    return s;
}


// unchecked access
char utString::operator[](const size_type n) const
{
    return p[n];
}


// checked access
char utString::at(const size_type n) const
{
    if (n > strlen(p))
    {
        abort();
    }

    return p[n];
}


utString& utString::erase(size_type pos, size_type len)
{
    size_type s = size();

    if (pos > s)
    {
        abort();
    }

    s -= pos;
    if (len > s)
    {
        len = s;
    }
    ++s;

    // erase by overwriting
    memmove(p + pos, p + pos + len, s);

    // remove unused space
    p = static_cast<char*>(lmRealloc(NULL, p, s + pos));

    return *this;
}


utString utStringFormat(const char *format, ...)
{
#ifdef _MSC_VER
# define ut_vsnprintf    _vsnprintf_s
#else
# define ut_vsnprintf    vsnprintf
#endif

    va_list args;
    va_start(args, format);

    int       nBuf     = 0;
    const int BUF_SIZE = 1024;
    char      szBuffer[BUF_SIZE + 1];

    nBuf = ut_vsnprintf(szBuffer, BUF_SIZE, format, args);

    if (nBuf < 0)
    {
        szBuffer[BUF_SIZE] = 0;
    }

    va_end(args);

    return utString(szBuffer);

#undef ut_vsnprintf
}
