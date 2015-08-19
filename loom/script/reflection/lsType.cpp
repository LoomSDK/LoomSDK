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

#include "loom/common/utils/utString.h"
#include "loom/script/common/lsError.h"
#include "loom/script/reflection/lsType.h"

#include "loom/script/reflection/lsMethodInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"

#include "loom/script/runtime/lsLuaState.h"

namespace LS {

Assembly *Type::getAssembly()
{
    assert(module);
    return module->getAssembly();
}


void Type::addMember(MemberInfo *member)
{
    LOOM_ALLOCATOR_VERIFY(member);

    member->declaringType = this;
    members.push_back(member);

    // setup full member name
    member->fullMemberName  = this->getFullName();
    member->fullMemberName += ".";
    member->fullMemberName += member->name;

    if (member->isProperty())
    {
        PropertyInfo *p = (PropertyInfo *)member;

        // don't call getGetMethod as that will query parent class info
        // for missing getter
        MethodBase *mb = p->getter;
        if (mb)
        {
            mb->fullMemberName  = this->getFullName();
            mb->fullMemberName += ".";
            mb->fullMemberName += mb->name;
        }

        // don't call getSetMethod as that will query parent class info
        // for missing setter
        mb = p->setter;
        if (mb)
        {
            mb->fullMemberName  = this->getFullName();
            mb->fullMemberName += ".";
            mb->fullMemberName += mb->name;
        }
    }
}


void Type::freeByteCode()
{
    for (size_t i = 0; i < members.size(); i++)
    {
        MemberInfo *m = members.at((int)i);
        if (m->isConstructor())
        {
            ConstructorInfo *ci = (ConstructorInfo*)m;
            ci->freeByteCode();
        }
        else if(m->isMethod())
        {
            MethodInfo *mi = (MethodInfo *)m;
            mi->freeByteCode();
        }
        else if (m->isProperty())
        {
            PropertyInfo *pi = (PropertyInfo *)m;
            if(pi->getGetMethod())
                pi->getGetMethod()->freeByteCode();
            if(pi->getSetMethod())
                pi->getSetMethod()->freeByteCode();
        }
    }

    if (bcStaticInitializer)
    {
        lmDelete(NULL, bcStaticInitializer);
        bcStaticInitializer = NULL;
    }

    if (bcInstanceInitializer)
    {
        lmDelete(NULL, bcInstanceInitializer);
        bcInstanceInitializer = NULL;
    }
}

void Type::findMembers(const MemberTypes& memberTypes,
                       utArray<MemberInfo *>& membersOut, bool includeBases, bool includePropertyGetterSetters)
{
    if (!includeBases)
    {
        membersOut.clear();
    }

    for (size_t i = 0; i < members.size(); i++)
    {
        MemberInfo *m = members.at((int)i);

        if (m->isConstructor() && memberTypes.constructor)
        {
            membersOut.push_back(m);
        }

        if (m->isMethod() && memberTypes.method)
        {
            membersOut.push_back(m);
        }

        if (m->isField() && memberTypes.field)
        {
            membersOut.push_back(m);
        }

        if (m->isProperty() && memberTypes.property)
        {
            membersOut.push_back(m);

            if (includePropertyGetterSetters)
            {
                PropertyInfo *p = (PropertyInfo *)m;

                if (p->getter && (p->getter->getDeclaringType() == p->getDeclaringType()))
                {
                    membersOut.push_back(p->getter);
                }

                if (p->setter && (p->setter->getDeclaringType() == p->getDeclaringType()))
                {
                    membersOut.push_back(p->setter);
                }
            }
        }
    }

    if (baseType && includeBases)
    {
        baseType->findMembers(memberTypes, membersOut, true, includePropertyGetterSetters);
    }
}


MemberInfo *Type::findMember(const char *name, bool includeBases)
{
    if (cached)
    {
        MemberInfo **minfo = memberCache.get(name);

        if (minfo)
        {
            return *minfo;
        }

        return NULL;
    }

    for (UTsize i = 0; i < members.size(); i++)
    {
        MemberInfo *m = members.at(i);
        if (!strcmp(m->getName(), name))
        {
            return m;
        }
    }

    if (includeBases && baseType)
    {
        MemberInfo *m = baseType->findMember(name, true);

        return m;
    }

    return NULL;
}


FieldInfo *Type::findFieldInfoByName(const char *name)
{
    MemberInfo *mi = findMember(name);

    if (mi && mi->isField())
    {
        return (FieldInfo *)mi;
    }

    return NULL;
}


PropertyInfo *Type::findPropertyInfoByName(const char *name)
{
    MemberInfo *mi = findMember(name);

    if (mi && mi->isProperty())
    {
        return (PropertyInfo *)mi;
    }

    return NULL;
}


bool Type::isNativeMemberPure(bool ignoreStaticMembers)
{
    //if (!attr.isNative)
    //	return false;

    for (UTsize i = 0; i < members.size(); i++)
    {
        MemberInfo *memberInfo = members.at(i);

        if (ignoreStaticMembers && memberInfo->isStatic())
        {
            continue;
        }

        if (memberInfo->isConstructor())
        {
            ConstructorInfo *cinfo = (ConstructorInfo *)memberInfo;
            if (cinfo->defaultConstructor)
            {
                continue;
            }
        }

        if (memberInfo->isConstructor() || memberInfo->isMethod())
        {
            if (!((MethodBase *)memberInfo)->isNative())
            {
                return false;
            }
        }

        if (memberInfo->isProperty())
        {
            PropertyInfo *pinfo = (PropertyInfo *)memberInfo;
            if (pinfo->getGetMethod() && !pinfo->getGetMethod()->isNative())
            {
                return false;
            }
            if (pinfo->getSetMethod() && !pinfo->getSetMethod()->isNative())
            {
                return false;
            }
        }

        if (memberInfo->isField())
        {
            if (!memberInfo->getOrdinal())
            {
                return false;
            }
        }
    }

    if (baseType)
    {
        return baseType->isNativeMemberPure();
    }

    return true;
}


MethodInfo *Type::findOperatorMethod(const utString& methodName)
{
    MemberInfo *mi = findMember(methodName.c_str());

    if (!mi)
    {
        return NULL;
    }
    if (!mi->isMethod())
    {
        return NULL;
    }
    if (!((MethodInfo *)mi)->isOperator())
    {
        return NULL;
    }

    return (MethodInfo *)mi;
}


ConstructorInfo *Type::getConstructor()
{
    if(cachedConstructor)
        return cachedConstructor;

    for (UTsize i = 0; i < members.size(); i++)
    {
        MemberInfo *m = members.at(i);
        if (m->isConstructor())
        {
            cachedConstructor = (ConstructorInfo *)m;
            return (ConstructorInfo *)m;
        }
    }

    return NULL;
}


Type *Type::castToType(Type *to, bool tryReverse)
{
    if (!to)
    {
        return NULL;
    }

    lmAssert(module, "Type has no module");
    LSLuaState *lstate = module->getAssembly()->getLuaState();

    if (this == to)
    {
        return this;
    }

    if (attr.isEnum || to->attr.isEnum)
    {
        bool fromNumber = (this == lstate->numberType);
        bool toNumber   = (to == lstate->numberType);

        if (fromNumber && to->attr.isEnum)
        {
            return to;
        }

        if (toNumber && attr.isEnum)
        {
            return to;
        }
    }

    if (attr.isStruct || to->attr.isStruct)
    {
        // we cannot cast a struct o null
        if ((to == lstate->nullType) || (this == lstate->nullType))
        {
            return NULL;
        }
    }

    if (to == lstate->objectType)
    {
        return to;
    }

    Type *base;
    if (to->isInterface())
    {
        if (this == lstate->nullType)
        {
            return to;
        }

        base = this;
        while (base)
        {
            // check direct descendant
            if (base == to)
            {
                return to;
            }

            for (UTsize i = 0; i < base->interfaces.size(); i++)
            {
                Type *interface = base->interfaces[i];
                while (interface)
                {
                    if (interface == to)
                    {
                        return to;
                    }
                    interface = interface->baseType;
                }
            }
            base = base->baseType;
        }

        if (tryReverse)
        {
            return to->castToType(this);
        }

        return NULL;
    }

    base = baseType;
    while (base)
    {
        if (base == to)
        {
            return to;
        }
        base = base->baseType;
    }

    //TODO: invalidate Number Boolean -> null
    if (this == lstate->nullType)
    {
        return to;
    }

    if (tryReverse)
    {
        return to->castToType(this);
    }

    return NULL;
}


int Type::getFieldInfoCount()
{
    // Cache the result.
    if (fieldInfoCount != -1)
    {
        return fieldInfoCount;
    }

    MemberTypes types;
    types.field = true;
    utArray<MemberInfo *> members;

    findMembers(types, members, true);

    fieldInfoCount = (int)members.size();
    return fieldInfoCount;
}


FieldInfo *Type::getFieldInfo(int index)
{
    if (fieldMembersValid == false)
    {
        MemberTypes types;
        types.field = true;
        findMembers(types, fieldMembers, true);
        fieldMembersValid = true;
    }

    if ((index < 0) || (index >= (int)fieldMembers.size()))
    {
        LSError("Bad field info index");
    }

    return (FieldInfo *)fieldMembers[index];
}




MethodInfo *Type::getMethodInfo(int index)
{
    if (methodMembersValid == false)
    {
        MemberTypes types;
        types.method = true;
        findMembers(types, methodMembers, true);
        methodMembersValid = true;
    }

    if ((index < 0) || (index >= (int)methodMembers.size()))
    {
        LSError("Bad method info index");
    }

    return (MethodInfo *)methodMembers[index];
}

int Type::getMethodInfoCount()
{
    // Cache the result.
    if (methodInfoCount != -1)
    {
        return methodInfoCount;
    }

    MemberTypes types;
    types.method = true;
    utArray<MemberInfo *> members;

    findMembers(types, members, true);

    methodInfoCount = (int)members.size();
    return methodInfoCount;
}

MethodInfo *Type::findMethodInfoByName(const utString& name)
{
    MemberInfo *minfo = findMember(name.c_str());

    if (minfo && minfo->isMethod())
    {
        return (MethodInfo *)minfo;
    }

    return NULL;
}


PropertyInfo *Type::getPropertyInfo(int index)
{
    if (propertyMembersValid == false)
    {
        MemberTypes types;
        types.property = true;
        findMembers(types, propertyMembers, true);
        propertyMembersValid = true;
    }

    if ((index < 0) || (index >= (int)propertyMembers.size()))
    {
        LSError("Bad property info index");
    }

    return (PropertyInfo *)propertyMembers[index];
}


int Type::getPropertyInfoCount()
{
    // Cache the result.
    if (propertyInfoCount != -1)
    {
        return propertyInfoCount;
    }

    MemberTypes types;
    types.property = true;
    utArray<MemberInfo *> members;

    findMembers(types, members, true);

    propertyInfoCount = (int)members.size();

    return propertyInfoCount;
}


Type *Type::getType(const utString& fullName, lua_State *L)
{
    LSLuaState *vm = LSLuaState::getLuaState(L);

    utList<Assembly *> assemblies;
    Assembly::getLoadedAssemblies(vm, assemblies);

    for (UTsize i = 0; i < assemblies.size(); i++)
    {
        Type *type = assemblies.at(i)->getType(fullName);
        if (type)
        {
            return type;
        }
    }

    return NULL;
}


void Type::assignOrdinals()
{
    if (baseType)
    {
        baseType->assignOrdinals();
    }

    // already assigned?
    if (members.size() && members.at(0)->ordinal)
    {
        return;
    }

    MemberTypes types;

    types.constructor = true;
    types.field       = true;
    types.method      = true;
    types.property    = true;

    utArray<MemberInfo *> allMembers;
    findMembers(types, allMembers, true, true);

    int maxOrdinal = 0;
    for (UTsize i = 0; i < allMembers.size(); i++)
    {
        MemberInfo *mi = allMembers.at(i);

        if (mi->getOrdinal() > maxOrdinal)
        {
            maxOrdinal = mi->getOrdinal();
        }
    }

    // and assign
    int start = maxOrdinal + 1;

    for (UTsize i = 0; i < allMembers.size(); i++)
    {
        MemberInfo *mi = allMembers.at(i);

        if (!mi->ordinal)
        {
            lmAssert(mi->getDeclaringType() == this, "ordinal being assigned to non-declared member");

            UTsize j;
            for (j = 0; j < allMembers.size(); j++)
            {
                MemberInfo *other = allMembers.at(j);

                if (other->getDeclaringType() == this)
                {
                    continue;
                }

                if (strcmp(other->getName(), mi->getName()))
                {
                    continue;
                }

                break;
            }

            if (j == allMembers.size())
            {
                mi->setOrdinal(start++);
            }
            else
            {
                mi->setOrdinal(allMembers.at(j)->getOrdinal());
            }
        }
    }
}


void Type::cache()
{
    if (baseType)
    {
        baseType->cache();
    }

    if (cached)
    {
        return;
    }

    cached = true;

    MemberTypes types;

    types.constructor = true;
    types.field       = true;
    types.method      = true;
    types.property    = true;

    utArray<MemberInfo *> allMembers;

    findMembers(types, allMembers, true, true);

    maxMemberOrdinal = 0;

    for (UTsize i = 0; i < allMembers.size(); i++)
    {
        MemberInfo *mi = allMembers.at(i);

        if (mi->ordinal > maxMemberOrdinal)
        {
            maxMemberOrdinal = mi->ordinal;
        }
    }

    maxMemberOrdinal++;

    memberInfoOrdinalLookup = (MemberInfo **)lmAlloc(NULL, sizeof(MemberInfo *) * maxMemberOrdinal);
    memset(memberInfoOrdinalLookup, 0, sizeof(MemberInfo *) * maxMemberOrdinal);

    for (int i = (int)(allMembers.size() - 1); i >= 0; i--)
    {
        MemberInfo *mi = allMembers.at(i);

        memberCache.insert(mi->getName(), mi);
        memberInfoOrdinalLookup[mi->getOrdinal()] = mi;
    }
}
}
