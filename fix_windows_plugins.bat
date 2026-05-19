@echo off
REM This script removes Firebase plugin references from auto-generated files
REM Run this before compiling on Windows

REM Fix generated_plugin_registrant.cc
echo Fixing Windows build for Firebase incompatibility...

set FILE=%1\windows\flutter\generated_plugin_registrant.cc

if not exist "%FILE%" (
    echo Error: %FILE% not found
    exit /b 1
)

REM Create a temporary file without Firebase includes
(
    echo //
    echo //  Generated file. Do not edit.
    echo //
    echo // NOTE: Firebase plugins are excluded from Windows builds.
    echo // They're conditionally initialized in main.dart for
    echo // supported platforms (Android, iOS, Web).
    echo //
    echo.
    echo // clang-format off
    echo.
    echo #include "generated_plugin_registrant.h"
    echo.
    echo #include ^<file_selector_windows/file_selector_windows.h^>
    echo.
    echo void RegisterPlugins(flutter::PluginRegistry* registry) {
    echo   FileSelectorWindowsRegisterWithRegistrar(
    echo       registry-^>GetRegistrarForPlugin("FileSelectorWindows"^)^);
    echo }
) > "%FILE%.tmp"

REM Replace original with fixed version
move /Y "%FILE%.tmp" "%FILE%" > nul

if %ERRORLEVEL% EQU 0 (
    echo✓ Successfully fixed plugin registrant
    exit /b 0
) else (
    echo X Failed to fix plugin registrant
    exit /b 1
)
