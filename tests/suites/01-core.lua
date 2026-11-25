-- Startup: plugins, parsers, errors.
---@param t SmokeTest
return function(t)
  local check = t.check

  check("config loaded on VeryLazy", package.loaded["config.azerty"] ~= nil)

  local missing = {}
  for _, plugin in ipairs(require("lazy").plugins()) do
    if not plugin._.installed and plugin.enabled ~= false and plugin.cond ~= false then
      missing[#missing + 1] = plugin.name
    end
  end
  check("all plugins installed", #missing == 0, table.concat(missing, ", "))

  local errors = {}
  for _, line in ipairs(vim.split(vim.api.nvim_exec2("messages", { output = true }).output, "\n")) do
    if line:match("^E%d+:") or line:match("[Ee]rror") then
      errors[#errors + 1] = line
    end
  end
  check("no errors at startup", #errors == 0, table.concat(errors, " | "))

  if not t.offline then
    local absent = {}
    for _, lang in ipairs(LazyVim.opts("nvim-treesitter").ensure_installed or {}) do
      if not pcall(vim.treesitter.language.add, lang) then
        absent[#absent + 1] = lang
      end
    end
    check("treesitter parsers installed", #absent == 0, table.concat(absent, ", "))
  end
end
