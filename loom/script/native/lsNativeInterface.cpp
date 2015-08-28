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

#include "loom/script/common/lsLog.h"
#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/reflection/lsType.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"

namespace LS {
utHashTable<utPointerHashKey, NativeTypeBase *> NativeInterface::nativeTypes;

utHashTable<utPointerHashKey, Type *>         NativeInterface::scriptTypes;
utHashTable<utHashedString, NativeTypeBase *> NativeInterface::cTypes;

utHashTable<utPointerHashKey, NativeTypeBase *> NativeInterface::scriptToNative;

utHashTable<utPointerHashKey, lua_State *> NativeInterface::handleEntryToLuaState;


bool NativeTypeBase::checkBridgeTable(lua_State *L, MemberInfo *info, void *ptr, const char *key)
{
    if (info->getDeclaringType()->isPrimitive() && !info->isStatic())
    {
        return true;
    }

    int top = lua_gettop(L);

    lua_rawgetp(L, LUA_REGISTRYINDEX, ptr);

    assert(lua_istable(L, -1));
    lua_getmetatable(L, -1);

    lua_pushstring(L, key);
    lua_rawget(L, -2);

    if (!lua_isnil(L, -1))
    {
        lua_rawseti(L, -2, info->getOrdinal());
        lua_settop(L, top);
        return true;
    }

    lua_pop(L, 1);

    lua_rawgeti(L, -1, LSINDEXBRIDGE_PROPGET);
    lua_pushstring(L, key);
    lua_rawget(L, -2);

    // store via native ordinal as well for fast lookup
    bool ret = !lua_isnil(L, -1);
    lua_rawseti(L, -2, info->getOrdinal());

    lua_pop(L, 1);

    lua_rawgeti(L, -1, LSINDEXBRIDGE_PROPSET);

    lua_pushstring(L, key);
    lua_rawget(L, -2);

    // store via native ordinal as well for fast lookup
    lua_rawseti(L, -2, info->getOrdinal());

    lua_settop(L, top);

    return ret;
}


void NativeTypeBase::checkBridge(MemberInfo *info)
{
    lua_State *L = info->getDeclaringType()->getAssembly()->getLuaState()->VM();

    int top = lua_gettop(L);

    const char *key = info->getName();

    // in the case of a native constructor, we'll we using the __call metamethod on the
    // class table itself
    if (info->isConstructor() && info->getDeclaringType()->isNative())
    {
        key = "__call";
    }

    // we have to look in the static table, as the native instance method may be implemented using a static C++ method
    // So, check all the class tables

    if (!checkBridgeTable(L, info, bridgeStaticKey, key))
    {
        if (!checkBridgeTable(L, info, bridgeClassKey, key))
        {
            if (!checkBridgeTable(L, info, bridgeConstKey, key))
            {
                LSError("Type %s defines native member %s, but no equivalent native member was found.",
                    fullName.c_str(), info->getName());
            }
        }
    }

    lua_settop(L, top);
}


void NativeTypeBase::validate(Type *type)
{
    utArray<MemberInfo *> members;
    MemberTypes           mtypes;
    mtypes.property = true;
    mtypes.field = true;
    mtypes.constructor = true;
    mtypes.method = true;
    type->findMembers(mtypes, members);

    for (UTsize i = 0; i < members.size(); i++)
    {
        MemberInfo *info = members.at(i);

        // if we don't have an ordinal we aren't native
        if (!info->isNative())
        {
            continue;
        }

        checkBridge(info);
    }
}


void NativeInterface::shutdownLuaState(lua_State *L)
{
    utArray<utPointerHashKey> entries;
    for (UTsize i = 0; i < handleEntryToLuaState.size(); i++)
    {
        if (handleEntryToLuaState.at(i) == L)
        {
            entries.push_back(handleEntryToLuaState.keyAt(i));
        }
    }

    for (UTsize i = 0; i < entries.size(); i++)
    {
        handleEntryToLuaState.remove(entries.at(i));
    }

    //TODO: LOOM-708, improve vm shutdown
    scriptTypes.clear();
    scriptToNative.clear();
}


// note this method may be called multiple times per type, per VM
void NativeInterface::resolveScriptType(Type *type)
{
    for (UTsize i = 0; i < nativeTypes.size(); i++)
    {
        NativeTypeBase *ntype = nativeTypes.at(i);

        if (type->getPackageName() == ntype->getScriptPackage())
        {
            if (!strcmp(ntype->getScriptName().c_str(), type->getName()))
            {
                scriptTypes.insert(ntype, type);
                scriptToNative.insert(type, ntype);

                return;
            }
        }
    }

    lmAssert(0, "Unable to resolve script type %s", type->getFullName().c_str());
}


int NativeInterface::getManagedObectCount(const char *classPath,
    LSLuaState *ls)
{
    Type *type = ls->getType(classPath);

    assert(type);

    int count = 0;

    lua_State *L = ls->VM();

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);

    int tidx = lua_gettop(L);

    lua_pushnil(L); /* first key */
    while (lua_next(L, tidx) != 0)
    {
        lua_rawgeti(L, -1, LSINDEXTYPE);
        Type *t = (Type *)lua_topointer(L, -1);
        lua_pop(L, 1);

        lua_rawgeti(L, -1, LSINDEXDELETEDMANAGED);
        bool isDeleted = lua_toboolean(L, -1);
        lua_pop(L, 1);

        if (t == type && !isDeleted)
        {
            count++;
        }

        /* removes 'value'; keeps 'key' for next iteration */
        lua_pop(L, 1);
    }

    lua_settop(L, tidx - 1);

    return count;
}


void NativeInterface::dumpManagedNatives(lua_State *L)
{
    utHashTable<utPointerHashKey, int> count;

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);

    int tidx = lua_gettop(L);

    lua_pushnil(L); /* first key */
    while (lua_next(L, tidx) != 0)
    {
        lua_rawgeti(L, -1, LSINDEXTYPE);
        Type *type = (Type *)lua_topointer(L, -1);
        lua_pop(L, 1);

        if (count.find(type) == UT_NPOS)
        {
            count.insert(type, 1);
        }
        else
        {
            int *v = count.get(type);
            (*v)++;
        }

        /* removes 'value'; keeps 'key' for next iteration */
        lua_pop(L, 1);
    }

    lua_settop(L, tidx - 1);

    LSLog(LSLogInfo, "Dumping Managed Natives:");

    for (UTsize i = 0; i < count.size(); i++)
    {
        Type *type = (Type *)count.keyAt(i).key();
        int  v = count.at(i);

        LSLog(LSLogInfo, "%s : %i", type->getFullName().c_str(), v);
    }
}

void NativeInterface::managedPointerReleased(void* entry, int version)
{
    lua_State **statePtr = handleEntryToLuaState.get(entry);
    if (!statePtr)
        return;

    lua_State *L = *statePtr;

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDVERSION);

    lua_pushlightuserdata(L, entry);
    lua_pushnil(L);
    lua_settable(L, -3);

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDUSERDATA);
    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);

    lua_pushlightuserdata(L, entry);
    lua_gettable(L, -3); // get from userdata
    if (!lua_isnil(L, -1))
    {
        lua_pushvalue(L, -1);
        lua_gettable(L, -3);

        assert(lua_istable(L, -1));

        // clear the instance table of any values
        // this will force the deleted managed metatable
        // to trip on access (once set below)
        int tidx = lua_gettop(L);

        lua_newtable(L);

        int clearTableIdx = tidx + 1;
        int numClearValues = 0;

        lua_pushnil(L); /* first key */

        while (lua_next(L, tidx) != 0)
        {
            if (lua_isnumber(L, -2))
            {
                // We want to keep basic info in the (deleted) instance
                int indexer = (int)lua_tonumber(L, -2);

                if ((indexer == LSINDEXNATIVE) || (indexer == LSINDEXTYPE))
                {
                    lua_pop(L, 1); // pop value
                    continue;
                }
            }

            // push the key
            lua_pushvalue(L, -2);
            lua_rawseti(L, clearTableIdx, numClearValues++);

            // removes 'value'; keeps 'key' for next iteration
            lua_pop(L, 1);
        }

        // now run through the clearTable which holds the instance keys as values
        // and null out the instance keys

        for (int i = 0; i < numClearValues; i++)
        {
            lua_rawgeti(L, clearTableIdx, i);
            lua_pushnil(L);
            lua_settable(L, tidx);
        }

        lua_settop(L, tidx);

        lua_pushboolean(L, 1);
        lua_rawseti(L, tidx, LSINDEXDELETEDMANAGED);

        // mark managed instance as deleted
        // this replaces the metatable of the instance
        // with the deleted managed metatable which
        // provides errors on access
        luaL_getmetatable(L, LSDELETEDMANAGED);
        lua_setmetatable(L, -2);
        lua_pop(L, 1);

        lua_pushnil(L);
        lua_settable(L, -3); // clear from script
    }

    lua_pop(L, 1);
    // pop managed script

    lua_pushlightuserdata(L, entry);
    lua_pushnil(L);
    lua_settable(L, -3);

    lua_pop(L, 2);
}


void *lualoom_getnativepointer(lua_State *L, int index, bool replaceIndex, const char *typecheck)
{
    index = lua_absindex(L, index);

    lmAssert(!lua_isnil(L, index), "Internal Error: lua_getnativepointer() passes null value for type %s", typecheck ? typecheck : "Undefined");
    lmAssert(lua_istable(L, index), "Internal Error: lua_getnativepointer() received non-table for type %s", typecheck ? typecheck : "Undefined");

    if (typecheck)
    {
        lua_rawgeti(L, index, LSINDEXTYPE);
        Type *type = (Type *)lua_topointer(L, -1);
        lmAssert(type, "Internal Error: Unable to get valid Type* from native instance table");
        lmAssert(type->getFullName() == typecheck, "Internal Error: Type mismatch in lua_getnativepointer().  Expected %s, received %s", typecheck, type->getFullName().c_str());
        lua_pop(L, 1);
    }

    lua_rawgeti(L, index, LSINDEXNATIVE);

    lmAssert(lua_isuserdata(L, -1), "Internal Error: lua_getpointer() native index is not a userdata");

    int _index = -1;
    if (replaceIndex)
    {
        lua_replace(L, index);
        _index = index;
    }

    LS::Detail::Userdata *p = (Detail::Userdata *)lua_topointer(L, _index);
    lmAssert(p, "Internal Error: lua_getpointer() invalid pointer on lua stack");
    void *pointer = p->getPointer();
    lmAssert(pointer, "Internal Error: lua_getpointer() unable to get pointer from Userdata");

    if (!replaceIndex)
    {
        lua_pop(L, 1);
    }

    return pointer;
}

// Dump the global table of managed instances, filtering to only show two types.
static void lualoom_dumpmanagedtable(lua_State *L, Type *filterA, Type *filterB)
{
    LSLog(LSLogError, "----- managed table dump -----\n");

    NativeTypeBase *ntbA = NativeInterface::getNativeType(filterA);
    NativeTypeBase *ntbB = NativeInterface::getNativeType(filterB);

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);
    lua_pushnil(L);  // first key
    while (lua_next(L, -2) != 0)
    {
        Detail::UserdataPtr *ud = (Detail::UserdataPtr *)lua_topointer(L, -2);
        if(ud->m_nativeType == ntbA || ud->m_nativeType == ntbB)
        {
            // uses 'key' (at index -2) and 'value' (at index -1)
            LSLog(LSLogError, "%x - %s *%x\n", ud, ud->m_nativeType->getCTypeName().c_str(), ud->getPointer());
        }

        // removes 'value'; keeps 'key' for next iteration
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

void lualoom_downcastnativeinstance(lua_State *L, int instanceIdx, Type *fromType, Type *toType)
{
    // ensure that we match
    lmAssert(fromType->isNativeManaged() == toType->isNativeManaged(), "lualoom_downcastnativeinstance - managed/non-managed downcast mixmatch from type %s to type %s", fromType->getFullName().c_str(), toType->getFullName().c_str());
    lmAssert(fromType != toType, "lualoom_downcastnativeinstance - downcasting identical type %s to type %s", fromType->getFullName().c_str(), toType->getFullName().c_str());
    lmAssert(toType->isDerivedFrom(fromType), "lualoom_downcastnativeinstance - downcasting unrelated type %s to type %s", fromType->getFullName().c_str(), toType->getFullName().c_str());
    lmAssert(!toType->isInterface() && !fromType->isInterface(), "lualoom_downcastnativeinstance - downcasting interface type in cast type %s to type %s", fromType->getFullName().c_str(), toType->getFullName().c_str());

    // This and the one at the end of the function are useful when debugging
    // downcast issues - you can see if erroneous instances are present in the
    // table and if the table was modified properly. It filters to only show
    // instances matching the types we are casting from and to.
    //lualoom_dumpmanagedtable(L, fromType, toType);

    int top = lua_gettop(L);

    NativeTypeBase *nativeType = NativeInterface::getNativeType(toType);

    // replace the class table with the downcast table
    lsr_getclasstable(L, toType);
    lua_rawseti(L, instanceIdx, LSINDEXCLASS);

    // replace the type
    lua_pushlightuserdata(L, toType);
    lua_rawseti(L, instanceIdx, LSINDEXTYPE);

    // get the current user data
    lua_rawgeti(L, instanceIdx, LSINDEXNATIVE);

    bool managed = fromType->isNativeManaged();

    if (managed)
    {
        // if we're managed we need to clear original userdata
        // from managed -> script table.
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);
        lua_pushvalue(L, -2);
        lua_pushnil(L);
        lua_rawset(L, -3);
        lua_pop(L, 1);
    }

    Detail::UserdataPtr *ud = (Detail::UserdataPtr *)lua_topointer(L, -1);

    // create a new userdata of the "to" type given the native pointer
    lualoom_newnativeuserdata(L, nativeType, ud->getPointer());

    // ensure that we created the proper type
    Detail::UserdataPtr *nud = (Detail::UserdataPtr *)lua_topointer(L, -1);
    lmAssert(nud->m_nativeType == nativeType, "lualoom_downcastnativeinstance - native type mismatch on new user data");

    int uIdx = lua_gettop(L);

    // replace userdata
    lua_pushvalue(L, -1);
    lua_rawseti(L, instanceIdx, LSINDEXNATIVE);

    if (managed)
    {
        // if we're managed, need to update the managed tables

        // store (void*) entry to native bridge user data
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDUSERDATA);
        lua_pushlightuserdata(L, ud->getPointer());
        lua_pushvalue(L, uIdx);
        lua_settable(L, -3);
        lua_pop(L, 1);

        // store userdata -> script table
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);
        lua_pushvalue(L, uIdx);
        lua_pushvalue(L, instanceIdx);
        lua_settable(L, -3);
        lua_pop(L, 1);

        // we need to call the instance initializers for all types in the downcast
        // from the downcast type up to the from (which would have already been initialized)
        lualoom_callscriptinstanceinitializerchain_internal(L, toType, instanceIdx, fromType);
    }

    lua_settop(L, top);

    //lualoom_dumpmanagedtable(L, toType, fromType);
}


Type *lualoom_gettype(lua_State *L, const utString& fullPath)
{
    LSLuaState *ls = LSLuaState::getLuaState(L);
    Type       *type = ls->getType(fullPath.c_str());

    lmAssert(type, "ls_gettype() unable to get type: %s", fullPath.c_str());

    return type;
}


void lualoom_newnativeuserdata(lua_State *L, NativeTypeBase *nativeType, void *p)
{
    // In-place new the user data pointer and get a reference to it.
    new (lua_newuserdata(L, sizeof(Detail::UserdataPtr))) Detail::UserdataPtr(p);
    Detail::Userdata *ud = (Detail::Userdata *)lua_topointer(L, -1);

    // set the user data's native type
    ud->m_nativeType = nativeType;

    // look up the class' meta table by bridge key
    lua_rawgetp(L, LUA_REGISTRYINDEX, nativeType->getBridgeClassKey());

    // If this goes off it means you forgot to register the class!
    lmAssert(lua_istable(L, -1), "Unable to retrieve metatable for native class %s", nativeType->getCTypeName().c_str());

    lua_setmetatable(L, -2);
}


bool lualoom_pushnative(lua_State *L, NativeTypeBase *nativeType, void *p)
{
    if (!p)
    {
        lua_pushnil(L);
        return false;
    }

    // whenever we are pushing an unmanaged class, we must wrap the instance in a new
    // userdata
    if (!nativeType->isManaged())
    {
        // create the new userdata with given native type
        lualoom_newnativeuserdata(L, nativeType, p);
        // wrap the instance with the corresponding LoomScript class table
        lualoom_pushnative_userdata(L, NativeInterface::getScriptType(nativeType), -1);
        lua_remove(L, -2); // remove the user data
    }
    else
    {
        // we're managed
        NativeInterface::pushManagedNativeInternal(L, nativeType, p);
        lmAssert(lua_istable(L, -1), "Internal Error: unable to register managed native");
        return true;
    }

    return false;
}


void lualoom_pushnative_userdata(lua_State *L, Type *type, int nativeIdx)
{
    nativeIdx = lua_absindex(L, nativeIdx);

    lmAssert(lua_isuserdata(L, nativeIdx), "Internal Error: userdata expected in lsr_instancewrapnative");

    if (type->isNativeManaged())
    {
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);
        lua_pushvalue(L, nativeIdx);
        lua_gettable(L, -2);
        lmAssert(lua_istable(L, -1), "Internal Error: Unable to get managed native for return value");
        lua_remove(L, -2); // remove managed table
        return;
    }

    nativeIdx = lua_absindex(L, nativeIdx);

    lua_newtable(L);
    int instanceIdx = lua_gettop(L);

    lsr_getclasstable(L, type);
    lua_rawseti(L, instanceIdx, LSINDEXCLASS);

    lua_pushlightuserdata(L, type);
    lua_rawseti(L, instanceIdx, LSINDEXTYPE);

    lua_pushvalue(L, nativeIdx);
    lua_rawseti(L, instanceIdx, LSINDEXNATIVE);

    // set meta table
    luaL_getmetatable(L, LSINSTANCE);
    lua_setmetatable(L, instanceIdx);
}


void lualoom_managedpointerreleased(void *p)
{
    NativeInterface::managedPointerReleased(p, 1);
}


Type *lualoom_checkinstancetype(lua_State *L, int index, const char *fullTypePath)
{
    index = lua_absindex(L, index);

    if (!fullTypePath)
    {
        return NULL;
    }

    if (lua_isnil(L, index))
    {
        return NULL;
    }

    if (!lua_istable(L, index))
    {
        return NULL;
    }

    lua_rawgeti(L, index, LSINDEXTYPE);
    Type *type = (Type *)lua_topointer(L, -1);
    lua_pop(L, 1);

    if (!type)
    {
        return NULL;
    }

    if (!strcmp(type->getFullName().c_str(), fullTypePath))
    {
        return type;
    }

    return NULL;
}
}
