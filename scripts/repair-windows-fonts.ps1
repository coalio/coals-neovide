param(
    [string]$FontSource = (Join-Path (Split-Path -Parent $PSScriptRoot) "assets\windows\fonts"),
    [string]$FontDestination = (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"),
    [string]$FontFamily = "Hack Nerd Font Mono",
    [string]$FontFilePattern = "HackNerdFontMono*.ttf",
    [switch]$ConfigureWindowsTerminal
)

$ErrorActionPreference = "Stop"

function Add-NativeFontMethods {
    if ("Win32.FontRefresh" -as [type]) {
        return
    }

    Add-Type -Namespace Win32 -Name FontRefresh -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("gdi32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
public static extern int AddFontResourceW(string lpFileName);
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
public static extern System.IntPtr SendMessageTimeout(System.IntPtr hWnd, int Msg, System.UIntPtr wParam, string lParam, int flags, int timeout, out System.UIntPtr result);
'@
}

function Get-EmbeddedFontFamilies {
    param([Parameter(Mandatory = $true)][string]$Path)

    Add-Type -AssemblyName System.Drawing
    $collection = New-Object System.Drawing.Text.PrivateFontCollection
    try {
        $collection.AddFontFile($Path)
        return @($collection.Families | ForEach-Object { $_.Name })
    } finally {
        $collection.Dispose()
    }
}

function Get-FontRegistryValueName {
    param(
        [Parameter(Mandatory = $true)][string]$Family,
        [Parameter(Mandatory = $true)][System.IO.FileInfo]$FontFile
    )

    $type = if ($FontFile.Extension -ieq ".otf") { "OpenType" } else { "TrueType" }
    $baseName = $FontFile.BaseName
    $style = "Regular"

    if ($baseName -match "(BoldItalic|BoldOblique)") {
        $style = "Bold Italic"
    } elseif ($baseName -match "Bold") {
        $style = "Bold"
    } elseif ($baseName -match "(Italic|Oblique)") {
        $style = "Italic"
    }

    if ($style -eq "Regular") {
        return "$Family ($type)"
    }

    return "$Family $style ($type)"
}

function Remove-StaleFontRegistryEntries {
    param(
        [Parameter(Mandatory = $true)][string]$FontRegistryPath,
        [Parameter(Mandatory = $true)][string]$Family,
        [Parameter(Mandatory = $true)][System.IO.FileInfo[]]$FontFiles
    )

    $key = Get-Item $FontRegistryPath
    $fileBaseNames = @($FontFiles | ForEach-Object { $_.BaseName })
    $fileNames = @($FontFiles | ForEach-Object { $_.Name })

    foreach ($name in $key.GetValueNames()) {
        $value = [string]$key.GetValue($name)
        $nameWithoutType = $name -replace " \((TrueType|OpenType)\)$", ""

        if (
            $name -like "$Family*" -or
            $fileBaseNames -contains $nameWithoutType -or
            $fileNames -contains $value -or
            ($value -and ($fileNames | Where-Object { $value.EndsWith($_, [StringComparison]::OrdinalIgnoreCase) }))
        ) {
            Remove-ItemProperty -Path $FontRegistryPath -Name $name -ErrorAction SilentlyContinue
        }
    }
}

function Test-FontFamilyVisible {
    param([Parameter(Mandatory = $true)][string]$Family)

    Add-Type -AssemblyName System.Drawing
    $installed = New-Object System.Drawing.Text.InstalledFontCollection
    return [bool]($installed.Families | Where-Object { $_.Name -eq $Family })
}

function Update-WindowsTerminalFont {
    param([Parameter(Mandatory = $true)][string]$Family)

    $settingsPaths = @(
        (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
    )

    foreach ($path in $settingsPaths) {
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $text = [IO.File]::ReadAllText($path)
        if ($text -notmatch "BitstromWera Nerd Font Mono") {
            continue
        }

        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backup = "$path.coals-neovide-fontfix-$timestamp.bak"
        Copy-Item -LiteralPath $path -Destination $backup -Force
        $text = $text -replace "BitstromWera Nerd Font Mono", $Family
        [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))

        Write-Host "Updated Windows Terminal font in $path"
        Write-Host "Backup saved to $backup"
    }
}

if (-not (Test-Path -LiteralPath $FontSource)) {
    throw "Font source does not exist: $FontSource"
}

New-Item -ItemType Directory -Force -Path $FontDestination | Out-Null

$sourceFonts = @(Get-ChildItem -LiteralPath $FontSource -File -Filter $FontFilePattern)
if (-not $sourceFonts) {
    throw "No fonts matched $FontFilePattern under $FontSource"
}

$installedFonts = foreach ($font in $sourceFonts) {
    $destination = Join-Path $FontDestination $font.Name
    if (Test-Path -LiteralPath $destination) {
        $existing = Get-Item -LiteralPath $destination
        if ($existing.Length -ne $font.Length) {
            throw "Font file already exists but differs and may be in use: $destination. Close apps using the font, then rerun this script."
        }
    } else {
        Copy-Item -LiteralPath $font.FullName -Destination $destination -Force
    }
    Get-Item -LiteralPath $destination
}

$fontRegistryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
New-Item -Path $fontRegistryPath -Force | Out-Null
Remove-StaleFontRegistryEntries -FontRegistryPath $fontRegistryPath -Family $FontFamily -FontFiles $installedFonts

Add-NativeFontMethods

foreach ($font in $installedFonts) {
    $families = @(Get-EmbeddedFontFamilies -Path $font.FullName)
    if ($families -notcontains $FontFamily) {
        Write-Warning "$($font.Name) does not advertise '$FontFamily'. Embedded families: $($families -join ', ')"
    }

    foreach ($family in $families) {
        $valueName = Get-FontRegistryValueName -Family $family -FontFile $font
        New-ItemProperty -Path $fontRegistryPath -Name $valueName -Value $font.FullName -PropertyType String -Force | Out-Null
    }

    [void][Win32.FontRefresh]::AddFontResourceW($font.FullName)
}

$result = [UIntPtr]::Zero
[void][Win32.FontRefresh]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [UIntPtr]::Zero, $null, 2, 1000, [ref]$result)

if ($ConfigureWindowsTerminal) {
    Update-WindowsTerminalFont -Family $FontFamily
}

if (-not (Test-FontFamilyVisible -Family $FontFamily)) {
    throw "Windows still cannot see font family '$FontFamily'. Close and reopen Windows Terminal/Neovide, then rerun this script."
}

Write-Host "Registered $FontFamily for the current user."
Get-Item $fontRegistryPath |
    ForEach-Object {
        $key = $_
        foreach ($name in ($key.GetValueNames() | Where-Object { $_ -like "$FontFamily*" } | Sort-Object)) {
            [pscustomobject]@{
                Name = $name
                Value = $key.GetValue($name)
                Exists = Test-Path -LiteralPath $key.GetValue($name)
            }
        }
    } |
    Format-Table -AutoSize
