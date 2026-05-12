# Coal's Neovide + WSL Neovim Setup

This repository captures the Windows Neovide + WSL Neovim setup migrated from the Ubuntu distro stored on the `V:` partition.

It vendors the custom/local pieces so another Windows + WSL machine can reproduce the setup without rediscovering paths, versions, launch flags, fonts, and config details.

## Included Versions

- Neovide for Windows: `0.15.2`
- Neovim for WSL: `0.11.6`
- Node for WSL tooling: `24.14.1` vendored as a Linux x64 tarball
- OpenClaude CLI package: `@gitlawb/openclaude@0.4.0` vendored as an npm tarball
- Coc extensions installed by the WSL script: `coc-css`, `coc-html`, `coc-json`

## Repository Layout

```text
assets/windows/neovide/          Neovide Windows executable
assets/windows/launcher/         Custom Neovim.exe launcher and source/icon assets
assets/windows/neovide-config/   Neovide AppData config files
assets/windows/fonts/            Nerd fonts used by the GUI config
assets/wsl/nvim/                 Neovim 0.11.6 Linux binary and matching runtime
assets/wsl/nvim-config/          Neovim config copied from the mounted Ubuntu distro
assets/wsl/coc-config/           Coc config/package manifest
assets/wsl/node/                 Node 24.14.1 Linux x64 tarball and checksum file
assets/wsl/npm/                  OpenClaude 0.4.0 npm tarball
scripts/                         Windows, WSL, and verification scripts
docs/                            Migration log, dependencies, and troubleshooting
checksums/                       SHA-256 checksums for vendored assets
```

## Install On A New Machine

Prerequisites:

- Windows 10/11 with WSL2 enabled.
- An Ubuntu WSL distro.
- Internet access for Neovim plugin git clones, unless you separately vendor the Lazy plugin cache.
- Run the Windows installer from an elevated PowerShell if installing to `C:\Program Files\Neovide`.
- The WSL installer uses `sudo` for `/usr/local/bin/nvim` and `/usr/local/share/nvim`, so it may prompt for the distro user's password.

From WSL:

```bash
cd ~/opensource/coals-neovide
bash scripts/install-wsl.sh
```

From Windows PowerShell, either inside this repo or using the Windows path to it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1
```

If running PowerShell from WSL:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w scripts/install-windows.ps1)"
```

## Verify

From WSL:

```bash
bash scripts/verify-wsl.sh
```

From Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-windows.ps1
```

## Installed Paths

Windows:

- `C:\Program Files\Neovide\neovide.exe`
- `%USERPROFILE%\utils\Neovim.exe`
- `%LOCALAPPDATA%\neovide\neovide-settings.json`
- `%APPDATA%\neovide\config.toml`
- `%LOCALAPPDATA%\Microsoft\Windows\Fonts\*.ttf`
- `HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe`

WSL:

- `/usr/local/bin/nvim`
- `/usr/local/share/nvim`
- `~/.config/nvim`
- `~/.config/coc`
- `~/.local/share/fonts`
- `~/.local/share/coals-neovide/node-v24.14.1-linux-x64`

## Important Considerations

- The Neovim binary and runtime must match. This repo installs both `nvim` and `/usr/local/share/nvim` from the same `0.11.6` source.
- Neovide starts WSL with a login shell. The WSL installer adds a `.zprofile` PATH block so Coc can find the repo-local Node binary.
- The original Windows context menu/MSIX package is intentionally not installed. It was skipped because the certificate/MSIX path was not reliable.
- Existing files are backed up before replacement under `~/coals-neovide-backups` in WSL and `%USERPROFILE%\coals-neovide-backups` on Windows.

See [docs/migration-log.md](docs/migration-log.md), [docs/dependencies.md](docs/dependencies.md), and [docs/troubleshooting.md](docs/troubleshooting.md) for details.
