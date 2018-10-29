@echo off
if "%1" == "" goto label1
set WALK32=%1
:label1
if "%WALK32%" == "" goto label2
ml /I. /Zm /c /Cp /Ta %WALK32%.asm
if errorlevel 1 goto label3
W32Link /d %WALK32% >%WALK32%.log
if errorlevel 1 goto label3
if exist %WALK32%.exe rename %WALK32%.exe %WALK32%.exe
if exist %WALK32%.dll rename %WALK32%.dll %WALK32%.dll
del %WALK32%.obj
goto label3
:label2
echo.
echo Please specify a file name!
echo.
:label3

