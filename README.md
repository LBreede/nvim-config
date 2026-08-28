# Neovim Config

Personal Neovim configuration layered over
[`naysayer.nvim`](https://github.com/LBreede/naysayer.nvim).

The `base/` submodule provides the standalone, plugin-free editor. This
repository adds daily-driver plugins, LSP configuration, formatting, and
build/run commands without duplicating the base config.

## Install

```sh
git clone --recurse-submodules \
  git@github.com:LBreede/nvim-config.git \
  "$HOME/.config/nvim"
```

## Update Base

```sh
git submodule update --remote base
git add base
git commit -m "chore: update base config"
git push
```

## Layout

```text
init.lua              loads the base config
base/                 naysayer.nvim submodule
after/plugin/         personal options, plugins, and workflows
lsp/                  native Neovim LSP configurations
nvim-pack-lock.json   vim.pack lockfile
```
