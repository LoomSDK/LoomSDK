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

#include "loom/common/assets/assets.h"

#include <cstring>

#ifdef _MSC_VER
#define stricmp    _stricmp
#endif

#if LOOM_PLATFORM_IS_APPLE == 1 || ANDROID_NDK || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#define stricmp    strcasecmp //I feel dirty.
#endif
 
 int loom_asset_identifyShader(const char *extension)
 {
     if (!stricmp(extension, "vert"))
     {
         return LATVertexShader;
     }
     if (!stricmp(extension, "vsh"))
     {
         return LATVertexShader;
     }
     if (!stricmp(extension, "frag"))
     {
         return LATFragmentShader;
     }
     if (!stricmp(extension, "fsh"))
     {
         return LATFragmentShader;
     }

     return 0;
 }

 void loom_asset_registerShaderAsset()
 {
     loom_asset_registerType(LATText, loom_asset_textDeserializer, loom_asset_identifyShader);
 }
 