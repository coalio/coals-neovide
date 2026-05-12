#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$HOME/coals-neovide-backups/wsl-$timestamp"
node_dir="$HOME/.local/share/coals-neovide/node-v24.14.1-linux-x64"
node_tar="$repo_root/assets/wsl/node/node-v24.14.1-linux-x64.tar.xz"
openclaude_tgz="$repo_root/assets/wsl/npm/gitlawb-openclaude-0.4.0.tgz"
nvim_config_url="https://github.com/coalio/nvim-config.git"
nvim_config_path="$repo_root/assets/wsl/nvim-config"

backup_path() {
  local path="$1"
  if [ -e "$path" ]; then
    local safe_name="$path"
    if [[ "$safe_name" == "$HOME/"* ]]; then
      safe_name="${safe_name#"$HOME/"}"
    fi
    safe_name="${safe_name#/}"
    safe_name="${safe_name//\//__}"
    mkdir -p "$backup_root"
    mv "$path" "$backup_root/$safe_name"
  fi
}

require_file() {
  local path="$1"
  if [ ! -e "$path" ]; then
    printf 'Missing required file: %s\n' "$path" >&2
    exit 1
  fi
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$command_name" >&2
    exit 1
  fi
}

if [ "$(uname -m)" != "x86_64" ]; then
  printf 'This vendored Node/Neovim setup is for x86_64 WSL only. Detected: %s\n' "$(uname -m)" >&2
  exit 1
fi

require_file "$repo_root/assets/wsl/nvim/bin/nvim"
require_file "$repo_root/assets/wsl/nvim/share/nvim/runtime"
require_file "$node_tar"
require_file "$openclaude_tgz"
require_command git
require_command rsync
require_command tar

backup_path "$HOME/.config/nvim"
backup_path "$HOME/.config/coc"
backup_path "$HOME/.local/share/nvim"
backup_path "$HOME/.local/state/nvim"
backup_path "$HOME/.cache/nvim"

mkdir -p "$HOME/.config" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache"

nvim_config_ref=""
if git -C "$repo_root" rev-parse --verify "HEAD:assets/wsl/nvim-config" >/dev/null 2>&1; then
  nvim_config_ref="$(git -C "$repo_root" rev-parse "HEAD:assets/wsl/nvim-config")"
elif git -C "$nvim_config_path" rev-parse --verify HEAD >/dev/null 2>&1; then
  nvim_config_ref="$(git -C "$nvim_config_path" rev-parse HEAD)"
fi

printf 'Cloning Neovim config from %s...\n' "$nvim_config_url"
git clone "$nvim_config_url" "$HOME/.config/nvim"
if [ -n "$nvim_config_ref" ]; then
  git -C "$HOME/.config/nvim" reset --hard "$nvim_config_ref" >/dev/null
fi

rsync -a "$repo_root/assets/wsl/coc-config/" "$HOME/.config/coc/"

printf 'Installing Neovim 0.11.6 binary and matching runtime...\n'
sudo -v
sudo sh -c "
  set -e
  if [ -e /usr/local/share/nvim ]; then
    mkdir -p '$backup_root'
    mv /usr/local/share/nvim '$backup_root/nvim-runtime'
  fi
  install -m 0755 '$repo_root/assets/wsl/nvim/bin/nvim' /usr/local/bin/nvim
  mkdir -p /usr/local/share
  cp -a '$repo_root/assets/wsl/nvim/share/nvim' /usr/local/share/nvim
"

printf 'Installing WSL fonts...\n'
mkdir -p "$HOME/.local/share/fonts"
rsync -a "$repo_root/assets/windows/fonts/" "$HOME/.local/share/fonts/"
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$HOME/.local/share/fonts" >/dev/null || true
fi

printf 'Installing repo-local Node and OpenClaude...\n'
mkdir -p "$HOME/.local/share/coals-neovide"
rm -rf "$node_dir"
tar -xJf "$node_tar" -C "$HOME/.local/share/coals-neovide"
"$node_dir/bin/npm" install -g --prefix "$node_dir" "$openclaude_tgz" >/dev/null

zprofile="$HOME/.zprofile"
touch "$zprofile"
if ! grep -q "BEGIN coals-neovide" "$zprofile"; then
  cat >> "$zprofile" <<'EOF'

# BEGIN coals-neovide
export PATH="$HOME/.local/share/coals-neovide/node-v24.14.1-linux-x64/bin:$PATH"
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
# END coals-neovide
EOF
fi

export PATH="$node_dir/bin:$PATH"

printf 'Installing Lazy plugins...\n'
nvim --headless '+Lazy! sync' '+qa'

printf 'Installing Coc extensions...\n'
nvim --headless '+CocInstall -sync coc-css coc-html coc-json' '+qa'

printf 'Verifying Neovim startup...\n'
nvim --headless '+qa'

printf '\nWSL install complete.\n'
printf 'Backups, if any, are under: %s\n' "$backup_root"
printf 'Neovim: %s\n' "$(nvim --version | sed -n '1p')"
printf 'Node: %s\n' "$(node --version)"
printf 'OpenClaude: %s\n' "$(openclaude --version 2>/dev/null || true)"
