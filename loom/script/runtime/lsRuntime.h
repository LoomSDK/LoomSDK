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

#ifndef _lsruntime_h
#define _lsruntime_h

#include "loom/common/core/assert.h"
#include "loom/common/core/stringTable.h"
#include "loom/script/runtime/lsLua.h"
#include "loom/script/reflection/lsType.h"
#include "loom/script/reflection/lsMethodInfo.h"
#include "loom/script/common/lsError.h"

#undef _HAS_EXCEPTIONS
#include <typeinfo>

namespace LS {
// metatables
#define LSINSTANCE          "LSINSTANCE"
#define LSDELETEDMANAGED    "LSDELETEDMANAGED"
#define LSDICTIONARY        "LSDICTIONARY"
#define LSVECTOR            "LSVECTOR"
#define LSGCTRACKER         "LSGCTRACKER"

#define lualoom_isindexer(v)    (v >= LSINDEXNATIVE && v <= LSINDEXMAX)

// A native class instance will have a valid native userdata at this index.
// the native userdata is used to interface with the raw C++ properties, methods, etc
#define LSINDEXNATIVE                 -1000000

// Vector instance contain an internal table to hold values at this index
#define LSINDEXVECTOR                 -1000001

// Vector instances hold the length of the vector at this index
#define LSINDEXVECTORLENGTH           -1000002

// Vector instances which have been set to fixed size will have a boolean true at this index
#define LSINDEXVECTORFIXED            -1000003

// Global index for LoomScript class tables
#define LSINDEXCLASSES                -1000004

// Global index to retrievd script index from C++ userdata
#define LSINDEXMANAGEDNATIVESCRIPT    -1000005

// Instances will hold a pointer of Type* at this index
#define LSINDEXTYPE                   -1000006

// Instance will hold a reference to their script class table at this index
#define LSINDEXCLASS                  -1000007

// Class table holds a table of field name to ordinal at this index
#define LSINDEXMEMBERNAMEORDINALS     -1000008

// Dictionary instances maintain an internal table of pairs at this table
#define LSINDEXDICTPAIRS              -1000009

// Global table holding Native API Entry* -> C++ userdata
// (the default API is a pass thru so this will be actual native pointer of the C++ instance -> userdata
// other native api's (such as pooling) may map an entry to the userdata, etc
#define LSINDEXMANAGEDUSERDATA    -1000010

// Global table holding version information for Native API Entry* -> C++ userdata
// (the default API is a pass thru so this will always be version 1
// other native api's (such as pooling) may map a version to an entry
#define LSINDEXMANAGEDVERSION             -1000011

// Global table holding lua/luacfunction to MethodBase* lookups
#define LSINDEXMETHODLOOKUP               -1000012

// Global table holding native delegate pointer -> callback tables
#define LSINDEXNATIVEDELEGATES            -1000013

// index of callbacks on global native delegate table
#define LSINDEXNATIVEDELEGATECALLBACKS    -1000014

// MemberInfo* -> interned field name lookup
#define LSINDEXMEMBERINFONAME             -1000015

// LuaBridge indexers to avoid constant string interning
#define LSINDEXBRIDGE_CLASS               -1000016
#define LSINDEXBRIDGE_CONST               -1000017
#define LSINDEXBRIDGE_TYPE                -1000018
#define LSINDEXBRIDGE_PARENT              -1000019
#define LSINDEXBRIDGE_PROPGET             -1000020
#define LSINDEXBRIDGE_PROPSET             -1000021

// interned assembly name -> Assembly*
#define LSASSEMBLYLOOKUP                  -1000022

// Dictionary instances with weak keys will have a boolean true at this index
#define LSINDEXDICTIONARYWEAKKEYS         -1000023

// index of userdata attached to instance table, which once it hits GC has meta method called
#define LSINDEXGCTRACKER                  -1000024

// index for fast checking on whether a managed native instance has been deleted (from C/C++ or LoomScript)
#define LSINDEXDELETEDMANAGED             -1000025

#define LSINDEXMAX                        -1000025

void lsr_getclasstable(lua_State *L, Type *type);
void lsr_classinitialize(lua_State *L, Type *type);
void lsr_declareclass(lua_State *L, Type *type);

// creates an instance of type on top of stack
void lsr_createinstance(lua_State *L, Type *type);

void lsr_instanceregister(lua_State *L);

// Get the type of object on the stack at the given index
Type *lsr_gettype(lua_State *L, int index);

// converts object on index of stack to string, leaves stack unmodified
const char *lsr_objecttostring(lua_State *L, int index);

int lsr_method(lua_State *L);
void *lsr_getmethodcfunctionaddress();

inline void lsr_getclasstable(lua_State *L, Type *type)
{
    // check cache first
    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXCLASSES);
    lua_pushlightuserdata(L, type);
    lua_rawget(L, -2);
    if (!lua_isnil(L, -1))
    {
        lua_remove(L, -2); // remove __ls_classes
        return;
    }

    lua_pop(L, 1); // pop nil

    // cache type->class table

    int classesIdx = lua_gettop(L);

    lua_pushstring(L, type->getPackageName().c_str());
    lua_rawget(L, -2);

    lua_pushstring(L, type->getName());
    lua_rawget(L, -2);

    lua_remove(L, -2); // remove package table


    lmAssert(lua_istable(L, -1), "Unable to retrieve class table for type: %s", type->getFullName().c_str());

    lua_pushlightuserdata(L, type);
    lua_pushvalue(L, -2);      // push class table
    lua_rawset(L, classesIdx); //__ls_classes[type] -> class table

    lua_remove(L, -2);         // remove classes table
}


/*
 *  Gets the member ordinal from an instance at the specified index on the stack by name
 *  Please note that this value should be cached as this is an expensive operation
 *  which involves string interning
 */
inline int lualoom_getmemberordinal(lua_State *L, int index, const char *memberName)
{
    int top = lua_gettop(L);

    index = lua_absindex(L, index);

    // get the class from the instance
    lua_rawgeti(L, index, LSINDEXCLASS);

    // get the membername -> ordinal table
    lua_rawgeti(L, -1, LSINDEXMEMBERNAMEORDINALS);

    // get the ordinal
    lua_getfield(L, -1, memberName);

    if (!lua_isnumber(L, -1))
    {
        lua_settop(L, top);
        return 0;
    }

    int ordinal = (int)lua_tonumber(L, -1);

    lua_settop(L, top);

    return ordinal;
}


/*
 *  Sets the member of  the instance at the specified stack index to the value at the top of the stack
 *  Please note that this is an expensive operation and in performance critical code
 *  the instance should be manipulated directly by a cached ordinal instead of by string name
 */
inline bool lualoom_setmember(lua_State *L, int index, const char *memberName)
{
    int top = lua_gettop(L);

    index = lua_absindex(L, index);

    int ordinal = lualoom_getmemberordinal(L, index, memberName);

    if (!ordinal)
    {
        return false;
    }

    lua_rawgeti(L, index, LSINDEXTYPE);
    Type *type = (Type *)lua_topointer(L, -1);

    MemberInfo *mi = type->getMemberInfoByOrdinal(ordinal);

    lmAssert(mi, "Unable to find member: %s", memberName);

    if (mi->isStatic())
    {
        // set to the class table
        lua_rawgeti(L, index, LSINDEXCLASS);

        lua_pushnumber(L, ordinal);
        lua_pushvalue(L, top);
        lua_settable(L, -3);
    }
    else
    {
        lua_pushnumber(L, ordinal);
        lua_pushvalue(L, top);
        lua_settable(L, index);
    }

    lua_settop(L, top);

    return true;
}


/*
 *  Gets the member of  the instance at the specified stack index leaving the value at the top of the stack
 *  Please note that this is an expensive operation and in performance critical code
 *  the instance should be manipulated directly by a cached ordinal instead of by string name
 */
inline void lualoom_getmember(lua_State *L, int index, const char *memberName)
{
    index = lua_absindex(L, index);

    // result
    lua_pushnil(L);
    int top = lua_gettop(L);

    int ordinal = lualoom_getmemberordinal(L, index, memberName);

    if (!ordinal)
    {
        lua_settop(L, top);
        return;
    }

    lua_rawgeti(L, index, LSINDEXTYPE);
    Type *type = (Type *)lua_topointer(L, -1);

    MemberInfo *mi = type->getMemberInfoByOrdinal(ordinal);

    lmAssert(mi, "Unable to find member: %s", memberName);

    if (mi->isStatic())
    {
        // get from the class table
        lua_rawgeti(L, index, LSINDEXCLASS);
        lua_pushnumber(L, ordinal);
        lua_gettable(L, -2);
    }
    else
    {
        lua_pushnumber(L, ordinal);
        lua_gettable(L, index);
    }

    lua_replace(L, top);
    lua_settop(L, top);
}


/*
 * Given a MethodBase, will push the lua function on the stack.  If it is not found, will push nil instead
 */
inline void lsr_pushmethodbase(lua_State *L, MethodBase *base)
{
    Type *dtype = base->getDeclaringType();

    lua_pushnil(L); // for return
    int top = lua_gettop(L);

    // look in the native class table, first we look up the package
    lua_getglobal(L, "__ls_nativeclasses");
    lua_getfield(L, -1, dtype->getPackageName().c_str());

    if (lua_isnil(L, -1))
    {
        LSError("Missing native class %s",
                dtype->getFullName().c_str());
    }

    // next we look up the class in the package table
    lua_getfield(L, -1, dtype->getName());

    if (!lua_isnil(L, -1))
    {
        // look up the method by name in the class table
        lua_getfield(L, -1, base->getName());
        if (!lua_isnil(L, -1))
        {
            // it exists, great
        }
        else
        {
            // we didn't find it there, so look in the luabridge __class table
            lua_pop(L, 1);
            lua_pushnumber(L, LSINDEXBRIDGE_CLASS);
            lua_gettable(L, -2);

            if (!lua_isnil(L, -1))
            {
                lua_pushstring(L, base->getName());
                lua_rawget(L, -2);
            }

            // if we're still not found, look for a native constructor
            // which will be in the __call metamethod
            if (base->isConstructor() && lua_isnil(L, -1))
            {
                lua_pop(L, 1);
                lua_getmetatable(L, -2);
                lua_pushstring(L, "__call");
                lua_rawget(L, -2);
            }
        }

        // replace nil return
        lua_replace(L, top);
    }

    lua_settop(L, top);
}


// avoid oodles of static buffers compiler into template code
#define TYPENAME_BUFFER_SIZE    1024
extern char *_normalizedTypeNameBuffer;
extern char *_typeNameBuffer;

/*
 * We normalize to one compiler's typename reporting
 * which means gcc/clang, we also remove const info
 */
inline const char *LSNormalizeTypeName(const char *typeName)
{
    const char *src = typeName;

    if (!strncmp(typeName, "class ", 6))
    {
        src = &typeName[6];
    }
    else if (!strncmp(typeName, "struct ", 7))
    {
        src = &typeName[7];
    }

    int j = 0;
    for (size_t i = 0; i < strlen(src); i++)
    {
        if (src[i] == ' ')
        {
            if (src[i + 1] == '*')
            {
                //remove space
                _normalizedTypeNameBuffer[j++] = '*';
                i++;
                continue;
            }

            if (!strcmp(&src[i], " const"))
            {
                i += 5; // skip const
                continue;
            }
        }

        _normalizedTypeNameBuffer[j++] = src[i];
    }

    _normalizedTypeNameBuffer[j] = '\0';

    return _normalizedTypeNameBuffer;
}


// For unmangling typenames
#ifndef HAVE_CXA_DEMANGLE
template<typename TYPE>
const char *LSGetTypeName()
{
    // remove "class " or "struct " under MSC_VER
    return LSNormalizeTypeName(typeid(TYPE).name());
}


#else
#include <cxxabi.h>
template<typename TYPE>
const char *LSGetTypeName()
{
    size_t size = (size_t)TYPENAME_BUFFER_SIZE;
    int    status;

    const char *name = typeid(TYPE).name();

    memset(_typeNameBuffer, 0, TYPENAME_BUFFER_SIZE);

    char *res = abi::__cxa_demangle(name,
                                    _typeNameBuffer,
                                    &size,
                                    &status);

    return LSNormalizeTypeName(res);
}
#endif

// run a frame of GC (implemented in lmGC.cpp)
void lualoom_gc_update(lua_State *L);

struct GCTracker
{
    Type       *type;
    MethodBase *methodBase;
};
}
#endif
