@echo off

REM Helper to run rake with the right environment setup for visual studio.

IF EXIST "%programfiles%\Microsoft Visual Studio 10.0\VC" (
  echo Registering Visual Studio 10.0 vars...
  call "%programfiles%\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x86
  GOTO YAY
)
IF EXIST "%programfiles(x86)%\Microsoft Visual Studio 10.0\VC" (
  echo Registering Visual Studio 10.0 vars...
  call "%programfiles(x86)%\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x86
  GOTO YAY
)
IF EXIST "%programfiles%\Microsoft Visual Studio 11.0\VC" (
  echo Registering Visual Studio 11.0 vars...
  call "%programfiles%\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
  GOTO YAY
)
IF EXIST "%programfiles(x86)%\Microsoft Visual Studio 11.0\VC" (
  echo Registering Visual Studio 11.0 vars...
  call "%programfiles(x86)%\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
  GOTO YAY
)

echo Your version of Visual Studio is not currently supported.
rem EXIT /B 1
EXIT

:YAY
echo Launching rake...
rake %*
