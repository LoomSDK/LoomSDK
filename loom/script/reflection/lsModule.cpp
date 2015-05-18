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

#include "loom/script/reflection/lsModule.h"
#include "loom/script/common/lsError.h"
#include "loom/script/serialize/lsTypeReader.h"

namespace LS {
Module *Module::create(Assembly *assembly, const utString& name)
{
    Module *m = lmNew(NULL) Module();

    m->name = name;

    assembly->registerModule(m);

    return m;
}


Type *Module::getType(const utString& typeName)
{
    for (UTsize i = 0; i < types.size(); i++)
    {
        Type *type = types.at(i);
        if (type->fullName == typeName)
        {
            return type;
        }
    }

    return NULL;
}


void Module::getTypes(utArray<Type *>& _types)
{
    for (UTsize i = 0; i < types.size(); i++)
    {
        _types.push_back(types.at(i));
    }
}


void Module::getPackageTypes(const utString&  packageName,
                             utArray<Type *>& types)
{
    for (UTsize i = 0; i < this->types.size(); i++)
    {
        Type *type = this->types.at(i);
        if (type->getPackageName() == packageName)
        {
            types.push_back(type);
        }
    }
}


void Module::addType(Type *type)
{
    Type *check = getType(type->getFullName());

    if (check)
    {
        LSError("Module already contains type:%s", type->getFullName().c_str());
    }

    type->module = this;
    types.push_back(type);
}
}
