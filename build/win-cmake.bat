@echo off

IF EXIST "%PROGRAMFILES(X86)%" (
	set KEY_BASE=HKLM\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\
	set HOST_ARCH=x64
) ELSE (
	set KEY_BASE==HKLM\SOFTWARE\Microsoft\VisualStudio\
	set HOST_ARCH=x86
)

echo Host architecture is %HOST_ARCH%

set VS_TARGET_VERNUM=12.0
set VS_TARGET_VER=Visual Studio 12 2013
call :CHECK_VS_REG
set VS_TARGET_VERNUM=11.0
set VS_TARGET_VER=Visual Studio 11 2012
call :CHECK_VS_REG
set VS_TARGET_VERNUM=10.0
set VS_TARGET_VER=Visual Studio 10 2010
call :CHECK_VS_REG

goto FALLBACK

:CHECK_VS_REG
	echo Checking for %VS_TARGET_VER%...
	set VALUE_NAME=ShellFolder
	set KEY_NAME="%KEY_BASE%%VS_TARGET_VERNUM%"
	reg query %KEY_NAME% /v %VALUE_NAME% > NUL 2>&1
	if %ERRORLEVEL% EQU 1 GOTO _END_CHECK_VS_REG

	FOR /F "usebackq skip=2 tokens=2,*" %%A IN (`REG QUERY %KEY_NAME% /v %VALUE_NAME%`) DO (
		set REG_RESULT=%%B
	)

	if defined REG_RESULT (
		set VS_VER=%VS_TARGET_VER%
		goto FOUND_VS
	)

	:_END_CHECK_VS_REG
goto :eof

REM Try a whole bunch of potential visual studio paths and see which if any exist.
:FALLBACK
echo Could not find paths in registry, trying default paths...

IF EXIST "%programfiles%\Microsoft Visual Studio 12.0\VC" (
	SET VS_VER=Visual Studio 12 2013
	GOTO FOUND_VS
)
IF EXIST "%programfiles(x86)%\Microsoft Visual Studio 12.0\VC" (
	SET VS_VER=Visual Studio 12 2013
	GOTO FOUND_VS
)
IF EXIST "%programfiles%\Microsoft Visual Studio 11.0\VC" (
	SET VS_VER=Visual Studio 11 2012
	GOTO FOUND_VS
)
IF EXIST "%programfiles(x86)%\Microsoft Visual Studio 11.0\VC" (
	SET VS_VER=Visual Studio 11 2012
	GOTO FOUND_VS
)
IF EXIST "%programfiles%\Microsoft Visual Studio 10.0\VC" (
	SET VS_VER=Visual Studio 10 2010
	GOTO FOUND_VS
)
IF EXIST "%programfiles(x86)%\Microsoft Visual Studio 10.0\VC" (
	SET VS_VER=Visual Studio 10 2010
	GOTO FOUND_VS
)

:EXIT
echo Visual Studio 2010, 2012, or 2013 not present.
echo exiting build...
EXIT

:FOUND_VS
echo Found %VS_VER%!

if "%1" == "x64" (
	set CMAKE_GENERATOR=%VS_VER% Win64
) else (
	set CMAKE_GENERATOR=%VS_VER%
)

cmake .. -G "%CMAKE_GENERATOR%" -DLOOM_BUILD_JIT=%2 -DLUA_GC_PROFILE_ENABLED=%3 -DLOOM_BUILD_NUMCORES=%4 %5 %6 %7 -DLOOM_LUAJIT_LIB=%8
