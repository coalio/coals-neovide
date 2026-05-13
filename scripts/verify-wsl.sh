#!/usr/bin/env bash
set -euo pipefail

echo "Neovim:"
nvim --version | sed -n '1,4p'

echo
echo "Runtime:"
nvim --clean --headless '+lua print(vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch)' '+qa'

echo
echo "Neovim config:"
if git -C "$HOME/.config/nvim" remote get-url origin >/dev/null 2>&1; then
  git -C "$HOME/.config/nvim" remote get-url origin
  git -C "$HOME/.config/nvim" rev-parse --short HEAD
else
  echo "$HOME/.config/nvim is not a git checkout"
  exit 1
fi

echo
echo "Node:"
if command -v node >/dev/null 2>&1; then
  command -v node
  node --version
else
  echo "node not found"
  exit 1
fi

echo
echo "OpenClaude:"
if command -v openclaude >/dev/null 2>&1; then
  command -v openclaude
  openclaude --version
else
  echo "openclaude not found"
fi

echo
echo "Fonts:"
if command -v fc-match >/dev/null 2>&1; then
  fc-match 'Hack Nerd Font Mono'
else
  echo "fc-match not found"
fi

echo
echo "Neovim startup:"
nvim --headless '+qa'
echo "OK"
