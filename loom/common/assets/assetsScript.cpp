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


#include <string.h>
#include "loom/common/core/allocator.h"
#include "loom/common/core/log.h"
#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsScript.h"

#ifdef _MSC_VER
#define stricmp    _stricmp
#endif

#if LOOM_PLATFORM_IS_APPLE == 1 || ANDROID_NDK || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#define stricmp    strcasecmp //I feel dirty.
#endif

extern "C"  
{
  extern loom_allocator_t *gAssetAllocator;
}

static loom_logGroup_t gScriptAssetGroup = { "scriptAsset", 1 };

void loom_asset_registerScriptAsset()
{
   loom_asset_registerType(LATScript, loom_asset_scriptDeserializer, loom_asset_identifyScript);
}


int loom_asset_identifyScript(const char *extension)
{
    if (!stricmp(extension, "loom"))
    {
        return LATScript;
    }
    return 0;
}

void *loom_asset_scriptDeserializer( void *buffer, size_t bufferLen, LoomAssetCleanupCallback *dtor )
{
   loom_asset_script_t *script = (loom_asset_script_t *) lmAlloc(gAssetAllocator, sizeof(loom_asset_script_t));
   script->bits = (void*) lmAlloc(gAssetAllocator, bufferLen);
   memcpy(script->bits, buffer, bufferLen);
   script->length = bufferLen;
   return script;
}
