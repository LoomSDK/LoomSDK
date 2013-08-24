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

#ifndef _PLATFORM_PLATFORMIO_H
#define _PLATFORM_PLATFORMIO_H

#ifdef __cplusplus
extern "C" {
#endif

// If file can be opened, returns 1. outPointer and outSize will be set
// to describe a block of memory holding the file. Assume this memory is
// read only, it may be serviced via memory mapping.
int platform_mapFile(const char *path, void **outPointer, long *outSize);

// Unmap a file opened with platform_mapFile. Always matched to a call
// to platform_mapFile.
void platform_unmapFile(void *ptr);

// If file can be opened, returns 1, otherwise returns 0
int platform_mapFileExists(const char *path);

// Walk a directory and callback for each subdirectory.
typedef void (*platform_subdirectoryWalkerCallback)(const char *subdirectoryPath, void *payload);
void platform_walkSubdirectories(const char *rootPath, platform_subdirectoryWalkerCallback cb, void *payload);

typedef void (*platform_fileWalkerCallback)(const char *filePath, void *payload);
void platform_walkFiles(const char *rootPath, platform_fileWalkerCallback cb, void *payload);

long long platform_getFileModifiedDate(const char *path);

// Convert a relative path to an absolute path.
char *platform_realpath(const char *name, char *resolved);

#ifdef __cplusplus
};
#endif
#endif
