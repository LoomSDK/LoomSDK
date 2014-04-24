@echo off

REM Try a whole bunch of potential visual studio paths and see which if any exist.

echo Checking for Visual Studio 2013...
IF EXIST "%programfiles%\Microsoft Visual Studio 12.0\VC" (GOTO VS2013-X64-CMAKE) ELSE (GOTO VS2013-X86)

:VS2013-X86
IF EXIST "%programfiles(x86)%\Microsoft Visual Studio 12.0\VC" (GOTO VS2013-X86-CMAKE) ELSE (GOTO VS2012-X64)

:VS2012-X64
echo Checking for Visual Studio 2012...
IF EXIST "%programfiles%\Microsoft Visual Studio 11.0\VC" (GOTO VS2012-X64-CMAKE) ELSE (GOTO VS2012-X86)

:VS2012-X86
IF EXIST "%programfiles(x86)%\Microsoft Visual Studio 11.0\VC" (GOTO VS2012-X86-CMAKE) ELSE (GOTO VS2010-X64)

:VS2010-X64
echo Checking for Visual Studio 2010...
IF EXIST "%programfiles%\Microsoft Visual Studio 10.0\VC" (GOTO VS2010-X64-CMAKE) ELSE (GOTO VS2010-X86)

:VS2010-X86
IF EXIST "%programfiles(x86)%\Microsoft Visual Studio 10.0\VC" (GOTO VS2010-X86-CMAKE) ELSE (GOTO EXIT)

:EXIT
echo Visual Studio 2010, 2012, or 2013 not present.
echo exiting build...
EXIT

:VS2013-X64-CMAKE
cmake .. -G "Visual Studio 12" -DLOOM_BUILD_JIT=%1 -DLOOM_BUILD_NUMCORES=%2 %3
EXIT

:VS2013-X86-CMAKE
cmake .. -G "Visual Studio 12" -DLOOM_BUILD_JIT=%1 -DLOOM_BUILD_NUMCORES=%2 %3
EXIT

:VS2012-X64-CMAKE
cmake .. -G "Visual Studio 11" -DLOOM_BUILD_JIT=%1 -DLOOM_BUILD_NUMCORES=%2 %3
EXIT

:VS2012-X86-CMAKE
cmake .. -G "Visual Studio 11" -DLOOM_BUILD_JIT=%1 -DLOOM_BUILD_NUMCORES=%2 %3
EXIT

:VS2010-X64-CMAKE
cmake .. -G "Visual Studio 10" -DLOOM_BUILD_JIT=%1 -DLOOM_BUILD_NUMCORES=%2 %3
EXIT

:VS2010-X86-CMAKE
cmake .. -G "Visual Studio 10" -DLOOM_BUILD_JIT=%1 -DLOOM_BUILD_NUMCORES=%2 %3
EXIT
