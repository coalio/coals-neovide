# Dependencies

## Windows

Required:

- Windows 10/11.
- WSL2.
- PowerShell 5.1 or newer.
- Admin PowerShell if installing Neovide to `C:\Program Files\Neovide`.

Installed by this repo:

- `C:\Program Files\Neovide\neovide.exe`
- `%USERPROFILE%\utils\Neovim.exe`
- Neovide user config.
- User fonts.
- User PATH entry for Neovide.
- User App Paths entry for `neovide.exe`.

Not installed:

- Windows Explorer context menu integration.
- MSIX sparse package registration.
- Any certificate for `Coal.Utils.Neovim`.

## WSL

Required:

- Ubuntu or another glibc-based x86_64 WSL distro.
- `bash`, `tar`, `rsync`, `sudo`.
- `git` and internet access for Lazy plugin cloning/updating.
- `curl` only if you choose to update vendored assets manually.

Installed by this repo:

- `/usr/local/bin/nvim`
- `/usr/local/share/nvim`
- `~/.config/nvim`
- `~/.config/coc`
- `~/.local/share/fonts`
- `~/.local/share/coals-neovide/node-v24.14.1-linux-x64`
- `@gitlawb/openclaude@0.4.0` under the repo-local Node prefix.

The repo-local Node install is used instead of putting files under `~/.nvm` when nvm is not actually managing that installation.
Local `.claude` and `.openclaude` permission files from the source Neovim config are intentionally excluded because they are machine-specific and are not required for Neovide or Neovim startup.

## External Network Use

The repo vendors the Neovide binary, Neovim binary/runtime, Node tarball, OpenClaude tarball, fonts, and config.

The WSL installer still uses network access for:

- Lazy plugin clone/update operations.
- Coc extension installation through Coc/npm if those extensions are not already installed.

To make the repo fully offline, vendor a tested `~/.local/share/nvim/lazy` plugin cache and adjust `scripts/install-wsl.sh` to copy it before running Lazy.
