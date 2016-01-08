@echo off

:: Arguments
:: %1 - source precompiled library path
:: %2 - target output lib dir

if not exist %2 mkdir %2
copy /y %1 %2 >nul