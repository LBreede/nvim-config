return {
  cmd = { "sourcekit-lsp" },
  filetypes = { "swift" },
  root_markers = { "buildServer.json", ".bsp", "Package.swift", ".git" },
  capabilities = {
    workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
    textDocument = { diagnostic = { dynamicRegistration = true, relatedDocumentSupport = true } },
  },
}
