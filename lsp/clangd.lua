-- clangd uses compile_commands.json or compile_flags.txt when present.
return {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = { "compile_commands.json", "compile_flags.txt", ".git" },
}
