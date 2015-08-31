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

#ifndef _UTILS_AUTO_PTR_H_
#define _UTILS_AUTO_PTR_H_

#include "loom/common/core/allocator.h"

template <typename T>
class lmAutoPtr
{
private:
    T* ptr;
    bool owned;

public:
    lmAutoPtr()
    : ptr(0)
    , owned(false)
    {}

    lmAutoPtr(T* p)
    : ptr(p)
    , owned(p ? true : false)
    {}

    ~lmAutoPtr()
    {
        if (owned)
            lmDelete(NULL, ptr);
    }
    
    T* get()
    {
        return ptr;
    }
    
    T* release()
    {
        owned = false;
        return ptr;
    }
    
    void reset(T* p = NULL)
    {
        owned = p ? true : false;
        ptr = p;
    }
};

#endif
