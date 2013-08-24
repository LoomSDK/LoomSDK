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
#include "loom/script/native/core/system/lmConsole.h"

#include <math.h>
#include <float.h>

// Workaround for no NAN on Windows.
// From http://tdistler.com/2011/03/24/how-to-define-nan-not-a-number-on-windows
#ifdef _MSC_VER
#define INFINITY    (DBL_MAX + DBL_MAX)
#define NAN         (INFINITY - INFINITY)
#endif

using namespace LS;

extern "C" {
#include "lauxlib.h"
}

class LSObject {
public:

    static int trace(lua_State *L)
    {
        return Console::print(L);
    }

    static int getNativeDebugString(lua_State *L)
    {
        lua_rawgeti(L, 1, LSINDEXNATIVE);

        assert(lua_isuserdata(L, -1));

        Detail::Userdata *p1 = (Detail::Userdata *)lua_topointer(L, -1);

        static char debugstring[256];
        sprintf(debugstring, "%p", p1->getPointer());

        lua_pushstring(L, debugstring);
        return 1;
    }

    static int deleteNative(lua_State *L)
    {
        // mark table as deleted managed
        lua_pushboolean(L, 1);
        lua_rawseti(L, 1, LSINDEXDELETEDMANAGED);

        lua_rawgeti(L, 1, LSINDEXNATIVE);
        assert(lua_isuserdata(L, -1));

        // set metatable so any (non-raw) access of table will result in error
        luaL_getmetatable(L, LSDELETEDMANAGED);
        lua_setmetatable(L, 1);

        Detail::Userdata *p1 = (Detail::Userdata *)lua_topointer(L, -1);

        assert(p1);

        p1->deletePointer();

        lua_pop(L, 1);

        return 0;
    }

    static int _as(lua_State *L)
    {
        // as of null returns null
        if (lua_isnil(L, 1))
        {
            lua_pushnil(L);
            return 1;
        }

        // get the assembly lookup table
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSASSEMBLYLOOKUP);
        // push the (interned) assembly name
        lua_pushvalue(L, 2);
        lua_gettable(L, -2);
        // get the Assembly*
        Assembly *assembly = (Assembly *)lua_topointer(L, -1);
        lua_pop(L, 2);

        lmAssert(assembly, "Object::_as - unable to get Assembly");

        LSLuaState *lstate = assembly->getLuaState();

        // the castType is the type we're casting to
        Type *castType = assembly->getTypeByOrdinal((LSTYPEID)lua_tonumber(L, 3));

        lmAssert(castType, "Object::_as - unable to resolve TypeID %u", (LSTYPEID)lua_tonumber(L, 3));

        // checking number -> enum coercian
        if (lua_isnumber(L, 1))
        {
            if (castType->isEnum())
            {
                lua_pushvalue(L, 1);
                return 1;
            }
        }

        bool valid = false;
        if (castType == lstate->numberType)
        {
            if (lua_isnumber(L, 1))
            {
                valid = true;
            }
        }
        else if (castType == lstate->stringType)
        {
            if (lua_isstring(L, 1))
            {
                valid = true;
            }
        }
        else if (castType == lstate->booleanType)
        {
            if (lua_isboolean(L, 1))
            {
                valid = true;
            }
        }
        else if (castType == lstate->functionType)
        {
            if (lua_iscfunction(L, 1))
            {
                valid = true;
            }
            else if (lua_isfunction(L, 1))
            {
                valid = true;
            }
        }
        else
        {
            // If it's a primitive type but we expected an instance table, it is nil.
            valid = true;
            if (lua_isnumber(L, 1))
            {
                valid = false;
            }
            else if (lua_isstring(L, 1))
            {
                valid = false;
            }
            else if (lua_isboolean(L, 1))
            {
                valid = false;
            }
            else if (lua_iscfunction(L, 1))
            {
                valid = false;
            }
            else if (lua_isfunction(L, 1))
            {
                valid = false;
            }

            if (valid)
            {
                // If we are not a primitive type (as detected previously)
                // we should be an instance table, if not something went horribly wrong
                if (!lua_istable(L, 1))
                {
                    lua_pushfstring(L, "Object._as - instance table expected but got %s", lua_typename(L, 1));
                    lua_error(L);
                }

                // retrieve the instance's type
                lua_rawgeti(L, 1, LSINDEXTYPE);
                Type *type = (Type *)lua_topointer(L, -1);

                lmAssert(type, "error getting type in Object._as");

                lua_rawgeti(L, 1, LSINDEXDELETEDMANAGED);
                if (lua_toboolean(L, -1) == 1)
                {
                    lua_pushfstring(L, "Object._as - accessing deleted managed native instance of type %s", type->getFullName().c_str());
                    lua_error(L);
                }
                lua_pop(L, 1);

                // we're the same type, so push identity and return
                if (castType == type)
                {
                    lua_pushvalue(L, 1);
                    return 1;
                }

                // if we're native types, C++ RTTI can be used
                if (type->isNative() && castType->isNative())
                {
                    // get the native user data from the instance
                    lua_rawgeti(L, 1, LSINDEXNATIVE);
                    assert(lua_isuserdata(L, -1));

                    Detail::Userdata *ptr = (Detail::Userdata *)lua_topointer(L, -1);

                    // push the instance on the stack, possibly downcasting it
                    NativeInterface::pushDynamicCast(L, type, castType, 1, ptr->getPointer());
                    return 1;
                }

                valid = type->castToType(castType) ? true : false;
            }
        }

        if (valid)
        {
            lua_pushvalue(L, 1);
        }
        else
        {
            lua_pushnil(L);
        }

        return 1;
    }

    static int _is(lua_State *L)
    {
        // Call _as, then pop result and push bool based on nil-ness.
        // is and as should ALWAYS agree.
        // see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/operators.html#is
        _as(L);

        bool valid = (lua_isnil(L, -1) != 1);
        lua_pop(L, 1);
        lua_pushboolean(L, valid ? 1 : 0);

        return 1;
    }

    static int toString(lua_State *L)
    {
        assert(L);
        assert(!lua_isnil(L, 1));

        lua_rawgeti(L, 1, LSINDEXTYPE);

        Type *type = (Type *)lua_topointer(L, -1);

        char sbuffer[1024];
        snprintf(sbuffer, 1024, "Object:%s", type->getFullName().c_str());
        lua_pushstring(L, sbuffer);

        return 1;
    }

    static int _nativeDeleted(lua_State *L)
    {
        lua_rawgeti(L, 1, LSINDEXDELETEDMANAGED);
        return 1;
    }

    // static version, used for String(expr) and expr.toString() special cases
    static int _toString(lua_State *L)
    {
        lua_pushstring(L, lsr_objecttostring(L, 1));
        return 1;
    }

    static int _toInt(lua_State *L)
    {
        if (lua_isnumber(L, 1) || lua_isstring(L, 1))
        {
            lua_pushnumber(L, floor(lua_tonumber(L, 1)));
            return 1;
        }

        // boolean false = 0
        // boolean true = 1
        if (lua_isboolean(L, 1))
        {
            lua_pushnumber(L, lua_toboolean(L, 1));
            return 1;
        }

        lua_pushstring(L, "Unknown type passed to int() cast method.  Boolean, Number, and String types are accepted.");
        lua_error(L);

        return 1;
    }

    static int getTypeName(lua_State *L)
    {
        lmAssert(lua_istable(L, 1),
                 "system.Object.getTypeName called on non-instance, this should have been transformed to static system.Object._getTypeName");
        return _getTypeName(L);
    }

    static int getFullTypeName(lua_State *L)
    {
        lmAssert(lua_istable(L, 1),
                 "system.Object.getFullTypeName called on non-instance, this should have been transformed to static system.Object._getFullTypeName");
        return _getFullTypeName(L);
    }

    static Type *getType(lua_State *L)
    {
        lmAssert(lua_istable(L, 1),
                 "system.Object.getType called on non-instance, this should have been transformed to static system.Object._getType");
        return _getType(L);
    }

    static int nativeDeleted(lua_State *L)
    {
        lmAssert(lua_istable(L, 1),
                 "system.Object.nativeDeleted called on non-instance, this should have been transformed to static system.Object._nativeDeleted");
        return _nativeDeleted(L);
    }

    static int _getTypeName(lua_State *L)
    {
        Type *type = _getType(L);

        lua_pushstring(L, type->getName());

        return 1;
    }

    static int _getFullTypeName(lua_State *L)
    {
        Type *type = _getType(L);

        lua_pushstring(L, type->getFullName().c_str());

        return 1;
    }

    static Type *_getType(lua_State *L)
    {
        return lsr_gettype(L, 1);
    }

    static int _getNaN(lua_State *L)
    {
        lua_pushnumber(L, NAN);
        return 1;
    }

    static int _isNaN(lua_State *L)
    {
        lua_Number n = lua_tonumber(L, -1);

        // NaN is not equal to itself!
        lua_pushboolean(L, n != n ? 1 : 0);
        return 1;
    }

    static int _hasOwnProperty(lua_State *L)
    {
        Type *t = lsr_gettype(L, 1);

        MemberInfo *mi = t->findMember(lua_tostring(L, 2));

        lua_pushboolean(L, mi != NULL ? 1 : 0);
        return 1;
    }
};

static int registerSystemObject(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<LSObject> ("Object")

       .addStaticLuaFunction("deleteNative", &LSObject::deleteNative)
       .addStaticLuaFunction("getNativeDebugString", &LSObject::getNativeDebugString)
       .addStaticLuaFunction("toString", &LSObject::toString)
       .addStaticLuaFunction("_toString", &LSObject::_toString)
       .addStaticLuaFunction("_toInt", &LSObject::_toInt)

    // see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/operators.html#is
    // This should return true if we could cast to the type passed.
       .addStaticLuaFunction("_is", &LSObject::_is)

    // see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/operators.html#as
    // This should return a caste pointer to the specified type.
       .addStaticLuaFunction("_as", &LSObject::_as)

    // _instanceof is same as _is, mostly.
    // see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/operators.html#instanceof
    // for a full discussion; it should not match on interfaces but we are lazy.
       .addStaticLuaFunction("_instanceof", &LSObject::_is)
       .addStaticMethod("getType", &LSObject::getType)
       .addStaticLuaFunction("getTypeName", &LSObject::getTypeName)
       .addStaticLuaFunction("getFullTypeName", &LSObject::getFullTypeName)
       .addStaticLuaFunction("nativeDeleted", &LSObject::nativeDeleted)
       .addStaticMethod("_getType", &LSObject::_getType)
       .addStaticLuaFunction("_getTypeName", &LSObject::_getTypeName)
       .addStaticLuaFunction("_getFullTypeName", &LSObject::_getFullTypeName)
       .addStaticLuaFunction("_nativeDeleted", &LSObject::_nativeDeleted)

       .addStaticLuaFunction("trace", &LSObject::trace)

       .addStaticLuaFunction("__pget_NaN", &LSObject::_getNaN)
       .addStaticLuaFunction("isNaN", &LSObject::_isNaN)

       .addStaticLuaFunction("hasOwnProperty", &LSObject::_hasOwnProperty)
       .addStaticLuaFunction("_hasOwnProperty", &LSObject::_hasOwnProperty)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemObject()
{
    NativeInterface::registerNativeType<LSObject>(registerSystemObject);
}
