-- OLS project-specific settings belong in ols.json.
return {
  cmd = { "ols" },
  filetypes = { "odin" },
  root_markers = { "ols.json", "odin.json", ".git" },
  init_options = {
    enable_format = true,
    enable_hover = true,
    enable_document_symbols = true,
    enable_references = true,
    enable_snippets = true,
  },
}
