# Migration Log

This is the concrete work that was required to migrate the setup from the Ubuntu distro stored on the `V:` partition.

## Source Mount

- Located the WSL Ubuntu disk at:
  `V:\Users\coal\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu22.04LTS_79rhkp1fndgsc\LocalState\ext4.vhdx`
- Mounted it read-only with WSL:
  `wsl.exe --mount ... --vhd --name ubuntu22-v --type ext4 --options ro`
- Read source files from:
  `/mnt/wsl/ubuntu22-v/home/coal`

## WSL Neovim

- Replaced the copied `~/.config/nvim` snapshot with a Git submodule for:
  `https://github.com/coalio/nvim-config`
- The WSL installer clones that repository into:
  `~/.config/nvim`
- The clone is reset to the submodule-pinned commit recorded by this setup repo.
- Installed the source distro's Neovim binary:
  `/mnt/wsl/ubuntu22-v/usr/local/bin/nvim`
- Matched local version:
  `NVIM v0.11.6`
- Replaced `/usr/local/share/nvim` with the matching runtime from the source distro.
- This runtime replacement was required because a newer local runtime caused:
  `attempt to call field '_assert_integer' (a nil value)`
- Installed/synced Lazy plugins.
- Installed Coc extensions:
  `coc-css`, `coc-html`, `coc-json`

## Windows Neovide

- Copied Neovide from:
  `V:\Program Files\Neovide`
- Installed to:
  `C:\Program Files\Neovide`
- Verified version:
  `neovide 0.15.2`
- Copied Neovide AppData config from:
  `V:\Users\coal\AppData\Local\neovide`
  `V:\Users\coal\AppData\Roaming\neovide`
- Installed current copies to:
  `%LOCALAPPDATA%\neovide`
  `%APPDATA%\neovide`

## Launcher

- Copied the custom launcher from:
  `V:\Users\coal\utils\Neovim.exe`
- Installed to:
  `%USERPROFILE%\utils\Neovim.exe`
- Added a user App Paths entry so `ShellExecute("neovide.exe")` can resolve Neovide:
  `HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe`
- The launcher source uses:
  `neovide.exe --maximized --wsl -- <converted file paths>`

## Fonts

- Copied and registered these user fonts:
  `BitstromWeraNerdFont*.ttf`
  `HackNerdFontMono-Regular.ttf`
- Installed them in Windows under:
  `%LOCALAPPDATA%\Microsoft\Windows\Fonts`
- Also copied them into WSL:
  `~/.local/share/fonts`
- Refreshed WSL fontconfig with:
  `fc-cache`

## Node And OpenClaude

- Coc requires `node` to be visible from the shell that Neovide launches.
- Neovide launches WSL with a login shell, so `.zprofile` matters.
- For reproducible installs, this repo vendors:
  `node-v24.14.1-linux-x64.tar.xz`
  `gitlawb-openclaude-0.4.0.tgz`
- The installer uses a local Node path under:
  `~/.local/share/coals-neovide/node-v24.14.1-linux-x64`

## Context Menu

- The original sparse MSIX/context-menu installer was intentionally skipped.
- The attempted package/certificate side effects were cleaned up:
  `Coal.Utils.Neovim` AppX package count was verified as `0`.
  The temporary `CN=Coal Utils` trusted certificate was removed.
  Exact known context-menu/CLSID keys were removed.

## Verification Performed

- `nvim --headless '+qa'` exited without errors.
- `nvim +'qa!'` exited with code `0`.
- `nvim --clean` reported `0.11.6`.
- `neovide.exe --version` reported `0.15.2`.
- Short Neovide WSL launch attached to Neovim and loaded `Hack Nerd Font Mono`.
