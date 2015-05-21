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

#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/common/utils/utString.h"


using namespace LS;


/// Script bindings to the native ModestMaps API.
///
/// See ModestMaps.ls for documentation on this API.
class ModestMaps
{
public:

    static utString tileKey(int col, int row, int zoom)
    {
        char key[256];
        sprintf(key, "%c:%i:%i", (char)(((int)'a')+zoom), col, row);
        return utString(key);
    }

};



static int registerLoomModestMaps(lua_State *L)
{
    ///set up lua bindings
    beginPackage(L, "loom.modestmaps")

        .beginClass<ModestMaps>("ModestMaps")

            .addStaticMethod("tileKey", &ModestMaps::tileKey)

        .endClass()

    .endPackage();

    return 0;
}


void installLoomModestMaps()
{
    LOOM_DECLARE_NATIVETYPE(ModestMaps, registerLoomModestMaps);
}
