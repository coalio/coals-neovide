# Troubleshooting

## `_assert_integer` Startup Error

Symptom:

```text
attempt to call field '_assert_integer' (a nil value)
```

Cause:

The Neovim binary and runtime do not match. In the migration, `nvim` was `0.11.6` but `/usr/local/share/nvim/runtime` was still from a newer development build.

Fix:

Run:

```bash
bash scripts/install-wsl.sh
```

Or manually install both:

```bash
sudo install -m 0755 assets/wsl/nvim/bin/nvim /usr/local/bin/nvim
sudo rm -rf /usr/local/share/nvim
sudo cp -a assets/wsl/nvim/share/nvim /usr/local/share/nvim
```

## Neovim Config Is Missing Or Not A Git Checkout

The installer expects `~/.config/nvim` to be a clone of:

```text
https://github.com/coalio/nvim-config
```

Fix:

```bash
bash scripts/install-wsl.sh
```

Or manually:

```bash
rm -rf ~/.config/nvim
git clone https://github.com/coalio/nvim-config ~/.config/nvim
```

## Coc Says `node` Is Not Executable

Symptom:

```text
[coc.nvim] "node" is not executable
```

Cause:

Neovide launches WSL through a login shell, and the login shell may not read `.zshrc`. PATH changes only in `.zshrc` are invisible to Neovide-launched Neovim.

Fix:

The WSL installer adds a managed `.zprofile` block:

```zsh
export PATH="$HOME/.local/share/coals-neovide/node-v24.14.1-linux-x64/bin:$PATH"
```

Then verify:

```bash
zsh -l -c 'command -v node && node --version'
```

## Neovide Launcher Cannot Find `neovide.exe`

The custom `Neovim.exe` launcher calls `ShellExecuteW(..., "neovide.exe", ...)`.

The Windows installer adds:

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe
```

Verify:

```powershell
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe'
```

## Context Menu Is Missing

Expected. This repo intentionally does not install the old MSIX/context-menu package because that path depended on a certificate/MSIX setup that was not reliable.

The launcher remains available at:

```text
%USERPROFILE%\utils\Neovim.exe
```

## Font Looks Wrong

Verify Windows font files:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" *NerdFont*.ttf
```

Verify WSL fontconfig:

```bash
fc-match 'Hack Nerd Font Mono'
```

## WSL Interop From Shell Fails

If `powershell.exe`, `cmd.exe`, or `wsl.exe` from inside WSL prints a `UtilAcceptVsock` timeout, the shell may have a stale `WSL_INTEROP` value.

Check live sockets:

```bash
ls -la /run/WSL/*_interop
```

Then retry with a live socket:

```bash
WSL_INTEROP=/run/WSL/2_interop powershell.exe -NoProfile -Command '$PSVersionTable.PSVersion'
```
