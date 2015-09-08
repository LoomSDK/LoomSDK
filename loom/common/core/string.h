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

#ifndef _CORE_STRING_H_
#define _CORE_STRING_H_

/* This file provides cross-platform compatibility of some string functions
 * in C and C++ code.
 */

#ifdef _MSC_VER
#define stricmp    _stricmp
#endif

#if LOOM_PLATFORM_IS_APPLE == 1 || ANDROID_NDK || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#define stricmp    strcasecmp //I feel dirty.
#endif

#endif
