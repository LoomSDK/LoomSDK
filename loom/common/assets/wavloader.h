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

#ifndef _ASSETS_WAVLOADER_H_
#define _ASSETS_WAVLOADER_H_

#include <stdint.h>

typedef struct
{
    uint16_t numChannels;
    uint32_t samplesPerSecond;
    uint16_t sampleSize;
    int32_t sampleDataSize;
} wav_info;

/* This function takes raw file data and it's length. That data is parsed as WAV
 * and results set to outData and outInfo (if not NULL).
 *
 * The correct amount of memory needed for outData can be calculated by calling
 * this function with outData as NULL and outInfo will contain the needed size in
 * sampleDataSize. Then this function can be called again (optinally with outInfo
 * as NULL). 
 *
 * This WAV parser currently only supports 8 and 16 bit PCM formats.
 */
bool load_wav(const uint8_t* inData,
              const int32_t inDataLen,
              uint8_t* outData,
              wav_info* outInfo);

#endif
