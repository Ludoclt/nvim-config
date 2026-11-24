-- Format on save only in projects that chose a formatter style.
--
-- LazyVim formats every buffer on save. On someone else's project without a
-- formatter config, that rewrites whole files with our defaults and pollutes
-- the diff. This module looks upward from each file for a config of the
-- formatter of its filetype; when none is found it sets
-- `vim.b.autoformat = false` for that buffer. Filetypes not listed here are
-- never formatted on save.
--
-- Override per buffer with <leader>uF, globally with <leader>uf.
-- Formatting by hand (<leader>cf) always works.

local M = {}

---@class config.FormatRule
---@field filetypes string[]
---@field files? string[] presence of one of these files is enough
---@field content? table<string, string[]> these files count when they contain one of the Lua patterns

---@type config.FormatRule[]
M.rules = {
  {
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    files = { ".clang-format", "_clang-format" },
  },
  {
    filetypes = { "cmake" },
    files = { ".cmake-format", ".cmake-format.yaml", ".cmake-format.yml", ".cmake-format.json", ".cmake-format.py" },
  },
  {
    -- rustfmt is the ecosystem default: a Cargo project is enough
    filetypes = { "rust" },
    files = { "rustfmt.toml", ".rustfmt.toml", "Cargo.toml" },
  },
  {
    filetypes = { "python" },
    files = { "ruff.toml", ".ruff.toml" },
    content = { ["pyproject.toml"] = { "%[tool%.ruff", "%[tool%.black" } },
  },
  {
    filetypes = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
      "svelte",
      "astro",
      "json",
      "jsonc",
      "css",
      "scss",
      "less",
      "html",
      "yaml",
      "markdown",
      "graphql",
    },
    files = {
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
    },
    content = { ["package.json"] = { '"prettier"' } },
  },
  {
    filetypes = { "lua" },
    files = { "stylua.toml", ".stylua.toml" },
  },
  {
    filetypes = { "cs" },
    files = { ".csharpierrc", ".csharpierrc.json", ".csharpierrc.yaml" },
  },
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

---@param ft string
---@return config.FormatRule?
function M.rule(ft)
  for _, rule in ipairs(M.rules) do
    if vim.tbl_contains(rule.filetypes, ft) then
      return rule
    end
  end
end

--- Whether a project above `dir` has a formatter config for filetype `ft`.
---@param dir string
---@param ft string
---@return boolean
function M.has_config(dir, ft)
  local rule = M.rule(ft)
  if not rule then
    return false
  end
  local opts = { upward = true, path = dir, stop = vim.uv.os_homedir() }
  if rule.files and #vim.fs.find(rule.files, vim.tbl_extend("force", opts, { limit = 1 })) > 0 then
    return true
  end
  local content = rule.content or {}
  local found = vim.fs.find(vim.tbl_keys(content), vim.tbl_extend("force", opts, { limit = math.huge }))
  for _, file in ipairs(found) do
    if contains(file, content[vim.fs.basename(file)]) then
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
  if name == "" or vim.bo[buf].filetype == "" then
    return
  end
  if not M.has_config(vim.fs.dirname(vim.fs.abspath(name)), vim.bo[buf].filetype) then
    vim.b[buf].autoformat = false
  end
end

function M.setup()
  -- FileType rather than BufRead: the decision depends on the filetype.
  vim.api.nvim_create_autocmd("FileType", {
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
