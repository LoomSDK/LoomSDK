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

#ifndef _PLATFORM_PLATFORMFILE_H_
#define _PLATFORM_PLATFORMFILE_H_

#include "loom/common/platform/platform.h"

#ifdef __cplusplus
extern "C" {
#endif

/*!
 * What is the current working directory?
 *
 * @param out Buffer to copy out to.
 * @param maxLen Size of the buffer (to avoid buffer overruns)
 */
void platform_getCurrentWorkingDir(char *out, int maxLen);

/*!
 * Set the current working directory.
 */
void platform_setCurrentWorkingDir(const char *path);

/*!
 * Read out the path to our binary.
 *
 * @param out Buffer to copy out to.
 * @param maxLen Size of the buffer (to avoid buffer overruns)
 */
void platform_getCurrentExecutablePath(char *out, unsigned int maxLen);

/*!
 * Get the writeable path
 *
 * @return The path that can write/read file
 */
const char *platform_getWritablePath();

/*!
 * Recursively create the folders in path
 *
 * @param path recursively creates the folders in path
 * @return 0 on success and other value on failure
 */
int platform_makeDir(const char *path);

/*!
 * Write a file at the given path
 *
 * @param path the full path to the file to write
 * @param data a pointer to the raw data to write
 * @param size the number of bytes to write
 * @return 0 on success and other value on failure
 */

int platform_writeFile(const char *path, void *data, int size);

/*!
* Removes a file at the given path
*
* @param path the full path to the file to remove
* @return 0 on success and other value on failure
*/
int platform_removeFile(const char *path);

/*!
* Moves a file from source to dest
*
* @param source the full path of the file to move
* @param dest the full destination path of the file
* @return 0 on success and other value on failure
*/
int platform_moveFile(const char *source, const char *dest);

/*!
 * Checks if a directory exists at the given path
 *
 * @param path the full path to the file to remove
 * @return 0 if the directory exists and other value if not
 */
int platform_dirExists(const char *path);

/*!
 * Removes a directory at the given path
 *
 * @param path the full path to the directory to remove
 * @return 0 on success and other value on failure
 */
int platform_removeDir(const char *path);

/*!
 * Normalizes a path to use the system folder delimiter.
 * This function modifies the buffer in-place.
 *
 * @param path Path to normalize.
 */
void platform_normalizePath(const char *path);

/*!
 * Returns / or \ depending on platform.
 */
const char *platform_getFolderDelimiter();

#ifdef __cplusplus
};
#endif
#endif
