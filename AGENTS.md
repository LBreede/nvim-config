# AGENTS.md

## Repository Model

This is the daily-driver Neovim configuration.

`base/` is the `naysayer.nvim` submodule and contains the standalone,
plugin-free configuration. Everything outside `base/` belongs to this personal
overlay.

## Ownership

Change standalone editor behavior inside `base/` and commit it to the
`naysayer.nvim` repository.

Before editing the submodule, attach it to its branch and update it:

```sh
cd base
git switch master
git pull --ff-only
```

Change plugins, LSP configuration, personal options, keymaps, formatting,
building, and running in this repository. Do not duplicate base configuration
in the overlay.

## Style

Prefer native Neovim features. Add plugins only when they replace nontrivial
hand-rolled behavior.

Use `stylua` for Lua files.
