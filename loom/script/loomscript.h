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

#ifndef _loomscript_h
#define _loomscript_h

#include "loom/common/core/assert.h"
#include "loom/common/platform/platform.h"

#include <assert.h>
#undef _HAS_EXCEPTIONS
#include <exception>
#include <typeinfo>

// For unmangling typenames
#ifdef HAVE_CXA_DEMANGLE
#include <cxxabi.h>
#endif


#include "loom/script/runtime/lsLua.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/native/lsLuaBridge.h"

using namespace LS;

#define LOOM_DECLARE_NATIVETYPE(_class, regfunc) \
    NativeInterface::registerNativeType<_class>(regfunc);

#define LOOM_DECLARE_MANAGEDNATIVETYPE(_class, regfunc) \
    NativeInterface::registerManagedNativeType<_class>(regfunc);
#endif
