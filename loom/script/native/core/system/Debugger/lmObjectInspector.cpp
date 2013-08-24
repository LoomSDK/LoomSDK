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

#include "jansson.h"

namespace LS {
/*
 * ObjectInspector take a source object on the Lua stack and returns
 * a nicely formatted json dump of its type/value + field member values
 */
class ObjectInspector
{
public:

    static int inspect(lua_State *L)
    {
        json_t *jobject = json_object();

        Type *type = lsr_gettype(L, 1);

        json_object_set_new(jobject, "type", json_string(type->getFullName().c_str()));
        json_object_set_new(jobject, "value", json_string(lsr_objecttostring(L, 1)));


        MemberTypes memberTypes;
        memberTypes.field = true;
        utArray<MemberInfo *> members;
        type->findMembers(memberTypes, members, true);

        json_t *fields = NULL;

        if (members.size())
        {
            fields = json_object();
            json_object_set(jobject, "fields", fields);
        }

        for (UTsize i = 0; i < members.size(); i++)
        {
            MemberInfo *member = members.at(i);

            lua_pushnumber(L, member->getOrdinal());
            lua_gettable(L, 1);

            json_object_set_new(fields, member->getName(), json_string(lsr_objecttostring(L, -1)));

            lua_pop(L, 1);
        }

        lua_pushstring(L, json_dumps(jobject, JSON_INDENT(4)));

        json_decref(jobject);

        return 1;
    }
};

static int registerSystemDebugger(lua_State *L)
{
    beginPackage(L, "system.debugger")

       .beginClass<ObjectInspector> ("ObjectInspector")

       .addStaticLuaFunction("inspect", &ObjectInspector::inspect)

       .endClass()

       .endPackage();

    return 0;
}
}

void installSystemDebugger()
{
    NativeInterface::registerNativeType<LS::ObjectInspector>(registerSystemDebugger);
}
