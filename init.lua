-------------------------------------------------------------------------------
--
-- Keymaps
--
-------------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<Space>", "<Nop>", { silent = true })

-- vim.keymap.set("n", "<leader>w", "<Cmd>write<CR>") -- :w is fine
vim.keymap.set("n", "<leader><leader>", "<C-^>")

vim.keymap.set({ "n", "x", "o" }, "H", "^")
vim.keymap.set({ "n", "x", "o" }, "L", "$")

vim.keymap.set("n", "n", "nzz", { silent = true })
vim.keymap.set("n", "N", "Nzz", { silent = true })
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>")
vim.keymap.set("n", "<C-h>", "<Cmd>nohlsearch<CR>")

-- Use the home row for movement; Left/Right switch buffers in normal mode.
vim.keymap.set("n", "<Up>", "<Nop>")
vim.keymap.set("n", "<Down>", "<Nop>")
vim.keymap.set("n", "<Left>", "<Nop>")
vim.keymap.set("n", "<Right>", "<Nop>")
-- vim.keymap.set("n", "<Left>", ":bp<CR>")
-- vim.keymap.set("n", "<Right>", ":bn<CR>")
-- vim.keymap.set("i", "<Up>", "<Nop>")    -- One   day
-- vim.keymap.set("i", "<Down>", "<Nop>")  -- I    will
-- vim.keymap.set("i", "<Left>", "<Nop>")  -- uncomment
-- vim.keymap.set("i", "<Right>", "<Nop>") -- these  4!

-------------------------------------------------------------------------------
--
-- Editor options
--
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
--
-- Yank highlighting
--
-------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
  pattern = "*",
  command = "silent! lua vim.highlight.on_yank({ timeout = 500 })",
})

-------------------------------------------------------------------------------
--
-- Plugins
--
-------------------------------------------------------------------------------
vim.pack.add({
  "https://github.com/wincent/base16-nvim",
  "https://github.com/itchyny/lightline.vim",
  "https://github.com/ibhagwan/fzf-lua",
})

-------------------------------------------------------------------------------
--
-- File and text search
--
-------------------------------------------------------------------------------
-- fzf-lua has buffer deletion built in; mini.pick needed custom code.
local fzf = require("fzf-lua")
fzf.setup()
vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "Search text" })
vim.keymap.set("n", "<leader>sb", fzf.buffers, { desc = "Find buffer" })
vim.keymap.set("n", "<leader>ss", fzf.lsp_document_symbols, { desc = "Find symbol" })
vim.keymap.set("n", "<leader>sS", fzf.lsp_live_workspace_symbols, { desc = "Find workspace symbol" })

-------------------------------------------------------------------------------
--
-- Colorscheme
--
-------------------------------------------------------------------------------
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.cmd.colorscheme("gruvbox-dark-hard")
vim.api.nvim_set_hl(0, "Comment", { link = "Boolean" })

-------------------------------------------------------------------------------
--
-- Diagnostics and LSP mappings
--
-------------------------------------------------------------------------------
vim.diagnostic.config({ virtual_text = true, virtual_lines = false })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end)
vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

vim.api.nvim_create_user_command("InlayHints", function()
  local filter = { bufnr = 0 }
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
end, { desc = "Toggle inlay hints in the current buffer" })

local lsp_group = vim.api.nvim_create_augroup("LanguageServers", { clear = true })
local format_group = vim.api.nvim_create_augroup("RustFormat", { clear = true })

local function format_python(buf)
  if vim.fn.executable("uvx") ~= 1 then
    vim.notify("uvx is required to run Black 25", vim.log.levels.WARN)
    return
  end

  local filename = vim.api.nvim_buf_get_name(buf)
  if filename == "" then
    filename = "untitled.py"
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local result = vim
    .system({ "uvx", "--from", "black==25.12.0", "black", "--quiet", "--stdin-filename", filename, "-" }, {
      stdin = table.concat(lines, "\n") .. "\n",
      text = true,
    })
    :wait()
  if result.code ~= 0 then
    vim.notify("Black 25: " .. (result.stderr or "formatting failed"), vim.log.levels.ERROR)
    return
  end

  local formatted = vim.split(result.stdout or "", "\n", { plain = true })
  if formatted[#formatted] == "" then
    table.remove(formatted)
  end
  if not vim.deep_equal(lines, formatted) then
    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted)
    vim.fn.winrestview(view)
  end
  vim.bo[buf].endofline = true
end

local function format_lua(buf)
  if vim.fn.executable("stylua") ~= 1 then
    vim.notify("stylua is required to format Lua", vim.log.levels.WARN)
    return
  end

  local filename = vim.api.nvim_buf_get_name(buf)
  if filename == "" then
    filename = "untitled.lua"
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local result = vim
    .system({ "stylua", "--search-parent-directories", "--stdin-filepath", filename, "-" }, {
      stdin = table.concat(lines, "\n") .. "\n",
      text = true,
    })
    :wait()
  if result.code ~= 0 then
    vim.notify("StyLua: " .. (result.stderr or "formatting failed"), vim.log.levels.ERROR)
    return
  end

  local formatted = vim.split(result.stdout or "", "\n", { plain = true })
  if formatted[#formatted] == "" then
    table.remove(formatted)
  end
  if not vim.deep_equal(lines, formatted) then
    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted)
    vim.fn.winrestview(view)
  end
  vim.bo[buf].endofline = true
end

vim.api.nvim_create_autocmd("FileType", {
  group = lsp_group,
  pattern = "python",
  callback = function(event)
    vim.keymap.set("n", "<leader>f", function()
      format_python(event.buf)
    end, { buffer = event.buf, desc = "Format Python with Black 25" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = lsp_group,
  pattern = "lua",
  callback = function(event)
    vim.bo[event.buf].expandtab = true
    vim.bo[event.buf].shiftwidth = 2
    vim.bo[event.buf].softtabstop = 2
    vim.bo[event.buf].tabstop = 2
    vim.keymap.set("n", "<leader>f", function()
      format_lua(event.buf)
    end, { buffer = event.buf, desc = "Format Lua with StyLua" })
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end
    local opts = { buffer = event.buf }
    vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
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
    vim.keymap.set("n", "<leader>f", function()
      if vim.bo[event.buf].filetype == "python" then
        format_python(event.buf)
        return
      end
      if vim.bo[event.buf].filetype == "lua" then
        format_lua(event.buf)
        return
      end
      if not client:supports_method("textDocument/formatting") then
        vim.notify(client.name .. " does not provide formatting", vim.log.levels.INFO)
        return
      end
      vim.lsp.buf.format({ bufnr = event.buf, id = client.id, async = true })
    end, opts)
    vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
    vim.lsp.semantic_tokens.enable(false, { bufnr = event.buf })
    -- Replace this buffer's old callback when the server reattaches.
    vim.api.nvim_clear_autocmds({ group = format_group, event = "BufWritePre", buffer = event.buf })
    if client.name == "rust_analyzer" and client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        buffer = event.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = event.buf, name = "rust_analyzer", timeout_ms = 5000 })
        end,
      })
    end
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = lsp_group,
  pattern = "rust",
  callback = function()
    vim.wo.colorcolumn = "100"
  end,
})

-------------------------------------------------------------------------------
--
-- Statusline
--
-------------------------------------------------------------------------------
vim.opt.laststatus = 2
vim.opt.showmode = false

vim.g.lightline = {
  colorscheme = "editor",
  active = {
    left = {
      { "mode", "paste" },
      { "readonly", "filename", "modified" },
    },
    right = {
      { "lineinfo" },
      { "percent" },
      { "fileencoding", "filetype" },
    },
  },
}

-- Derive Lightline's palette from the current editor theme on every change.
local function refresh_statusline()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local function colors(name)
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    local fg = hl.fg or normal.fg or 0xffffff
    local bg = hl.bg or normal.bg or 0x000000
    if hl.reverse then
      fg, bg = bg, fg
    end
    return { string.format("#%06x", fg), string.format("#%06x", bg) }
  end
  local active = colors("StatusLine")
  local inactive = colors("StatusLineNC")
  local function mode_colors(name)
    return { active[2], colors(name)[1], "bold" }
  end
  vim.g["lightline#colorscheme#editor#palette"] = vim.fn["lightline#colorscheme#fill"]({
    normal = {
      left = { mode_colors("Function"), active },
      middle = { active },
      right = { active, active },
      error = { colors("DiagnosticError") },
      warning = { colors("DiagnosticWarn") },
    },
    inactive = { left = { inactive }, middle = { inactive }, right = { inactive } },
    insert = { left = { mode_colors("String"), active } },
    replace = { left = { mode_colors("ErrorMsg"), active } },
    visual = { left = { mode_colors("Statement"), active } },
    tabline = { left = { inactive }, middle = { inactive }, right = { active }, tabsel = { active } },
  })
  vim.fn["lightline#init"]()
  vim.fn["lightline#colorscheme"]()
  vim.fn["lightline#update"]()
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("StatuslineColors", { clear = true }),
  callback = refresh_statusline,
})
refresh_statusline()

-------------------------------------------------------------------------------
--
-- Language servers
--
-------------------------------------------------------------------------------
-- Report a missing executable only when opening its language.
for _, name in ipairs({ "rust_analyzer", "ruby_lsp", "basedpyright", "lua_ls", "sourcekit", "ols", "ts_ls" }) do
  local config = vim.lsp.config[name]
  local executable = name == "ruby_lsp" and "mise" or config.cmd[1]
  if vim.fn.executable(executable) == 1 then
    vim.lsp.enable(name)
  else
    vim.api.nvim_create_autocmd("FileType", {
      group = lsp_group,
      pattern = config.filetypes,
      once = true,
      callback = function()
        vim.notify("Install " .. executable .. " and restart Neovim to enable " .. name, vim.log.levels.WARN)
      end,
    })
  end
end
