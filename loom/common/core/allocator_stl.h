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

#ifndef _CORE_ALLOCATOR_STL_H_
#define _CORE_ALLOCATOR_STL_H_

#include "loom/common/core/allocator.h"

#include <memory>
#include <string>
#include <map>
#include <vector>

template<class T>
class lmStlAlloc
{
public:
    typedef size_t      size_type;
    typedef ptrdiff_t   difference_type;
    typedef T*          pointer;
    typedef const T*    const_pointer;
    typedef T&          reference;
    typedef const T&    const_reference;
    typedef T           value_type;

    template <class U>
    struct rebind
    {
        typedef lmStlAlloc<U> other;
    };

    lmStlAlloc() {}

    template <class U>
    lmStlAlloc(lmStlAlloc<U> const &) {}

    template <class U>
    lmStlAlloc& operator=(const lmStlAlloc<U>&) { return *this; }

    template <class U>
    bool operator==(const lmStlAlloc<U>&) const { return typeid(T) == typeid(U); }

    pointer allocate(size_type n, std::allocator<void>::const_pointer hint = 0)
    {
        return static_cast<pointer>(lmAlloc(nullptr, n * sizeof(value_type)));
    }

    void deallocate(pointer p, size_type n)
    {
        lmFree(nullptr, p);
    }

    template<typename... Args>
    void construct(pointer p, Args... args)
    {
        ::new(p)T(args...);
    }

    void destroy(pointer p)
    {
        p->~T();
    }

    size_type max_size() const throw()
    {
        // Android compiler doesn't know numeric limits :(
        //return std::numeric_limits<size_t>::max() / sizeof(T);
        return SIZE_MAX / sizeof(T);
    }
};

template<class T>
struct lmStlDelete
{
    lmStlDelete()
    {
    }

    template<class U>
    lmStlDelete(const lmStlDelete<U>&)
    {
    }

    void operator()(T *ptr) const
    {
        lmStlAlloc<T> alloc;
        alloc.destroy(ptr);
        alloc.deallocate(ptr, 1);
    }
};

template<typename K, typename V, typename comp = std::less<K>>
using lmMap = std::map<K, V, comp, lmStlAlloc<std::pair<K, V>>>;

using lmString = std::basic_string<char, std::char_traits<char>, lmStlAlloc<char>>;

template<typename T>
using lmSptr = std::shared_ptr<T>;

template<typename T, typename... Args>
inline lmSptr<T> lmMakeSptr(Args... args)
{
    lmStlAlloc<T> alloc;
    T* ptr = alloc.allocate(1);
    alloc.construct(ptr, args...);
    return lmSptr<T>(ptr, lmStlDelete<T>(), lmStlAlloc<T>());
}

template<typename T>
using lmUptr = std::unique_ptr<T, lmStlDelete<T>>;

template<typename T, typename... Args>
inline lmUptr<T> lmMakeUptr(Args... args)
{
    lmStlAlloc<T> alloc;
    T* ptr = alloc.allocate(1);
    alloc.construct(ptr, args...);
    return lmUptr<T>(ptr, lmStlDelete<T>());
}

template<typename T>
using lmWptr = std::weak_ptr<T>;

#endif