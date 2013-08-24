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

#ifndef _lsmodulewriter_h
#define _lsmodulewriter_h

#include "jansson.h"

#include "loom/common/utils/utString.h"

#include "loom/script/serialize/lsTypeWriter.h"

namespace LS {
class ModuleWriter {
    utString name;
    utString version;

    utArray<TypeWriter *> types;

    utArray<utString> dependencies;

public:

    void setName(const utString& name)
    {
        this->name = name;
    }

    void setVersion(const utString& version)
    {
        this->version = version;
    }

    void setDependencies(const utArray<utString>& deps)
    {
        this->dependencies = deps;
    }

    void addTypeWriter(TypeWriter *typeWriter)
    {
        types.push_back(typeWriter);
    }

    json_t *write();

    ModuleWriter()
    {
    }
};
}
#endif
