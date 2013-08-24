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

#ifndef _ls_alias_h
#define _ls_alias_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

namespace LS {
class Aliases {
private:

    static utHashTable<utHashedString, utString> aliases;
    static bool initialized;

public:


    static void initialize();

    static void addAlias(const utString& source, const utString& destination)
    {
        aliases.insert(source, destination);
    }

    static const utString& getAlias(const utString& source)
    {
        static utString none("");

        utString *alias = aliases.get(source);

        if (!alias)
        {
            return none;
        }

        return *alias;
    }
};
}
#endif
