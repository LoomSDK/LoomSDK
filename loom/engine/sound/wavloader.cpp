#include <string.h>
#include "wavloader.h"
#include "loom/common/core/log.h"
#include "loom/common/utils/utEndian.h"

extern loom_logGroup_t gLoomSoundLogGroup;

typedef struct
{
    char chunkId[4];
    uint32_t chunkDataSize;
} chunk_header;

typedef struct
{
    chunk_header header;
    char riffType[4];
} riff_header;

typedef struct
{
    uint16_t compressionType;
    uint16_t numChannels;
    uint32_t sampleRate;
    uint32_t avgBytesPerSecond;
    uint16_t blockAlign;
    uint16_t bitsPerSample;
} fmt_chunk;

bool load_wav(const uint8_t* inData,
                  const int32_t inDataLen,
                  uint8_t* outData,
                  wav_info* outInfo)
{
    if (inData == NULL)
    {
        lmLogDebug(gLoomSoundLogGroup, "No input data passed to wav loader");
        return false;
    }
    
    const uint8_t* cursor = inData;
    
    riff_header* riff = (riff_header*)cursor;
    if (riff->header.chunkId[0] != 'R' ||
        riff->header.chunkId[1] != 'I' ||
        riff->header.chunkId[2] != 'F' ||
        riff->header.chunkId[3] != 'F')
    {
        lmLogDebug(gLoomSoundLogGroup, "Bad wav file format");
        return false;
    }
    
    if (riff->riffType[0] != 'W' ||
        riff->riffType[1] != 'A' ||
        riff->riffType[2] != 'V' ||
        riff->riffType[3] != 'E')
    {
        lmLogDebug(gLoomSoundLogGroup, "Bad wav file format");
        return false;
    }
    
    riff->header.chunkDataSize = convertLEndianToHost(riff->header.chunkDataSize);
    
    if (inDataLen < sizeof(chunk_header) + riff->header.chunkDataSize)
    {
        lmLogDebug(gLoomSoundLogGroup, "Not enough data in wav buffer");
    }
    
    cursor += sizeof(riff_header);
    
    while (cursor < inData + inDataLen)
    {
        chunk_header* curChunkHeader = (chunk_header*)cursor;
        curChunkHeader->chunkDataSize = convertLEndianToHost(curChunkHeader->chunkDataSize);
        
        if (curChunkHeader->chunkId[0] == 'f' &&
            curChunkHeader->chunkId[1] == 'm' &&
            curChunkHeader->chunkId[2] == 't' &&
            curChunkHeader->chunkId[3] == ' ')
        {
            fmt_chunk* fmt = (fmt_chunk*)(cursor + sizeof(chunk_header));
            if (convertLEndianToHost(fmt->compressionType) != 0x01)
            {
                // This loader only supports PCM (which should be the most common case)
                lmLogDebug(gLoomSoundLogGroup, "Unsupported wav compression type");
                return false;
            }
            
            if (outInfo)
            {
                outInfo->numChannels = convertLEndianToHost(fmt->numChannels);
                outInfo->samplesPerSecond = convertLEndianToHost(fmt->sampleRate);
                outInfo->sampleSize = convertLEndianToHost(fmt->bitsPerSample);
            }
        }
        else if (curChunkHeader->chunkId[0] == 'd' &&
                 curChunkHeader->chunkId[1] == 'a' &&
                 curChunkHeader->chunkId[2] == 't' &&
                 curChunkHeader->chunkId[3] == 'a')
        {
            if (outInfo)
            {
                outInfo->sampleDataSize = curChunkHeader->chunkDataSize;
            }
            
            if (outData != NULL)
            {
                memcpy(outData, cursor + sizeof(chunk_header), curChunkHeader->chunkDataSize);
            }
        }
        
        cursor += sizeof(chunk_header) + curChunkHeader->chunkDataSize;
    }
    
    return true;
}