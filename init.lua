local base = vim.fs.joinpath(vim.fn.stdpath("config"), "base")

vim.opt.runtimepath:prepend(base)
dofile(vim.fs.joinpath(base, "init.lua"))

-- ============================================================
-- ENVIRONMENT
-- ============================================================
do
  -- Keep environment-provided tools ahead of user-local fallbacks.
  local user_bin = vim.fs.joinpath(vim.env.HOME, ".local", "bin")
  if not (":" .. (vim.env.PATH or "") .. ":"):find(":" .. user_bin .. ":", 1, true) then
    vim.env.PATH = (vim.env.PATH or "") .. ":" .. user_bin
  end
end

-- ============================================================
-- PLUGINS
-- ============================================================
do
  -- Pin the only third-party plugins to their stable branches.
  vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.pairs", version = "stable" },
    { src = "https://github.com/nvim-mini/mini.surround", version = "stable" },
  })

  require("mini.pairs").setup()
  require("mini.surround").setup()

  -- Bundled optional packages.
  vim.cmd.packadd("nvim.undotree")
  vim.cmd.packadd("cfilter")

  -- Compatibility command for Neovim 0.12.
  vim.api.nvim_create_user_command("PackUpdate", function()
    vim.pack.update()
  end, { desc = "Update the plugins managed by vim.pack" })
end

-- ============================================================
-- OPTIONS
-- ============================================================
do
  vim.o.number = true
  vim.o.relativenumber = true

  vim.o.mouse = "a"
  vim.o.signcolumn = "yes" -- always on, so text never shifts when a diagnostic appears

  vim.o.pummaxwidth = 60
  vim.o.pumheight = 12

  -- Allow trusted per-project configuration.
  vim.o.exrc = true

  vim.o.list = true
  vim.opt.listchars = { tab = "\u{bb} ", trail = "\u{b7}", nbsp = "\u{2423}" }

  vim.schedule(function()
    vim.o.clipboard = "unnamedplus"
  end)

  -- Return to the last cursor position recorded in ShaDa when reopening a file.
  vim.api.nvim_create_autocmd("BufReadPost", {
    desc = "Restore the last cursor position",
    group = vim.api.nvim_create_augroup("last-position", { clear = true }),
    callback = function(args)
      local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
      if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
        vim.api.nvim_win_set_cursor(0, mark)
      end
    end,
  })
end

-- ============================================================
-- KEYMAPS -- only what Neovim has no key for already
-- ============================================================
do
  -- Complete manually after text; preserve indentation and snippet navigation.
  vim.keymap.set("i", "<Tab>", function()
    if vim.fn.pumvisible() == 1 then
      return "<C-n>"
    end

    if vim.snippet.active({ direction = 1 }) then
      return "<Cmd>lua vim.snippet.jump(1)<CR>"
    end

    local col = vim.fn.col(".") - 1
    if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
      return "<Tab>"
    end

    return "<C-n>"
  end, { expr = true, desc = "Complete word" })

  vim.keymap.set("i", "<S-Tab>", function()
    if vim.fn.pumvisible() == 1 then
      return "<C-p>"
    end

    if vim.snippet.active({ direction = -1 }) then
      return "<Cmd>lua vim.snippet.jump(-1)<CR>"
    end

    return "<S-Tab>"
  end, { expr = true, desc = "Previous completion" })
end

-- ============================================================
-- LSP -- built in, no nvim-lspconfig and no mason
-- ============================================================
do
  -- Keep names available for the missing-server statusline check below.
  local servers = { "clangd", "basedpyright", "rust_analyzer", "ols" }
  vim.lsp.enable(servers)

  ---Show only the actionable state: a configured server is missing.
  ---@return string
  function _G.NaysayerStatuslineExtra()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
      return ""
    end
    for _, name in ipairs(servers) do
      local config = vim.lsp.config[name]
      if config and vim.tbl_contains(config.filetypes or {}, vim.bo.filetype) then
        return "  [no lsp]"
      end
    end
    return ""
  end

  -- Keep diagnostics off the canvas until requested.
  vim.diagnostic.config({
    virtual_text = false,
    underline = { severity = { min = vim.diagnostic.severity.WARN } },
    severity_sort = true,
    update_in_insert = false,
    float = { source = "if_many" }, -- the border comes from 'winborder'
  })

  -- :Diagnostics uses quickfix; :Diagnostics! uses the location list.
  vim.api.nvim_create_user_command("Diagnostics", function(opts)
    if opts.bang then
      vim.diagnostic.setloclist()
    else
      vim.diagnostic.setqflist()
    end
  end, { bang = true, desc = "Diagnostics into the quickfix list (! for location list)" })

  vim.keymap.set("n", "<leader>tl", function()
    vim.diagnostic.config({ virtual_lines = not vim.diagnostic.config().virtual_lines })
  end, { desc = "[T]oggle diagnostic [L]ines" })

  vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP keymaps",
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = function(event)
      -- These actions have no built-in LSP mapping.
      local map = function(keys, fn, desc)
        vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
      end
      map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
      map("gW", vim.lsp.buf.workspace_symbol, "Open Workspace Symbols")

      local client = vim.lsp.get_client_by_id(event.data.client_id)

      -- Enable manual built-in completion; leave autotrigger off.
      if client and client:supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, event.data.client_id, event.buf)
      end

      if client and client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
        map("<leader>th", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
        end, "[T]oggle Inlay [H]ints")
      end
    end,
  })
end

-- ============================================================
-- FORMATTING -- on demand only, never on save
-- ============================================================
do
  ---External stdin formatters by filetype; other filetypes use LSP formatting.
  local formatters = {
    python = function(name)
      return { "black", "--quiet", "--stdin-filename", name, "-" }
    end,
    lua = function(name)
      return { "stylua", "--stdin-filepath", name, "-" }
    end,
  }

  ---Filter the buffer through `argv`, keeping the cursor and scroll position.
  local function filter_through(buf, argv)
    if vim.fn.executable(argv[1]) ~= 1 then
      return vim.notify(argv[1] .. ": not on $PATH", vim.log.levels.WARN)
    end

    local input = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local result = vim.system(argv, { stdin = input }):wait()
    if result.code ~= 0 then
      return vim.notify(argv[1] .. ": " .. (result.stderr or "failed"), vim.log.levels.ERROR)
    end

    local formatted = vim.split(result.stdout or "", "\n")
    -- These tools always end with a newline, which `split` turns into a trailing
    --  empty element; writing it back would add a blank line on every format.
    if formatted[#formatted] == "" then
      table.remove(formatted)
    end
    if vim.deep_equal(input, formatted) then
      return
    end

    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted)
    vim.fn.winrestview(view)
  end

  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    local buf = vim.api.nvim_get_current_buf()
    local build = formatters[vim.bo[buf].filetype]
    if build then
      return filter_through(buf, build(vim.api.nvim_buf_get_name(buf)))
    end

    if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) == 0 then
      return vim.notify(("no formatter for filetype '%s'"):format(vim.bo[buf].filetype), vim.log.levels.WARN)
    end
    vim.lsp.buf.format({ bufnr = buf, timeout_ms = 5000 })
  end, { desc = "[F]ormat buffer" })
end

-- ============================================================
-- BUILDING AND RUNNING -- separate verbs, because they answer differently
-- ============================================================
do
  -- Build into quickfix; run interactively in a terminal split.
  local compilers = { c = "gcc", cpp = "gcc", rust = "cargo" }

  -- Read by cargo.vim as it loads, producing `cargo build $*`. Without it
  --  'makeprg' is a bare `cargo` and :make just prints the help text.
  vim.g.cargo_makeprg_params = "build"

  -- `main.odin(12:5) Error: undeclared identifier: foo`
  local odin_errorformat = [[%f(%l:%c) %m]]

  -- Parse a traceback into its innermost frame.
  local python_errorformat = table.concat({
    [[%A%*\sFile "%f"\, line %l\, in %o]],
    [[%A%*\sFile "%f"\, line %l]],
    [[%C %.%#]],
    [[%Z%m]],
    [[%-G%.%#]],
  }, ",")

  -- Arguments remain shell fragments; filenames are escaped here.
  local runners = {
    c = function(_, args)
      return "make run" .. (args == "" and "" or " ARGS=" .. vim.fn.shellescape(args))
    end,
    cpp = function(_, args)
      return "make run" .. (args == "" and "" or " ARGS=" .. vim.fn.shellescape(args))
    end,
    rust = function(_, args)
      return "cargo run" .. (args == "" and "" or " -- " .. args)
    end,
    odin = function(_, args)
      return "odin run ." .. (args == "" and "" or " -- " .. args)
    end,
    python = function(name, args)
      return "python " .. vim.fn.shellescape(name) .. (args == "" and "" or " " .. args)
    end,
  }

  vim.api.nvim_create_autocmd("FileType", {
    desc = "Set 'makeprg' and 'errorformat' for :make",
    group = vim.api.nvim_create_augroup("make", { clear = true }),
    pattern = { "c", "cpp", "rust", "odin", "python" },
    callback = function(event)
      local ft = vim.bo[event.buf].filetype
      if compilers[ft] then
        vim.cmd.compiler(compilers[ft])
      elseif ft == "odin" then
        vim.bo[event.buf].makeprg = "odin build ."
        vim.bo[event.buf].errorformat = odin_errorformat
      elseif ft == "python" then
        vim.bo[event.buf].makeprg = "python %"
        vim.bo[event.buf].errorformat = python_errorformat
      end
    end,
  })

  -- Python runs but has no build step.
  local buildable = { c = true, cpp = true, rust = true, odin = true }

  vim.keymap.set("n", "<leader>b", function()
    local ft = vim.bo.filetype
    if not buildable[ft] then
      local hint = runners[ft] and " -- use <leader>r to run it" or ""
      return vim.notify(("nothing to build for filetype '%s'%s"):format(ft, hint), vim.log.levels.WARN)
    end
    vim.cmd("update")
    vim.cmd("silent make")
    vim.cmd("redraw!")
  end, { desc = "[B]uild" })

  -- C and C++ projects expose their executable through a Makefile run target.
  local function run(args)
    local build = runners[vim.bo.filetype]
    if not build then
      return vim.notify(("nothing to run for filetype '%s'"):format(vim.bo.filetype), vim.log.levels.WARN)
    end
    vim.cmd("update")
    local cmd = build(vim.api.nvim_buf_get_name(0), args or "")
    vim.cmd.new()
    vim.cmd("resize 15")
    -- `termopen()` is deprecated as of 0.12; this is its replacement.
    vim.fn.jobstart(cmd, { term = true })
  end

  -- Command-line history retains previous argument sets.
  vim.api.nvim_create_user_command("Run", function(opts)
    run(opts.args)
  end, { nargs = "*", complete = "file", desc = "Run the current file, with arguments" })

  vim.keymap.set("n", "<leader>r", function()
    run("")
  end, { desc = "[R]un" })
  vim.keymap.set("n", "<leader>R", ":Run ", { desc = "[R]un with arguments" })

  -- Keep the overlay augroup separate from the base search augroup.
  vim.api.nvim_create_autocmd("QuickFixCmdPost", {
    desc = "Open quickfix when :make has entries",
    group = vim.api.nvim_create_augroup("quickfix-make", { clear = true }),
    pattern = "make",
    callback = function()
      vim.cmd(#vim.fn.getqflist() > 0 and "copen" or "cclose")
    end,
  })
end

-- ============================================================
-- SMALL THINGS
-- ============================================================

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Flash the yanked text",
  group = vim.api.nvim_create_augroup("yank-highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Promptly notice files changed by external tools.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  desc = "Check for files changed outside Neovim",
  group = vim.api.nvim_create_augroup("checktime", { clear = true }),
  callback = function()
    if vim.o.buftype == "" then
      vim.cmd.checktime()
    end
  end,
})
