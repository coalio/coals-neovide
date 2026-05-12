param(
    [string]$NeovideInstallDir = "$env:ProgramFiles\Neovide",
    [string]$LauncherInstallDir = "$env:USERPROFILE\utils",
    [switch]$SkipFonts
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$assets = Join-Path $repoRoot "assets\windows"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $env:USERPROFILE "coals-neovide-backups\windows-$timestamp"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Backup-Path {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        $safeName = ($Path -replace '^[A-Za-z]:', '') -replace '[\\/:*?"<>|]', '_'
        $safeName = $safeName.Trim("_")
        if (-not $safeName) {
            $safeName = Split-Path -Leaf $Path
        }
        Move-Item -LiteralPath $Path -Destination (Join-Path $backupRoot $safeName) -Force
    }
}

function Copy-DirectoryFresh {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    Backup-Path $Destination
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Copy-DirectoryContentsWithBackups {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        $target = Join-Path $Destination $_.Name
        Backup-Path $target
        Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
    }
}

if ($NeovideInstallDir.StartsWith($env:ProgramFiles, [StringComparison]::OrdinalIgnoreCase) -and -not (Test-IsAdmin)) {
    throw "Installing to $NeovideInstallDir requires an elevated PowerShell. Re-run as Administrator or pass -NeovideInstallDir under your user profile."
}

Copy-DirectoryFresh -Source (Join-Path $assets "neovide") -Destination $NeovideInstallDir
Copy-DirectoryContentsWithBackups -Source (Join-Path $assets "launcher") -Destination $LauncherInstallDir
Copy-DirectoryFresh -Source (Join-Path $assets "neovide-config\Local") -Destination (Join-Path $env:LOCALAPPDATA "neovide")
Copy-DirectoryFresh -Source (Join-Path $assets "neovide-config\Roaming") -Destination (Join-Path $env:APPDATA "neovide")

if (-not $SkipFonts) {
    $fontSource = Join-Path $assets "fonts"
    $fontDest = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    $fontReg = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

    New-Item -ItemType Directory -Force -Path $fontDest | Out-Null
    New-Item -Path $fontReg -Force | Out-Null

    if (-not ("Win32.NativeMethods" -as [type])) {
        Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("gdi32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
public static extern int AddFontResourceW(string lpFileName);
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
public static extern System.IntPtr SendMessageTimeout(System.IntPtr hWnd, int Msg, System.UIntPtr wParam, string lParam, int flags, int timeout, out System.UIntPtr result);
'@
    }

    Get-ChildItem -LiteralPath $fontSource -File | Where-Object { $_.Extension -in @(".ttf", ".otf") } | ForEach-Object {
        $destFile = Join-Path $fontDest $_.Name
        Copy-Item -LiteralPath $_.FullName -Destination $destFile -Force
        $type = if ($_.Extension -ieq ".otf") { "OpenType" } else { "TrueType" }
        $valueName = "$($_.BaseName) ($type)"
        New-ItemProperty -Path $fontReg -Name $valueName -Value $destFile -PropertyType String -Force | Out-Null
        [void][Win32.NativeMethods]::AddFontResourceW($destFile)
    }

    $result = [UIntPtr]::Zero
    [void][Win32.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [UIntPtr]::Zero, $null, 2, 1000, [ref]$result)
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathParts = @()
if ($userPath) {
    $pathParts = $userPath -split ";" | Where-Object { $_ }
}
if ($pathParts -notcontains $NeovideInstallDir) {
    [Environment]::SetEnvironmentVariable("Path", (($pathParts + $NeovideInstallDir) -join ";"), "User")
}

$appPathKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe")
$appPathKey.SetValue("", (Join-Path $NeovideInstallDir "neovide.exe"), [Microsoft.Win32.RegistryValueKind]::String)
$appPathKey.SetValue("Path", $NeovideInstallDir, [Microsoft.Win32.RegistryValueKind]::String)
$appPathKey.Close()

Write-Host "Installed Neovide to $NeovideInstallDir"
Write-Host "Installed launcher to $LauncherInstallDir"
Write-Host "Installed Neovide config under AppData"
Write-Host "Context-menu/MSIX registration was intentionally skipped."
if (Test-Path $backupRoot) {
    Write-Host "Backups saved under $backupRoot"
}
