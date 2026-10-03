return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },
  settings = {
    ["rust-analyzer"] = {
      cargo = { features = "all" },
      checkOnSave = true,
      imports = { group = { enable = false } },
      completion = { postfix = { enable = false } },
      check = {
        command = "clippy",
      },
    },
  },
}
