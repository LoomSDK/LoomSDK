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

#ifndef _PLATFORM_PLATFORMADMOB_H_
#define _PLATFORM_PLATFORMADMOB_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef int   loom_adMobHandle;

typedef enum
{
    ADMOB_BANNER_SIZE_SMART_LANDSCAPE    = 0,
    ADMOB_BANNER_SIZE_SMART_PORTRAIT     = 1,
    ADMOB_BANNER_SIZE_STANDARD           = 2,
    ADMOB_BANNER_SIZE_TABLET_MEDIUM      = 3,
    ADMOB_BANNER_SIZE_TABLET_FULL        = 4,
    ADMOB_BANNER_SIZE_TABLET_LEADERBOARD = 5
} loom_adMobBannerSize;

typedef enum
{
    ADMOB_AD_RECEIVED = 0,
    ADMOB_AD_ERROR    = 1
} loom_adMobCallbackType;

typedef void (*loom_adMobCallback)(void *payload, loom_adMobCallbackType callbackType, const char *data);

typedef struct
{
    int x;
    int y;
    int width;
    int height;
} loom_adMobDimensions;

void platform_adMobInitalize(const char*publisherID);
loom_adMobHandle platform_adMobCreate(const char *adUnitId, loom_adMobCallback callback, void *payload, loom_adMobBannerSize size);

loom_adMobHandle platform_adMobCreateInterstitial(const char *adUnitId, loom_adMobCallback callback, void *payload);
void platform_adMobLoadInterstitial(loom_adMobHandle handle);
void platform_adMobShowInterstitial(loom_adMobHandle handle);
void platform_adMobDestroyInterstitial(loom_adMobHandle handle);

void platform_adMobLoad(loom_adMobHandle handle);
void platform_adMobShow(loom_adMobHandle handle);
void platform_adMobHide(loom_adMobHandle handle);
void platform_adMobDestroy(loom_adMobHandle handle);
void platform_adMobDestroyAll();
void platform_adMobSetDimensions(loom_adMobHandle handle, loom_adMobDimensions frame);
loom_adMobDimensions platform_adMobGetDimensions(loom_adMobHandle handle);

#ifdef __cplusplus
}
#endif
#endif
