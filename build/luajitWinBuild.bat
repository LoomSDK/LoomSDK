@echo off

:: Arguments
:: %1 - path to the Visual Studio vcvarsall.bat
:: %2 - architecture to set with vcvarsall (x86 or amd64)
:: %3 - LuaJIT msvcbuild extra arguments (e.g. debug)
:: %4 - target directory of lua51.lib

call %1 %2
cd ..\loom\vendor\luajit\src\
call msvcbuild static
if not exist %4 mkdir %4
ls -lh lua51.lib
move lua51.lib %4 >nul