# Neovim config

A small Neovim setup centered on Python, Rust, and Lua. It uses Neovim's built-in LSP and plugin manager, fzf-lua for finding things, Conform for formatting, and Lightline for the statusline. Completion is manual with `<C-x><C-o>`; there is no completion menu while typing.

## Setup

Use Neovim 0.12 or newer and run `nvim` to install the plugins listed in `init.lua`. Keep `nvim-pack-lock.json` with the config for repeatable plugin versions.

Install the tools you use:

| Purpose | Executable |
| --- | --- |
| Finding files and text | `fzf`, `rg` |
| Python language server and formatter | `basedpyright-langserver`, `black` |
| Rust language server, checks, and formatting | `rust-analyzer`, `cargo` with Clippy and rustfmt |
| Lua language server and formatter | `lua-language-server`, `stylua` |
| Zig language server and formatter | `zls`, `zig` |
| HTML formatter | `deno` |

Additional language server configs for Ruby, Swift, Odin, and JavaScript/TypeScript live in `lsp/`.
Use matching Zig and ZLS release series (for example, Zig 0.16 with ZLS 0.16).

## Key commands

| Keys or command | Action |
| --- | --- |
| `<leader>sf` / `<leader>sg` / `<leader>sb` | Find files / search text / switch buffers |
| `<leader>ss` / `<leader>sS` | Search document / workspace symbols |
| `<C-x>` in the buffer picker | Close a buffer |
| `<leader>f` | Format the current buffer |
| `<C-x><C-o>` in insert mode | Request LSP completion |
| `:InlayHints` | Toggle inlay hints for the current buffer (off by default) |
| `<Esc>` in normal mode | Clear search highlighting |

Python uses Black. Lua uses StyLua and the two-space style in `stylua.toml`. Rust uses rustfmt on save and Clippy for checks through rust-analyzer. Zig uses `zig fmt` on save. HTML uses `deno fmt` on save.
