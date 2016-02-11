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

#include "loom/script/reflection/lsPropertyInfo.h"
#include "loom/script/reflection/lsMethodInfo.h"

namespace LS {
PropertyInfo::~PropertyInfo()
{
    if (getter && ownGetter)
    {
        lmDelete(NULL, getter);
    }

    if (setter && ownSetter)
    {
        lmDelete(NULL, setter);
    }

    lualoom_managedpointerreleased(this);
}


MethodInfo *PropertyInfo::getGetMethod()
{
    if (getter)
    {
        return getter;
    }

    if (!ownGetter)
    {
        return NULL;
    }

    // alright, we don't have a get method defined on this
    // property info, but we may have once in a parent type
    // so find it, note that this is only done once per
    // property info

    ownGetter = false;

    Type *baseType = getDeclaringType()->getBaseType();

    PropertyInfo *baseProp = NULL;

    while (baseType)
    {
        MemberInfo *minfo = baseType->findMember(this->getName(), false);

        if (minfo && minfo->isProperty() && ((PropertyInfo *)minfo)->getter)
        {
            baseProp = (PropertyInfo *)minfo;
            break;
        }

        baseType = baseType->getBaseType();
    }

    if (!baseProp)
    {
        return NULL;
    }

    getter = baseProp->getter;

    return getter;
}


MethodInfo *PropertyInfo::getSetMethod()
{
    if (setter)
    {
        return setter;
    }

    if (!ownSetter)
    {
        return NULL;
    }

    ownSetter = false;

    // alright, we don't have a set method defined on this
    // property info, but we may have once in a parent type
    // so find it, note that this is only done once per
    // property info

    Type *baseType = getDeclaringType()->getBaseType();

    PropertyInfo *baseProp = NULL;

    while (baseType)
    {
        MemberInfo *minfo = baseType->findMember(this->getName(), false);

        if (minfo && minfo->isProperty() && ((PropertyInfo *)minfo)->setter)
        {
            baseProp = (PropertyInfo *)minfo;
            break;
        }

        baseType = baseType->getBaseType();
    }

    if (!baseProp)
    {
        return NULL;
    }

    setter = baseProp->setter;

    return setter;
}
}
