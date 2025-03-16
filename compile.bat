@echo off
echo Compiling setup.c for Windows...

REM Check if GCC is available
where gcc >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo GCC not found. You need to install MinGW or GCC for Windows.
    echo You can install it via:
    echo - Chocolatey: choco install mingw
    echo - or download from: https://sourceforge.net/projects/mingw/
    exit /b 1
)

REM Compile the program
gcc -o setup.exe setup.c

if %ERRORLEVEL% neq 0 (
    echo Compilation failed.
    exit /b 1
) else (
    echo Compilation successful. You can now run setup.exe
) 