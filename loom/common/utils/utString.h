/*
 * -------------------------------------------------------------------------------
 *  General Purpose Utility Library, should be kept dependency free.
 *  Unless the dependency can be compiled along with this library.
 *
 *  Copyright (c) 2009-2010 Charlie C.
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
 *   claim that you wrote the original software. If you use this software
 *   in a product, an acknowledgment in the product documentation would be
 *   appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *   misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 * -------------------------------------------------------------------------------
 */
#ifndef _utString_h_
#define _utString_h_

#include "utCommon.h"
#include "utTypes.h"
#include <stdlib.h> // malloc, realloc, size_t - NOTE: Moved to .h from .cpp for Android compilation
//#include <string>

#define utStrlen    strlen
#define utStrcpy    strncpy
#define utCharNEq(a, b, n)    ((a && b) && !strncmp(a, b, n))
#define utCharEq(a, b)        ((a && b) && (*a == *b) && !strcmp(a, b))
#define utCharEqL(a, b, l)    ((a && b) && (*a == *b) && !strncmp(a, b, l))

#ifdef _MSC_VER
#pragma warning(disable : 4996)
#define strdup        _strdup
#define strcasecmp    _stricmp
#define stricmp       _stricmp
#endif

//* utString based on "mystring"
//* Copyright (C) Christian Stigen Larsen, 2007
//* Placed in the Public Domain by the author.
class utString {
    char *p;
public:
    typedef size_t   size_type;
    static const size_type npos;

    utString();
    virtual ~utString();
    utString(const utString&);
    utString(const char *);
    utString& operator=(const char *);
    utString& operator=(const utString&);
    utString& operator+=(const utString&);

    friend utString operator+(const utString& lhs, const utString& rhs);
    bool operator==(const char *) const;
    bool operator==(const utString&) const;
    bool operator!=(const char *) const;
    bool operator!=(const utString&) const;
    void clear();
    size_type size() const;
    size_type length() const;
    bool empty() const;

    inline const char *c_str() const
    {
        return p;
    }

    utString substr(const size_type start, size_type length = npos) const;
    char operator[](const size_type n) const;
    char at(const size_type n) const;
    utString& erase(size_type pos, size_type len);

    // Set this string's value from raw bytes, NULL terminating them.
    void fromBytes(const void *bytes, int length);

    size_type find(char c, size_type start = 0);

    // inplace replace
    void replace(char from, char to);
};

//typedef std::string utString;
typedef utArray<utString>   utStringArray;


// For operations on a fixed size character array
template<const UTuint16 L>
class utFixedString
{
public:
    UT_ASSERTCOMP((L < 0xFFFF), Limit);

    typedef char   Pointer[(L + 1)];


public:

    utFixedString() : m_size(0) { m_buffer[m_size] = 0; }


    utFixedString(const utFixedString& o) : m_size(0)
    {
        if (o.size())
        {
            UTuint16   i;
            const char *cp = o.c_str();
            for (i = 0; i < L && i < o.size(); ++i, ++m_size)
            {
                m_buffer[i] = cp[i];
            }
            m_buffer[m_size] = 0;
        }
        m_buffer[m_size] = 0;
    }

    utFixedString(const char *o) : m_size(0)
    {
        if (o)
        {
            UTuint16 i;
            for (i = 0; i < L && o[i]; ++i, ++m_size)
            {
                m_buffer[i] = o[i];
            }
            m_buffer[m_size] = 0;
        }
        m_buffer[m_size] = 0;
    }

    UT_INLINE void push_back(char ch)
    {
        if (m_size >= L) { return; }
        m_buffer[m_size++] = ch;
        m_buffer[m_size]   = 0;
    }

    void resize(UTuint16 ns)
    {
        if (ns < L)
        {
            if (ns < m_size)
            {
                for (UTuint16 i = ns; i < m_size; i++)
                {
                    m_buffer[i] = 0;
                }
            }
            else
            {
                for (UTuint16 i = m_size; i < ns; i++)
                {
                    m_buffer[i] = 0;
                }
            }
            m_size           = ns;
            m_buffer[m_size] = 0;
        }
    }

    utFixedString<L>& operator =(const utFixedString<L>& o)
    {
        if (o.m_size > 0)
        {
            if (!(utCharEqL(m_buffer, o.m_buffer, o.m_size)))
            {
                UTuint16 i;
                m_size = 0;
                for (i = 0; i < L && i < o.m_size; ++i, ++m_size)
                {
                    m_buffer[i] = o.m_buffer[i];
                }
                m_buffer[m_size] = 0;
            }
        }
        return *this;
    }

    // Raw data access

    UT_INLINE const char *c_str(void) const { return m_buffer; }
    UT_INLINE char *ptr(void)                               { return m_buffer; }
    UT_INLINE const char *ptr(void) const { return m_buffer; }
    UT_INLINE const char operator [](UTuint16 i) const { UT_ASSERT(i < m_size && i < L); return m_buffer[i]; }
    UT_INLINE const char at(UTuint16 i) const { UT_ASSERT(i < m_size && i < L); return m_buffer[i]; }
    UT_INLINE void clear(void)                              { m_buffer[0] = 0; m_size = 0; }


    // Size queries

    UT_INLINE int empty(void) const { return m_size == 0; }
    UT_INLINE int size(void) const { return m_size; }
    UT_INLINE int capacity(void) const { return L; }


    UT_INLINE bool operator ==(const utFixedString& str) const { return utCharEqL(m_buffer, str.m_buffer, bufMin(L, str.m_size + 1)); }
    UT_INLINE bool operator !=(const utFixedString& str) const { return !utCharEqL(m_buffer, str.m_buffer, bufMin(L, str.m_size + 1)); }



    UT_INLINE UThash hash(void) const
    {
        utCharHashKey ch(m_buffer);

        return ch.hash();
    }

protected:
    UT_INLINE UTuint16 bufMin(UTuint16 a, UTuint16 b) const { return a > b ? b : a; }
    Pointer  m_buffer;
    UTuint16 m_size;
};

/*
 * Hashed String which stores key value for future use, if you do not need this
 * consider using utFastHashedString which is much faster
 */
class utHashedString
{
protected:
    utString       m_key;
    mutable UThash m_hash;

public:
    utHashedString() : m_key(""), m_hash(UT_NPOS) {}
    ~utHashedString() {}

    utHashedString(char *k) : m_key(k), m_hash(UT_NPOS) { hash(); }
    utHashedString(const char *k) : m_key(const_cast<char *>(k)), m_hash(UT_NPOS) { hash(); }
    utHashedString(const utString& k) : m_key(k), m_hash(UT_NPOS) { hash(); }
    utHashedString(const utHashedString& k) : m_key(k.m_key), m_hash(k.m_hash) {}

    UT_INLINE const utString& str(void) const { return m_key; }

    UThash hash(void) const
    {
        // use cached hash
        if (m_hash != UT_NPOS) { return m_hash; }

        const char *str = m_key.c_str();

        // magic numbers from http://www.isthe.com/chongo/tech/comp/fnv/
        static const unsigned int InitialFNV  = 2166136261u;
        static const unsigned int FNVMultiple = 16777619u;

        // Fowler / Noll / Vo (FNV) Hash
        m_hash = (UThash)InitialFNV;
        for (int i = 0; str[i]; i++)
        {
            m_hash = m_hash ^ (str[i]);               // xor  the low 8 bits
            m_hash = m_hash * FNVMultiple;            // multiply by the magic number
        }
        return m_hash;
    }

    UT_INLINE bool operator==(const utHashedString& v) const { return hash() == v.hash(); }
    UT_INLINE bool operator!=(const utHashedString& v) const { return hash() != v.hash(); }
    UT_INLINE bool operator==(const UThash& v) const { return hash() == v; }
    UT_INLINE bool operator!=(const UThash& v) const { return hash() != v; }
};

/*
 * Fast string hash which doesn't store key value
 */
class utFastStringHash
{
protected:
    mutable UThash m_hash;

public:
    utFastStringHash() : m_hash(UT_NPOS) {}
    ~utFastStringHash() {}

    utFastStringHash(char *k) : m_hash(UT_NPOS) { _hash(k); }
    utFastStringHash(const char *k) : m_hash(UT_NPOS) { _hash(k); }
    utFastStringHash(const utString& k) : m_hash(UT_NPOS) { _hash(k.c_str()); }
    utFastStringHash(const utFastStringHash& k) : m_hash(k.m_hash) {}

    UThash hash(void) const
    {
        return m_hash;
    }

    UThash _hash(const char *str) const
    {
        // magic numbers from http://www.isthe.com/chongo/tech/comp/fnv/
        static const unsigned int InitialFNV  = 2166136261u;
        static const unsigned int FNVMultiple = 16777619u;

        // Fowler / Noll / Vo (FNV) Hash
        m_hash = (UThash)InitialFNV;
        for (int i = 0; str[i]; i++)
        {
            m_hash = m_hash ^ (str[i]);               // xor  the low 8 bits
            m_hash = m_hash * FNVMultiple;            // multiply by the magic number
        }
        return m_hash;
    }

    UT_INLINE bool operator==(const utFastStringHash& v) const { return hash() == v.hash(); }
    UT_INLINE bool operator!=(const utFastStringHash& v) const { return hash() != v.hash(); }
    UT_INLINE bool operator==(const UThash& v) const { return hash() == v; }
    UT_INLINE bool operator!=(const UThash& v) const { return hash() != v; }
};


utString utStringFormat(const char *format, ...);
#endif //_utString_h_
