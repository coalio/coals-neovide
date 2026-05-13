# Troubleshooting

## Windows Says `Hack Nerd Font Mono` Is Missing

Symptoms:

```text
Unable to find the following fonts: Hack Nerd Font Mono
```

or Neovide prints:

```text
Font can't be updated to: FontOptions { ... family: "Hack Nerd Font Mono" ... }
Following fonts couldn't be loaded ...
```

This can happen after a Windows update or reboot even when the font file still exists under:

```text
%LOCALAPPDATA%\Microsoft\Windows\Fonts
```

The usual failure is a stale per-user font registry value under:

```text
HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts
```

Windows may leave a filename-only value such as:

```text
HackNerdFontMono-Regular (TrueType) = HackNerdFontMono-Regular.ttf
```

That is not reliable for per-user fonts after reboot. The value must use the embedded family name and a full path:

```text
Hack Nerd Font Mono (TrueType) = C:\Users\<user>\AppData\Local\Microsoft\Windows\Fonts\HackNerdFontMono-Regular.ttf
```

### Fix

From this repo in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\repair-windows-fonts.ps1 -ConfigureWindowsTerminal
```

From WSL:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w scripts/repair-windows-fonts.ps1)" -ConfigureWindowsTerminal
```

Then close and reopen Windows Terminal and Neovide. Do not switch the setup to Bitstrom; this setup uses `Hack Nerd Font Mono`.

### Diagnose

Check the font file exists:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" HackNerdFontMono*.ttf
```

Check the registry value:

```powershell
$key = Get-Item 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
$key.GetValue('Hack Nerd Font Mono (TrueType)')
```

The returned value should be a full path, and `Test-Path` should return `True`:

```powershell
$path = $key.GetValue('Hack Nerd Font Mono (TrueType)')
Test-Path -LiteralPath $path
```

Check whether Windows can resolve the family:

```powershell
Add-Type -AssemblyName System.Drawing
$fonts = New-Object System.Drawing.Text.InstalledFontCollection
$fonts.Families | Where-Object Name -eq 'Hack Nerd Font Mono'
```

Check whether Windows Terminal still references Bitstrom:

```powershell
Select-String `
  -LiteralPath "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" `
  -Pattern 'Bitstrom|Hack'
```

If `BitstromWera Nerd Font Mono` appears, rerun:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\repair-windows-fonts.ps1 -ConfigureWindowsTerminal
```

## WSL Cannot Run `powershell.exe`

If WSL prints this when running `powershell.exe`, `cmd.exe`, or `wsl.exe`:

```text
exec format error
```

then WSL interop is not registered in `binfmt_misc`.

Diagnose:

```bash
cat /proc/sys/fs/binfmt_misc/WSLInterop
```

If that file is missing, repair it:

```bash
sudo sh -c 'echo ":WSLInterop:M::MZ::/init:PF" > /proc/sys/fs/binfmt_misc/register'
```

Then retry:

```bash
powershell.exe -NoProfile -Command '$PSVersionTable.PSVersion'
```

## Neovim `_assert_integer` Startup Error

Symptom:

```text
attempt to call field '_assert_integer' (a nil value)
```

Cause:

The Neovim binary and runtime do not match.

Fix:

```bash
bash scripts/install-wsl.sh
```

## Coc Says `node` Is Not Executable

Symptom:

```text
[coc.nvim] "node" is not executable
```

Fix:

The WSL installer adds this managed login-shell PATH block:

```zsh
export PATH="$HOME/.local/share/coals-neovide/node-v24.14.1-linux-x64/bin:$PATH"
```

Verify:

```bash
zsh -l -c 'command -v node && node --version'
```
