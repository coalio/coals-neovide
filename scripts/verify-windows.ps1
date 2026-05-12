$ErrorActionPreference = "Stop"

$neovide = "C:\Program Files\Neovide\neovide.exe"
$launcher = Join-Path $env:USERPROFILE "utils\Neovim.exe"
$localConfig = Join-Path $env:LOCALAPPDATA "neovide\neovide-settings.json"
$roamingConfig = Join-Path $env:APPDATA "neovide\config.toml"
$fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$appPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe"

Write-Host "Neovide:"
if (Test-Path $neovide) {
    & $neovide --version
} else {
    throw "Missing $neovide"
}

Write-Host "`nLauncher:"
if (Test-Path $launcher) {
    Get-Item $launcher | Select-Object FullName,Length | Format-Table -AutoSize
} else {
    throw "Missing $launcher"
}

Write-Host "`nConfig:"
foreach ($path in @($localConfig, $roamingConfig)) {
    if (-not (Test-Path $path)) {
        throw "Missing $path"
    }
    Write-Host $path
}

Write-Host "`nFonts:"
$fonts = Get-ChildItem $fontDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "HackNerdFontMono|BitstromWeraNerdFont" }
if (-not $fonts) {
    throw "Expected Nerd fonts were not found in $fontDir"
}
$fonts | Select-Object Name,Length | Format-Table -AutoSize

Write-Host "`nApp Paths:"
if (Test-Path $appPath) {
    $appPathKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe")
    $defaultValue = $appPathKey.GetValue("")
    $pathValue = $appPathKey.GetValue("Path")
    $appPathKey.Close()
    Write-Host "Default: $defaultValue"
    Write-Host "Path: $pathValue"
    if (-not (Test-Path $defaultValue)) {
        throw "App Paths default points to a missing file: $defaultValue"
    }
} else {
    throw "Missing $appPath"
}

Write-Host "`nContext package count:"
$count = @((Get-AppxPackage -Name "Coal.Utils.Neovim" -ErrorAction SilentlyContinue)).Count
Write-Host $count
if ($count -ne 0) {
    throw "Coal.Utils.Neovim AppX package should not be installed by this repo."
}

Write-Host "`nOK"
