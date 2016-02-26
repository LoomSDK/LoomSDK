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

#ifndef _lstype_h
#define _lstype_h

extern "C" {
#include "lua.h"
}

#include "loom/common/core/allocator.h"
#include "loom/common/utils/utString.h"
#include "loom/script/common/lsError.h"
#include "loom/script/reflection/lsMemberInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"

#ifndef LOOM_ENABLE_JIT
#include "loom/script/reflection/lsByteCode.h"
#else
#include "loom/script/reflection/lsJitByteCode.h"
#endif

typedef unsigned int   LSTYPEID;

namespace LS {
struct TypeAttributes
{
    bool isPublic;
    bool isClass;
    bool isInterface;
    bool isStruct;
    bool isDelegate;
    bool isEnum;
    bool isImport; // type is from another module
    bool isNative;
    bool isNativeManaged;
    bool isStatic;
    bool isFinal;

    TypeAttributes()
    {
        isPublic        = false;
        isClass         = false;
        isInterface     = false;
        isStruct        = false;
        isDelegate      = false;
        isEnum          = false;
        isImport        = false;
        isNative        = false;
        isNativeManaged = false;
        isStatic        = false;
        isFinal         = false;
    }
};

class ByteCode;
class ConstructorInfo;
class FieldInfo;
class Type;

class Type : public MemberInfo {
    friend class Module;
    friend class TypeReader;
    friend class TypeWriter;
    friend class BinReader;

private:

    Type *baseType;

    utString fullName;

    utString packageName;

    utString ctypeName;

    Module *module;

    LSTYPEID typeID;

    utString assemblyQualifiedName;

    TypeAttributes attr;

    utList<MemberInfo *> members;

    utArray<Type *> imports;
    utArray<Type *> interfaces;

    utArray<Type *> delegateTypes;
    Type            *delegateReturnType;

    ByteCode *bcStaticInitializer;
    ByteCode *bcInstanceInitializer;

    utHashTable<utFastStringHash, MemberInfo *> memberCache;

    int fieldInfoCount;
    int methodInfoCount;
    int propertyInfoCount;

    bool fieldMembersValid;
    bool methodMembersValid;
    bool propertyMembersValid;

    utArray<MemberInfo *> fieldMembers;
    utArray<MemberInfo *> methodMembers;
    utArray<MemberInfo *> propertyMembers;

    void addMember(MemberInfo *member);

    bool cached;
    int  maxMemberOrdinal;

    // allocated as an array of pointers for fastest memory access
    MemberInfo **memberInfoOrdinalLookup;

    bool hadInstanceInitializer;
    bool hadStaticInstanceInitializer;

    bool _isVector, _isDictionary, _isVector_Cached, _isDictionary_Cached;

    Type *nativeBaseType;
    bool nativeBaseType_cached;

    bool _isNativeMemberPure, _isNativeMemberPure_cached;

    ConstructorInfo *cachedConstructor;

public:

    static bool ignoreMissingTypes;

    inline void setMissing(const char *format, ...)
    {
        static char message[256];
        va_list args;

        MemberInfo::setMissing();

        va_start(args, format);
        vsnprintf(message, sizeof(message), format, args);
        va_end(args);

        if (ignoreMissingTypes) {
            LSLog(LSLogQuiet, "Ignoring missing type %s (%s)", getFullName().c_str(), message);
        }
        else
        {
            LSError("Error: Type missing or incomplete: %s (%s)\nUse --ignore-missing-types to ignore all missing types", getFullName().c_str(), message);
        }
    }

    Type() :
        baseType(NULL), module(NULL), typeID(0),
        delegateReturnType(NULL),
        bcStaticInitializer(NULL), bcInstanceInitializer(NULL),
        fieldInfoCount(-1), methodInfoCount(-1), propertyInfoCount(-1),
        fieldMembersValid(false), methodMembersValid(false), propertyMembersValid(false),
        cached(false), maxMemberOrdinal(0), memberInfoOrdinalLookup(NULL),
        hadInstanceInitializer(false), hadStaticInstanceInitializer(false),
        _isVector(false), _isDictionary(false), _isVector_Cached(false), _isDictionary_Cached(false),
        nativeBaseType(NULL), nativeBaseType_cached(false),
        _isNativeMemberPure(false), _isNativeMemberPure_cached(false),
        cachedConstructor(NULL)
    {
    }

    ~Type()
    {
        for (UTsize i = 0; i < members.size(); i++)
        {
            lmDelete(NULL, members.at(i));
        }

        lmSafeDelete(NULL, bcStaticInitializer);
        lmSafeDelete(NULL, bcInstanceInitializer);
        lmSafeDelete(NULL, memberInfoOrdinalLookup);
        
        lualoom_managedpointerreleased(this);
    }

    // Get the first native type in the inheritance chain (potentially this class).
    Type *getNativeBaseType()
    {
        if(!nativeBaseType_cached)
        {
            Type *t = this;
            while(t)
            {
                if(t->isNative())
                {
                    nativeBaseType = t;
                    break;
                }

                t = t->getBaseType();
            }
            nativeBaseType_cached = true;
        }

        return nativeBaseType;
    }

    void freeByteCode();

    void findMembers(const MemberTypes& memberTypes, utArray<MemberInfo *>& membersOut,
                     bool includeBases = false, bool includePropertyGetterSetters = false);

    int getFieldInfoCount();
    FieldInfo *getFieldInfo(int index);

    int getMethodInfoCount();
    MethodInfo *getMethodInfo(int index);

    int getPropertyInfoCount();
    PropertyInfo *getPropertyInfo(int index);
    
    MemberInfo *findMember(const char *name, bool includeBases = true);

    FieldInfo *findFieldInfoByName(const char *name);

    MethodInfo *findMethodInfoByName(const utString& name);

    PropertyInfo *findPropertyInfoByName(const char *name);

    MethodInfo *findOperatorMethod(const utString& methodName);

    const TypeAttributes& attributes()
    {
        return attr;
    }

    bool isValueType();

    bool isClass()
    {
        return attr.isClass;
    }

    bool isInterface()
    {
        return attr.isInterface;
    }

    bool isStruct()
    {
        return attr.isStruct;
    }

    bool isDelegate()
    {
        return attr.isDelegate;
    }

    bool isEnum()
    {
        return attr.isEnum;
    }

    bool isNative()
    {
        return attr.isNative;
    }

    bool isStatic()
    {
        return attr.isStatic;
    }

    bool isFinal()
    {
        return attr.isFinal;
    }

    bool isNativeDerived()
    {
        if (attr.isNative)
        {
            return false;
        }

        Type *base = baseType;
        while (base)
        {
            if (base->isNative())
            {
                return true;
            }
            base = base->baseType;
        }

        return false;
    }

    bool isNativeMemberPure(bool ignoreStaticMembers = false);

    bool isNativeMemberPure_Cached(bool ignoreStaticMembers = false)
    {
        lmAssert(ignoreStaticMembers == true, "isNativeMemberPure_Cached only implemented when ignoring static members.");
        if(!_isNativeMemberPure_cached)
        {
            _isNativeMemberPure = isNativeMemberPure(ignoreStaticMembers);
            _isNativeMemberPure_cached = true;
        }

        return _isNativeMemberPure;
    }

    inline bool isNativeScriptExtension()
    {
        if (!isNativeDerived())
        {
            return false;
        }

        if (!isNativeMemberPure())
        {
            return true;
        }

        return false;
    }

    inline bool isNativeOrNativeDerived()
    {
        if (attr.isNative)
        {
            return true;
        }

        return isNativeDerived();
    }

    inline bool isNativeManaged()
    {
        if (attr.isNativeManaged)
        {
            return true;
        }

        // Check parents.
        Type *base = baseType;
        while (base)
        {
            if (base->attr.isNativeManaged)
            {
                // Propagate flag to this item to save on subsequent iteration.
                attr.isNativeManaged = true;
                return true;
            }
            base = base->baseType;
        }

        return false;
    }

    inline bool isNativePure()
    {
        return isNative() && !isNativeManaged();
    }


    bool hasStaticNativeMember()
    {
        for (UTsize i = 0; i < members.size(); i++)
        {
            if (members.at(i)->isStatic() && members.at(i)->isNative())
            {
                return true;
            }
        }

        return false;
    }

    bool isPrimitive()
    {
        if (fullName == "system.String")
        {
            return true;
        }

        if (fullName == "system.Number")
        {
            return true;
        }

        if (fullName == "system.Boolean")
        {
            return true;
        }

        if (fullName == "system.Null")
        {
            return true;
        }

        if (fullName == "system.Function")
        {
            return true;
        }

        return false;
    }

    bool isPublic()
    {
        return attr.isPublic;
    }

    bool isPrivate()
    {
        return !attr.isPublic;
    }

    int inline getMaxMemberOrdinal()
    {
        return maxMemberOrdinal;
    }

    int inline getMemberOrdinal(const char *memberName)
    {
        MemberInfo *mi = findMember(memberName);

        if (!mi)
        {
            return 0;
        }

        return mi->getOrdinal();
    }

    inline MemberInfo *getMemberInfoByOrdinal(int ordinal)
    {
        assert(cached);

        if ((ordinal >= maxMemberOrdinal) || (ordinal < 0))
        {
            return NULL;
        }

        return memberInfoOrdinalLookup[ordinal];
    }

    inline bool isNativeOrdinal(int ordinal)
    {
        MemberInfo *mi = getMemberInfoByOrdinal(ordinal);

        lmAssert(mi, "Type::isNativeOrdinal, ordinal %i is not a member of %s", ordinal, getFullName().c_str());
        return mi->isNative();
    }

    const utString& getPackageName()
    {
        return packageName;
    }

    const utString& getFullName()
    {
        return fullName;
    }

    inline Type *getBaseType()
    {
        return baseType;
    }

    void setBaseType(Type *baseType)
    {
        this->baseType = baseType;
    }

    /*
     * Returns true if this type is derived from baseType
     */
    inline bool isDerivedFrom(Type *baseType)
    {
        Type *t = this->baseType;

        while (t)
        {
            if (t == baseType)
            {
                return true;
            }

            t = t->baseType;
        }

        return false;
    }

    void addInterface(Type *_interface)
    {
        interfaces.push_back(_interface);
    }

    Type *getInterface(UTsize idx)
    {
        return interfaces.at(idx);
    }

    UTsize getNumInterfaces()
    {
        return interfaces.size();
    }

    bool implementsInterface(Type *_interface)
    {
        if (_interface == this)
        {
            return true;
        }

        for (UTsize i = 0; i < interfaces.size(); i++)
        {
            if (_interface == interfaces.at(i))
            {
                return true;
            }

            if (interfaces.at(i)->implementsInterface(_interface))
            {
                return true;
            }
        }

        // look in base types
        if (baseType)
        {
            return baseType->implementsInterface(_interface);
        }

        return false;
    }

    void getInterfaceMembers(utArray<MemberInfo *>& members)
    {
        // go through all interfaces this type implements
        for (UTsize i = 0; i < interfaces.size(); i++)
        {
            Type *iface = interfaces.at(i);
            if (!iface)
            {
                LSWarning("Found NULL interface on type '%s', are you referencing a class that doesn't exist?", getFullName().c_str());
                continue;
            }

            utArray<MemberInfo *> imembers;
            MemberTypes           types;
            types.method   = true;
            types.property = true;

            // find all method/propery members of interface (and it's base interfaces)
            iface->findMembers(types, imembers, true);
            for (UTsize j = 0; j < imembers.size(); j++)
            {
                MemberInfo *mi = imembers[j];
                UTsize     k;
                for (k = 0; k < members.size(); k++)
                {
                    if (mi->name == members[k]->name)
                    {
                        break;
                    }
                }

                // if we haven't already snagged this member, add it
                if (k == members.size())
                {
                    members.push_back(mi);
                }
            }
        }
    }

    /*
     * If this is a native type, we can access the C/C++ typename
     * reported by the compiler.  This will also be qualified with
     * any C++ namespace
     */
    const utString& getCTypeName()
    {
        return ctypeName;
    }

    void setCTypeName(const utString& name)
    {
        ctypeName = name;
    }

    void setTypeID(LSTYPEID id)
    {
        typeID = id;
    }

    inline LSTYPEID getTypeID()
    {
        return typeID;
    }

    void addDelegateType(Type *dtype)
    {
        delegateTypes.push_back(dtype);
    }

    UTsize getNumDelegateTypes()
    {
        return delegateTypes.size();
    }

    Type *getDelegateType(UTsize idx)
    {
        return delegateTypes.at(idx);
    }

    void setDelegateReturnType(Type *dtype)
    {
        delegateReturnType = dtype;
    }

    Type *getDelegateReturnType()
    {
        return delegateReturnType;
    }

    const Module *getModule()
    {
        return module;
    }

    Assembly *getAssembly();

    ConstructorInfo *getConstructor();

    void getImports(utArray<Type *>& imports)
    {
        imports = this->imports;
    }

    void addImport(Type *import)
    {
        imports.push_back(import);
    }

    void clearImports()
    {
        imports.clear();
    }

    // outside of assembly
    bool isVisible();

    bool isSerializable();

    bool isArray();

    bool isVector()
    {
        if(!_isVector_Cached)
        {
            _isVector = (fullName == "system.Vector");
            _isVector_Cached = true;
        }
        return _isVector;
    }

    bool isDictionary()
    {
        if(!_isDictionary_Cached)
        {
            _isDictionary = (fullName == "system.Dictionary");
            _isDictionary_Cached = true;
        }
        return _isDictionary;
    }

    bool isDefined(Type *attributeType, bool inherit)
    {
        return false;
    }

    void setBCStaticInitializer(ByteCode *bc)
    {
        if (bcStaticInitializer != NULL) lmDelete(NULL, bcStaticInitializer);
        bcStaticInitializer = bc;
        if(bc->getByteCode().size() != 0)
            hadStaticInstanceInitializer = true;
    }

    ByteCode *getBCStaticInitializer()
    {
        return bcStaticInitializer;
    }

    void setBCInstanceInitializer(ByteCode *bc)
    {
        if (bcInstanceInitializer != NULL) lmDelete(NULL, bcInstanceInitializer);
        bcInstanceInitializer = bc;
        if(bc->getByteCode().size() != 0)
            hadInstanceInitializer = true;
    }

    ByteCode *getBCInstanceInitializer()
    {
        return bcInstanceInitializer;
    }

    bool hasInstanceInitializer() const
    {
        return hadInstanceInitializer;
    }

    bool hasStaticInstanceInitializer() const
    {
        return hadStaticInstanceInitializer;
    }

    Type *castToType(Type *to, bool tryReverse = false);

    void assignOrdinals();

    void cache();

    static Type *getType(const utString& fullName, lua_State *L);
};

}
#endif
