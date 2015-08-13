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

#ifndef _UTILS_FOURCC_H_
#define _UTILS_FOURCC_H_

#include "loom/common/utils/utEndian.h"

#if UT_ENDIAN == UT_ENDIAN_BIG
#define LOOM_FOURCC(ch0, ch1, ch2, ch3)           \
    ((unsigned int)(unsigned char)(ch3)           \
     | ((unsigned int)(unsigned char)(ch2) << 8)  \
     | ((unsigned int)(unsigned char)(ch1) << 16) \
     | ((unsigned int)(unsigned char)(ch0) << 24))
#else
#define LOOM_FOURCC(ch0, ch1, ch2, ch3)           \
    ((unsigned int)(unsigned char)(ch0)           \
     | ((unsigned int)(unsigned char)(ch1) << 8)  \
     | ((unsigned int)(unsigned char)(ch2) << 16) \
     | ((unsigned int)(unsigned char)(ch3) << 24))
const char* LOOM_FOURCC_CHARS(unsigned int fourcc);
#endif
#endif
