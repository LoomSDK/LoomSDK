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
#include "loom/common/platform/platformStore.h"

#if LOOM_PLATFORM != LOOM_PLATFORM_ANDROID && LOOM_PLATFORM != LOOM_PLATFORM_IOS

// The NULL store.
void platform_storeInitialize(StoreEventCallback eventCallback)
{
}


int platform_storeAvailable()
{
    return 0;
}


const char *platform_storeProviderName()
{
    return "Null";
}


void platform_storeListProducts(const char *requestJson)
{
}


void platform_storeRequestPurchase(const char *identifier)
{
}
#endif
