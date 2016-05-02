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


#ifndef _lserror_h
#define _lserror_h

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "lsLog.h"

namespace LS {

typedef void(*LSExitHandler)();

extern "C" {
void LSSetExitHandler(LSExitHandler handler);
void LSError(const char *format, ...);
void LSWarning(const char *format, ...);
}
}
#endif
