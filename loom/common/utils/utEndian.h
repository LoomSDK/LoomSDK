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

#ifndef _utEndian_h_
#define _utEndian_h_

#define UT_ENDIAN_LITTLE    0
#define UT_ENDIAN_BIG       1

#if defined(__sgi) || defined (__sparc) ||      \
    defined (__sparc__) || defined (__PPC__) || \
    defined (__ppc__) || defined (__BIG_ENDIAN__)
#define UT_ENDIAN           UT_ENDIAN_BIG
#else
#define UT_ENDIAN           UT_ENDIAN_LITTLE
#endif

// The following is only valid under C++, though we
// want consistent endian detection under C/C++

#ifdef __cplusplus

//------------------------------------------------------------------------------
// Endian conversions

inline unsigned char endianSwap(const unsigned char in_swap)
{
    return in_swap;
}


inline char endianSwap(const char in_swap)
{
    return in_swap;
}


inline bool endianSwap(const bool in_swap)
{
    return in_swap;
}


/**
 * Convert the byte ordering on the unsigned short to and from big/little endian format.
 * @param in_swap Any unsigned short
 * @returns swapped unsigned short.
 */
inline unsigned short endianSwap(const unsigned short in_swap)
{
    return (unsigned short)(((in_swap >> 8) & 0x00ff)
                            | ((in_swap << 8) & 0xff00));
}


inline short endianSwap(const short in_swap)
{
    return short(endianSwap((unsigned short)(in_swap)));
}


/**
 * Convert the byte ordering on the unsigned int to and from big/little endian format.
 * @param in_swap Any unsigned int
 * @returns swapped unsigned int.
 */
inline unsigned int endianSwap(const unsigned int in_swap)
{
    return (unsigned int)(((in_swap >> 24) & 0x000000ff)
                          | ((in_swap >> 8) & 0x0000ff00) | ((in_swap << 8) & 0x00ff0000)
                          | ((in_swap << 24) & 0xff000000));
}


inline int endianSwap(const int in_swap)
{
    return int(endianSwap((unsigned int)(in_swap)));
}


inline unsigned long long endianSwap(const unsigned long long in_swap)
{
    unsigned int       *inp = (unsigned int *)&in_swap;
    unsigned long long ret;
    unsigned int       *outp = (unsigned int *)&ret;

    outp[0] = endianSwap(inp[1]);
    outp[1] = endianSwap(inp[0]);
    return ret;
}


inline long long endianSwap(const long long in_swap)
{
    return (long long)(endianSwap((unsigned long long)(in_swap)));
}


inline float endianSwap(const float in_swap)
{
    unsigned int result = endianSwap(*((unsigned int *)&in_swap));

    return *((float *)&result);
}


inline double endianSwap(const double in_swap)
{
    unsigned long long result = endianSwap(*((unsigned long long *)&in_swap));

    return *((double *)&result);
}


//------------------------------------------------------------------------------
// Endian conversions

#if UT_ENDIAN == UT_ENDIAN_LITTLE

#define DECLARE_TEMPLATIZED_ENDIAN_CONV(type)                                \
    inline type convertHostToLEndian(const type i) { return i; }             \
    inline type convertLEndianToHost(const type i) { return i; }             \
    inline type convertHostToBEndian(const type i) { return endianSwap(i); } \
    inline type convertBEndianToHost(const type i) { return endianSwap(i); }

#elif UT_ENDIAN == UT_ENDIAN_BIG

#define DECLARE_TEMPLATIZED_ENDIAN_CONV(type)                                \
    inline type convertHostToLEndian(const type i) { return endianSwap(i); } \
    inline type convertLEndianToHost(const type i) { return endianSwap(i); } \
    inline type convertHostToBEndian(const type i) { return i; }             \
    inline type convertBEndianToHost(const type i) { return i; }

#else
#error "Endian define not set!"
#endif

DECLARE_TEMPLATIZED_ENDIAN_CONV(bool)
DECLARE_TEMPLATIZED_ENDIAN_CONV(unsigned char)
DECLARE_TEMPLATIZED_ENDIAN_CONV(char)
DECLARE_TEMPLATIZED_ENDIAN_CONV(unsigned short)
DECLARE_TEMPLATIZED_ENDIAN_CONV(short)
DECLARE_TEMPLATIZED_ENDIAN_CONV(unsigned int)
DECLARE_TEMPLATIZED_ENDIAN_CONV(int)
DECLARE_TEMPLATIZED_ENDIAN_CONV(unsigned long long)
DECLARE_TEMPLATIZED_ENDIAN_CONV(long long)
DECLARE_TEMPLATIZED_ENDIAN_CONV(float)
DECLARE_TEMPLATIZED_ENDIAN_CONV(double)
#endif //__cplusplus
#endif
