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

#include "platformAdMob.h"
#include "platform.h"

#if LOOM_PLATFORM != LOOM_PLATFORM_IOS && LOOM_PLATFORM != LOOM_PLATFORM_ANDROID

loom_adMobHandle platform_adMobCreate(const char *publisherID, loom_adMobBannerSize size)
{
    return 0;
}


void platform_adMobShow(loom_adMobHandle handle)
{
}


void platform_adMobHide(loom_adMobHandle handle)
{
}


void platform_adMobDestroy(loom_adMobHandle handle)
{
}


void platform_adMobDestroyAll()
{
}


void platform_adMobSetDimensions(loom_adMobHandle handle, loom_adMobDimensions frame)
{
}


loom_adMobDimensions platform_adMobGetDimensions(loom_adMobHandle handle)
{
    loom_adMobDimensions frame;

    frame.x      = 0;
    frame.y      = 0;
    frame.width  = 0;
    frame.height = 0;
    return frame;
}


void platform_adMobShowInterstitial(loom_adMobHandle handle)
{
}


loom_adMobHandle platform_adMobCreateInterstitial(const char *publisherID, loom_adMobCallback callback, void *payload)
{
    return 0;
}


void platform_adMobDestroyInterstitial(loom_adMobHandle handle)
{
}
#endif
