@echo off

:: Arguments
:: %1 - path to the Visual Studio vcvarsall.bat
:: %2 - architecture to set with vcvarsall (x86 or amd64)
:: %3 - LuaJIT msvcbuild extra arguments (e.g. debug)
:: %4 - target directory of lua51.lib
:: %5..9 - additional compiler arguments

call %1 %2
cd ..\loom\vendor\luajit\src\
call msvcbuild static %5 %6 %7 %8 %9
if not exist %4 mkdir %4
move lua51.lib %4 >nul