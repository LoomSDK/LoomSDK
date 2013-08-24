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

#ifndef _platformfileios_h
#define _platformfileios_h

#include "loom/common/platform/platform.h"
#if LOOM_PLATFORM_IS_APPLE == 1

#ifdef __cplusplus
extern "C" {
#endif
const char *platform_getWorkingDirectory();
const char *platform_getResourceDirectory();
void platform_changeDirectory(const char *folder);

#ifdef __cplusplus
}
#endif
#endif
#endif
