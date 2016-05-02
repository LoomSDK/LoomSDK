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


#include <string.h>
#include <stdio.h>
#include "platformFile.h"
#include "platformDisplay.h"
#include "loom/common/platform/platform.h"

const char *platform_getFolderDelimiter();

void platform_normalizePath(char *path)
{
    size_t      i;
    size_t      nlen;
    char        delimiter;

    nlen = strlen(path);

    delimiter = platform_getFolderDelimiter()[0];

    for (i = 0; i < nlen; i++)
    {
        if ((path[i] == '\\') || (path[i] == '/'))
        {
            path[i] = delimiter;
        }
    }
}


int platform_writeFile(const char *path, void *data, int size)
{
    FILE *file;
    int  result;

    file = fopen(path, "wb");

    if (!file)
    {
        return -1;
    }

    result = (int)fwrite(data, 1, size, file);

    fclose(file);

    if (result == size)
    {
        return 0;
    }

    return -1;
}


int platform_removeFile(const char *path)
{
    FILE *file;

    // check to see if we have write permission
    file = fopen(path, "wb");

    if (!file)
    {
        return -1;
    }

    fclose(file);

    return remove(path);
}

int platform_moveFile(const char *source, const char *dest)
{
    return rename(source, dest);
}


#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <Shlobj.h>
#include <stdio.h>
#include <stdlib.h>
#include <tchar.h>

void platform_getCurrentWorkingDir(char *out, int maxLen)
{
    GetCurrentDirectory(maxLen, out);
}


void platform_setCurrentWorkingDir(const char *path)
{
    SetCurrentDirectory(path);
}


void platform_getCurrentExecutablePath(char *out, unsigned int maxLen)
{
    // TODO: Implement this.
    // Function needed is here: http://msdn.microsoft.com/en-us/library/ms683197.aspx
    strcpy(out, ".");
}


const char *platform_getFolderDelimiter()
{
    return "\\";
}


/**
 * @brief   Get the writeable path
 * @return  The path that can write/read file
 */
const char *platform_getWritablePath()
{
    static char path[1024];

    char spath[MAX_PATH];

    HRESULT hr = SHGetFolderPathA(NULL, CSIDL_MYDOCUMENTS, NULL, SHGFP_TYPE_CURRENT, spath);

    // use $HOME/Documents
    _snprintf(path, 1023, "%s", spath);

    return path;
}


int platform_makeDir(const char *path)
{
    LPSECURITY_ATTRIBUTES lpSecurityAttributes = NULL;
    int   bSuccess    = 0;
    DWORD dwLastError = 0;

    const BOOL bCD = CreateDirectory(path, lpSecurityAttributes);

    if (!bCD)
    {
        dwLastError = GetLastError();
    }
    else
    {
        return 0;
    }

    switch (dwLastError)
    {
    case ERROR_ALREADY_EXISTS:
        bSuccess = 1;
        break;

    case ERROR_PATH_NOT_FOUND:
       {
           TCHAR   szPrev[MAX_PATH] = { 0 };
           LPCTSTR szLast           = _tcsrchr(path, '\\');
           _tcsnccpy(szPrev, path, (int)(szLast - path));
           if (!platform_makeDir(szPrev))
           {
               bSuccess = CreateDirectory(path, lpSecurityAttributes) != 0;
               if (!bSuccess)
               {
                   bSuccess = (GetLastError() == ERROR_ALREADY_EXISTS);
               }
           }
           else
           {
               bSuccess = 0;
           }
       }
       break;

    default:
        bSuccess = 0;
        break;
    }

    return bSuccess ? 0 : -1;
}


int platform_dirExists(const char *path)
{
    DWORD dwAttrib = GetFileAttributes(path);

    return (dwAttrib != INVALID_FILE_ATTRIBUTES &&
            (dwAttrib & FILE_ATTRIBUTE_DIRECTORY)) ? 0 : -1;
}


int platform_removeDir(const char *path)
{
    return RemoveDirectory(path) ? -1 : 0;
}


#elif LOOM_PLATFORM_IS_APPLE
#include <mach-o/dyld.h> // _NSGetExecutablePath
#include <unistd.h>

void platform_getCurrentWorkingDir(char *out, int maxLen)
{
    getcwd(out, maxLen);
    out[maxLen - 1] = '\0';
}


void platform_setCurrentWorkingDir(const char *path)
{
    chdir(path);
}


void platform_getCurrentExecutablePath(char *out, unsigned int maxLen)
{
    char *lastSlash;

    if (_NSGetExecutablePath(out, &maxLen) != 0)
    {
        platform_error("Could not retrieve path of executable -- buffer of %d is too small.\n", maxLen);
        return;
    }

    // Ensure that the string is null terminated.
    out[maxLen] = '\0';

    // The executable path retrieved now has the executable name appended to it, so we need to remove it.
    // The easiest way to do this is to search for the last '/', and just set it to \0
    lastSlash = strrchr(out, '/');

    if (lastSlash)
    {
        // If we have room for it, retain the trailing / and only null-terminate after it
        if ((lastSlash - out) < maxLen - 1)
        {
            lastSlash++;
        }

        // Null terminate the string so that the name of the executable is not included in the path.
        *lastSlash = '\0';
    }
    else
    {
        platform_error("Could not retrieve path of executable -- no directory delimiter found.\n");
    }
}


const char *platform_getFolderDelimiter()
{
    return "/";
}


#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include <unistd.h>

void platform_getCurrentWorkingDir(char *out, int maxLen)
{
    getcwd(out, maxLen);
    out[maxLen - 1] = '\0';
}


void platform_setCurrentWorkingDir(const char *path)
{
    chdir(path);
}


void platform_getCurrentExecutablePath(char *out, unsigned int maxLen)
{
    strcpy(out, ".");
}


const char *platform_getFolderDelimiter()
{
    return "/";
}


#else

void platform_getCurrentWorkingDir(char *out, int maxLen)
{
    strcpy(out, ".");
}


void platform_setCurrentWorkingDir(const char *path)
{
}


void platform_getCurrentExecutablePath(char *out, unsigned int maxLen)
{
    strcpy(out, ".");
}


const char *platform_getFolderDelimiter()
{
    return "/";
}
#endif

// *nix
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID || \
    LOOM_PLATFORM == LOOM_PLATFORM_OSX ||     \
    LOOM_PLATFORM == LOOM_PLATFORM_LINUX ||   \
    LOOM_PLATFORM == LOOM_PLATFORM_IOS

// do_mkdir and mkpath are from:
// http://stackoverflow.com/questions/675039/how-can-i-create-directory-tree-in-c-linux
// used with attribution
// (c) JLSS 1990-91,1997-98,2001,2005,2008,2012

#include <errno.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>

typedef struct stat   Stat;

static int do_mkdir(const char *path, mode_t mode)
{
    Stat st;
    int  status = 0;

    if (stat(path, &st) != 0)
    {
        /* Directory does not exist. EEXIST for race condition */
        if ((mkdir(path, mode) != 0) && (errno != EEXIST))
        {
            status = -1;
        }
    }
    else if (!S_ISDIR(st.st_mode))
    {
        errno  = ENOTDIR;
        status = -1;
    }

    return(status);
}


/**
** mkpath - ensure all directories in path exist
** Algorithm takes the pessimistic view and works top-down to ensure
** each directory in path exists, rather than optimistically creating
** the last element and working backwards.
*/
static int mkpath(const char *path, mode_t mode)
{
    char *pp;
    char *sp;
    int  status;
    char *copypath = strdup(path);

    status = 0;
    pp     = copypath;

    while (status == 0 && (sp = strchr(pp, '/')) != 0)
    {
        if (sp != pp)
        {
            /* Neither root nor double slash in path */
            *sp    = '\0';
            status = do_mkdir(copypath, mode);
            *sp    = '/';
        }
        pp = sp + 1;
    }

    if (status == 0)
    {
        status = do_mkdir(path, mode);
    }

    free(copypath);
    return(status);
}


int platform_makeDir(const char *path)
{
    return mkpath(path, 0777);
}


int platform_dirExists(const char *path)
{
    DIR *dir;

    dir = opendir(path);

    if (dir)
    {
        closedir(dir);
        return 0;
    }

    return -1;
}


int platform_removeDir(const char *path)
{
    if (!platform_dirExists(path))
    {
        return rmdir(path);
    }

    return -1;
}
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_LINUX

#include <pwd.h>

/**
 * @brief   Get the writeable path
 * @return  The path that can write/read file
 */
const char *platform_getWritablePath()
{
    static char path[1024];

    const char *home = getenv("HOME");

    if (!home)
    {
        struct passwd *pw = getpwuid(getuid());
        home = pw->pw_dir;
    }

    if (!home)
    {
        return "";
    }

    // use $HOME/Documents on Linux, as per OSX
    snprintf(path, 1023, "%s/Documents", home);

    return path;
}
#endif
