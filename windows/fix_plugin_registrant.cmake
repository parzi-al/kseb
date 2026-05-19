# CMake script to fix generated_plugin_registrant.cc for Windows builds
# Firebase C++ SDK is not available for Windows, so we remove Firebase plugin references

set(PLUGIN_REGISTRANT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/flutter/generated_plugin_registrant.cc")

# Read the current file
if(EXISTS "${PLUGIN_REGISTRANT_FILE}")
  file(READ "${PLUGIN_REGISTRANT_FILE}" REGISTRANT_CONTENT)
  
  # Check if Firebase includes are present (indicating file needs fixing)
  if(REGISTRANT_CONTENT MATCHES "cloud_firestore_plugin_c_api.h")
    message(STATUS "Fixing Windows plugin registrant (removing Firebase plugins)...")
    
    # Create the fixed content
    set(FIXED_CONTENT "//
//  Generated file. Do not edit.
//
// NOTE: Firebase plugins are excluded from Windows builds.
// They are conditionally initialized in main.dart for
// supported platforms (Android, iOS, Web).

// clang-format off

#include \"generated_plugin_registrant.h\"

#include <file_selector_windows/file_selector_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin(\"FileSelectorWindows\"));
}")
    
    # Write the fixed content
    file(WRITE "${PLUGIN_REGISTRANT_FILE}" "${FIXED_CONTENT}")
    message(STATUS "Plugin registrant fixed successfully")
  else()
    message(STATUS "Plugin registrant is already fixed or valid")
  endif()
else()
  message(STATUS "Plugin registrant file not found at ${PLUGIN_REGISTRANT_FILE}")
endif()
