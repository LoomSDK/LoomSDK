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
#include "loom/common/assets/assetsSound.h"

#include "stb_vorbis.h"
#include "minimp3.h"

#ifdef _MSC_VER
#define stricmp    _stricmp
#endif

#if LOOM_PLATFORM_IS_APPLE == 1 || ANDROID_NDK || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#define stricmp    strcasecmp //I feel dirty.
#endif

extern "C" loom_allocator_t *gAssetAllocator;
static loom_logGroup_t gSoundAssetGroup = { "soundAsset", 1 };

void loom_asset_registerSoundAsset()
{
   loom_asset_registerType(LATSound, loom_asset_soundDeserializer, loom_asset_identifySound);
}


int loom_asset_identifySound(const char *extension)
{
    if (!stricmp(extension, "ogg"))
    {
        return LATSound;
    }
    if (!stricmp(extension, "mp3"))
    {
        return LATSound;
    }

    // TODO: Wav

    return 0;
}

void loom_asset_soundDtor(void *bits)
{
    loom_asset_sound_t *sound = (loom_asset_sound_t*)bits;
    lmFree(gAssetAllocator, sound->buffer);
    lmFree(gAssetAllocator, bits);
}

void *loom_asset_soundDeserializer( void *buffer, size_t bufferLen, LoomAssetCleanupCallback *dtor )
{
   loom_asset_sound_t *sound = (loom_asset_sound_t*)lmAlloc(gAssetAllocator, sizeof(loom_asset_sound_t));
   unsigned char *charBuff = (unsigned char *)buffer;

    // Look for magic header in buffer.
    if(charBuff[0] == 0x4f 
        && charBuff[1] == 0x67
        && charBuff[2] == 0x67
        && charBuff[3] == 0x53)
    {
        // It's an Ogg, assume vorbis and throw it to stb_vorbis.
        int channels = 0;
        short *outputBuffer = NULL;
        int sampleCount = stb_vorbis_decode_memory(charBuff, bufferLen, &channels, &outputBuffer);
        if(sampleCount < 0)
        {
            lmLogError(gSoundAssetGroup, "Failed to decode Ogg Vorbis!");
            return NULL;
        }

        sound->channels = channels;
        sound->bytesPerSample = 2;
        sound->sampleCount = sampleCount;
        sound->bufferSize = sampleCount * channels * 2;

        // We can skip this if we get clever about allocations in stbv.
        sound->buffer = lmAlloc(gAssetAllocator, sound->bufferSize);
        memcpy(sound->buffer, outputBuffer, sound->bufferSize);

        free(outputBuffer);
    }
    else if(charBuff[0] == 0x49
        && charBuff[1] == 0x44
        && charBuff[2] == 0x33)
    {
        // It's an MP3, y'all!
        short *outBuffer = (short*)lmAlloc(gAssetAllocator, MP3_MAX_SAMPLES_PER_FRAME * 2);
        mp3_info_t mp3Info;

        // Decode once to get total size.
        int totalBytes = 0;
        int bytesRead = 0, bytesLeft = bufferLen;

        mp3_decoder_t decmp3 = mp3_create();
        for(;;)
        {
            int bytesDecoded = mp3_decode(decmp3, charBuff + bytesRead, bytesLeft, outBuffer, &mp3Info);
            bytesRead += bytesDecoded;
            bytesLeft -= bytesDecoded;
            totalBytes += mp3Info.audio_bytes;
            if(bytesDecoded > 0)
                continue;

            // Clean up.
            mp3_done(decmp3);
            break;
        }

        // Great, set up the sound asset.
        // TODO: Warn about non 44.1khz mp3s.
        sound->channels = mp3Info.channels;
        sound->bytesPerSample = 2;
        sound->sampleCount = totalBytes / sound->bytesPerSample;
        sound->bufferSize = sound->channels * sound->bytesPerSample * sound->sampleCount;
        sound->buffer = lmAlloc(gAssetAllocator, sound->bufferSize);

        // Decode again to get real samples.        
        decmp3 = mp3_create();
        bytesRead = 0; bytesLeft = bufferLen;
        int curBufferOffset = 0;
        for(;;)
        {
            int bytesDecoded = mp3_decode(decmp3, charBuff + bytesRead, bytesLeft, outBuffer, &mp3Info);
            bytesRead += bytesDecoded;
            bytesLeft -= bytesDecoded;

            memcpy(((unsigned char*)sound->buffer) + curBufferOffset, outBuffer, mp3Info.audio_bytes);
            curBufferOffset += mp3Info.audio_bytes;

            if(bytesDecoded > 0)
                continue;

            // Clean up.
            mp3_done(decmp3);
            break;
        }

        // Awesome, all set!
        lmFree(gAssetAllocator, outBuffer);
    }
    else
    {
        lmLogError(gSoundAssetGroup, "Failed to identify sound buffer by magic number!");
        return 0;
    }

   *dtor = loom_asset_soundDtor;
   if(!sound->buffer)
   {
      lmLogError(gSoundAssetGroup, "Image load failed due to this cryptic reason: %s", "(unknown)");
      lmFree(gAssetAllocator, sound);
      return 0;
   }

   lmLogError(gSoundAssetGroup, "Allocated %d bytes for a sound!", sound->bufferSize);
   return sound;
}
