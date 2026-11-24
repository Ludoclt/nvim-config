-- Headless smoke test, run by scripts/smoke-test.sh:
--   nvim --headless -c "luafile tests/smoke.lua"
-- Exits with status 0 when every check passes, 1 otherwise.

local failures = 0

local function check(name, ok, detail)
  if ok then
    io.stdout:write(("  ok    %s\n"):format(name))
  else
    failures = failures + 1
    io.stdout:write(("  FAIL  %s%s\n"):format(name, detail and (": " .. detail) or ""))
  end
end

local function finish()
  io.stdout:write(failures == 0 and "smoke test passed\n" or ("%d check(s) failed\n"):format(failures))
  vim.cmd(failures == 0 and "qall!" or "cquit! 1")
end

local function run()
  io.stdout:write("startup\n")
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

  if vim.env.SMOKE_SKIP_PARSERS ~= "1" then
    local absent = {}
    for _, lang in ipairs(LazyVim.opts("nvim-treesitter").ensure_installed or {}) do
      if not pcall(vim.treesitter.language.add, lang) then
        absent[#absent + 1] = lang
      end
    end
    check("treesitter parsers installed", #absent == 0, table.concat(absent, ", "))
  end

  io.stdout:write("azerty layer\n")
  local function maps_to(lhs, rhs, mode)
    local map = vim.fn.maparg(lhs, mode or "n", false, true)
    return map.rhs == rhs, ("%s -> %s"):format(lhs, tostring(map.rhs))
  end
  for _, pair in ipairs({ { "(", "[" }, { ")", "]" }, { "ù", "%" }, { "à", "0" } }) do
    for _, mode in ipairs({ "n", "x", "o" }) do
      check(("%s aliases %s (%s)"):format(pair[1], pair[2], mode), maps_to(pair[1], pair[2], mode))
    end
  end
  check("local leader is é", vim.g.maplocalleader == "é")
  check("<C-ù> opens the terminal", vim.fn.maparg("<C-ù>", "n") ~= "")

  -- `)q` must reach LazyVim's `]q` (next quickfix entry) through the alias.
  vim.fn.setqflist({}, "r", {
    items = {
      { filename = "smoke-a", lnum = 1, text = "a" },
      { filename = "smoke-b", lnum = 1, text = "b" },
    },
  })
  vim.cmd("silent! cfirst")
  local function qf_idx()
    return vim.fn.getqflist({ idx = 0 }).idx
  end
  vim.api.nvim_feedkeys(vim.keycode(")q"), "mtx", false)
  check(")q goes to the next quickfix entry", qf_idx() == 2, "idx " .. qf_idx())
  vim.api.nvim_feedkeys(vim.keycode("(q"), "mtx", false)
  check("(q goes back", qf_idx() == 1, "idx " .. qf_idx())

  -- ù jumps to the matching bracket.
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "f(a, (b), c)" })
  vim.api.nvim_win_set_cursor(0, { 1, 1 })
  vim.api.nvim_feedkeys(vim.keycode("ù"), "mtx", false)
  check("ù jumps to the matching bracket", vim.api.nvim_win_get_cursor(0)[2] == 11)

  -- The aliases must not leak into text objects or f/t targets.
  local function edit(keys, col)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "foo(bar, baz) end" })
    vim.api.nvim_win_set_cursor(0, { 1, col })
    vim.api.nvim_feedkeys(vim.keycode(keys), "mtx", false)
    return vim.api.nvim_get_current_line()
  end
  check("di) still deletes inside parentheses", edit("di)", 5) == "foo() end")
  check("ci( still changes inside parentheses", edit("ci(x<Esc>", 5) == "foo(x) end")
  check("dt) still deletes up to the parenthesis", edit("dt)", 0) == ") end")

  io.stdout:write("format on save detection\n")
  local format = require("config.format")
  local root = vim.fn.tempname()
  local function project(name, files)
    local dir = vim.fs.joinpath(root, name)
    vim.fn.mkdir(vim.fs.joinpath(dir, "src"), "p")
    for file, text in pairs(files) do
      vim.fn.writefile(vim.split(text, "\n"), vim.fs.joinpath(dir, file))
    end
    return vim.fs.joinpath(dir, "src")
  end
  check("no config: off", not format.has_config(project("bare", {})))
  check(".clang-format: on", format.has_config(project("clang", { [".clang-format"] = "BasedOnStyle: LLVM" })))
  check("Cargo.toml: on", format.has_config(project("rust", { ["Cargo.toml"] = "[package]" })))
  check("pyproject with [tool.ruff]: on", format.has_config(project("ruff", { ["pyproject.toml"] = "[tool.ruff]" })))
  check("pyproject without formatter: off", not format.has_config(project("py", { ["pyproject.toml"] = "[project]" })))

  local bare = vim.fs.joinpath(project("bare2", {}), "main.c")
  vim.fn.writefile({ "int main(void){return 0;}" }, bare)
  vim.cmd.edit(bare)
  check("buffer without config gets autoformat=false", vim.b.autoformat == false)
  local clang = vim.fs.joinpath(project("clang2", { [".clang-format"] = "BasedOnStyle: LLVM" }), "main.c")
  vim.fn.writefile({ "int main(void){return 0;}" }, clang)
  vim.cmd.edit(clang)
  check("buffer with config inherits the global setting", vim.b.autoformat == nil)
  vim.fn.delete(root, "rf")

  finish()
end

-- `-c` runs before VimEnter: wait for LazyVim to load the lazy config
-- (keymaps, autocmds) on VeryLazy, then run the checks. lazy.nvim fires
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
