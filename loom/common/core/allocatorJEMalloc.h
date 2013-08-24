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

#ifndef _CORE_JEMALLOC_ALLOCATORJEMALLOC_H_
#define _CORE_JEMALLOC_ALLOCATORJEMALLOC_H_

#include "loom/common/core/allocator.h"

#ifdef __cplusplus
extern "C" {
#endif

loom_allocator_t *loom_allocator_initializeJemallocAllocator(loom_allocator_t *parent);

#ifdef __cplusplus
};
#endif
#endif
