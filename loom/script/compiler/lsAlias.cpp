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

#include "loom/script/compiler/lsAlias.h"

namespace LS {
utHashTable<utHashedString, utString> Aliases::aliases;
bool Aliases::initialized = false;

void Aliases::initialize()
{
    if (initialized)
    {
        return;
    }

    initialized = true;

    addAlias("byte", "Number");
    addAlias("char", "Number");
    addAlias("short", "Number");
    addAlias("ushort", "Number");
    addAlias("long", "Number");
    addAlias("double", "Number");
    addAlias("float", "Number");
    addAlias("int", "Number");
    addAlias("uint", "Number");
    addAlias("string", "String");
    addAlias("boolean", "Boolean");
    addAlias("*", "Object");
}
}
