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
- `git` and internet access for cloning `https://github.com/coalio/nvim-config` plus Lazy plugin cloning/updating.
- `curl` only if you choose to update vendored assets manually.

Installed by this repo:

- `/usr/local/bin/nvim`
- `/usr/local/share/nvim`
- `~/.config/nvim`, cloned from `https://github.com/coalio/nvim-config` and reset to this repo's pinned submodule commit.
- `~/.config/coc`
- `~/.local/share/fonts`
- `~/.local/share/coals-neovide/node-v24.14.1-linux-x64`
- `@gitlawb/openclaude@0.4.0` under the repo-local Node prefix.

The repo-local Node install is used instead of putting files under `~/.nvm` when nvm is not actually managing that installation.
Local `.claude` and `.openclaude` permission files from the source Neovim config are intentionally excluded because they are machine-specific and are not required for Neovide or Neovim startup.
The Neovim config itself is now represented as a Git submodule rather than copied files, so changes to that config should be made in `coalio/nvim-config` and then the submodule pointer should be advanced here.

## External Network Use

The repo vendors the Neovide binary, Neovim binary/runtime, Node tarball, OpenClaude tarball, and fonts. The Neovim config is pinned as a Git submodule.

The WSL installer still uses network access for:

- Cloning `https://github.com/coalio/nvim-config`.
- Lazy plugin clone/update operations.
- Coc extension installation through Coc/npm if those extensions are not already installed.

To make the repo fully offline, vendor a tested `~/.local/share/nvim/lazy` plugin cache and adjust `scripts/install-wsl.sh` to copy it before running Lazy.
