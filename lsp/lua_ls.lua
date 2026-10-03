return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", "stylua.toml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = "Disable", library = { vim.env.VIMRUNTIME } },
      hint = { enable = true },
      format = { enable = false },
    },
  },
}
