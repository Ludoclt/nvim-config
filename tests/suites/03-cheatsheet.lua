-- Keymaps documented in docs/CHEATSHEET.md: tables after
-- `<!-- check: global -->` list LazyVim keymaps, and each key of their first
-- column must still exist after plugin updates.
---@param t SmokeTest
return function(t)
  local check = t.check

  local sheet = vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "CHEATSHEET.md")
  local absent, checked, in_table = {}, 0, false
  for _, line in ipairs(vim.fn.readfile(sheet)) do
    if line:match("^<!%-%- check: global %-%->") then
      in_table = true
    elseif in_table and not line:match("^|") then
      in_table = false
    elseif in_table and not line:match("^| %-") and not line:match("^| Keys") then
      local cell = line:match("^|([^|]*)|")
      for key in cell:gmatch("`([^`]+)`") do
        checked = checked + 1
        if vim.fn.maparg(key, "n") == "" then
          absent[#absent + 1] = key
        end
      end
    end
  end
  check(("%d documented keymaps exist"):format(checked), checked > 0 and #absent == 0, table.concat(absent, " "))
end
