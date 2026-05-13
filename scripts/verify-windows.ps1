$ErrorActionPreference = "Stop"

$neovide = "C:\Program Files\Neovide\neovide.exe"
$launcher = Join-Path $env:USERPROFILE "utils\Neovim.exe"
$localConfig = Join-Path $env:LOCALAPPDATA "neovide\neovide-settings.json"
$roamingConfig = Join-Path $env:APPDATA "neovide\config.toml"
$fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$fontFamily = "Hack Nerd Font Mono"
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
    Where-Object { $_.Name -match "HackNerdFontMono" }
if (-not $fonts) {
    throw "Expected Nerd fonts were not found in $fontDir"
}
$fonts | Select-Object Name,Length | Format-Table -AutoSize

$fontRegistryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
$fontRegistry = Get-Item $fontRegistryPath
$fontRegistryValue = $fontRegistry.GetValue("$fontFamily (TrueType)")
if (-not $fontRegistryValue) {
    throw "Missing HKCU font registry entry for $fontFamily"
}
if (-not (Test-Path -LiteralPath $fontRegistryValue)) {
    throw "Font registry entry points to a missing file: $fontRegistryValue"
}
if ([IO.Path]::IsPathRooted($fontRegistryValue) -eq $false) {
    throw "Font registry entry must use a full path, not a filename-only value: $fontRegistryValue"
}

Add-Type -AssemblyName System.Drawing
$installedFonts = New-Object System.Drawing.Text.InstalledFontCollection
if (-not ($installedFonts.Families | Where-Object { $_.Name -eq $fontFamily })) {
    throw "Windows cannot see font family: $fontFamily"
}
Write-Host "Font family visible: $fontFamily"

$terminalSettings = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path -LiteralPath $terminalSettings) {
    $terminalText = Get-Content -Raw -LiteralPath $terminalSettings
    if ($terminalText -match "BitstromWera Nerd Font Mono") {
        throw "Windows Terminal still references BitstromWera Nerd Font Mono. Run scripts\repair-windows-fonts.ps1 -ConfigureWindowsTerminal"
    }
}

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
