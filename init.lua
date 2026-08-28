local base = vim.fs.joinpath(vim.fn.stdpath("config"), "base")

vim.opt.runtimepath:prepend(base)
dofile(vim.fs.joinpath(base, "init.lua"))
