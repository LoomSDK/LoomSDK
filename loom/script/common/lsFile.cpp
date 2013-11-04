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

#include "lsFile.h"
#include "lsError.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/allocator.h"
#include "utils/utStreams.h"

namespace LS {
static MapFileFunction   MapFileFunc   = NULL;
static UnmapFileFunction UnmapFileFunc = NULL;

loom_allocator_t *gScriptFileAllocator = NULL;
    
#define MAX_NOTES 8

struct FileNote
{
    char path[1024];
    void *ptr;
} notes[MAX_NOTES];

void LSFileInitialize(MapFileFunction mapFunc, UnmapFileFunction unmapFunc)
{
    MapFileFunc   = mapFunc;
    UnmapFileFunc = unmapFunc;
    for (int i = 0; i < MAX_NOTES; i++)
    {
        notes[i].ptr     = NULL;
        notes[i].path[0] = 0;
    }
}


void LSMapFile(const char *path, void **outPointer, long *outSize)
{
    *outSize    = 0;
    *outPointer = 0;

    if (MapFileFunc)
    {
        MapFileFunc(path, outPointer, outSize);
        return;
    }

    // fallback to utFileStream
    utFileStream fs;

    fs.open(path, utStream::SM_READ);

    int sz = fs.size();

    if (sz <= 0)
    {
        return;
    }

    // TODO: external memory API, woot
    char* buffer = (char *) lmAlloc(gScriptFileAllocator, sz);
    fs.read(buffer, sz);

    *outPointer = buffer;
    *outSize    = sz;

    // Note open file.
    bool foundSlot = false;
    for (int i = 0; i < MAX_NOTES; i++)
    {
        if (notes[i].ptr != NULL)
        {
            continue;
        }

        strcpy(notes[i].path, path);
        notes[i].ptr = buffer;
        foundSlot    = true;
        break;
    }

    lmAssert(foundSlot, "Too many open files in LSMapFile!");
}


void LSUnmapFile(const char *ptr)
{
    if (UnmapFileFunc)
    {
        UnmapFileFunc(ptr);
        return;
    }

    // TODO: external memory API, woot
    bool foundSlot = false;
    for (int i = 0; i < MAX_NOTES; i++)
    {
        if (notes[i].ptr == NULL)
        {
            continue;
        }

        if (strcmp(notes[i].path, ptr) != 0)
        {
            continue;
        }

        lmFree(gScriptFileAllocator, notes[i].ptr);
        notes[i].ptr = NULL;
        notes[i].path[0] = 0;
        foundSlot        = true;
        break;
    }

    lmAssert(foundSlot, "Could not find matching file to unmap in LSUnmapFile!");
}
}
