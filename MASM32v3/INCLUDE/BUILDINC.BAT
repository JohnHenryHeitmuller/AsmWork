@echo off

:------------------------------------------------------------------
: Simple test for library, if user32.lib is there, so are the rest.
:------------------------------------------------------------------
if not exist ..\lib\user32.lib goto NoLibs

l2inc /M ..\lib\*.lib
goto TheEnd

:NoLibs

echo Assembler, Pure and Simple
echo.
echo The necessary library files are not present in the LIB directory.
echo.
echo If you have downloaded the "PLATFORMSDK" from Microsoft, copy the
echo import libraries into the LIB directory and run this batch file again
echo to build a set of include files. If not, you will need to get the
echo import libraries from Microsoft by downloading the "PLATFORMSDK".

:TheEnd
