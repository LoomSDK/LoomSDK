@echo off

IF EXIST "%programfiles%\Microsoft Visual Studio 11.0\VC" (

cmake .. -G "Visual Studio 11" -DLOOM_BUILD_JIT=%1 -DLOOM_BUILD_NUMCORES=%2 %3

) ELSE (

cmake .. -G "Visual Studio 10" -DLOOM_BUILD_JIT=%1 -DLOOM_BUILD_NUMCORES=%2 %3

)