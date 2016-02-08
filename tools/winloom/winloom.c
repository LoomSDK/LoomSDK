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
#include <string.h>
#include <tchar.h>
#include <windows.h>

/**
 *  Small executable which executes the ruby loom script and forwards command line to it
 */

static BOOL gKillProcess = FALSE;

BOOL CtrlHandler(DWORD fdwCtrlType)
{
    if ((fdwCtrlType == CTRL_C_EVENT) || (fdwCtrlType == CTRL_BREAK_EVENT))
    {
        gKillProcess = TRUE;
        // eat the event
        return TRUE;
    }

    //process the event as normal
    return FALSE;
}


int main(int argc, const char **argv)
{
    PROCESS_INFORMATION pinfo;
    STARTUPINFO         sinfo;
    char                loompath[4096];
    char                rubypath[4096];
    char                commandline[4096];
    char                args[4096];
    const char          *_args;
    DWORD               exitCode;
    BOOL                result;
    size_t              length, count;
    unsigned int        size = sizeof(loompath);

    if (!SetConsoleCtrlHandler((PHANDLER_ROUTINE)CtrlHandler, TRUE))
    {
        printf("\nERROR: Could not set control handler");
        exit(EXIT_FAILURE);
    }

    //init the STARTUPINFO struct
    memset(&sinfo, 0, sizeof(sinfo));
    sinfo.cb = sizeof(sinfo);

    // get the full path to this executable
    GetModuleFileName(NULL, loompath, size);

    // go up 2 levels, this is the main Loom folder
    length = strlen(loompath);
    count  = 0;
    while (length)
    {
        if ((loompath[length] == '/') || (loompath[length] == '\\'))
        {
            count++;
            if (count == 2)
            {
                break;
            }
        }

        length--;
    }

    if (!length)
    {
        exit(EXIT_FAILURE);
    }

    loompath[length] = 0;

    // find arguments after the loom command
    _args  = GetCommandLineA();
    length = strlen(_args);
    count  = 0;
    while (count < length && _args[count++] != ' ')
    {
        continue;
    }

    if (count >= length)
    {
        args[0] = 0;
    }
    else
    {
        strcpy(args, &_args[count + 1]);
    }

    // setup the ruby executable path
    _snprintf(rubypath, 4095, "%s\\ruby\\bin\\ruby.exe", loompath);
    // setup the command line, which is the ruby exe + the loom script to run and the command args
    _snprintf(commandline, 4095, "\"%s\" \"%s\\bin\\loom\" %s", rubypath, loompath, args);

    // http://msdn.microsoft.com/en-us/library/windows/desktop/ms682425(v=vs.85).aspx
    result = CreateProcess(_tcsdup(TEXT(rubypath)), _tcsdup(TEXT(commandline)), NULL, NULL, FALSE, 0, NULL, NULL, &sinfo, &pinfo);

    if (!result)
    {
        exit(EXIT_FAILURE);
    }

    // wait for the process to finish
    while (TRUE)
    {
        // get the exit code
        result = GetExitCodeProcess(pinfo.hProcess, &exitCode);

        if (!result || (exitCode != STILL_ACTIVE) || gKillProcess)
        {
            break;
        }
    }

    if (result && ((exitCode == STILL_ACTIVE) && gKillProcess))
    {
        result   = TerminateProcess(pinfo.hProcess, 0);
        exitCode = EXIT_SUCCESS;
    }
    else if (!result)
    {
        exitCode = EXIT_FAILURE;
    }

    // release handles
    CloseHandle(pinfo.hProcess);
    CloseHandle(pinfo.hThread);

    return exitCode;
}
