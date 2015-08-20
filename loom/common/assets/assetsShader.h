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
 
 #ifndef _ASSETS_ASSETSSHADER_H_
 #define _ASSETS_ASSETSSHADER_H_
 
 // For now, a shader asset is simply text, no special type needed.
 
 void loom_asset_registerShaderAsset();
 int loom_asset_identifyShader(const char *path);
 void *loom_asset_shaderDeserializer(void *buffer, size_t bufferLen, LoomAssetCleanupCallback *dtor);
 
 #endif
 