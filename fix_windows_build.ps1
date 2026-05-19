# Fix Windows build by removing Firebase plugins from CMake configuration
# This script should be run after 'flutter pub get' and before 'flutter build windows'

$pluginsCMakePath = "windows\flutter\generated_plugins.cmake"

if (Test-Path $pluginsCMakePath) {
    Write-Host "Fixing Windows build - removing Firebase plugins from CMake..."
    
    $content = Get-Content $pluginsCMakePath -Raw
    
    # Replace the FLUTTER_PLUGIN_LIST to exclude Firebase plugins
    $newContent = $content -replace `
        'list\(APPEND FLUTTER_PLUGIN_LIST.*?(?=\n\nlist\(APPEND FLUTTER_FFI_PLUGIN_LIST)', `
        'list(APPEND FLUTTER_PLUGIN_LIST
  file_selector_windows
)'
    
    # Alternative approach if the above doesn't work
    if ($newContent -eq $content) {
        Write-Host "Using alternative fix..."
        # Remove each firebase plugin entry manually
        $newContent = $content
        $firebasePlugins = @(
            'cloud_firestore',
            'firebase_auth',
            'firebase_core',
            'firebase_storage',
            'firebase_remote_config',
            'firebase_database',
            'firebase_app_check'
        )
        
        foreach ($plugin in $firebasePlugins) {
            $newContent = $newContent -replace "  $plugin`r?`n?", ""
        }
    }
    
    Set-Content $pluginsCMakePath -Value $newContent -NoNewline
    Write-Host "✓ Firebase plugins removed from CMake configuration"
} else {
    Write-Host "Error: generated_plugins.cmake not found at $pluginsCMakePath"
    exit 1
}
