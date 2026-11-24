-- Format on save only in projects that chose a formatter style.
--
-- LazyVim formats every buffer on save. On someone else's project without a
-- formatter config, that rewrites whole files with our defaults and pollutes
-- the diff. This module looks upward from each file for a formatter config;
-- when none is found it sets `vim.b.autoformat = false` for that buffer.
--
-- Override per buffer with <leader>uF, globally with <leader>uf.
-- Formatting by hand (<leader>cf) always works.

local M = {}

-- Files whose presence means "this project has a formatter style".
M.markers = {
  -- C / C++
  ".clang-format",
  "_clang-format",
  -- Rust: rustfmt is the ecosystem default, a Cargo project is enough
  "rustfmt.toml",
  ".rustfmt.toml",
  "Cargo.toml",
  -- Python
  "ruff.toml",
  ".ruff.toml",
  -- JavaScript / TypeScript
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.json5",
  ".prettierrc.yaml",
  ".prettierrc.yml",
  ".prettierrc.toml",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
  "prettier.config.ts",
  "biome.json",
  "biome.jsonc",
  -- Lua
  "stylua.toml",
  ".stylua.toml",
  -- C#
  ".csharpierrc",
  ".csharpierrc.json",
  ".csharpierrc.yaml",
}

-- Files that only count when they contain one of these Lua patterns.
M.content_markers = {
  ["pyproject.toml"] = { "%[tool%.ruff", "%[tool%.black" },
  ["package.json"] = { '"prettier"' },
}

local function contains(file, patterns)
  local fd = io.open(file, "r")
  if not fd then
    return false
  end
  local text = fd:read("*a")
  fd:close()
  for _, pattern in ipairs(patterns) do
    if text:find(pattern) then
      return true
    end
  end
  return false
end

---@param dir string
---@return boolean
function M.has_config(dir)
  local opts = { upward = true, path = dir, stop = vim.uv.os_homedir() }
  if #vim.fs.find(M.markers, vim.tbl_extend("force", opts, { limit = 1 })) > 0 then
    return true
  end
  local names = vim.tbl_keys(M.content_markers)
  for _, file in ipairs(vim.fs.find(names, vim.tbl_extend("force", opts, { limit = math.huge }))) do
    if contains(file, M.content_markers[vim.fs.basename(file)]) then
      return true
    end
  end
  return false
end

---@param buf integer
function M.apply(buf)
  if vim.bo[buf].buftype ~= "" or vim.b[buf].autoformat ~= nil then
    return
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return
  end
  if not M.has_config(vim.fs.dirname(vim.fs.abspath(name))) then
    vim.b[buf].autoformat = false
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("config_format_detect", { clear = true }),
    callback = function(ev)
      M.apply(ev.buf)
    end,
  })
  -- Buffers opened before this module was loaded
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      M.apply(buf)
    end
  end
end

return M
