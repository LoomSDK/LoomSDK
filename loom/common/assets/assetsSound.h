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


#ifndef _ASSETS_ASSETSSOUND_H_
#define _ASSETS_ASSETSSOUND_H_

#ifdef __cplusplus
extern "C" {
#endif

#define LATSound    LOOM_FOURCC('S', 'N', 'D', 1)

typedef struct loom_asset_sound
{
	int channels, bytesPerSample;
	int sampleCount, bufferSize;
    void *buffer;
} loom_asset_sound_t;

void loom_asset_registerSoundAsset();
int loom_asset_identifySound(const char *path);
void *loom_asset_soundDeserializer(void *buffer, size_t bufferLen, LoomAssetCleanupCallback *dtor);

#ifdef __cplusplus
};
#endif
#endif
