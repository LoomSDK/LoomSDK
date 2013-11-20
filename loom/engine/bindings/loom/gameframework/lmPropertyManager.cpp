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

#include "loom/script/loomscript.h"

using namespace LS;

namespace Loom {
class PropertyManager {
public:

    static int applyBindings(lua_State *L)
    {
        // Component "this" at stack 1
        // encoded property vector at stack 2

        // get the encoded property length
        int numbindings = lsr_vector_get_length(L, 2);

        // get the vector table
        lua_rawgeti(L, 2, LSINDEXVECTOR);
        // snap it into stack 3
        lua_replace(L, 2);

        int idx = 0;

        while (idx < numbindings)
        {
            // the component we are getting from
            lua_rawgeti(L, 2, idx++);

            // the number of lookups
            lua_rawgeti(L, 2, idx++);
            int nprops = (int)lua_tonumber(L, -1);
            lua_pop(L, 1);

            int ordinal;

            // run through the lookups
            while (nprops--)
            {
                lua_rawgeti(L, 2, idx++);

                ordinal = (int)lua_tonumber(L, -1);

                lmAssert(ordinal, "ordinal was not encoded properly");

                // If we're a field (encoded as positive ordinal), look it up in the table
                if (ordinal > 0)
                {
                    // we have a null in the property chain, exit
                    if (lua_isnil(L, -2))
                    {
                        return 0;
                    }

                    lua_gettable(L, -2);
                    lua_replace(L, -2);
                }
                else
                {
                    // we have a null in the property chain, exit
                    if (lua_isnil(L, -2))
                    {
                        return 0;
                    }

                    // we're a property, so get it via ordinal
                    // and call
                    lua_pop(L, 1);
                    lua_pushnumber(L, -ordinal);

                    lua_gettable(L, -2);
                    lua_call(L, 0, 1);
                    lua_replace(L, -2);
                }
            }

            // get the setter
            lua_rawgeti(L, 2, idx++);

            ordinal = (int)lua_tonumber(L, -1);

            lmAssert(ordinal, "ordinal was not encoded properly");

            // check whether we are a property setter
            if (ordinal < 0)
            {
                lua_pop(L, 1);
                lua_pushnumber(L, -ordinal);

                lua_gettable(L, 1);
                lua_pushvalue(L, -2);
                lua_call(L, 1, 0);
            }
            else
            {
                // set in the field
                lua_pushvalue(L, -2);
                lua_settable(L, 1);
            }
        }

        return 0;
    }
};

static int registerLoomPropertyManager(lua_State *L)
{
    beginPackage(L, "loom.gameframework")

       .beginClass<PropertyManager>("PropertyManager")

       .addStaticLuaFunction("applyBindings", &PropertyManager::applyBindings)

       .endClass()

       .endPackage();

    return 0;
}
}

void installLoomPropertyManager()
{
    LOOM_DECLARE_NATIVETYPE(Loom::PropertyManager, Loom::registerLoomPropertyManager);
}
