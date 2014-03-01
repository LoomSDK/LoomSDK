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


#include "loom/script/native/lsNativeInterface.h"
#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/reflection/lsPropertyInfo.h"
#include "loom/script/common/lsError.h"
#include "loom/script/runtime/lsProfiler.h"
#include "loom/script/reflection/lsFieldInfo.h"


namespace LS {
static char _gLastAccessedMember[64];
char        *gLastAccessedMember = _gLastAccessedMember;

void lsr_createinstance(lua_State *L, Type *type)
{
    lsr_getclasstable(L, type);
    lua_call(L, 0, 1);
}


void lualoom_callscriptinstanceinitializerchain_internal(lua_State *L, Type *type, int instanceIdx, Type *stopAtParentType)
{
    instanceIdx = lua_absindex(L, instanceIdx);

    utStack<Type *> types;
    Type            *t = type;
    while (t)
    {
        if (t == stopAtParentType)
        {
            break;
        }
        types.push(t);
        t = t->getBaseType();
    }

    int top = lua_gettop(L);

    t = types.pop();
    while (t)
    {
        lsr_getclasstable(L, t);

        // get the instance initializer function
        // this is not the constructor, which is a method
        lua_getfield(L, -1, "__ls_instanceinitializer");

        lua_pushvalue(L, instanceIdx);

        // call with new instance as "this" local

        if (lua_pcall(L, 1, LUA_MULTRET, 0))
        {
            LSError("Error running instance initializer for %s\n%s\n", t->getFullName().c_str(), lua_tostring(L, -1));
        }

        lua_settop(L, top);

        t = NULL;
        if (!types.empty())
        {
            t = types.pop();
        }
    }
}


// creates the basic script table of our instance, doesn't handle
// any constructor, native instantiation, etc
void lualoom_newscriptinstance_internal(lua_State *L, Type *type)
{
    lmAssert(type, "Internal Error: lsr_newscriptinstance_internal passes a NULL type");

    // allocate a table with enough array and hash space to hold all of our member ordinals
    // we have to allocate enough hash nodes otherwise, upon first table set, it will rehash
    // which will shrink out table array down and then use the lua array heuristic to split between
    // array and hash, which is not a good fit as we want solely array access for member ordinals
    lua_createtable(L, type->getMaxMemberOrdinal() + 16, type->getMaxMemberOrdinal() + 16);

    int instanceIdx = lua_gettop(L);
    lsr_getclasstable(L, type);
    lua_rawseti(L, instanceIdx, LSINDEXCLASS);

    lua_pushlightuserdata(L, type);
    lua_rawseti(L, instanceIdx, LSINDEXTYPE);

    double uniqueId = LSLuaState::getUniqueKey();

    lua_pushstring(L, "__ls_id");
    lua_pushnumber(L, uniqueId);
    lua_settable(L, -3);

    if (type->isDictionary())
    {
        luaL_getmetatable(L, LSDICTIONARY);
    }
    else if (type->isVector())
    {
        luaL_getmetatable(L, LSVECTOR);
    }
    else
    {
        luaL_getmetatable(L, LSINSTANCE);
    }

    lua_setmetatable(L, instanceIdx);
}


// class instance creator
static int lsr_classcreateinstance(lua_State *L)
{
    int nargs = lua_gettop(L) - 1;

    // index 1 on stack is class table

    Type *type = (Type *)lua_topointer(L, lua_upvalueindex(1));

    lualoom_newscriptinstance_internal(L, type);
    int instanceIdx = lua_gettop(L);

    if (LSProfiler::isEnabled())
    {
        MethodBase *methodBase = LSProfiler::registerAllocation(type);

        // attach the gctracker
        GCTracker *gct = (GCTracker *)lua_newuserdata(L, sizeof(GCTracker));
        gct->type       = type;
        gct->methodBase = methodBase;
        luaL_getmetatable(L, LSGCTRACKER);
        lua_setmetatable(L, -2);
        lua_rawseti(L, instanceIdx, LSINDEXGCTRACKER);
    }


    Type *t = type;

    bool nativeCreated = false;
    while (t)
    {
        if (!nativeCreated && t->isNative())
        {
            //LSLog(LSLogError, "Creating native: %s", t->getFullName().c_str());

            nativeCreated = true;
            int ntop = lua_gettop(L);
            lua_getglobal(L, "__ls_nativeclasses");
            lua_getfield(L, -1, t->getPackageName().c_str());
            lua_getfield(L, -1, t->getName());
            int _nargs = nargs;

            for (int i = 0; i < _nargs; i++)
            {
                lua_pushvalue(L, 2 + i);
            }

            ConstructorInfo *cinfo = t->getConstructor();

            // If we have a constructor defined and that constructor isn't the
            // compiler default
            if (cinfo && !cinfo->defaultConstructor)
            {
                // do we have default args?
                if (cinfo->getFirstDefaultParm() != -1)
                {
                    int dargs = _nargs;

                    int fidx = cinfo->getFirstDefaultParm();

                    assert(fidx >= 0);

                    if (dargs < cinfo->getNumParameters())
                    {
                        lsr_getclasstable(L, t);
                        lua_getfield(L, -1, "__ls_constructor__default_args");
                        assert(!lua_isnil(L, -1));

                        // remove the class table
                        lua_remove(L, -2);
                        int d = lua_gettop(L);

                        // add the default args to the call
                        for (int i = dargs; i < cinfo->getNumParameters(); i++)
                        {
                            lua_pushnumber(L, i);
                            lua_gettable(L, d);
                            _nargs++;
                        }

                        // remove the default arg table
                        lua_remove(L, d);
                    }
                }
            }

            if (lua_pcall(L, _nargs, 1, 0))
            {
                LSLuaState *ls = LSLuaState::getLuaState(L);

                ls->triggerRuntimeError(
                    "Error creating instance for native class %s\n\nPlease make sure you have a constructor defined in your native bindings\nFor example: .addConstructor <void (*)(void) >()"
                    , type->getFullName().c_str());
            }

            lua_rawseti(L, instanceIdx, LSINDEXNATIVE);

            NativeTypeBase *nativeType = NativeInterface::getNativeType(t);
            assert(nativeType);

            if (type->isNativeManaged())
            {
                lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);
                lua_rawgeti(L, instanceIdx, LSINDEXNATIVE);
                lua_pushvalue(L, instanceIdx);
                lua_settable(L, -3);
                lua_pop(L, 1);
            }
            else
            {
                if (!type->isNativeMemberPure(true))
                {
                    LSError("Error creating native instance for %s\nUnmanaged native class must be native pure\n", type->getFullName().c_str());
                }
            }

            lua_settop(L, ntop);
        }

        t = t->getBaseType();
    }

    // instance intializer chain
    lualoom_callscriptinstanceinitializerchain_internal(L, type, instanceIdx, NULL);

    // call constructor chain

    utStack<Type *> types;

    t = type;

    while (t)
    {
        types.push(t);
        t = t->getBaseType();
    }

    int top = lua_gettop(L);

    t = types.pop();
    while (t)
    {
        ConstructorInfo *cinfo = t->getConstructor();

        bool cskip = t->isNative() && (cinfo && cinfo->isNative());

        if (cinfo && !cskip && !cinfo->defaultConstructor)
        {
            // skip if the next constructor in chain has a super call
            bool skip = false;
            if (!types.empty())
            {
                Type            *type = types.peek(0);
                ConstructorInfo *ci   = type->getConstructor();
                if (ci && ci->hasSuperCall())
                {
                    skip = true;
                }
            }

            if (!skip)
            {
                // if we don't specify a super call, default is to call
                // base constructor (we do so with args passed, this right?)

                lsr_getclasstable(L, t);

                int conClsIdx = lua_gettop(L);

                // get the LSMethod
                lua_getfield(L, -1, "__ls_constructor");

                assert(!lua_isnil(L, -1));

                lua_pushvalue(L, instanceIdx);

                for (int i = 0; i < nargs; i++)
                {
                    lua_pushvalue(L, 2 + i);
                }

                if (cinfo->getFirstDefaultParm() != -1)
                {
                    int dargs = nargs;

                    int fidx = cinfo->getFirstDefaultParm();
                    lmAssert(fidx >= 0, "Got valid default parm index, then it was -1 on second read!");


                    if (dargs < cinfo->getNumParameters())
                    {
                        lua_getfield(L, conClsIdx, "__ls_constructor__default_args");
                        assert(!lua_isnil(L, -1));
                        int d = lua_gettop(L);

                        for (int i = dargs; i < cinfo->getNumParameters(); i++)
                        {
                            lua_pushnumber(L, i);
                            lua_gettable(L, d);
                            //LSLog(LSLogError, "Processing %d %s", i, lua_tostring(L, -1));
                            nargs++;
                        }
                        //LSLog(LSLogError, "-------");

                        lua_remove(L, d);
                    }
                }


                if (lua_pcall(L, nargs + 1, LUA_MULTRET, 0))
                {
                    LSError("ERROR in constructor for %s\n:%s\n", t->getFullName().c_str(), lua_tostring(L, -1));
                }
            }

            // setup top for next constructor
            lua_settop(L, top);
        }

        t = NULL;
        if (!types.empty())
        {
            t = types.pop();
        }
    }

    // return this
    lua_pushvalue(L, instanceIdx);
    return 1;
}


static int lsr_classindex(lua_State *L)
{
    Type *type = (Type *)lua_topointer(L, lua_upvalueindex(1));

    if (lua_isnumber(L, 2))
    {
        int ordinal = (int)lua_tonumber(L, 2);

        // a loom indexer should be in the table (not missing so it his the index metamethod)
        lmAssert(!lualoom_isindexer(ordinal), "Internal Error: class table being indexed by a LSINDEX value.");

        MemberInfo *mi = type->getMemberInfoByOrdinal(ordinal);

        lmAssert(mi, "Out of range ordinal %i on type %s", ordinal, type->getFullName().c_str());

        if (type != mi->getDeclaringType())
        {
            lsr_getclasstable(L, mi->getDeclaringType());
            lua_pushvalue(L, 2);
            lua_gettable(L, -2);
            return 1;
        }

        if (type->isNativeOrdinal(ordinal))
        {
            // grab the native class (bridge userdata)
            lua_getglobal(L, "__ls_nativeclasses");
            int nativeClassIdx = lua_gettop(L);
            lua_pushlightuserdata(L, type);
            lua_rawget(L, -2);
            assert(!lua_isnil(L, -1));

            // the bridge userdata
            int nativeUserDataIdx = lua_gettop(L);

            lua_pushnumber(L, ordinal);
            lua_gettable(L, nativeUserDataIdx);

            // if it is a userdata, we have raw native
            // which we need to wrap
            if (lua_isuserdata(L, -1))
            {
                lualoom_pushnative_userdata(L, mi->getType(), -1);
            }

            return 1;
        }

        lua_pushnil(L);
        return 1;
    }

    Type *baseType = type->getBaseType();

    if (baseType)
    {
        lsr_getclasstable(L, baseType);
        lua_pushvalue(L, 2);
        lua_gettable(L, -2);
        return 1;
    }

    lua_pushnil(L);
    return 1;
}


static int lsr_classnewindex(lua_State *L)
{
    if (!lua_isnumber(L, 2))
    {
        // just raw set into the class table
        lua_rawset(L, 1);
        return 0;
    }

    Type *type = (Type *)lua_topointer(L, lua_upvalueindex(1));

    int ordinal = (int)lua_tonumber(L, 2);

    // a loom indexer should be in the table (not missing so it his the index metamethod)
    lmAssert(!lualoom_isindexer(ordinal), "Internal Error: class table being new indexed by a LSINDEX value.");

    if (!type->isNativeOrdinal(ordinal))
    {
        // just raw set into the class table
        lua_rawset(L, 1);
        return 0;
    }

    MemberInfo *mi = type->getMemberInfoByOrdinal(ordinal);

    lmAssert(mi, "Out of range ordinal %i on %s", ordinal, type->getFullName().c_str());

    lmAssert(mi->isNative(), "not native %s : %i", type->getFullName().c_str(), ordinal);

    // grab the native class (bridge userdata)
    lua_getglobal(L, "__ls_nativeclasses");
    int nativeClassIdx = lua_gettop(L);
    lua_pushlightuserdata(L, type);
    lua_rawget(L, -2);
    lmAssert(!lua_isnil(L, -1), "Unable to get native class %s", type->getFullName().c_str());

    // the bridge userdata
    int nativeUserDataIdx = lua_gettop(L);

    // get the field name
    lua_pushnumber(L, ordinal);
    lua_pushvalue(L, 3);
    // set to native data
    lua_settable(L, nativeUserDataIdx);

    return 0;
}


void lsr_declareclass(lua_State *L, Type *type)
{
    int top = lua_gettop(L);

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXCLASSES);

    const char *packageName = type->getPackageName().c_str();
    const char *typeName    = type->getName();

    lua_getfield(L, -1, packageName);

    if (lua_isnil(L, -1))
    {
        lua_newtable(L);
        lua_pushvalue(L, -1);
        lua_setfield(L, -4, packageName);
    }

    // allocate a table with enough array and hash space to hold all of our member ordinals
    // we have to allocate enough hash nodes otherwise, upon first table set, it will rehash
    // which will shrink out table array down and then use the lua array heuristic to split between
    // array and hash, which is not a good fit as we want solely array access for member ordinals
    lua_createtable(L, type->getMaxMemberOrdinal() + 16, type->getMaxMemberOrdinal() + 16);

    int clsIdx = lua_gettop(L);

    lua_pushvalue(L, -1);
    lua_setfield(L, -3, typeName);

    lua_pushvalue(L, -1);
    lua_setfield(L, top + 1, type->getFullName().c_str());

    // create metatable
    lua_newtable(L);
    int mtidx = lua_gettop(L);

    // store Type* in metatable
    lua_pushlightuserdata(L, type);
    lua_rawseti(L, clsIdx, LSINDEXTYPE);

    LSLuaState *ls = LSLuaState::getLuaState(L);

    // store LSState* in metatable
    lua_pushstring(L, "__lsstate");
    lua_pushlightuserdata(L, ls);
    lua_settable(L, clsIdx);

    // store call
    lua_pushstring(L, "__call");
    lua_pushlightuserdata(L, type);
    lua_pushcclosure(L, lsr_classcreateinstance, 1);
    lua_rawset(L, mtidx);

    lua_pushstring(L, "__index");
    lua_pushlightuserdata(L, type);
    lua_pushcclosure(L, lsr_classindex, 1);
    lua_rawset(L, mtidx);

    lua_pushstring(L, "__newindex");
    lua_pushlightuserdata(L, type);
    lua_pushcclosure(L, lsr_classnewindex, 1);
    lua_rawset(L, mtidx);

    lua_pushvalue(L, mtidx);
    lua_setmetatable(L, clsIdx);

    // restore the stack
    lua_settop(L, top);
}


// ipair implementation which starts counting at 0 instead of 1
static int loomscript_ipairsaux(lua_State *L)
{
    int i = luaL_checkint(L, 2);

    luaL_checktype(L, 1, LUA_TTABLE);
    
    int length = lsr_vector_get_length(L, 1);

    lua_rawgeti(L, 1, LSINDEXVECTOR);
    luaL_checktype(L, -1, LUA_TTABLE);
    lua_replace(L, 1);

    i++;  /* next value */
    lua_pushinteger(L, i);
    lua_rawgeti(L, 1, i);

    if (i >= length)
    {
        return 0;
    }

    return 2;
}


static int loomscript_ipairs(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_pushvalue(L, lua_upvalueindex(1)); /* return generator, */
    lua_pushvalue(L, 1);                   /* state, */
    lua_pushinteger(L, -1);                /* and initial value */
    return 3;
}


static void lsr_classimportluasymbols(lua_State *L, int index)
{
    index = lua_absindex(L, index);

    // todo, if we want some more stuff from Lua, generalize this
    lua_getglobal(L, "coroutine");
    lua_pushstring(L, "yield");
    lua_getfield(L, -2, "yield");
    lua_rawset(L, index);
    lua_pop(L, 1);

    lua_pushstring(L, "__lua_pairs");
    lua_getglobal(L, "pairs");
    lua_rawset(L, index);

    lua_pushstring(L, "__lua_ipairs");
    lua_pushcfunction(L, loomscript_ipairsaux);
    lua_pushcclosure(L, loomscript_ipairs, 1);
    lua_rawset(L, index);


#ifdef LOOM_ENABLE_JIT
    lua_getglobal(L, "bit");
    lua_getfield(L, -1, "band");
    lua_setfield(L, index, "__ls_band");
    lua_getfield(L, -1, "bor");
    lua_setfield(L, index, "__ls_bor");
    lua_getfield(L, -1, "bxor");
    lua_setfield(L, index, "__ls_xor");
    lua_getfield(L, -1, "lshift");
    lua_setfield(L, index, "__ls_blshift");
    lua_getfield(L, -1, "rshift");
    lua_setfield(L, index, "__ls_brshift");
    lua_getfield(L, -1, "bnot");
    lua_setfield(L, index, "__ls_bnot");
    lua_pop(L, 1);
#endif
}


static void lsr_classimportsymbols(lua_State *L, Type *type, int index)
{
    int top = lua_gettop(L);

    index = lua_absindex(L, index);

    // imports
    utArray<Type *> imports;
    type->getImports(imports);

    LSLuaState *ls = LSLuaState::getLuaState(L);

    // import the system types (if we're not in the system assembly)
    Assembly *system = ls->getAssembly("System");
    assert(system);
    Assembly *typeAssembly = Assembly::getAssembly(type);
    if (system != typeAssembly)
    {
        utArray<Type *> systemTypes;
        system->getTypes(systemTypes);

        for (UTsize i = 0; i < systemTypes.size(); i++)
        {
            Type *systemType = systemTypes[i];

            if (imports.find(systemType) == UT_NPOS)
            {
                imports.push_back(systemType);
            }
        }
    }

    // bring the package classes into the class environment
    utArray<Type *> packageTypes;
    ls->getPackageTypes(type->getPackageName(), packageTypes);

    // combine lists
    for (UTsize i = 0; i < packageTypes.size(); i++)
    {
        Type *packageType = packageTypes.at(i);
        if (imports.find(packageType) == UT_NPOS)
        {
            imports.push_back(packageType);
        }
    }

    // bring the type's imports into the class environment
    for (UTsize i = 0; i < imports.size(); i++)
    {
        Type *import = imports.at(i);

        int t = lua_gettop(L);

        lsr_getclasstable(L, import);

        // import class name
        lua_pushstring(L, import->getName());
        lsr_getclasstable(L, import);
        lua_rawset(L, index);

        // import full class path
        lua_pushstring(L, import->getFullName().c_str());
        lsr_getclasstable(L, import);
        lua_rawset(L, index);

        lua_settop(L, t);
    }

    lua_settop(L, top);
}


static void lsr_classinitializemethod(lua_State *L, MethodBase *methodBase, int index)
{
    int top = lua_gettop(L);

    index = lua_absindex(L, index);

    utString name = methodBase->getName();

    if (methodBase->isConstructor())
    {
        name = "__ls_constructor";
    }

    // default arg table
    lua_pushstring(L, (name + "__default_args").c_str());
    lua_newtable(L);
    lua_rawset(L, index);

    lua_pushstring(L, name.c_str());

    if (methodBase->isNative())
    {
        // instance methods on primitive types are transformed to static method calls
        if (methodBase->getDeclaringType()->isPrimitive() && !methodBase->isStatic())
        {
            lua_pushnil(L);
        }
        else
        {
            lsr_pushmethodbase(L, methodBase);
            if (lua_isnil(L, -1) && !methodBase->isFastCall())
            {
                LSError("Native Method resolution error: %s", methodBase->getStringSignature().c_str());
            }
        }
    }
    else
    {
        ByteCode *bc = methodBase->getByteCode();
        assert(bc);
        if (!bc->load(LSLuaState::getLuaState(L)))
        {
            LSError("Bytecode Error: %s:%s\n",
                    methodBase->getDeclaringType()->getFullName().c_str(),
                    methodBase->getName());
        }
    }

    if (!methodBase->isNative())
    {
        int functionIdx = lua_gettop(L);

        // create the function environment
        lua_newtable(L);

        int functionEnv = lua_gettop(L);

        lua_pushvalue(L, functionEnv);
        lua_setfenv(L, functionIdx);

        // push the function
        lua_pushvalue(L, functionIdx);
        lua_setfield(L, functionEnv, "__lua_function");

        // setup method meta table
        lua_newtable(L);
        lua_pushvalue(L, index);
        lua_setfield(L, -2, "__index");

        // set the methods environment metatable to class env
        lua_setmetatable(L, functionEnv);

        lua_settop(L, functionIdx);
    }

    // store to method lookup
    if (!lua_isnil(L, -1))
    {
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
        lua_pushvalue(L, -2);
        lua_pushlightuserdata(L, methodBase);
        lua_rawset(L, -3);
        lua_pop(L, 1);
    }

    // write to ordinal
    lua_pushvalue(L, -1);
    lua_rawseti(L, index, methodBase->getOrdinal());

    lua_rawset(L, index);

    lua_settop(L, top);
}


static void lsr_classinitializenative(lua_State *L, Type *type, int index)
{
    int top = lua_gettop(L);

    // Cache from Type* -> bridge userdata

    lua_getglobal(L, "__ls_nativeclasses");
    int nativeClassesIdx = lua_gettop(L);

    lua_getfield(L, nativeClassesIdx, type->getPackageName().c_str());

    if (lua_isnil(L, -1))
    {
        lua_settop(L, top);
        return;
    }
    lua_pushlightuserdata(L, type);
    lua_getfield(L, -2, type->getName());

    if (lua_isnil(L, -1))
    {
        lua_settop(L, top);
        return;
    }


    lua_rawset(L, nativeClassesIdx);

    lua_settop(L, top);
}


static void lsr_classinitializeordinalfields(lua_State *L, Type *type, int index)
{
    int top = lua_gettop(L);

    index = lua_absindex(L, index);

    lua_newtable(L);
    lua_pushvalue(L, -1);
    lua_rawseti(L, index, LSINDEXMEMBERNAMEORDINALS);

    int fieldTblIdx = lua_gettop(L);

    utArray<MemberInfo *> members;
    MemberTypes           memberTypes;
    memberTypes.field    = true;
    memberTypes.property = true;
    memberTypes.method   = true;

    // NOTE: We store all *public/protected* fields from base classes too
    type->findMembers(memberTypes, members, true);

    for (UTsize i = 0; i < members.size(); i++)
    {
        MemberInfo *member = members.at(i);

        int ordinal = member->getOrdinal();

        lua_pushstring(L, member->getName());
        lua_pushnumber(L, ordinal);
        lua_rawset(L, fieldTblIdx);
    }

    lua_settop(L, top);
}


static void lsr_classinitializemethods(lua_State *L, Type *type, int index)
{
    int top = lua_gettop(L);

    index = lua_absindex(L, index);

    utArray<MemberInfo *> members;
    MemberTypes           memberTypes;
    memberTypes.constructor = true;
    memberTypes.property    = true;
    memberTypes.method      = true;

    type->findMembers(memberTypes, members, false);

    for (UTsize i = 0; i < members.size(); i++)
    {
        MemberInfo *m = members.at(i);
        if (m->isProperty())
        {
            PropertyInfo *prop = (PropertyInfo *)m;
            if (prop->getGetMethod())
            {
                lsr_classinitializemethod(L, prop->getGetMethod(), index);
            }
            if (prop->getSetMethod())
            {
                lsr_classinitializemethod(L, prop->getSetMethod(), index);
            }
        }
        else
        {
            lsr_classinitializemethod(L, (MethodBase *)m, index);
        }
    }

    lua_settop(L, top);
}


static void lsr_classinitializestaticmethods(lua_State *L, Type *type, int index)
{
    int top = lua_gettop(L);

    index = lua_absindex(L, index);

    utArray<MemberInfo *> members;
    MemberTypes           memberTypes;
    memberTypes.method = true;

    type->findMembers(memberTypes, members, false);

    for (UTsize i = 0; i < members.size(); i++)
    {
        MethodBase *method = (MethodBase *)members.at(i);

        if (!method->isStatic())
        {
            continue;
        }

        if (true /*method->getFirstDefaultParm() != -1*/)
        {
            int ttop = lua_gettop(L);

            // must create static method with default args
            lua_pushlightuserdata(L, method);
            lua_getfield(L, index, method->getName());

            int nup = 2;

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

                lua_pushstring(L, dname.c_str());
                lua_rawget(L, index);

                int dargs = lua_gettop(L);

                for (int i = fd; i < method->getNumParameters(); i++)
                {
                    lua_pushnumber(L, i);
                    lua_gettable(L, dargs);
                    nup++;
                }

                lua_remove(L, dargs);
            }

            lua_pushcclosure(L, lsr_method, nup);

            // cache
            lua_pushstring(L, method->getName());
            lua_pushvalue(L, -2);
            lua_rawset(L, index);

            // store tp global function -> methodbase table for fast lookups
            lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
            lua_pushvalue(L, -2);
            lua_pushlightuserdata(L, method);
            lua_rawset(L, -3);
            lua_pop(L, 1);


            lua_rawseti(L, index, method->getOrdinal());

            lua_settop(L, ttop);
        }
    }

    lua_settop(L, top);
}


/*
 * Initializes the static elements of a class including
 * running the static code initializer, initializing static methods including
 * default initializers, also calls any static constructors
 */
void lsr_classinitializestatic(lua_State *L, Type *type)
{
    lsr_getclasstable(L, type);
    int clsIdx = lua_gettop(L);

    // run the static initializer
    lua_getfield(L, clsIdx, "__ls_staticinitializer");

    //printf("running static initializer %s\n", type->getFullName().c_str());

    if (lua_pcall(L, 0, LUA_MULTRET, 0))
    {
        lmAssert(0, "Error running static initializer for %s\n%s\n", type->getFullName().c_str(), lua_tostring(L, -1));
    }

    lua_settop(L, clsIdx);

    // setup static function default args
    lsr_classinitializestaticmethods(L, type, clsIdx);

    lua_settop(L, clsIdx);

    // run the static constructor if any
    utString scon = type->getName();
    scon += "__ls_staticconstructor";
    MemberInfo *memberInfo = type->findMember(scon.c_str());
    if (memberInfo)
    {
        assert(memberInfo->isMethod());
        MethodInfo *sconMethod = (MethodInfo *)memberInfo;
        assert(sconMethod->isStatic());

        lua_getfield(L, clsIdx, scon.c_str());
        lua_call(L, 0, LUA_MULTRET);
    }


    lua_settop(L, clsIdx - 1);
}


/*
 * Initializes a class including its import table, initializes methods,
 * loads instance and static byte code, also initializes any native information
 * including fields.
 */
void lsr_classinitialize(lua_State *L, Type *type)
{
    int top = lua_gettop(L);

    lsr_getclasstable(L, type);

    int clsIdx = lua_gettop(L);

    lsr_classimportluasymbols(L, clsIdx);
    lua_settop(L, clsIdx);
    lsr_classimportsymbols(L, type, clsIdx);
    lua_settop(L, clsIdx);
    lsr_classinitializemethods(L, type, clsIdx);
    lua_settop(L, clsIdx);

    // load initializer bytecode
    for (UTsize i = 0; i < 2; i++)
    {
        // load the static initializer byte code and stuff it in class
        ByteCode *bc =
            i == 0 ?
            type->getBCStaticInitializer() :
            type->getBCInstanceInitializer();
        assert(bc);

        if (!bc->load(LSLuaState::getLuaState(L)))
        {
            LSError("Error loading bytecode for %s:%s",
                    type->getFullName().c_str(),
                    i == 0 ?
                    "__ls_staticinitializer" :
                    "__ls_instanceinitializer");
        }

        // set initializer env to class table
        lua_pushvalue(L, clsIdx);
        lua_setfenv(L, -2);

        // store
        lua_pushstring(L, i == 0 ? "__ls_staticinitializer" : "__ls_instanceinitializer");
        lua_pushvalue(L, -2);
        lua_rawset(L, clsIdx);
        lua_pop(L, 1);
    }

    lua_settop(L, clsIdx);

    // setup base native class info
    lsr_classinitializenative(L, type, clsIdx);

    // setup class ordinal -> native field information cache
    lsr_classinitializeordinalfields(L, type, clsIdx);

    lua_settop(L, top);
}
}
