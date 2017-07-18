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
#include "loom/common/platform/platformTeak.h"

#if !LOOM_ALLOW_FACEBOOK || (LOOM_PLATFORM != LOOM_PLATFORM_ANDROID)

///The NULL Teak implementation

void platform_teakInitialize(AuthStatusCallback authStatusCB)
{
}

bool platform_isTeakActive()
{
	return false;
}

void platform_setAccessToken(const char *fbAccessToken)
{
}

int platform_getStatus()
{
    return -1;
}

bool platform_postAchievement(const char *achievementId)
{
    return false;
}

bool platform_postHighScore(int score)
{
    return false;
}

bool platform_postAction(const char *actionId, const char *objectInstanceId)
{
    return false;
}

bool platform_postActionWithProperties(const char *actionId, const char *objectInstanceId, const char *jsonProperties)
{
    return false;
}

#endif
