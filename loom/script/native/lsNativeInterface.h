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

#ifndef _lsnativeinterface_h
#define _lsnativeinterface_h

#include "loom/common/core/assert.h"
#include "loom/common/core/allocator.h"

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/runtime/lsRuntime.h"

#include <lua.hpp>

namespace LS {
class LSLuaState;
class Type;
class MemberInfo;
class NativeTypeBase;

/*
 * Note:  lualoom_* are intended as the native interface's public api (for use when writing custom bindings).
 * If you find yourself using non-lualoom_* functions to manipulate the lua stack in binding code
 * please generate a JIRA issue regarding the usage
 */

/*
 * downcasts an instance in place on the stack, this replaces  the instances class table, and
 * bookkeeping to reflect the new type
 */
void lualoom_downcastnativeinstance(lua_State *L, int instanceIdx, Type *fromType, Type *toType);

/*
 * Creates a new bridge user data on the stack given a native type and a void* to the instance
 * If owner is true, the pointed instance gets deleted with `lmDelete`
 * when the object gets garbage collected, otherwise the responsibility of instance deletion
 * falls on the caller
 */
void lualoom_newnativeuserdata(lua_State *L, NativeTypeBase *nativeType, void *p, bool owner = false);

/*
 * Pushes a native pointer onto the stack, constructing
 * new a native bridge userdata
 * and possibly registering the native data with the managed table
 */
bool lualoom_pushnative(lua_State *L, NativeTypeBase *nativeType, void *ptr);

/*
 * Wrap a native userdata bridge on the stack with a LS class table
 * In the case of a managed native, the userdata must have already
 * been registered with the managed table and the class table will
 * be reused
 * For unmanaged natives, a new class table will be constructed
 * and the bridge userdata will be wrapped by it
 */
void lualoom_pushnative_userdata(lua_State *L, Type *type, int nativeIdx);

/*
 * Given a full path string, retrieve the reflection type instance from the given VM
 */
Type *lualoom_gettype(lua_State *L, const utString& fullPath);

/*
 * Retrieve a native pointer off the stack at index x, with an optional type check given the full type name
 * NOTE: if replaceIndex is true replaces the index with the native userdata
 */
void *lualoom_getnativepointer(lua_State *L, int index, bool replaceIndex = false, const char *typecheck = NULL);

/*
 * Internal function to create a new script instance of given type on the stack, does not run constructors, etc
 */
void lualoom_newscriptinstance_internal(lua_State *L, Type *type);

/*
 * Internal function to can class initializers (not constructors) for a hierarchy chain stopping at the given
 * parent type (in the case of the parents initilaizers already having been run)
 */
void lualoom_callscriptinstanceinitializerchain_internal(lua_State *L, Type *type, int instanceIdx, Type *stopAtParentType);


/*
 * for use in destructors, etc to tell the managed native system
 * that an instance has been deleted C++ side
 */
void lualoom_managedpointerreleased(void *p);

/*
 * returns the Type on success, otherwise null
 * index is the index on the lua stack of the instance
 * fullTypePath is the fully qualified type path for example: "system.Object"
 */
Type *lualoom_checkinstancetype(lua_State *L, int index, const char *fullTypePath);


class NativeEntry;

// registration with a given lua_State
typedef int (*FunctionLuaRegisterType)(lua_State *L);

// cast using dynamic_cast from parent type defined when
// using .deriveClass
typedef bool (*FunctionCast)(void *ptr);

// note we cannot store Type here as this is only valid per VM
class NativeTypeBase {
    friend class NativeInterface;

protected:
    utString scriptPackage;
    utString scriptName;
    utString fullName;
    bool     managed;
    // application specific key
    void *externalKey;

    // bridge keys
    void *bridgeStaticKey;
    void *bridgeClassKey;
    void *bridgeConstKey;

    FunctionCast functionCast;

public:

    virtual void *getKey()              = 0;
    virtual void *getExternalKey()      = 0;
    virtual void *getBridgeStaticKey()  = 0;
    virtual void *getBridgeClassKey()   = 0;
    virtual void *getBridgeConstKey()   = 0;
    virtual utString& getCTypeName()    = 0;
    virtual void deletePointer(void *p, bool owner = false) = 0;

    const utString& getScriptPackage()
    {
        return scriptPackage;
    }

    const utString& getScriptName()
    {
        return scriptName;
    }

    const utString& getFullName()
    {
        return fullName;
    }

    bool isManaged()
    {
        return managed;
    }

    void setScriptPackage(const char *package, const char *name)
    {
        scriptPackage = package;
        scriptName    = name;
        fullName      = package;
        fullName     += ".";
        fullName     += name;
    }

    void validate(Type *type);

    void checkBridge(MemberInfo *info);
    bool checkBridgeTable(lua_State *L, MemberInfo *info, void *ptr, const char *key);

    FunctionLuaRegisterType registerFunction;
};

template<class T>
class NativeType : public NativeTypeBase {
    utString cTypeName;

public:

    void *getKey()
    {
        return getStaticKey();
    }

    static void *getStaticKey()
    {
        static char value;

        return &value;
    }

    void *getExternalKey()
    {
        return externalKey;
    }

    void *getBridgeStaticKey()
    {
        return bridgeStaticKey;
    }

    void *getBridgeClassKey()
    {
        return bridgeClassKey;
    }

    void *getBridgeConstKey()
    {
        return bridgeConstKey;
    }

    void deletePointer(void *p, bool owner = false)
    {
        assert(isManaged() || owner);

        if (isManaged() && !owner) lualoom_managedpointerreleased(p);

        // If you get a compiler error here, note that destructor must be public!
        // also, you should take care when calling nativeDelete from script (which will end
        // up here, as the native C++ API may have other ideas.  This should be documented
        // in the script API bindings as there is no "general case" for bound code)
        lmDelete(NULL, (T *)p);
    }

    virtual utString& getCTypeName()
    {
        if (!cTypeName.length())
        {
            cTypeName = LSGetTypeName<T>();
        }

        return cTypeName;
    }

    NativeType(void *externalKey, FunctionLuaRegisterType rf)
    {
        this->externalKey     = externalKey;
        this->bridgeStaticKey = NULL;
        this->bridgeClassKey  = NULL;
        this->bridgeConstKey  = NULL;
        this->functionCast    = NULL;

        registerFunction = rf;
        managed          = false;
    }
};

// Managed native classes can be inherited and extended via LoomScript.  They
// can also use custom allocation/pooling systems.

template<class T>
class ManagedNativeType : public NativeType<T> {
public:

    ManagedNativeType(void *externalKey, FunctionLuaRegisterType rf) : NativeType<T> (externalKey, rf)
    {
        this->managed = true;
    }
};

class NativeInterface {
    // templated static key -> NativeTypeBase
    static utHashTable<utPointerHashKey, NativeTypeBase *> nativeTypes;

    // These are stored statically here as Types are per VM

    // NativeTypeBase* -> Type*
    static utHashTable<utPointerHashKey, Type *> scriptTypes;

    // C/C++ type string -> NativeTypeBase*
    static utHashTable<utHashedString, NativeTypeBase *> cTypes;

    // Type* -> NativeTypeBase*
    static utHashTable<utPointerHashKey, NativeTypeBase *> scriptToNative;

    // void* -> LSLuaState
    static utHashTable<utPointerHashKey, lua_State *> handleEntryToLuaState;

    /*
     * Store the managed native user data on the top of the stack
     * to the entry->version and entry->userdata global lookup table
     */
    static void registerManagedNativeUserData(lua_State *L, NativeTypeBase *nativeType, void *ptr)
    {
        if (!nativeType->isManaged())
        {
            return;
        }

        int uIdx = lua_gettop(L);

        handleEntryToLuaState.insert(ptr, L);

        // store (void*) entry to version number
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDVERSION);
        lua_pushlightuserdata(L, ptr);
        lua_pushnumber(L, 1);
        lua_settable(L, -3);

        // store (void*) entry to native bridge user data
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDUSERDATA);
        lua_pushlightuserdata(L, ptr);
        lua_pushvalue(L, uIdx);
        lua_settable(L, -3);

        lua_settop(L, uIdx);
    }

    /*
     * given native user data, register the data and wrap it in a LoomScript class table
     * also, for C++ instantiated instances, make sure the object initializer chain is
     * called (when inConstructor is false)
     */
    static inline void wrapManagedNative(lua_State *L, NativeTypeBase *nativeType, void *ptr, bool inConstructor)
    {
        // native userdata on top of stack
        int wrapIdx = lua_gettop(L);

        registerManagedNativeUserData(L, nativeType, ptr);

        Type *type = getScriptType(nativeType);

        lualoom_newscriptinstance_internal(L, type);

        int instanceIdx = lua_gettop(L);

        lua_pushvalue(L, wrapIdx);
        lua_rawseti(L, instanceIdx, LSINDEXNATIVE);

        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);
        lua_pushvalue(L, wrapIdx);
        lua_pushvalue(L, instanceIdx);
        lua_settable(L, -3);

        // If we're in a constructor we are being explicitly initialized in script with a new
        // the object initializer chain will be automatically called in this case
        // otherwise, we're handing back a C++ created instance to script and need to
        // call the object initializer so that script members are properly initialized
        // for this managed native instance
        if (!inConstructor)
        {
            lualoom_callscriptinstanceinitializerchain_internal(L, type, instanceIdx, NULL);
        }

        lua_settop(L, wrapIdx);
    }

public:

    static void shutdownLuaState(lua_State *L);

    inline static Type *getScriptType(NativeTypeBase *nativeType)
    {
        Type **type = scriptTypes.get(nativeType);

        if (type)
        {
            return *type;
        }
        return NULL;
    }

    /*
     * Retrieve the native type given the ctype name (which is possibly qualified by C++ namespace)
     */
    static NativeTypeBase *getNativeType(const utString& ctypename)
    {
        NativeTypeBase **n = cTypes.get(ctypename.c_str());

        if (n)
        {
            lmAssert(*n, "Unexpected NULL result on getNativeType: %s", ctypename.c_str());
            return *n;
        }

        // linear search
        utHashTableIterator<utHashTable<utPointerHashKey, Type *> > itr(scriptTypes);
        while (itr.hasMoreElements())
        {
            NativeTypeBase *ntb = (NativeTypeBase *)itr.peekNextKey().key();

            if (ntb->getCTypeName() == ctypename)
            {
                // cache
                cTypes.insert(ctypename, ntb);
                return ntb;
            }

            itr.next();
        }

        return NULL;
    }

    static void registerNativeTypes(lua_State *L)
    {
        // it is possible that the registration function is shared
        // by multiple types, so avoid duplicate registrations
        utArray<FunctionLuaRegisterType> called;

        for (UTsize i = 0; i < nativeTypes.size(); i++)
        {
            NativeTypeBase *ntype = nativeTypes.at(i);
            assert(ntype->registerFunction);

            if (called.find(ntype->registerFunction) != UT_NPOS)
            {
                continue;
            }

            ntype->registerFunction(L);

            called.push_back(ntype->registerFunction);
        }
    }

    template<class T>
    static bool dynamicCast(void *ptr)
    {
        // root of hierarchy is always true
        return true;
    }

    template<class T, class U>
    static bool dynamicCast(void *ptr)
    {
        // if you get polymorphic error make sure
        // that base type has at least one virtual
        // method otherwise it isn't polymorphic
        T *p = dynamic_cast<T *>((U *)ptr);

        // check that pointer is same address
        if (p)
        {
            assert((size_t)ptr == (size_t)p);
        }

        return p ? true : false;
    }

    template<class T>
    static void setNativeTypePackage(void *key, const void *bridgeStaticKey, const void *bridgeClassKey, const void *bridgeConstKey, const char *package, const char *name)
    {
        UTsize idx = nativeTypes.find(key);

        if (idx == UT_NPOS)
        {
            lmAssert(0, "ERROR: unabled to find native type %s, was it declared with LOOM_DECLARE_NATIVETYPE or LOOM_DECLARE_MANAGEDNATIVETYPE?", LSGetTypeName<T>());
        }

        NativeTypeBase *ntype = nativeTypes.at(idx);

        ntype->bridgeClassKey  = (void *)bridgeClassKey;
        ntype->bridgeConstKey  = (void *)bridgeConstKey;
        ntype->bridgeStaticKey = (void *)bridgeStaticKey;

        // store off a template instantiation of dynamic cast (to self)
        ntype->functionCast = dynamicCast<T>;

        ntype->setScriptPackage(package, name);
    }

    template<class T, class U>
    static void deriveNativeTypePackage(void *key, const void *bridgeStaticKey, const void *bridgeClassKey, const void *bridgeConstKey, const char *package, const char *name)
    {
        UTsize idx = nativeTypes.find(key);

        if (idx == UT_NPOS)
        {
            utString ts = LSGetTypeName<T>();
            utString us = LSGetTypeName<U>();
            lmAssert(0, "ERROR: unabled to find derived native type %s (:%s), was it declared with LOOM_DECLARE_NATIVETYPE or LOOM_DECLARE_MANAGEDNATIVETYPE?", ts.c_str(), us.c_str());
        }

        assert(idx != UT_NPOS);

        NativeTypeBase *ntype = nativeTypes.at(idx);

        ntype->bridgeClassKey  = (void *)bridgeClassKey;
        ntype->bridgeConstKey  = (void *)bridgeConstKey;
        ntype->bridgeStaticKey = (void *)bridgeStaticKey;

        // store off a template instantiation of dynamic cast (to parent class)
        ntype->functionCast = dynamicCast<T, U>;

        ntype->setScriptPackage(package, name);
    }

    template<class T>
    static void registerNativeType(void *externalKey, FunctionLuaRegisterType regFunc = 0)
    {
        NativeType<T> *nativeType = lmNew(NULL) NativeType<T>(externalKey, regFunc);

        nativeTypes.insert(nativeType->getKey(), nativeType);
    }

    template<class T>
    static void registerNativeType(FunctionLuaRegisterType regFunc = 0)
    {
        NativeType<T> *nativeType = lmNew(NULL) NativeType<T>(NULL, regFunc);

        nativeTypes.insert(nativeType->getKey(), nativeType);
    }

    template<class T>
    static void registerManagedNativeType(FunctionLuaRegisterType regFunc = 0)
    {
        ManagedNativeType<T> *nativeType = lmNew(NULL) ManagedNativeType<T>(NULL, regFunc);

        nativeTypes.insert(nativeType->getKey(), nativeType);
    }

    template<class T>
    static NativeTypeBase *getNativeType()
    {
        void *key = NativeType<T>::getStaticKey();

        UTsize pos = nativeTypes.find(key);

        if (pos == UT_NPOS)
        {
            return NULL;
        }

        return nativeTypes.at(pos);
    }

    static NativeTypeBase *getNativeType(Type *scriptType)
    {
        NativeTypeBase **ntb = scriptToNative.get(scriptType);

        if (ntb)
        {
            return *ntb;
        }

        return NULL;
    }

    static void dumpManagedNatives(lua_State *L);

    static int getManagedObectCount(const char *classPath, LSLuaState *ls);

    /*
     * Internal method to push a managed native either created in LS with new or returned from a native method call
     * lualoom_pushnative is the public interface to the functionality
     */
    static void pushManagedNativeInternal(lua_State *L, NativeTypeBase *nativeType, void *ptr, bool inConstructor = false, bool owner = false)
    {
        lmAssert(nativeType->isManaged(), "pushManagedNativeInternal - pushing unmanaged native type %s", nativeType->getFullName().c_str());

        // look in the managed table for our entry
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDVERSION);
        lua_pushlightuserdata(L, ptr);
        lua_gettable(L, -2);

        // get the stored version number
        double version = -1;
        if (lua_isnumber(L, -1))
        {
            version = lua_tonumber(L, -1);
        }

        lua_pop(L, 2);


        if (version == -1)
        {
            // haven't seen this entry before

            // If we get a C++ pointer that we haven't seen before (ie. was not instantiated in script, or returned via a
            // native method, we need to wrap the managed native automatically

            lualoom_newnativeuserdata(L, nativeType, ptr, owner);
            wrapManagedNative(L, nativeType, ptr, inConstructor);
            lua_pop(L, 1);

            version = 1;
        }

        if (version != 1)
        {
            lmAssert(0, "NativeInterface::pushManagedNativeInternal - mismatched version");
        }

        // we have a match, so reuse the existing table
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDUSERDATA);
        lua_pushlightuserdata(L, ptr);
        lua_gettable(L, -2);
        lua_remove(L, -2);

        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);
        lua_pushvalue(L, -2);
        lua_gettable(L, -2);
        lua_remove(L, -2);
        lua_remove(L, -2);

        lmAssert(lua_istable(L, -1), "NativeInterface::pushManagedNativeInternal - unabled to retrieve managed script instance");
    }

    template<class T>
    static void pushManagedNativeInternal(lua_State *L, T *ptr)
    {
        // early out
        if (!ptr)
        {
            lua_pushnil(L);
            return;
        }

        NativeTypeBase *nativeType = getNativeType<T>();

        pushManagedNativeInternal(L, nativeType, ptr);
    }

    static void managedPointerReleased(void *entry, int version = 1);
    static void resolveScriptType(Type *type);

    /*
     * Use C++ RTTI via dynamic_cast to check the type of the ptr instance
     * If valid, push the instance as a new bridge userdata on the stack.
     * returns false with nil on top of stack on failure
     * returns true with native userdata wrapped instance on success
     */
    static bool pushDynamicCast(lua_State *L, Type *fromType, Type *toType, int instanceIdx, void *ptr)
    {
        if (!ptr)
        {
            lua_pushnil(L);
            return false;
        }

        instanceIdx = lua_absindex(L, instanceIdx);

        // upcasts are always valid and return identity
        if ((fromType == toType) || fromType->isDerivedFrom(toType))
        {
            lua_pushvalue(L, instanceIdx);
            return true;
        }

        // down casts must use C++ RTTI & dynamic_cast to verify that they
        // are valid
        if (toType->isDerivedFrom(fromType))
        {
            NativeTypeBase *to = getNativeType(toType);
            if (to->functionCast(ptr))
            {
                // Handle the downcast - we may have to initialize fields.
                lualoom_downcastnativeinstance(L, instanceIdx, fromType, toType);
                lua_pushvalue(L, instanceIdx);
                return true;
            }
        }

        // Cast failed, return NULL.
        lua_pushnil(L);
        return false;
    }

    /*
     * Checks the cast without pushing anything on stack, for native types if dynamic_cast reports true
     * the cast is considered valid
     */
    static bool validCast(lua_State *L, Type *fromType, Type *toType, int instanceIdx, void *ptr)
    {
        if (!ptr)
        {
            return false;
        }

        // upcasts are always valid
        if ((fromType == toType) || fromType->isDerivedFrom(toType))
        {
            return true;
        }

        // down casts must use C++ RTTI & dynamic_cast to verify that they
        // are valid
        if (toType->isDerivedFrom(fromType))
        {
            NativeTypeBase *to = getNativeType(toType);

            if (to->functionCast(ptr))
            {
                return true;
            }
        }

        return false;
    }
};

// template for convenience
template<class T>
bool lualoom_pushnative(lua_State *L, T *ptr)
{
    return lualoom_pushnative(L, NativeInterface::getNativeType<T>(), ptr);
}
}
#endif
