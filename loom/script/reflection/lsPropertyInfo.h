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

#ifndef _lspropertyinfo_h
#define _lspropertyinfo_h

#include "loom/script/reflection/lsMemberInfo.h"

namespace LS {
struct PropertyAttributes : BaseAttributes
{
    // whether the field has a default initializer
    bool hasDefault;

    // initialized only, cannot be written after
    bool isInitOnly;

    PropertyAttributes()
    {
        hasDefault = false;
        isInitOnly = false;
    }
};

class PropertyInfo : public MemberInfo {
    friend class PropertyInfoReader;
    friend class PropertyInfoWriter;
    friend class BinReader;

private:

    PropertyAttributes attr;


public:

    PropertyInfo() : ownGetter(true), ownSetter(true), getter(NULL), setter(NULL)
    {
        memberType.property = true;
    }

    ~PropertyInfo();

    bool canRead();
    bool canWrite();

    bool isPublic()
    {
        return attr.isPublic;
    }

    bool isProtected()
    {
        return attr.isProtected;
    }

    bool isPrivate()
    {
        return attr.isPrivate;
    }

    bool isNative()
    {
        return attr.isNative;
    }

    bool isStatic()
    {
        return attr.isStatic;
    }

    MethodInfo *getGetMethod();

    MethodInfo *getSetMethod();

    // if the get/set method is owned by a base type, these
    // will be true
    bool ownGetter;
    bool ownSetter;

    MethodInfo *getter;
    MethodInfo *setter;

    // invoke
    Object *getValue();
    void setValue(Object *othis, Object *value);

    bool isDefined(Type *attributeType, bool inherit)
    {
        return true;
    }
};
}
#endif
