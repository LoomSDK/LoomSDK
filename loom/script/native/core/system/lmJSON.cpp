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

#include "loom/common/utils/json.h"
#include "loom/script/loomscript.h"

static int registerSystemJSON(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<JSON> ("JSON")
       .addConstructor<void (*)(void)>()
       .addMethod("initObject", &JSON::initObject)
       .addMethod("initArray", &JSON::initArray)
       .addMethod("loadString", &JSON::loadString)
       .addMethod("serialize", &JSON::serialize)

       .addMethod("getError", &JSON::getError)
       .addMethod("getJSONType", &JSON::getJSONType)
       .addMethod("getObjectJSONType", &JSON::getObjectJSONType)
       .addMethod("getArrayJSONType", &JSON::getArrayJSONType)
	   
       .addMethod("getLongLongAsString", &JSON::getLongLongAsString)
       .addMethod("getInteger", &JSON::getInteger)
       .addMethod("setInteger", &JSON::setInteger)
       .addMethod("getFloat", &JSON::getFloat)
       .addMethod("setFloat", &JSON::setFloat)
       .addMethod("getNumber", &JSON::getNumber)
       .addMethod("setNumber", &JSON::setNumber)
       .addMethod("getString", &JSON::getString)
       .addMethod("setString", &JSON::setString)
       .addMethod("getBoolean", &JSON::getBoolean)
       .addMethod("setBoolean", &JSON::setBoolean)
       .addMethod("getObject", &JSON::getObject)
       .addMethod("setObject", &JSON::setObject)
       .addMethod("getArray", &JSON::getArray)
       .addMethod("setArray", &JSON::setArray)

       .addMethod("isObject", &JSON::isObject)
       .addMethod("getObjectFirstKey", &JSON::getObjectFirstKey)
       .addMethod("getObjectNextKey", &JSON::getObjectNextKey)

       .addMethod("isArray", &JSON::isArray)
       .addMethod("getArrayCount", &JSON::getArrayCount)

       .addMethod("getArrayBoolean", &JSON::getArrayBoolean)
       .addMethod("setArrayBoolean", &JSON::setArrayBoolean)

       .addMethod("getArrayInteger", &JSON::getArrayInteger)
       .addMethod("setArrayInteger", &JSON::setArrayInteger)

       .addMethod("getArrayFloat", &JSON::getArrayFloat)
       .addMethod("setArrayFloat", &JSON::setArrayFloat)

       .addMethod("getArrayNumber", &JSON::getArrayNumber)
       .addMethod("setArrayNumber", &JSON::setArrayNumber)

       .addMethod("getArrayString", &JSON::getArrayString)
       .addMethod("setArrayString", &JSON::setArrayString)

       .addMethod("getArrayObject", &JSON::getArrayObject)
       .addMethod("setArrayObject", &JSON::setArrayObject)

       .addMethod("getArrayArray", &JSON::getArrayArray)
       .addMethod("setArrayArray", &JSON::setArrayArray)


       .endClass()
       .endPackage();

    return 0;
}


void installSystemJSON()
{
    NativeInterface::registerManagedNativeType<JSON>(registerSystemJSON);
}
