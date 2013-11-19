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

#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/runtime/lsProfiler.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"

namespace LS
{
/*
 * Fast call C closure for property set
 */
static int lsr_method_fastcall_set(lua_State *L)
{
    CallFastMemberBase *fastcall = (CallFastMemberBase *)lua_topointer(L, lua_upvalueindex(1));

    fastcall->call(L, (void *)lua_topointer(L, lua_upvalueindex(2)), fastcall);
    return 0;
}


/*
 * Fast call C closure for property get
 */
static int lsr_method_fastcall_get(lua_State *L)
{
    CallFastMemberBase *fastcall = (CallFastMemberBase *)lua_topointer(L, lua_upvalueindex(1));

    fastcall->call(L, (void *)lua_topointer(L, lua_upvalueindex(2)), fastcall);
    return 1;
}


/*
 * Static methods use the lsr_method closure which is generated at class initialization time
 * Instance methods are bound to a generated lsr_method closure the first time the method is referenced (at runtime)
 * lsr_method is a thin wrapper which handles catching native calls for profiling, default arguments, etc
 */
int lsr_method(lua_State *L)
{
    int nargs = lua_gettop(L);

    MethodBase *method = (MethodBase *)lua_topointer(L, lua_upvalueindex(1));

    bool staticCall = method->isStatic();

    if (staticCall)
    {
        lua_pushvalue(L, lua_upvalueindex(2));
        lua_insert(L, 1); // method
    }
    else
    {
        lua_pushvalue(L, lua_upvalueindex(2));
        lua_insert(L, 1); // this (can be a loomscript table or luabridge userdata

        lua_pushvalue(L, lua_upvalueindex(3));
        lua_insert(L, 1); // method
    }


    int dargs = nargs;

    int fidx            = method->getFirstDefaultParm();
    int varArgIdx       = method->getVarArgIndex();
    int varArgVectorIdx = lua_gettop(L);

    // don't consider the varargs in when
    // checking whether we need to insert default arguments
    if ((fidx != -1) && (varArgIdx != -1))
    {
        dargs--;
    }

    if (dargs < method->getNumParameters())
    {
        // TODO: Report line numbers LOOM-603
        // if we have var args and not enough parameters, VM will insert null for ...args value
        // otherwise, we have a compiler error
        if (varArgIdx < 0)
            lmAssert(fidx >= 0, "Method '%s::%s' called with too few arguments.", method->getDeclaringType()->getFullName().c_str(), method->getStringSignature().c_str());

        bool inserted = false;
        for (int i = dargs; i < method->getNumParameters(); i++)
        {
            if (i == varArgIdx)
            {
                break;
            }

            lua_pushvalue(L, lua_upvalueindex(i - fidx + (staticCall ? 3 : 4)));
            inserted = true;
            nargs++;
        }

        // if we inserted *and* have var args, we
        // need to shift the var args to the end
        if (inserted && (varArgIdx != -1))
        {
            lua_pushvalue(L, varArgVectorIdx);
            lua_remove(L, varArgVectorIdx);
        }
    }

    LSLuaState *ls = LSLuaState::getLuaState(L);

    // error handling
    lua_getglobal(L, "__ls_traceback");
    lua_insert(L, 1);

    if (lua_pcall(L, nargs + (staticCall ? 0 : 1), LUA_MULTRET, 1))
    {
        ls->triggerRuntimeError("Error calling %s:%s", method->getDeclaringType()->getFullName().c_str(), method->getName());
    }

    // get rid of the traceback
    lua_remove(L, 1);

    int nreturn = lua_gettop(L);

    if (nreturn == 1)
    {
        if (method->isNative() && method->isMethod() && lua_isuserdata(L, -1))
        {
            lualoom_pushnative_userdata(L, ((MethodInfo *)method)->getReturnType(), -1);
        }
    }

    return nreturn;
}


void *lsr_getmethodcfunctionaddress()
{
    return (void *)lsr_method;
}


// only called when table index does not exist
static int lsr_instancenewindex(lua_State *L)
{
    if (!lua_isnumber(L, 2))
    {
        lua_rawset(L, 1);
        return 0;
    }

    lua_rawgeti(L, 1, LSINDEXTYPE);
    Type *type = (Type *)lua_topointer(L, -1);
    lua_pop(L, 1);

    lmAssert(type, "Missing type on instance new index");

    int ordinal = (int)lua_tonumber(L, 2);
    // a loom indexer should be in the table (not missing so it his the index metamethod)
    lmAssert(!lualoom_isindexer(ordinal), "Internal Error: instance table being indexed by a LSINDEX value.");

    if (!type->isNativeOrdinal(ordinal))
    {
        lua_rawset(L, 1);
        return 0;
    }
    else
    {
        lua_rawgeti(L, 1, LSINDEXNATIVE);
        lua_replace(L, 1);
        lua_settable(L, 1);
    }

    return 0;
}


static int lsr_instanceindex(lua_State *L)
{
    // we hit the instance index metamethod when we can't find a value
    // in the instance's table, this is a native or a bound method

    lua_rawgeti(L, 1, LSINDEXTYPE);
    Type *type = (Type *)lua_topointer(L, -1);
    lua_pop(L, 1);

    lmAssert(type, "Missing type on instance index");

    if (lua_isnumber(L, 2))
    {
        int ordinal = (int)lua_tonumber(L, 2);

        MemberInfo *mi = type->getMemberInfoByOrdinal(ordinal);

        lmAssert(mi, "Unable to find ordinal %s %i", type->getFullName().c_str(), ordinal);

        if (mi->isStatic())
        {
            lua_rawgeti(L, 1, LSINDEXCLASS);
            lua_replace(L, 1);
            lua_gettable(L, 1);
            return 1;
        }

        // we need to look in the class, the result will be cached to instance

        MethodBase *method = NULL;

        if (mi->isMethod())
        {
            method = (MethodBase *)mi;
        }

        if (method)
        {
            lua_rawgeti(L, 1, LSINDEXCLASS);
            assert(!lua_isnil(L, -1));

            int clsIdx = lua_gettop(L);

            if (!method->isStatic())
            {
                if (method->isFastCall())
                {
                    // get the fast call structure pointer
                    lua_pushlightuserdata(L, method->getFastCall());

                    // get the the "this"
                    if (lua_type(L, 1) == LUA_TTABLE)
                    {
                        lua_rawgeti(L, 1, LSINDEXNATIVE);
                    }
                    else
                    {
                        lua_pushvalue(L, 1);
                    }

                    // unwrap this
                    Detail::UserdataPtr *p1 = (Detail::UserdataPtr *)lua_topointer(L, -1);
                    lua_pushlightuserdata(L, p1->getPointer());
                    lua_replace(L, -2);

                    lua_pushnumber(L, ordinal);
                    lua_gettable(L, clsIdx);
                }
                else
                {
                    lua_pushlightuserdata(L, method);
                    lua_pushvalue(L, 1);
                    lua_pushnumber(L, ordinal);
                    lua_gettable(L, clsIdx);
                }

                assert(!lua_isnil(L, -1));

                int nup = 3;

                int fd = method->getFirstDefaultParm();
                if (fd != -1)
                {
                    utString dname;
                    if (method->isConstructor())
                    {
                        dname = "__ls_constructor";
                    }
                    else
                    {
                        dname = method->getName();
                    }

                    dname += "__default_args";

                    lua_getfield(L, clsIdx, dname.c_str());

                    int dargs = lua_gettop(L);

                    for (int i = fd; i < method->getNumParameters(); i++)
                    {
                        lua_pushnumber(L, i);
                        lua_gettable(L, dargs);
                        nup++;
                    }

                    lua_remove(L, dargs);
                }

                // check for fast path
                if (method->isFastCall())
                {
                    if (method->getNumParameters())
                    {
                        // setter
                        lua_pushcclosure(L, lsr_method_fastcall_set, nup);
                    }
                    else
                    {
                        // getter
                        lua_pushcclosure(L, lsr_method_fastcall_get, nup);
                    }
                }
                else
                {
                    // bind the instance method
                    lua_pushcclosure(L, lsr_method, nup);
                }

                // store to method lookup, this is worth it
                // as only happens once per instance method bind
                // and can now lookup MethodBase on any function
                // in one table lookup
                lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
                lua_pushvalue(L, -2);
                lua_pushlightuserdata(L, method);
                lua_rawset(L, -3);
                lua_pop(L, 1);

                // cache to instance
                lua_pushvalue(L, -1);
                lua_rawseti(L, 1, ordinal);


                return 1;
            }
            else
            {
                assert(0);
            }
        }

        FieldInfo *field = NULL;

        if (mi->isField())
        {
            field = (FieldInfo *)mi;
        }

        if (field && field->isNative())
        {
            // for primitive fields, we could generate
            // a direct lookup in the LSINDEXNATIVE table
            // in bytecode gen, however this only saves for
            // native vars and not properties
            // (which should be using fast path anyway and complicates bytecode)

            // get the native userdata
            lua_rawgeti(L, 1, LSINDEXNATIVE);
            lua_pushnumber(L, field->getOrdinal());
            lua_gettable(L, -2);

            // if we are native we need to wrap
            if (lua_isuserdata(L, -1))
            {
                lualoom_pushnative_userdata(L, field->getType(), -1);
            }

            return 1;
        }

        // if we get here the value actually is null
        lua_pushnil(L);
        return 1;
    }

    // if we hit here, this should be an interface access where we have to
    // look up by string (and cache as these are only ever instance methods)

    const char *name  = lua_tostring(L, 2);
    const char *pname = name;
    MemberInfo *mi    = NULL;

    if (!strncmp(name, "__pget_", 7))
    {
        pname = &name[7];
        mi    = type->findMember(pname, true);
        lmAssert(mi && mi->isProperty(), "Could not find property getter for '%s' on type '%s'", pname, type->getFullName().c_str());
        mi = ((PropertyInfo *)mi)->getGetMethod();
        lmAssert(mi, "Found NULL property getter for '%s' on type '%s'", pname, type->getFullName().c_str());
    }
    else if (!strncmp(name, "__pset_", 7))
    {
        pname = &name[7];
        mi    = type->findMember(pname, true);
        lmAssert(mi && mi->isProperty(), "Could not find property setter for '%s' on type '%s'", pname, type->getFullName().c_str());
        mi = ((PropertyInfo *)mi)->getSetMethod();
        lmAssert(mi, "Found NULL property setter for '%s' on type '%s'", pname, type->getFullName().c_str());
    }
    else
    {
        mi = type->findMember(name, true);
        lmAssert(mi, "Unable to find member via string %s : %s", type->getFullName().c_str(), name);
        assert(mi);
        assert(mi->isMethod());
        assert(mi->getOrdinal());
    }

    lua_pushnumber(L, mi->getOrdinal());
    lua_gettable(L, 1);
    lua_pushstring(L, name);
    lua_pushvalue(L, -2);
    lua_rawset(L, 1);

    return 1;
}


static int lsr_instanceequality(lua_State *L)
{
    if (lua_istable(L, 1) && lua_istable(L, 2))
    {
        lua_rawgeti(L, 1, LSINDEXNATIVE);
        if (lua_isuserdata(L, -1))
        {
            lua_replace(L, 1);
        }
        else
        {
            lua_pop(L, 1);
        }

        lua_rawgeti(L, 2, LSINDEXNATIVE);
        if (lua_isuserdata(L, -1))
        {
            lua_replace(L, 2);
        }
        else
        {
            lua_pop(L, 1);
        }

        if (lua_isuserdata(L, 1) && lua_isuserdata(L, 2))
        {
            // if we have an eq metamethod call it
            lua_getmetatable(L, 1);
            lua_pushstring(L, "__eq");
            lua_rawget(L, -2);
            if (!lua_isnil(L, -1))
            {
                // setup call
                lua_insert(L, 1);
                lua_pop(L, 1); // pop metatable
                lua_call(L, 2, 1);
                return 1;
            }

            // pop metatable and nil check
            lua_pop(L, 2);

            Detail::UserdataPtr *p1 =
                (Detail::UserdataPtr *)lua_topointer(L, 1);
            Detail::UserdataPtr *p2 =
                (Detail::UserdataPtr *)lua_topointer(L, 2);

            if (p1->getPointer() == p2->getPointer())
            {
                lua_pushboolean(L, 1);
            }
            else
            {
                lua_pushboolean(L, 0);
            }

            return 1;
        }

        if (lua_topointer(L, 1) == lua_topointer(L, 2))
        {
            lua_pushboolean(L, 1);
            return 1;
        }
    }

    lua_pushboolean(L, 0);
    return 1;
}


static int lsr_dictionary_index(lua_State *L)
{
    // default to standard indexer
    return lsr_instanceindex(L);
}


static int lsr_dictionary_newindex(lua_State *L)
{
    lua_rawgeti(L, 1, LSINDEXDICTPAIRS);
    lua_replace(L, 1);
    lua_rawset(L, 1);
    return 0;
}


static int lsr_vector_index(lua_State *L)
{
    // default to standard indexer
    return lsr_instanceindex(L);
}


static int lsr_vector_newindex(lua_State *L)
{
    lua_rawgeti(L, 1, LSINDEXVECTORLENGTH);
    int length = (int)lua_tonumber(L, -1);
    lua_pop(L, 1);

    if (!lua_isnumber(L, 2))
    {
        lua_pushstring(L, "Vector indexed with non-number");
        lua_error(L);
    }

    int idx = (int)lua_tonumber(L, 2);

    if (idx < 0)
    {
        lua_pushstring(L, "Vector indexed with negative number");
        lua_error(L);
    }

    if (idx >= length)
    {
        lua_pushstring(L, "Vector index out of bounds");
        lua_error(L);
    }

    lua_rawgeti(L, 1, LSINDEXVECTOR);
    lua_replace(L, 1);
    lua_rawset(L, 1);
    return 0;
}


static void lsr_deletedmanagederror(lua_State *L)
{
    lua_Debug ar;

    lua_getstack(L, 1, &ar);
    lua_getinfo(L, "nSl", &ar);
    LSLog(LSLogError, "Access deleted managed native at: %s %i", ar.source, ar.currentline);
    lua_pushstring(L, "Fatal Error");
    lua_error(L);
}


static int lsr_deletedinstanceindex(lua_State *L)
{
    lsr_deletedmanagederror(L);
    return 0;
}


static int lsr_deletedinstancenewindex(lua_State *L)
{
    lsr_deletedmanagederror(L);
    return 0;
}


static int lsr_deletedinstanceequality(lua_State *L)
{
    lsr_deletedmanagederror(L);
    return 0;
}


static int lsr_gctracker(lua_State *L)
{
    if (LSProfiler::isEnabled())
    {
        GCTracker *gct = (GCTracker *)lua_topointer(L, 1);
        lmAssert(gct, "unable to get GCTracker");
        LSProfiler::registerGC(gct->type, gct->methodBase);
    }

    return 0;
}


void lsr_instanceregister(lua_State *L)
{
    // Standard metatable for instances
    luaL_newmetatable(L, LSINSTANCE);

    lua_pushcfunction(L, lsr_instanceindex);
    lua_setfield(L, -2, "__index");

    lua_pushcfunction(L, lsr_instancenewindex);
    lua_setfield(L, -2, "__newindex");

    lua_pushcfunction(L, lsr_instanceequality);
    lua_setfield(L, -2, "__eq");

    // pop instance metatable
    lua_pop(L, 1);

    // Specialized metatable for dictionaries
    luaL_newmetatable(L, LSDICTIONARY);

    lua_pushcfunction(L, lsr_dictionary_index);
    lua_setfield(L, -2, "__index");

    lua_pushcfunction(L, lsr_dictionary_newindex);
    lua_setfield(L, -2, "__newindex");

    lua_pushcfunction(L, lsr_instanceequality);
    lua_setfield(L, -2, "__eq");

    // pop dictionary metatable
    lua_pop(L, 1);

    // Specialized metatable for vectors
    luaL_newmetatable(L, LSVECTOR);

    lua_pushcfunction(L, lsr_vector_index);
    lua_setfield(L, -2, "__index");

    lua_pushcfunction(L, lsr_vector_newindex);
    lua_setfield(L, -2, "__newindex");

    lua_pushcfunction(L, lsr_instanceequality);
    lua_setfield(L, -2, "__eq");

    // pop vector metatable
    lua_pop(L, 1);

    // Metatable for deleted natives, catches errors when accessed
    luaL_newmetatable(L, LSDELETEDMANAGED);

    lua_pushcfunction(L, lsr_deletedinstanceindex);
    lua_setfield(L, -2, "__index");

    lua_pushcfunction(L, lsr_deletedinstancenewindex);
    lua_setfield(L, -2, "__newindex");

    lua_pushcfunction(L, lsr_deletedinstanceequality);
    lua_setfield(L, -2, "__eq");

    // pop deleted managed metatable
    lua_pop(L, 1);

    // Standard metatable for gctracker
    luaL_newmetatable(L, LSGCTRACKER);

    lua_pushcfunction(L, lsr_gctracker);
    lua_setfield(L, -2, "__gc");

    // pop gctracker metatable
    lua_pop(L, 1);
}
}
