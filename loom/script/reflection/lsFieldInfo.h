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

#ifndef _lsfieldinfo_h
#define _lsfieldinfo_h

#include "loom/script/reflection/lsMemberInfo.h"
#include "loom/script/reflection/lsType.h"

namespace LS {
struct FieldAttributes : BaseAttributes
{
    // whether the field has a default initializer
    bool hasDefault;

    // initialized only, cannot be written after
    bool isInitOnly;

    FieldAttributes()
    {
        hasDefault = false;
        isInitOnly = false;
    }
};

class FieldInfo : public MemberInfo
{
    friend class FieldInfoReader;
    friend class FieldInfoWriter;
    friend class BinReader;

private:

    FieldAttributes attr;

public:

    FieldInfo()
    {
    }

    bool isAbstract();

    // can be called by other classes in the same assembly
    bool isAssembly();

    // access is limited to method limited to members of class and derived classes
    bool isFamily();

    // can be called by derived classes in the same assembly
    bool isFamilyAndAssembly();

    // can be called by derived classes (wherever they are) and all classes in same
    // assembly
    bool isFamilyOrAssembly();

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

    bool isConst()
    {
        return attr.isConst;
    }

    bool isVirtual();

    // module the method is defined in
    const Module *getModule()
    {
        assert(declaringType);
        return declaringType->getModule();
    }

    bool isDefined(Type *attributeType, bool inherit)
    {
        return false;
    }

    int setValue(lua_State *L);
    int getValue(lua_State *L);
};
}
#endif
