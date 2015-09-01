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

/*
 * Takes ownership of a pointer and frees/destroys it when it goes out of scope.
 */
template <typename T>
class lmAutoPtr
{
private:
    // Pointer that is held
    T* ptr;

    // Do we own the pointer? Delete only of owned.
    // Non-owned means ptr is uninitialized/null.
    bool owned;

    // Disable copy constructor
    lmAutoPtr(const lmAutoPtr& copy);

    // Disable assignment operator
    lmAutoPtr& operator=(const lmAutoPtr& other);

public:

    // Default constructor - sets everything to unintialized.
    // To set a value use reset()
    lmAutoPtr()
    : ptr(0)
    , owned(false)
    {}

    // A constructor that initializes to a pointer. If it's non-null, it becomes owned.
    lmAutoPtr(T* p)
    : ptr(p)
    , owned(p ? true : false)
    {}

    // If the poitner is owned, the memory will be freed.
    ~lmAutoPtr()
    {
        if (owned)
            lmDelete(NULL, ptr);
    }

    // Assign a pointer. If there was a previous pointer owned, free it.
    lmAutoPtr& operator=(T* p)
    {
        reset(p);
        return *this;
    }

    // Get the value of the pointer.
    T* get()
    {
        return ptr;
    }

    // Release ownership of the pointer. The pointer value will remain the same.
    T* release()
    {
        owned = false;
        return ptr;
    }

    // Set the pointer. If there was a previous pointer owned, free it.
    void reset(T* p = NULL)
    {
        if (owned)
            lmDelete(NULL, ptr);

        owned = p ? true : false;
        ptr = p;
    }
};

#endif
