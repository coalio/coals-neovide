# Coal's Neovide + WSL Neovim Setup

Reproducible Windows Neovide + WSL Neovim setup migrated from the Ubuntu distro that was stored on the `V:` partition.

The goal of this repo is to keep the binaries, launchers, fonts, config pointers, install scripts, and gotchas in one place so the setup can be reproduced on another Windows machine without rediscovering every dependency.

## What This Installs

- Windows Neovide `0.15.2`.
- Custom Windows `Neovim.exe` launcher for opening files through Neovide/WSL.
- Neovide AppData config.
- Nerd fonts used by the GUI config.
- WSL Neovim `0.11.6` binary plus matching runtime.
- Neovim config cloned from the `assets/wsl/nvim-config` submodule:
  `https://github.com/coalio/nvim-config`
- Coc config and extensions: `coc-css`, `coc-html`, `coc-json`.
- Node `24.14.1` for WSL tooling, installed under `~/.local/share/coals-neovide`.
- `@gitlawb/openclaude@0.4.0`, installed under the repo-local Node prefix.

## Config Features

The Neovim config is NvChad-based and is tracked as a submodule instead of copied into this repo as loose files.

Core experience:

- NvChad `v2.5` base with the `material-deep-ocean` theme.
- Neovide-specific GUI tuning: `Hack Nerd Font Mono:h12`, synced titlebar colors, remembered window size, round corner preference, faster cursor animation, `F11` fullscreen, and zoom controls on `Ctrl++`, `Ctrl+-`, and `Ctrl+0`.
- Alpha dashboard with new-file, recent-projects, Browse, quit, and recent-workspace entries.
- Session restoration with `persistence.nvim`; opening without args restores the last session, and opening a directory loads that workspace's session when available.
- NvimTree root handling that follows selected workspaces without forcing root changes during normal editing.

Custom workflow features:

- Browse picker: `<leader>f` opens a Telescope-backed directory browser from home. `Enter` descends into folders or opens files; `Ctrl-o` opens the current folder as a workspace, loads its session, opens NvimTree, and focuses the tree.
- Recent projects picker from `project.nvim`, surfaced on the dashboard and through the Browse flow.
- Toggleable bottom pane for terminal and problems:
  - `Ctrl-j`: toggle bottom terminal.
  - `<leader>pt`: open bottom terminal.
  - `<leader>pp`: open problems.
  - `<leader>pc`: close bottom pane.
  - `:BottomTerm`, `:Problems`, and `:BottomPaneClose` commands.
- Bottom pane has winbar tabs for Terminal and Problems, fixed-height/fixed-buffer behavior, and routing so buffer switches do not replace the pane content.
- Problems view reads Coc diagnostics into the quickfix list and displays them through `trouble.nvim`; if there are no diagnostics, it shows a stable "No problems" buffer.
- `:term`, `:te`, and `:terminal` are routed into the custom bottom terminal; `:vterm` opens a vertical terminal.
- Smart buffer close behavior keeps layouts intact when using `:q`, `:q!`, `:wq`, `F4`, or `<leader>q`.
- Explicit system clipboard mappings: `Ctrl-c` copies, `Ctrl-v` pastes in normal/insert/command/terminal modes while normal Vim registers remain internal by default.
- Visual multi-cursor support with `Ctrl-d`.
- Search/navigation shortcuts:
  - `Ctrl-p`: find files.
  - `F1`: keymaps.
  - `F2`: live grep.
  - `F3`: toggle search highlight.
  - `Ctrl-_`: fuzzy find in current buffer.
  - `Ctrl-Shift-b`: toggle NvimTree.
  - `<leader>r`: reveal current file in NvimTree.
  - `<leader>nr`: toggle relative line numbers.
- Coc language workflow:
  - `[g` / `]g`: previous/next diagnostic.
  - `gd`, `gy`, `gi`, `gr`: definition, type definition, implementation, references.
  - `K`: hover/help.
  - `<leader>rn`, `<leader>ca`, `<leader>qf`: rename, code action, quick fix.
  - `:Format` and `:OR` commands.
- OpenClaude integration through `coalio/openclaude.nvim`, using the vendored repo-local OpenClaude executable.

## Plugin Set

Pinned by `assets/wsl/nvim-config/lazy-lock.json`:

- `NvChad`, `base46`, `ui`, `volt`, `menu`, `minty`
- `lazy.nvim`
- `alpha-nvim`
- `persistence.nvim`
- `nvim-tree.lua`
- `telescope.nvim`, `plenary.nvim`
- `project.nvim`
- `coc.nvim`
- `trouble.nvim`
- `conform.nvim`
- `nvim-lspconfig`
- `nvim-treesitter`
- `nvim-cmp`, `cmp-buffer`, `cmp-nvim-lsp`, `cmp-nvim-lua`, `cmp_luasnip`, `cmp-async-path`
- `blink.cmp`
- `LuaSnip`, `friendly-snippets`
- `gitsigns.nvim`
- `indent-blankline.nvim`
- `nvim-autopairs`
- `nvim-web-devicons`
- `vim-visual-multi`
- `openclaude.nvim`
- `snacks.nvim`
- `nui.nvim`
- `mason.nvim`
- `which-key.nvim`

Some plugins are pinned by the lockfile but disabled in the current config, including `nvim-lspconfig`, `blink.cmp`, and `which-key.nvim`; Coc is the active language/completion path.

## Repository Layout

```text
assets/windows/neovide/          Neovide Windows executable
assets/windows/launcher/         Custom Neovim.exe launcher and source/icon assets
assets/windows/neovide-config/   Neovide AppData config files
assets/windows/fonts/            Nerd fonts used by the GUI config
assets/wsl/nvim/                 Neovim 0.11.6 Linux binary and matching runtime
assets/wsl/nvim-config/          Git submodule for https://github.com/coalio/nvim-config
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
- `git`, `bash`, `tar`, `rsync`, and `sudo` available in WSL.
- Internet access for cloning `coalio/nvim-config`, Lazy plugin clones, and Coc extension installation.
- Elevated PowerShell if installing Neovide to `C:\Program Files\Neovide`.

Clone with submodules if you want the pinned config visible in the repo checkout:

```bash
git clone --recurse-submodules https://github.com/coalio/coals-neovide ~/opensource/coals-neovide
```

If the repo was cloned without submodules:

```bash
git submodule update --init --recursive
```

Install the WSL side:

```bash
cd ~/opensource/coals-neovide
bash scripts/install-wsl.sh
```

Install the Windows side from elevated PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1
```

Or from WSL:

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
- The WSL installer clones `https://github.com/coalio/nvim-config` into `~/.config/nvim` and resets it to this repo's pinned submodule commit.
- Neovide starts WSL with a login shell. The WSL installer adds a `.zprofile` PATH block so Coc can find the repo-local Node binary.
- The original Windows context menu/MSIX package is intentionally not installed because the certificate/MSIX path was not reliable.
- Existing files are backed up before replacement under `~/coals-neovide-backups` in WSL and `%USERPROFILE%\coals-neovide-backups` on Windows.
- The checksum file covers files owned by this repository. The Neovim config submodule is pinned by Git rather than by `checksums/SHA256SUMS`.

See [docs/migration-log.md](docs/migration-log.md), [docs/dependencies.md](docs/dependencies.md), and [docs/troubleshooting.md](docs/troubleshooting.md) for details.
