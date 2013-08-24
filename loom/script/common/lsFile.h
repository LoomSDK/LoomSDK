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

#ifndef _lsfile_h

namespace LS {
// TODO: Combine log and file external API into a single external API

typedef int (*MapFileFunction)(const char *path, void **outPointer,
                               long *outSize);

typedef void (*UnmapFileFunction)(const char *ptr);

void LSFileInitialize(MapFileFunction mapFunc, UnmapFileFunction unmapFunc);

// map a file into memory
void LSMapFile(const char *path, void **outPointer, long *outSize);

// remove a mapped file from memory
void LSUnmapFile(const char *path);
}
#endif
