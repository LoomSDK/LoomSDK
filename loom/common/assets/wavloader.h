#ifndef __wavloader__
#define __wavloader__

#include <stdint.h>

typedef struct
{
    uint16_t numChannels;
    uint32_t samplesPerSecond;
    uint16_t sampleSize;
    int32_t sampleDataSize;
} wav_info;

bool load_wav(const uint8_t* inData,
                  const int32_t inDataLen,
                  uint8_t* outData,
                  wav_info* outInfo);

#endif
