-- rustup discovers rust-src itself. Use a local fallback when a toolchain does not.
local sysroot_src = vim.fn.expand("~/.local/share/rust-src/current/lib/rustlib/src/rust/library")

local config = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },
}

-- sysrootSrc is initialization-only and must omit the rust-analyzer prefix.
if vim.fn.isdirectory(sysroot_src) == 1 then
  config.init_options = {
    cargo = {
      sysrootSrc = sysroot_src,
    },
  }
end

return config
