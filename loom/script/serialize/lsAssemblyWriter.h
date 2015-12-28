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

#ifndef _lsassemblywriter_h
#define _lsassemblywriter_h

#include "loom/script/serialize/lsModuleWriter.h"

namespace LS {
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

class AssemblyWriter {
    Assembly *assembly;

    utString name;
    utString version;
    utString uid;
    utString loomConfig;

    utArray<ModuleWriter *> modules;

    utArray<utString> assemblyPath;
    utArray<utString> references;

public:

    AssemblyWriter() : assembly(NULL) {}

    void setName(const utString& name)
    {
        this->name = name;
    }

    void setVersion(const utString& version)
    {
        this->version = version;
    }

    void setUniqueId(const utString& uid)
    {
        this->uid = uid;
    }

    void addAssemblyPath(const utString& path)
    {
        assemblyPath.push_back(path);
    }

    void addReference(const utString& reference)
    {
        references.push_back(reference);
    }

    void addModuleWriter(ModuleWriter *moduleWriter)
    {
        modules.push_back(moduleWriter);
    }

    void setAssembly(Assembly *assembly) { this->assembly = assembly; }

    void setLoomConfig(const utString& _loomConfig)
    {
        loomConfig = _loomConfig;
    }

    void writeToString(utString& out);

    void writeToFile(const utString& filename);
};
}
#endif
