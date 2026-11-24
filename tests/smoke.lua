-- Headless smoke test, run by scripts/smoke-test.sh:
--   nvim --headless -c "luafile tests/smoke.lua"
-- Runs every suite in tests/suites/ in name order. Exits with status 0 when
-- every check passes, 1 otherwise.

---@class SmokeTest
local t = { failures = 0 }

--- Record one check.
---@param name string
---@param ok any
---@param detail? string shown on failure
function t.check(name, ok, detail)
  if ok then
    io.stdout:write(("  ok    %s\n"):format(name))
  else
    t.failures = t.failures + 1
    io.stdout:write(("  FAIL  %s%s\n"):format(name, detail and detail ~= "" and (": " .. detail) or ""))
  end
end

--- Report a check that cannot run here.
function t.skip(name, why)
  io.stdout:write(("  skip  %s (%s)\n"):format(name, why))
end

--- Wait for `cond`, processing events. Returns its last truthy value.
---@param ms integer
---@param cond fun(): any
function t.wait(ms, cond)
  local result
  vim.wait(ms, function()
    result = cond()
    return result
  end, 50)
  return result
end

--- Whether an executable needed by a check is there. Missing tools fail the
--- check, except offline (SMOKE_OFFLINE=1) where they are only skipped.
---@param name string check name
---@param exe string
function t.has(name, exe)
  if vim.fn.executable(exe) == 1 then
    return true
  end
  if t.offline then
    t.skip(name, exe .. " not installed")
  else
    t.check(name, false, exe .. " not installed")
  end
  return false
end

t.offline = vim.env.SMOKE_OFFLINE == "1"
t.repo = vim.fn.stdpath("config")
t.samples = vim.fs.joinpath(t.repo, "tests", "samples")

--- Copy tests/samples/{name} into a fresh temporary directory and cd there.
---@param name string
---@return string dir
function t.sample(name)
  local dir = vim.fs.joinpath(vim.fn.tempname(), name)
  vim.fn.mkdir(dir, "p")
  vim.system({ "cp", "-r", vim.fs.joinpath(t.samples, name) .. "/.", dir }):wait()
  vim.cmd.cd(dir)
  return dir
end

local function run()
  local suites = vim.fn.globpath(vim.fs.joinpath(t.repo, "tests", "suites"), "*.lua", false, true)
  table.sort(suites)
  for _, file in ipairs(suites) do
    io.stdout:write(vim.fn.fnamemodify(file, ":t:r") .. "\n")
    local ok, err = pcall(dofile(file), t)
    if not ok then
      t.check("suite ran to the end", false, tostring(err))
    end
    vim.cmd("silent! %bwipeout!")
    vim.cmd.cd(t.repo)
  end
  io.stdout:write(t.failures == 0 and "smoke test passed\n" or ("%d check(s) failed\n"):format(t.failures))
  vim.cmd(t.failures == 0 and "qall!" or "cquit! 1")
end

-- `-c` runs before VimEnter: wait for LazyVim to load the lazy config
-- (keymaps, autocmds) on VeryLazy, then run the suites. lazy.nvim fires
-- VeryLazy on UIEnter, which never happens headless: emit it ourselves.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      vim.api.nvim_exec_autocmds("UIEnter", { modeline = false })
    end)
  end,
})
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.schedule(function()
      local ok, err = pcall(run)
      if not ok then
        io.stdout:write("  FAIL  test crashed: " .. tostring(err) .. "\n")
        vim.cmd("cquit! 1")
      end
    end)
  end,
})
