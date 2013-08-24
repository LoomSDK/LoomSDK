@echo off

rem Generates a solution file for Visual Studio [Express] 2012 for Desktop

rem Set up environment variables for compiling / linking
call windowsBuildHelper.bat

rem Compiles a build\luajit_windows\lua51.lib file needed for building with VS2012
call rake build:windows
