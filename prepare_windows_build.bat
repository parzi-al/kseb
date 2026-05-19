@echo off
REM Quick fix for Windows build - run this before flutter build windows

echo Fixing Windows CMake/plugin errors...

REM Fix the generated_plugin_registrant.cc by creating a clean version
echo Patching generated_plugin_registrant.cc...
(
  echo //
  echo //  Generated file. Do not edit.
  echo //
  echo // NOTE: Firebase plugins are excluded from Windows builds.
  echo.
  echo // clang-format off
  echo.
  echo #include "generated_plugin_registrant.h"
  echo.
  echo #include ^<file_selector_windows/file_selector_windows.h^>
  echo.
  echo void RegisterPlugins(flutter::PluginRegistry* registry^) {
  echo   FileSelectorWindowsRegisterWithRegistrar(
  echo       registry-^>GetRegistrarForPlugin("FileSelectorWindows"^)^);
  echo }
) > windows\flutter\generated_plugin_registrant.cc

echo.
echo ✓ Windows build files are fixed!
echo.
echo Next steps:
echo 1. Run: flutter pub get
echo 2. Run: flutter build windows
echo.
