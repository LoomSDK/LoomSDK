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

#ifndef _lstypereader_h
#define _lstypereader_h

#include "jansson.h"

#include "loom/script/reflection/lsType.h"

namespace LS {
class TypeReader {
    static void declareClass(Type *type, json_t *classJSON);

    static void deserializeClass(Type *type, json_t *classJSON);

public:

    static Type *declareType(Module *module, json_t *json);

    static Type *deserialize(Module *module, json_t *json);
};
}
#endif
