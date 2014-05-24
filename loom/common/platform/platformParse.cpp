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

#include "loom/common/platform/platform.h"

#if LOOM_PLATFORM != LOOM_PLATFORM_ANDROID && LOOM_PLATFORM != LOOM_PLATFORM_IOS

///Null Parse class for all non-Mobile platforms


///initializes the data for the Parse class
void platform_parseInitialize()
{
}

///starts up the Parse service 
bool platform_startUp(const char *appID, const char *clientKey)
{
    return false;
}

///Returns the parse installation ID
const char* platform_getInstallationID()
{
    return "";
}

///Returns the parse installation object's objectId
const char* platform_getInstallationObjectID()
{
    return "";
}

///Updates the custom userId property on the installation
void platform_updateInstallationUserID(const char* userId)
{
}

#endif //LOOM_PLATFORM != LOOM_PLATFORM_ANDROID && LOOM_PLATFORM != LOOM_PLATFORM_IOS

