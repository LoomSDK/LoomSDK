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
#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platform.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include "loom/common/platform/platformAndroidJni.h"

#include <jni.h>
#include <cstddef>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fts.h>
#include <limits.h>

extern "C" {
const char *platform_getWritablePath()
{
    static utString path;

    if (path.size())
    {
        return path.c_str();
    }

    path = LoomJni::getWritablePath();

    return path.c_str();
}

const char *platform_getSettingsPath()
{
    static utString path;

    if (path.size())
    {
        return path.c_str();
    }

    path = LoomJni::getSettingsPath();

    return path.c_str();
}

}
#endif
