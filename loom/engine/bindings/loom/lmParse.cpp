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
#include "loom/common/platform/platformParse.h"

using namespace LS;


/// Script bindings to the native Parse API.
///
/// See Parse.ls for documentation on this API.
class Parse
{
public:
    static void initialize()
    {
        platform_parseInitialize();
    }
    
    static bool startUp(const char *appID, const char *clientKey)
    {
        return platform_startUp(appID, clientKey);
    }
	
	static const char* getInstallationID()
	{
		return platform_getInstallationID();
	}
	
	static const char* getInstallationObjectID()
	{
		return platform_getInstallationObjectID();
	}
	
	static void updateInstallationUserID(const char* userId)
	{
		platform_updateInstallationUserID(userId);
	}
};


static int registerLoomParse(lua_State *L)
{
    ///set up lua bindings
    beginPackage(L, "loom.platform")

        .beginClass<Parse>("Parse")

            .addStaticMethod("startUp", &Parse::startUp)
			.addStaticMethod("getInstallationID", &Parse::getInstallationID)
			.addStaticMethod("getInstallationObjectID", &Parse::getInstallationObjectID)
			.addStaticMethod("updateInstallationUserID", &Parse::updateInstallationUserID)

        .endClass()

    .endPackage();

    return 0;
}




void installLoomParse()
{
    LOOM_DECLARE_NATIVETYPE(Parse, registerLoomParse);
    Parse::initialize();
}
