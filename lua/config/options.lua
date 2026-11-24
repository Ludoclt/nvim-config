-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Keyboard layout: enables the AZERTY layer in lua/config/azerty.lua.
-- Set to false on a QWERTY keyboard to keep stock LazyVim keymaps.
vim.g.azerty = true

-- `\` (stock local leader) needs AltGr on AZERTY. `é` is a direct key with no
-- normal-mode meaning (`,` and `;` are taken by flash.nvim's f/t repeat).
if vim.g.azerty then
  vim.g.maplocalleader = "é"
end

-- Format on save stays enabled globally, but lua/config/format.lua turns it off
-- for buffers whose project has no formatter config (see README).
vim.g.autoformat = true
