-- C / C++: clangd, make tasks and the quickfix list (lua/plugins/cpp.lua).
---@param t SmokeTest
return function(t)
  local check = t.check
  local dir = t.sample("c")

  if t.has("clangd attaches to a C file", "clangd") then
    vim.cmd.edit("main.c")
    local client = t.wait(30000, function()
      return vim.lsp.get_clients({ bufnr = 0, name = "clangd" })[1]
    end)
    check("clangd attaches to a C file", client)
    if client then
      local cmd = table.concat(client.config.cmd, " ")
      check(
        "clangd trusts cross compilers (--query-driver)",
        cmd:find("--query-driver=/usr/bin/arm-none-eabi-*", 1, true)
      )
      -- gd on the call to square() must land on its definition (line 3).
      t.wait(10000, function()
        return client.initialized and not vim.tbl_isempty(client.server_capabilities or {})
      end)
      vim.api.nvim_win_set_cursor(0, { 8, 17 })
      vim.lsp.buf.definition()
      check(
        "go to definition works",
        t.wait(15000, function()
          return vim.api.nvim_win_get_cursor(0)[1] == 3
        end),
        "cursor at line " .. vim.api.nvim_win_get_cursor(0)[1]
      )
    end
  end

  check("build keymap <leader>mm exists", vim.fn.maparg("<leader>mm", "n") ~= "")

  local overseer = require("overseer")
  --- Run a task by name and wait for it to finish; returns its status.
  local function run_task(name)
    local task
    overseer.run_task({ name = name, autostart = true }, function(created)
      task = created
    end)
    return t.wait(120000, function()
      return task and task:is_complete() and task.status
    end)
  end

  check("make task builds the sample", run_task("make") == "SUCCESS" and vim.uv.fs_stat(dir .. "/app"))

  -- A compile error must land in the quickfix list, with its line.
  local lines = vim.fn.readfile(dir .. "/main.c")
  lines[4] = "int broken(void) { return undefined_symbol; }"
  vim.fn.writefile(lines, dir .. "/main.c")
  vim.fn.delete(dir .. "/app")
  check("make task reports the failure", run_task("make") == "FAILURE")
  local errors = vim.tbl_filter(function(item)
    return item.valid == 1 and item.lnum == 4
  end, vim.fn.getqflist())
  check("compile error is in the quickfix list", #errors > 0, #vim.fn.getqflist() .. " quickfix items")

  if t.has("bear -- make writes compile_commands.json", "bear") then
    vim.fn.writefile(vim.fn.readfile(t.samples .. "/c/main.c"), dir .. "/main.c")
    run_task("bear -- make")
    check("bear -- make writes compile_commands.json", vim.uv.fs_stat(dir .. "/compile_commands.json"))
  end

  -- CMake: configure and build through the <leader>m keymaps. The quickfix
  -- window left open by the failed make above must not get in the way.
  local cmake_dir = t.sample("cmake")
  if t.has("CMake configure writes compile_commands.json", "cmake") then
    require("lazy").load({ plugins = { "cmake-tools.nvim" } })
    vim.api.nvim_feedkeys(vim.keycode("<leader>mg"), "mtx", false)
    check(
      "CMake configure writes compile_commands.json",
      t.wait(60000, function()
        return vim.uv.fs_stat(cmake_dir .. "/compile_commands.json")
      end)
    )
    vim.api.nvim_feedkeys(vim.keycode("<leader>mm"), "mtx", false)
    check(
      "CMake build (target all) into build/<type>/",
      t.wait(60000, function()
        return #vim.fn.glob(cmake_dir .. "/build/*/app", false, true) > 0
      end),
      vim.fn.glob(cmake_dir .. "/build/*", false, true)[1] or "no build directory"
    )
  end

  -- CMake language server
  if t.has("CMake language server attaches", "neocmakelsp") then
    vim.cmd.edit("CMakeLists.txt")
    check(
      "CMake language server attaches",
      t.wait(30000, function()
        return vim.lsp.get_clients({ bufnr = 0, name = "neocmake" })[1]
      end)
    )
  end
end
