-- Embedded: templates, OpenOCD tasks, GDB remote debugging
-- (lua/plugins/embedded.lua). gdbserver stands in for OpenOCD's GDB server.
---@param t SmokeTest
return function(t)
  local check = t.check
  local dir = t.sample("c")

  vim.cmd("Template embedded")
  check(
    ":Template embedded copies the starter files",
    vim.uv.fs_stat(dir .. "/openocd.cfg")
      and vim.uv.fs_stat(dir .. "/.clangd")
      and vim.uv.fs_stat(dir .. "/.clang-format")
  )
  vim.fn.writefile({ "# mine" }, dir .. "/openocd.cfg")
  vim.cmd("Template embedded")
  check(":Template never overwrites", vim.fn.readfile(dir .. "/openocd.cfg")[1] == "# mine")

  local names
  require("overseer.template").list({ dir = dir }, function(tmpls)
    names = vim.tbl_map(function(tmpl)
      return tmpl.name
    end, tmpls)
  end)
  t.wait(10000, function()
    return names
  end)
  names = names or {}
  check(
    "OpenOCD tasks offered next to openocd.cfg",
    vim.tbl_contains(names, "openocd server") and vim.tbl_contains(names, "openocd flash")
  )

  local dap = require("dap")
  local config
  for _, cfg in ipairs(dap.configurations.c or {}) do
    if cfg.type == "gdb-target" then
      config = vim.deepcopy(cfg)
    end
  end
  check("C debug configurations include the OpenOCD attach", config)
  if not (config and t.has("remote debugging through GDB's DAP mode", "gdbserver")) then
    return
  end

  -- Build with debug info, serve it on :3333 like OpenOCD, attach, break.
  vim.system({ "make", "app" }, { cwd = dir }):wait()
  local server = vim.system({ "gdbserver", ":3333", dir .. "/app" })
  t.wait(2000, function()
    return false
  end)
  local stops = {}
  dap.listeners.after.event_stopped["smoke"] = function(_, body)
    stops[#stops + 1] = body.reason
  end
  vim.cmd.edit("main.c")
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  dap.toggle_breakpoint()
  config.program = dir .. "/app"
  config.gdb = "gdb"
  dap.run(config)
  check(
    "attach to the GDB server",
    t.wait(20000, function()
      return stops[1] == "attach"
    end)
  )
  -- Breakpoints are sent during the configuration phase: wait for its end.
  t.wait(10000, function()
    local session = dap.session()
    return session and session.initialized and session.current_frame
  end)
  dap.continue()
  check(
    "breakpoint hit in square()",
    t.wait(20000, function()
      local frame = dap.session() and dap.session().current_frame
      return stops[#stops] == "breakpoint" and frame and frame.line == 3
    end),
    "stops: " .. table.concat(stops, ", ")
  )
  dap.listeners.after.event_stopped["smoke"] = nil
  dap.terminate()
  dap.clear_breakpoints()
  t.wait(3000, function()
    return dap.session() == nil
  end)
  server:kill(9)
end
