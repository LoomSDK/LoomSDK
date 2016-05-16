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

#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "loom/common/core/allocator.h"
#include "loom/common/core/stringTable.h"
#include "loom/common/platform/platformThread.h"
#include "loom/common/platform/platform.h"

typedef struct stringTableEntry
{
    const char              *string;
    struct stringTableEntry *next;
} stringTableEntry_t;

#define csmTableSize    4027 // Biggest prime smaller than 4k.
static stringTableEntry_t *gTable[csmTableSize];
static MutexHandle        gTableMutex = NULL;

void stringtable_initialize()
{
    // Clear out the hash table.
    memset(gTable, 0, sizeof(stringTableEntry_t *) * csmTableSize);
    gTableMutex = loom_mutex_create();
}


static unsigned long hash(const char *str)
{
    // Courtesy of http://www.cse.yorku.ca/~oz/hash.html
    unsigned long hash_result = 5381;
    int           c;

    while ((c = *str++))
    {
        hash_result = ((hash_result << 5) + hash_result) + c; /* hash * 33 + c */
    }
    return hash_result;
}


static stringTableEntry_t *allocEntry(const char *str)
{
    size_t len;
    stringTableEntry_t *entry = (stringTableEntry_t *)lmAlloc(NULL, sizeof(stringTableEntry_t));

    entry->next = NULL;
    len = strlen(str);
    entry->string = (const char*)lmAlloc(NULL, len + 1);
    memcpy((char*)entry->string, str, len);
    ((char*)entry->string)[len] = '\0';

    return entry;
}


StringTableEntry stringtable_insert(const char *str)
{
    unsigned long      hash_result;
    stringTableEntry_t *walk  = NULL;
    StringTableEntry   result = NULL;
    int                bucket;

    // A NULL would cause a crash eventually
    if (str == NULL)
        str = "";

    // Hash the string.
    hash_result = hash(str);

    // Determine the hash table bucket.
    bucket = hash_result % csmTableSize;

    // TODO: Make this a readwrite lock, since most of the time we are just
    // traversing the stringtable to find existing data, not inserting.
    loom_mutex_lock(gTableMutex);

    // Walk the chain, if any.
    walk = gTable[bucket];

    // Empty bucket, easy case!
    if (!walk)
    {
        gTable[bucket] = allocEntry(str);
        assert(gTable[bucket]->string);
        result = gTable[bucket]->string;
        loom_mutex_unlock(gTableMutex);

        return result;
    }

    while (walk)
    {
        // Is it a match?
        if (strcmp(walk->string, str) == 0)
        {
            assert(walk->string);
            result = (StringTableEntry)walk->string;
            loom_mutex_unlock(gTableMutex);

            return result;
        }

        // Another one to check?
        if (walk->next != NULL)
        {
            walk = walk->next;
            continue;
        }

        break;
    }

    // No match. Chain 'er on.
    walk->next = allocEntry(str);
    assert(walk->next->string);
    result = walk->next->string;
    loom_mutex_unlock(gTableMutex);

    return result;
}
