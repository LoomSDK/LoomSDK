@echo off

:CheckOS
set VALUE_NAME=ShellFolder
echo Checking architecture...
IF EXIST "%PROGRAMFILES(X86)%" (GOTO X64) ELSE (GOTO X86)

:X64
echo Architecture is X64
set KEY_BASE=HKLM\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\
GOTO VS2013

:X86
echo Architecture is X86
set KEY_BASE=HKLM\SOFTWARE\Microsoft\VisualStudio\
GOTO VS2013


:VS2013
echo Checking for Visual Studio 2013...
set KEY_NAME=%KEY_BASE%12.0

reg query %KEY_NAME% /v %VALUE_NAME% > NUL 2>&1
if %ERRORLEVEL% EQU 1 GOTO VS2012

FOR /F "usebackq skip=2 tokens=2,*" %%A IN (`REG QUERY %KEY_NAME% /v %VALUE_NAME%`) DO (
	set ValueValue=%%B
)

if defined ValueValue (
    cmake .. -G "Visual Studio 12" -DLOOM_BUILD_JIT=%1 -DLUA_GC_PROFILE_ENABLED=%2 -DLOOM_BUILD_NUMCORES=%3 %4 %5 %6
) else (
    GOTO VS2012
)
EXIT

:VS2012
echo Checking for Visual Studio 2012...
set KEY_NAME=%KEY_BASE%11.0


reg query %KEY_NAME% /v %VALUE_NAME% > NUL 2>&1
if %ERRORLEVEL% EQU 1 GOTO VS2010

FOR /F "usebackq skip=2 tokens=2,*" %%A IN (`REG QUERY %KEY_NAME% /v %VALUE_NAME%`) DO (
	set ValueValue=%%B
)

if defined ValueValue (
    cmake .. -G "Visual Studio 11" -DLOOM_BUILD_JIT=%1 -DLUA_GC_PROFILE_ENABLED=%2 -DLOOM_BUILD_NUMCORES=%3 %4 %5 %6
) else (
    GOTO VS2010
)
EXIT

:VS2010
echo Checking for Visual Studio 2010...
set KEY_NAME=%KEY_BASE%10.0

reg query %KEY_NAME% /v %VALUE_NAME% > NUL 2>&1
if %ERRORLEVEL% EQU 1 GOTO FALLBACK

FOR /F "usebackq skip=2 tokens=2,*" %%A IN (`REG QUERY %KEY_NAME% /v %VALUE_NAME%`) DO (
	set ValueValue=%%B
)

if defined ValueValue (
    cmake .. -G "Visual Studio 10" -DLOOM_BUILD_JIT=%1 -DLUA_GC_PROFILE_ENABLED=%2 -DLOOM_BUILD_NUMCORES=%3 %4 %5 %6
) else (
    GOTO FALLBACK
)
EXIT



REM Try a whole bunch of potential visual studio paths and see which if any exist.

:FALLBACK
echo Could not find paths in registry, trying default paths...
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
cmake .. -G "Visual Studio 12" -DLOOM_BUILD_JIT=%1 -DLUA_GC_PROFILE_ENABLED=%2 -DLOOM_BUILD_NUMCORES=%3 %4 %5 %6
EXIT

:VS2013-X86-CMAKE
cmake .. -G "Visual Studio 12" -DLOOM_BUILD_JIT=%1 -DLUA_GC_PROFILE_ENABLED=%2 -DLOOM_BUILD_NUMCORES=%3 %4 %5 %6
EXIT

:VS2012-X64-CMAKE
cmake .. -G "Visual Studio 11" -DLOOM_BUILD_JIT=%1 -DLUA_GC_PROFILE_ENABLED=%2 -DLOOM_BUILD_NUMCORES=%3 %4 %5 %6
EXIT

:VS2012-X86-CMAKE
cmake .. -G "Visual Studio 11" -DLOOM_BUILD_JIT=%1 -DLUA_GC_PROFILE_ENABLED=%2 -DLOOM_BUILD_NUMCORES=%3 %4 %5 %6
EXIT

:VS2010-X64-CMAKE
cmake .. -G "Visual Studio 10" -DLOOM_BUILD_JIT=%1 -DLUA_GC_PROFILE_ENABLED=%2 -DLOOM_BUILD_NUMCORES=%3 %4 %5 %6
EXIT

:VS2010-X86-CMAKE
cmake .. -G "Visual Studio 10" -DLOOM_BUILD_JIT=%1 -DLUA_GC_PROFILE_ENABLED=%2 -DLOOM_BUILD_NUMCORES=%3 %4 %5 %6
EXIT

:END