-- Keymaps
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<Space>", "<Nop>", { silent = true })

vim.keymap.set("n", "<leader><leader>", "<C-^>")

vim.keymap.set({ "n", "x", "o" }, "H", "^")
vim.keymap.set({ "n", "x", "o" }, "L", "$")

vim.keymap.set("n", "n", "nzz", { silent = true })
vim.keymap.set("n", "N", "Nzz", { silent = true })
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>")

-- Use the home row for movement.
vim.keymap.set("n", "<Up>", "<Nop>")
vim.keymap.set("n", "<Down>", "<Nop>")
vim.keymap.set("n", "<Left>", "<Nop>")
vim.keymap.set("n", "<Right>", "<Nop>")

-- Editor options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.foldenable = false
vim.opt.scrolloff = 2
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Yank highlighting
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
  command = "silent! lua vim.highlight.on_yank({ timeout = 500 })",
})

-- Plugins
vim.pack.add({
  "https://github.com/wincent/base16-nvim",
  "https://github.com/itchyny/lightline.vim",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/stevearc/conform.nvim",
})

-- File and text search
-- fzf-lua has buffer deletion built in; mini.pick needed custom code.
local fzf = require("fzf-lua")
fzf.setup()
vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "Search text" })
vim.keymap.set("n", "<leader>sb", fzf.buffers, { desc = "Find buffer" })
vim.keymap.set("n", "<leader>ss", fzf.lsp_document_symbols, { desc = "Find symbol" })
vim.keymap.set("n", "<leader>sS", fzf.lsp_live_workspace_symbols, { desc = "Find workspace symbol" })

-- Colorscheme
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.cmd.colorscheme("gruvbox-dark-hard")
vim.api.nvim_set_hl(0, "Comment", { link = "Boolean" })

-- Diagnostics and LSP mappings
vim.diagnostic.config({ virtual_text = true })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

vim.api.nvim_create_user_command("InlayHints", function()
  local filter = { bufnr = 0 }
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
end, { desc = "Toggle inlay hints in the current buffer" })

-- Formatting
local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    python = { "black" },
    lua = { "stylua" },
    rust = { "rustfmt" },
  },
  format_on_save = function(buf)
    if vim.bo[buf].filetype == "rust" then
      return { timeout_ms = 5000, lsp_format = "fallback" }
    end
  end,
})
vim.keymap.set("n", "<leader>f", function()
  conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

-- Language-specific options and LSP mappings
local lsp_group = vim.api.nvim_create_augroup("LanguageServers", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = lsp_group,
  pattern = "lua",
  callback = function(event)
    vim.bo[event.buf].expandtab = true
    vim.bo[event.buf].shiftwidth = 2
    vim.bo[event.buf].softtabstop = 2
    vim.bo[event.buf].tabstop = 2
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  callback = function(event)
    local opts = { buffer = event.buf }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set("n", "<leader>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "x" }, "<leader>a", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.lsp.semantic_tokens.enable(false, { bufnr = event.buf })
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = lsp_group,
  pattern = "rust",
  callback = function()
    vim.wo.colorcolumn = "100"
  end,
})

-- Statusline
vim.opt.showmode = false

-- Language servers
vim.lsp.enable({ "rust_analyzer", "ruby_lsp", "basedpyright", "lua_ls", "sourcekit", "ols", "ts_ls" })
