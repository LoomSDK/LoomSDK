/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013, 2014, 2015
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#include "loom/common/core/allocator.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/platform/platformFont.h"

lmDefineLogGroup(gFontLogGroup, "PlatformFont", 1, LoomLogInfo);


typedef struct OffsetTable {
    uint32_t version;
    uint16_t numTables;
    uint16_t searchRange;
    uint16_t entrySelector;
    uint16_t rangeShift;
} OffsetTable;

typedef struct TableRecord {
    uint32_t tag;
    uint32_t checksum;
    uint32_t offset;
    uint32_t length;
} TableRecord;

uint32_t CalcTableChecksum(uint32_t *table, uint32_t numberOfBytesInTable)
{
    uint32_t sum = 0;
    uint32_t nLongs = (numberOfBytesInTable + 3) / 4;
    while (nLongs-- > 0)
        sum += *table++;
    return sum;
}

int platform_fontSystemFontFromName(const char *name, void** mem, unsigned int* size) {
    CFStringRef cfName = CFStringCreateWithCString(NULL, name, kCFStringEncodingASCII);
    CGFontRef font = CGFontCreateWithFontName(cfName);
    CFRelease(cfName);
    
    if (font == NULL) {
        return 0;
    }
    
    CFArrayRef tags = CGFontCopyTableTags(font);
    CFIndex tableNum = CFArrayGetCount(tags);
    CFIndex* tableLengths = (CFIndex*)lmCalloc(NULL, tableNum, sizeof(CFIndex));
    CFIndex totalLength = sizeof(OffsetTable) + tableNum * sizeof(TableRecord);
    
    bool containsCFF = false;
    for (CFIndex i = 0; i < tableNum; i++) {
        uint32_t tag = (uint32_t)CFArrayGetValueAtIndex(tags, i);
        if (tag == 'CFF ') containsCFF = true;
        CFDataRef table = CGFontCopyTableForTag(font, tag);
        lmAssert(table != NULL, "Unable to copy table for tag %x", tag);
        CFIndex tableLength = CFDataGetLength(table);
        CFRelease(table);
        
        tableLengths[i] = tableLength;
        
        // Align to 4 bytes
        totalLength += (tableLength + 3) & ~3;
    }
    
    void* data = lmCalloc(NULL, 1, totalLength);
    char* cur = (char*)data;
    
    uint16_t entrySelector = 0;
    uint16_t searchRange = 1;
    while (searchRange < tableNum/2) {
        entrySelector++;
        searchRange <<= 1;
    }
    searchRange <<= 4;
    
    uint16_t rangeShift = (tableNum << 4) - searchRange;
    
    OffsetTable* offsets = (OffsetTable*)cur;
    offsets->version = containsCFF ? 'OTTO' : CFSwapInt16HostToBig(1);
    offsets->numTables = CFSwapInt16HostToBig(tableNum);
    offsets->searchRange = CFSwapInt16HostToBig(searchRange);
    offsets->entrySelector = CFSwapInt16HostToBig(entrySelector);
    offsets->rangeShift = CFSwapInt16HostToBig(rangeShift);
    
    cur += sizeof(OffsetTable);
    
    TableRecord* record = (TableRecord*)cur;
    cur += tableNum * sizeof(TableRecord);
    
    for (CFIndex i = 0; i < tableNum; i++) {
        uint32_t tag = (uint32_t)CFArrayGetValueAtIndex(tags, i);
        CFDataRef table = CGFontCopyTableForTag(font, tag);
        CFIndex tableLength = CFDataGetLength(table);
        memcpy(cur, CFDataGetBytePtr(table), tableLength);
        CFRelease(table);
        
        record->tag = CFSwapInt32HostToBig(tag);
        record->checksum = CFSwapInt32HostToBig(CalcTableChecksum((uint32_t*)cur, tableLength));
        record->offset = CFSwapInt32HostToBig(cur - (char*)data);
        record->length = CFSwapInt32HostToBig(tableLength);
        
        // Aligned advance
        cur += (tableLength + 3) & ~3;
        record++;
    }
    
    lmFree(NULL, tableLengths);
    
    CGFontRelease(font);
    
    *size = (unsigned int)totalLength;
    *mem = data;
    return 1;
}