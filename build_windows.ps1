#!/usr/bin/env powershell
#Requires -Version 5.0

# Windows Build Wrapper for KSEB Flutter App
# This script fixes Firebase plugin incompatibilities before building

param(
    [string]$Command = "build"
)

$projectRoot = $PSScriptRoot
$regFile = Join-Path $projectRoot "windows\flutter\generated_plugin_registrant.cc"

function Fix-PluginRegistrant {
    if (-not (Test-Path $regFile)) {
        Write-Host "⚠️  Plugin registrant not found. Running flutter pub get first..."
        & flutter pub get
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ flutter pub get failed"
            return $false
        }
    }
    
    Write-Host "🔧 Fixing plugin registrant for Windows..."
    
    $newContent = @'
//
//  Generated file. Do not edit.
//
// NOTE: Firebase plugins are excluded from Windows builds.
// They are conditionally initialized in main.dart for
// supported platforms (Android, iOS, Web).

// clang-format off

#include "generated_plugin_registrant.h"

#include <file_selector_windows/file_selector_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorWindows"));
}
'@
    
    Set-Content $regFile -Value $newContent -Encoding UTF8 -Force
    Write-Host "✓ Plugin registrant fixed"
    return $true
}

# Fix the plugin registrant
if (-not (Fix-PluginRegistrant)) {
    exit 1
}

# Run the requested Flutter command
Write-Host "🚀 Running: flutter $Command windows"
& flutter $Command windows @args

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build succeeded!"
} else {
    Write-Host "❌ Build failed"
}

exit $LASTEXITCODE
