-- AZERTY layer: puts the LazyVim keys that need AltGr or Shift on AZERTY
-- under direct keys. Stock keys keep working; this only adds aliases.
-- Disable with `vim.g.azerty = false` in lua/config/options.lua.
-- The full table lives in docs/AZERTY.md.

if not vim.g.azerty then
  return
end

local nxo = { "n", "x", "o" }

-- `[` / `]` (AltGr+5 / AltGr+°) prefix every "previous/next" motion:
-- ]d diagnostic, ]h git hunk, ]f function, ]b buffer, ]q quickfix...
-- `(` / `)` are direct keys; their stock meaning (sentence motions) is of
-- little use in code. remap = true so that `(d` resolves to the `[d` mapping.
vim.keymap.set(nxo, "(", "[", { remap = true, desc = "Prev (AZERTY alias of [)" })
vim.keymap.set(nxo, ")", "]", { remap = true, desc = "Next (AZERTY alias of ])" })

-- `%` (Shift+ù): jump to the matching bracket. remap = true keeps matchit.
vim.keymap.set(nxo, "ù", "%", { remap = true, desc = "Matching pair (AZERTY alias of %)" })

-- `0` (Shift+à): start of line. Counts are unaffected: digits already need Shift.
vim.keymap.set(nxo, "à", "0", { desc = "Start of line (AZERTY alias of 0)" })

-- `^` is a dead key on AZERTY: use `_` (key 8), which Vim already maps to
-- "first non-blank character". Nothing to add here.

-- `<C-/>` (floating terminal) is Ctrl+Shift+: on AZERTY.
vim.keymap.set({ "n", "t" }, "<C-ù>", function()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
