-- Rust overloads `'`. The mini.pairs default -- pair unless a letter is to the
-- left, which exists to protect English apostrophes -- has it exactly backwards
-- here: it closes lifetimes (`&'a str` becomes `&'a str'`) and leaves byte
-- literals open (`b'a`). Telling the two apart needs the whole surrounding
-- token, which a two-character `neigh_pattern` cannot see.
local pairs_mod = require("mini.pairs")

local function quote()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".") - 1
  local before, after = line:sub(1, col), line:sub(col + 1)
  -- A quote already to the right is jumped over, never doubled.
  if after:sub(1, 1) == "'" then
    return pairs_mod.closeopen("''", "..")
  end
  -- Quoting text that is already there would strand the closing quote.
  if after:match("^[%w_]") then
    return "'"
  end
  -- Lifetime positions: `&'a`, an unclosed `<` as in `Vec<'a` or `<'a, 'b>`,
  -- and the bounds `T: 'a` and `dyn Trait + 'a`.
  if before:match("&$") or before:match("<[^>]*$") or before:match("[:+]%s$") then
    return "'"
  end
  -- Rust has no `'` inside identifiers, so a trailing word is prose -- except a
  -- lone `b`, which opens a byte literal.
  local word = before:match("[%w_]*$")
  if word ~= "" and word ~= "b" then
    return "'"
  end
  -- What is left is a character literal: `= 'a'`, `('a')`, `'a'..='z'`.
  return pairs_mod.closeopen("''", "..")
end

-- `expr` mappings made with `vim.keymap.set` replace keycodes by default, but
-- mini.pairs returns keys that are already terminal codes.
vim.keymap.set("i", "'", quote, {
  buffer = 0,
  expr = true,
  replace_keycodes = false,
  desc = "Pair ' for character and byte literals",
})

-- Generics follow an identifier directly (`Vec<`) or a turbofish (`Vec::<`), a
-- comparison does not (`a < b`), and `>` only ever jumps over a bracket that is
-- already there, so `->`, `=>` and `<<` are untouched.
pairs_mod.map_buf(0, "i", "<", {
  action = "open",
  pair = "<>",
  neigh_pattern = "^[%w_:]",
  register = { cr = false },
})
pairs_mod.map_buf(0, "i", ">", {
  action = "close",
  pair = "<>",
  register = { cr = false },
})

local undo = "silent! iunmap <buffer> ' | silent! iunmap <buffer> < | silent! iunmap <buffer> >"
vim.b.undo_ftplugin = vim.b.undo_ftplugin and (vim.b.undo_ftplugin .. " | " .. undo) or undo
