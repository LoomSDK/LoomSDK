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

#include <stdio.h>
#include "loom/common/core/assert.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/log.h"
#include "loom/common/core/stringTable.h"
#include "loom/common/platform/platformIO.h"
#include "loom/common/platform/platformDisplay.h"
#include "loom/common/platform/platformThread.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
AAssetManager *gAssetManager = NULL;
#endif

#if LOOM_PLATFORM_IS_APPLE == 1
#include <ftw.h>
#include <sys/stat.h>
#include "loom/common/platform/platformFileIOS.h"
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#include "loom/common/platform/platformFileAndroid.h"
#include <sys/stat.h>
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#include <ftw.h>
#include <sys/stat.h>
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include <windows.h>
#define STRSAFE_NO_DEPRECATE    // We still want to use strcpy and others.
#include <strsafe.h>
#include <sys/stat.h>
#endif

// A low but arbitrary number of concurrent file mappings is allowed.
//
// If you exceed this, ask yourself - why am I not closing my mappings? Note that
// if you enable the ioLogGroup (below), you will see a dump of all the open
// file mappings - this should give you a clear path to find the culprit who is
// leaving all the mappings open.
#define LOOM_MAX_FILEMAPPINGS    32

typedef struct loom_filemapping   loom_filemapping_t;

typedef void (*loom_filemapping_cleaner_t)(loom_filemapping_t *);

struct loom_filemapping
{
    // Might not be original requested path if we rewrote it to look elsewhere.
    StringTableEntry           path;
    void                       *mapping;
    void                       *payload;
    loom_filemapping_cleaner_t dtor;
}
gFileMappings[LOOM_MAX_FILEMAPPINGS];

static loom_allocator_t *fileMappingAllocator = NULL;
static loom_logGroup_t  ioLogGroup            = { "io", 0 };

static void ensureStartedUp()
{
    if (fileMappingAllocator)
    {
        return;
    }

    fileMappingAllocator = loom_allocator_initializeTrackerProxyAllocator(NULL);
}


static void dumpMappings()
{
    int i = 0;

    lmLog(ioLogGroup, "Dumping %d file mappings:", LOOM_MAX_FILEMAPPINGS);

    for (i = 0; i < LOOM_MAX_FILEMAPPINGS; i++)
    {
        if (gFileMappings[i].mapping == NULL)
        {
            lmLog(ioLogGroup, "   %3d NULL", i);
            continue;
        }

        lmLog(ioLogGroup, "   %3d mapping=%8x dtor=%8x path=%s",
              i,
              gFileMappings[i].mapping,
              gFileMappings[i].dtor,
              gFileMappings[i].path);
    }
}


static void registerMapping(const char *path, void *ptr, loom_filemapping_cleaner_t cleaner, void *payload)
{
    int i;

    lmAssert(ptr, "Cannot map file with no ptr!");

    for (i = 0; i < LOOM_MAX_FILEMAPPINGS; i++)
    {
        if (gFileMappings[i].mapping != NULL)
        {
            continue;
        }

        gFileMappings[i].path    = stringtable_insert(path);
        gFileMappings[i].mapping = ptr;
        gFileMappings[i].dtor    = cleaner;
        gFileMappings[i].payload = payload;
        return;
    }

    dumpMappings();

    lmAssert(0, "Ran out of file mappings!");
}


static void mappingCleaner_free(loom_filemapping_t *mapping)
{
    lmFree(mapping->payload, mapping->mapping);
}


#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
static void androidCleaner_free(loom_filemapping_t *mapping)
{
    AAsset_close((AAsset *)mapping->payload);
}
#endif

int platform_mapFileExists(const char *path)
{
    FILE *f;

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
    // Variables for the android path.
    AAsset     *asset    = NULL;
    AAssetDir  *assetDir = NULL;
    const char *dirName;
#endif

#if LOOM_PLATFORM_IS_APPLE == 1
    char inBundlePath[2048];
#endif

    // remove any local path qualifier "./"
    if ((path[0] == '.') && (path[1] == '/'))
    {
        path += 2;
    }

    // Verify our dependents are good.
    ensureStartedUp();

    // Try opening it with fopen.
    f = fopen(path, "rb");
    if (f)
    {
        fclose(f);

        // Great, all done!
        return 1;
    }

#if LOOM_PLATFORM_IS_APPLE == 1
    // If we're not looking in the app bundle already, try looking in there.
    if (strstr(path, platform_getResourceDirectory()) == NULL)
    {
        sprintf(inBundlePath, "%s/%s", platform_getResourceDirectory(), path);
        if (platform_mapFileExists(inBundlePath))
        {
            return 1;
        }
    }
#endif

    // If we get here, then we need to try another strategy.
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
    lmAssert(gAssetManager, "No AssetManager present!");

    if (asset = AAssetManager_open(gAssetManager, path, AASSET_MODE_UNKNOWN))
    {
        AAsset_close(asset);
        return 1;
    }
#endif

    return 0;
}


int platform_mapFile(const char *path, void **outPointer, long *outSize)
{
    FILE *f;
    long size;

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
    // Variables for the android path.
    AAsset     *asset    = NULL;
    AAssetDir  *assetDir = NULL;
    const char *dirName;
#endif

#if LOOM_PLATFORM_IS_APPLE == 1
    char inBundlePath[2048];
#endif

    // remove any local path qualifier "./"
    if ((path[0] == '.') && (path[1] == '/'))
    {
        path += 2;
    }

    // Verify our dependents are good.
    ensureStartedUp();

    // Set some sanity state.
    *outPointer = NULL;
    *outSize    = 0;

    // Try opening it with fopen.
    lmLog(ioLogGroup, "platform_mapFile - '%s' - trying to fopen.", path);
    f = fopen(path, "rb");
    if (f)
    {
        // Get length.
        fseek(f, 0, SEEK_END);
        size = ftell(f);

        // Get some memory and set return values!
        *outPointer = lmAlloc(fileMappingAllocator, size);
        *outSize    = size;

        lmLog(ioLogGroup, "platform_mapFile - '%s' - mapped via fopen %x, len=%d.", path, *outPointer, *outSize);

        // Read it in and close file.
        fseek(f, 0, SEEK_SET);
        fread(*outPointer, 1, size, f);
        fclose(f);

        // Register the mapping.
        registerMapping(path, *outPointer, mappingCleaner_free, fileMappingAllocator);

        // Great, all done!
        return 1;
    }

#if LOOM_PLATFORM_IS_APPLE == 1
    lmLog(ioLogGroup, "platform_mapFile - '%s' - seeing if we can look in app bundle.", path);

    // If we're not looking in the app bundle already, try looking in there.
    if (strstr(path, platform_getResourceDirectory()) == NULL)
    {
        sprintf(inBundlePath, "%s/%s", platform_getResourceDirectory(), path);
        lmLog(ioLogGroup, "platform_mapFile - '%s' - trying as '%s'.", path, inBundlePath);
        if (platform_mapFile(inBundlePath, outPointer, outSize))
        {
            return 1;
        }
    }
#endif

    // If we get here, then we need to try another strategy.
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
    lmLog(ioLogGroup, "platform_mapFile - '%s' - trying AssetManager %x.", path, gAssetManager);
    lmAssert(gAssetManager, "No AssetManager present!");

    // Dump out some directories.
    // On the current Android project, the stuff in "assets" ends up in root of APK
    // TODO: Kill this code? It's useful for debugging missing file issues. But
    //       it runs very slowly so can't leave it on normally.

/*   assetDir = AAssetManager_openDir(gAssetManager, "");
 * lmLog(ioLogGroup, "platform_mapFile - '%s' - listing dir %x.", path, assetDir);
 * dirName = AAssetDir_getNextFileName(assetDir);
 * while(dirName != NULL)
 * {
 *    lmLog(ioLogGroup, "   Saw %s", dirName);
 *    dirName = AAssetDir_getNextFileName(assetDir);
 * }
 * AAssetDir_close(assetDir); */

    if (asset = AAssetManager_open(gAssetManager, path, AASSET_MODE_UNKNOWN))
    {
        *outSize    = AAsset_getLength(asset);
        *outPointer = (void *)AAsset_getBuffer(asset);

        registerMapping(path, *outPointer, androidCleaner_free, asset);

        lmLog(ioLogGroup, "platform_mapFile - '%s' - mapped via AAsset %x, len=%d.", path, *outPointer, *outSize);

        return 1;
    }
#endif

    lmLog(ioLogGroup, "platform_mapFile - '%s' - could not open!", path);
    return 0;
}


void platform_unmapFile(void *ptr)
{
    int i;

    ensureStartedUp();

    // Find it in the mapping list.
    for (i = 0; i < LOOM_MAX_FILEMAPPINGS; i++)
    {
        if (gFileMappings[i].mapping != ptr)
        {
            continue;
        }

        if (gFileMappings[i].dtor)
        {
            gFileMappings[i].dtor(&gFileMappings[i]);
        }
        gFileMappings[i].mapping = NULL;
        return;
    }

    dumpMappings();

    lmAssert(0, "Could not find file mapping for %x!", ptr);
}


#if LOOM_PLATFORM == LOOM_PLATFORM_OSX || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
static platform_subdirectoryWalkerCallback gCurrentWalkCallback = NULL;
static void *gCurrentWalkPayload = NULL;
static int ftwWalker(const char *fpath, const struct stat *sb, int typeflag)
{
    if (typeflag == FTW_D)
    {
        gCurrentWalkCallback(fpath, gCurrentWalkPayload);
    }

    // Non-zero terminates the walk.
    return 0;
}
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
static void platform_walkDirectory_r(const char *path, platform_subdirectoryWalkerCallback cb, void *payload)
{
    char relativePath[MAX_PATH], searchPath[MAX_PATH];
    size_t l;

    // Time to walk directories. Stick \* on the end so it searches properly.
    WIN32_FIND_DATAA findData;
    HANDLE           findHandle;

    StringCchPrintf(searchPath, MAX_PATH, "%s\\*", path);

    findHandle = FindFirstFile(searchPath, &findData);
    if (findHandle == INVALID_HANDLE_VALUE)
    {
        return;
    }

    do
    {
        // Only consider directories.
        if ((findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0)
        {
            continue;
        }

        // Skip parent directories.
        if ((strcmp(findData.cFileName, ".") == 0) || (strcmp(findData.cFileName, "..") == 0))
        {
            continue;
        }

        // Great, a hit. Figure out the relative path.
        strcpy(relativePath, path);
        l = strlen(relativePath);
        relativePath[l]     = '/';
        relativePath[l + 1] = 0;
        strcpy(relativePath + l + 1, findData.cFileName);

        cb(relativePath, payload);

        // Recurse.
        platform_walkDirectory_r(relativePath, cb, payload);
    } while (FindNextFile(findHandle, &findData));

    FindClose(findHandle);
}
#endif

void platform_walkSubdirectories(const char *rootPath, platform_subdirectoryWalkerCallback cb, void *payload)
{
    // TODO: Can we do something crossplatform using findfirst/findnext?
#if LOOM_PLATFORM == LOOM_PLATFORM_OSX || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
    gCurrentWalkCallback = cb;
    gCurrentWalkPayload  = payload;
    ftw(rootPath, ftwWalker, 16);
#elif LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    platform_walkDirectory_r(rootPath, cb, payload);
#else
    lmAssert(0, "Not implemented on this platform.");
#endif
}


#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32

static void platform_walkFiles_r(const char *path, platform_fileWalkerCallback cb, void *payload)
{
    char relativePath[MAX_PATH], searchPath[MAX_PATH];
    size_t l;

    // Time to walk directories. Stick \* on the end so it searches properly.
    WIN32_FIND_DATAA findData;
    HANDLE           findHandle;

    StringCchPrintf(searchPath, MAX_PATH, "%s\\*", path);

    findHandle = FindFirstFile(searchPath, &findData);
    if (findHandle == INVALID_HANDLE_VALUE)
    {
        return;
    }

    do
    {
        // Skip parent directories.
        if ((strcmp(findData.cFileName, ".") == 0) || (strcmp(findData.cFileName, "..") == 0))
        {
            continue;
        }

        // Great, a hit. Figure out the relative path.
        strcpy(relativePath, path);
        l = strlen(relativePath);
        relativePath[l]     = '/';
        relativePath[l + 1] = 0;
        strcpy(relativePath + l + 1, findData.cFileName);

        // Recurse into directories and callback on files.
        if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        {
            platform_walkFiles_r(relativePath, cb, payload);
        }
        else
        {
            cb(relativePath, payload);
        }
    } while (FindNextFile(findHandle, &findData));

    FindClose(findHandle);
}
#endif

#if LOOM_PLATFORM_IS_APPLE == 1 || LOOM_PLATFORM == LOOM_PLATFORM_LINUX || LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
static platform_fileWalkerCallback gCurrentFileWalkCallback = NULL;
static void *gCurrentFileWalkPayload = NULL;
static void *gFileWalkLock           = NULL;
static int ftwFileWalker(const char *fpath, const struct stat *sb, int typeflag)
{
    if (typeflag != FTW_D)
    {
        gCurrentFileWalkCallback(fpath, gCurrentFileWalkPayload);
    }

    // Non-zero terminates the walk.
    return 0;
}
#endif

void platform_walkFiles(const char *rootPath, platform_fileWalkerCallback cb, void *payload)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    platform_walkFiles_r(rootPath, cb, payload);
#elif LOOM_PLATFORM_IS_APPLE == 1 || LOOM_PLATFORM == LOOM_PLATFORM_LINUX || LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
    // NOTE: This isn't super robust... it introduces a race. But it's good enough for now.
    // TODO: Tracked under LOOM-542
    if (gFileWalkLock == NULL)
    {
        gFileWalkLock = loom_mutex_create();
    }

    loom_mutex_lock(gFileWalkLock);

    gCurrentFileWalkCallback = cb;
    gCurrentFileWalkPayload  = payload;

    ftw(rootPath, ftwFileWalker, 16);

    loom_mutex_unlock(gFileWalkLock);
#else
    lmAssert(0, "Not implemented.");
#endif
}


long long platform_getFileModifiedDate(const char *path)
{
    struct stat pathStat;

    stat(path, &pathStat);
    return pathStat.st_mtime;
}


#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32

// Can we use http://msdn.microsoft.com/en-us/library/506720ff(v=vs.80).aspx instead?

/* realpath.c
 * $Id$
 *
 * Provides an implementation of the "realpath" function, conforming
 * approximately to SUSv3, and adapted for use on native Microsoft(R)
 * Win32 platforms.
 *
 * Written by Keith Marshall <keithmarshall@users.sourceforge.net>
 *
 * This is free software.  You may redistribute and/or modify it as you
 * see fit, without restriction of copyright.
 *
 * This software is provided "as is", in the hope that it may be useful,
 * but WITHOUT WARRANTY OF ANY KIND, not even any implied warranty of
 * MERCHANTABILITY, nor of FITNESS FOR ANY PARTICULAR PURPOSE.  At no
 * time will the author accept any form of liability for any damages,
 * however caused, resulting from the use of this software.
 *
 */

#include <io.h>
#include <stdlib.h>
#include <errno.h>

char *platform_realpath(const char *name, char *resolved)
{
    char *retname = NULL; /* we will return this, if we fail */

    /* SUSv3 says we must set `errno = EINVAL', and return NULL,
     * if `name' is passed as a NULL pointer.
     */

    if (name == NULL)
    {
        errno = EINVAL;

      /* Caller didn't give us a buffer, so we'll exercise the
       * option granted by SUSv3, and allocate one.
       *
       * `_fullpath' would do this for us, but it uses `malloc', and
       * Microsoft's implementation doesn't set `errno' on failure.
       * If we don't do this explicitly ourselves, then we will not
       * know if `_fullpath' fails on `malloc' failure, or for some
       * other reason, and we want to set `errno = ENOMEM' for the
       * `malloc' failure case.
       */

      retname = lmAlloc( NULL, _MAX_PATH );
    }

    /* Otherwise, `name' must refer to a readable filesystem object,
     * if we are going to resolve its absolute path name.
     */

    else if (_access(name, 4) == 0)
    {
        /* If `name' didn't point to an existing entity,
         * then we don't get to here; we simply fall past this block,
         * returning NULL, with `errno' appropriately set by `access'.
         *
         * When we _do_ get to here, then we can use `_fullpath' to
         * resolve the full path for `name' into `resolved', but first,
         * check that we have a suitable buffer, in which to return it.
         */

        if ((retname = resolved) == NULL)
        {
            /* Caller didn't give us a buffer, so we'll exercise the
             * option granted by SUSv3, and allocate one.
             *
             * `_fullpath' would do this for us, but it uses `malloc', and
             * Microsoft's implementation doesn't set `errno' on failure.
             * If we don't do this explicitly ourselves, then we will not
             * know if `_fullpath' fails on `malloc' failure, or for some
             * other reason, and we want to set `errno = ENOMEM' for the
             * `malloc' failure case.
             */

            retname = malloc(_MAX_PATH);
        }

        /* By now, we should have a valid buffer.
         * If we don't, then we know that `malloc' failed,
         * so we can set `errno = ENOMEM' appropriately.
         */

        if (retname == NULL)
        {
            errno = ENOMEM;
        }

        /* Otherwise, when we do have a valid buffer,
         * `_fullpath' should only fail if the path name is too long.
         */

        else if ((retname = _fullpath(retname, name, _MAX_PATH)) == NULL)
        {
            errno = ENAMETOOLONG;
        }
    }

    /* By the time we get to here,
     * `retname' either points to the required resolved path name,
     * or it is NULL, with `errno' set appropriately, either of which
     * is our required return condition.
     */

    return retname;
}


/* $RCSfile$: end of file */

#else

// Other platforms have this, so use the real implementation.
char *platform_realpath(const char *name, char *resolved)
{
    return realpath(name, resolved);
}
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

void loom_setAssetManager(AAssetManager *am)
{
    gAssetManager = am;
}
#endif
