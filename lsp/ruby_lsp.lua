return {
  cmd = function(dispatchers, config)
    return vim.lsp.rpc.start({ "mise", "exec", "ruby@4.0.6", "--", "ruby-lsp" }, dispatchers, {
      cwd = config.root_dir,
    })
  end,
  filetypes = { "ruby", "eruby" },
  root_markers = { "Gemfile", ".ruby-version", ".git" },
  init_options = {
    formatter = "rubocop",
    linters = { "rubocop" },
    addonSettings = {
      ["Ruby LSP Rails"] = { enablePendingMigrationsPrompt = false },
    },
  },
}
