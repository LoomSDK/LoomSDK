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

#include "loom/common/utils/utString.h"
#include "loom/script/common/lsError.h"
#include "loom/script/reflection/lsType.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/runtime/lsRuntime.h"

namespace LS {
void TemplateInfo::resolveTypes(LSLuaState *lstate)
{
    type = lstate->getType(fullTypeName.c_str());
    assert(type);
    for (UTsize i = 0; i < types.size(); i++)
    {
        types[i]->resolveTypes(lstate);
    }
}


int FieldInfo::setValue(lua_State *L)
{
    lua_pushnumber(L, ordinal);
    lua_pushvalue(L, 3);
    lua_settable(L, 2);

    return 0;
}


int FieldInfo::getValue(lua_State *L)
{
    lua_pushnumber(L, ordinal);
    lua_gettable(L, 2);
    return 1;
}
}
