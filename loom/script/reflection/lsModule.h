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

#ifndef _lsmodule_h
#define _lsmodule_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "jansson.h"

#include "loom/script/reflection/lsAssembly.h"
#include "loom/script/reflection/lsType.h"

namespace LS {
class Module {
    friend class ModuleWriter;
    friend class ModuleReader;
    friend class BinReader;

    utString fullyQualifiedName;
    utString name;

    utArray<Type *> types;

    Assembly *assembly;

public:

    const utString& getName()
    {
        return name;
    }

    inline Assembly *getAssembly() const
    {
        return assembly;
    }

    inline void setAssembly(Assembly *assembly)
    {
        this->assembly = assembly;
    }

    // get type by fully qualified type name
    Type *getType(const utString& typeName);

    //Type* getType(TypeId tid);

    void getTypes(utArray<Type *>& _types);

    void getPackageTypes(const utString& packageName, utArray<Type *>& types);

    Type *deserializeType(const char *json);

    static Module *create(Assembly *assembly, const utString& name);

    void addType(Type *type);
    void removeType(Type *type);
};
}
#endif
