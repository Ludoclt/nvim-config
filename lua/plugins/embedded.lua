-- Embedded: cross-compiled C/C++, OpenOCD and remote GDB debugging.
--
-- Flow: put an openocd.cfg at the project root (`:Template embedded` gives a
-- starting point), start the server with <leader>mo, flash with <leader>mf,
-- then debug with <leader>dc > "Embedded: attach to OpenOCD". The debugger is
-- GDB's own DAP mode (GDB >= 14), so any probe OpenOCD supports works:
-- ST-Link, CMSIS-DAP (Raspberry Pi Debug Probe), FTDI, ESP32 USB-JTAG...

-- Compilers clangd may run to learn their system headers (--query-driver).
-- Only these are trusted: a compile_commands.json can name any binary.
local drivers = {
  "/usr/bin/arm-none-eabi-*",
  "/usr/bin/riscv*-elf-*",
  "/usr/bin/avr-*",
  "/usr/bin/*-linux-gnu*-gcc*",
  "/usr/bin/*-linux-gnu*-g++*",
  "/usr/bin/gcc*",
  "/usr/bin/g++*",
  "/opt/*/bin/*-gcc",
  "/opt/*/bin/*-g++",
  vim.fn.expand("~/.espressif/tools/*/bin/*-gcc"),
  vim.fn.expand("~/.espressif/tools/*/bin/*-g++"),
}

-- GDB used for remote targets: the first one found, unless the debug
-- configuration sets `gdb` (e.g. xtensa-esp32-elf-gdb in a launch.json).
local function target_gdb()
  for _, gdb in ipairs({ "arm-none-eabi-gdb", "gdb-multiarch", "gdb" }) do
    if vim.fn.executable(gdb) == 1 then
      return gdb
    end
  end
  return "gdb"
end

--- ELF files under the cwd, build outputs first.
local function find_elves()
  local found = {}
  for name, kind in
    vim.fs.dir(vim.fn.getcwd(), {
      depth = 6,
      skip = function(dir)
        return not dir:match("^%.") and dir ~= "node_modules"
      end,
    })
  do
    if kind == "file" and (name:match("%.elf$") or name:match("%.axf$")) then
      found[#found + 1] = vim.fs.joinpath(vim.fn.getcwd(), name)
    end
  end
  table.sort(found, function(a, b)
    return vim.uv.fs_stat(a).mtime.sec > vim.uv.fs_stat(b).mtime.sec
  end)
  return found
end

--- Pick the ELF to debug or flash (runs inside nvim-dap's coroutine).
local function pick_elf()
  local elves = find_elves()
  if #elves == 1 then
    return elves[1]
  elseif #elves == 0 then
    local path = vim.fn.input("ELF file: ", vim.fn.getcwd() .. "/", "file")
    return path ~= "" and path or require("dap").ABORT
  end
  return require("dap.ui").pick_one(elves, "Select ELF: ", function(file)
    return vim.fn.fnamemodify(file, ":.")
  end) or require("dap").ABORT
end

local function openocd_root(dir)
  local cfg = vim.fs.find("openocd.cfg", { upward = true, type = "file", path = dir })[1]
  return cfg and vim.fs.dirname(cfg)
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local clangd = opts.servers and opts.servers.clangd
      if clangd and clangd.cmd then
        table.insert(clangd.cmd, "--query-driver=" .. table.concat(drivers, ","))
      end
    end,
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      dap.adapters["gdb-target"] = function(callback, config)
        callback({
          type = "executable",
          command = config.gdb or target_gdb(),
          args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
        })
      end
      local embedded = {
        type = "gdb-target",
        request = "attach",
        name = "Embedded: attach to OpenOCD (localhost:3333)",
        target = "localhost:3333",
        program = pick_elf,
        cwd = "${workspaceFolder}",
      }
      for _, lang in ipairs({ "c", "cpp", "asm" }) do
        dap.configurations[lang] = dap.configurations[lang] or {}
        table.insert(dap.configurations[lang], embedded)
      end
    end,
  },

  {
    "stevearc/overseer.nvim",
    opts = function()
      local overseer = require("overseer")
      overseer.register_template({
        name = "openocd",
        generator = function(search, cb)
          local cwd = openocd_root(search.dir)
          if not cwd then
            return cb("No openocd.cfg found")
          end
          cb({
            {
              name = "openocd server",
              desc = "GDB server on localhost:3333, using openocd.cfg",
              builder = function()
                return { cmd = { "openocd", "-f", "openocd.cfg" }, cwd = cwd }
              end,
            },
            {
              name = "openocd flash",
              desc = "Program an ELF, verify it and reset the target",
              params = {
                elf = { type = "string", desc = "ELF file", default = find_elves()[1] or "" },
              },
              builder = function(params)
                return {
                  cmd = { "openocd", "-f", "openocd.cfg", "-c", ("program {%s} verify reset exit"):format(params.elf) },
                  cwd = cwd,
                }
              end,
            },
          })
        end,
      })
    end,
  },

  {
    "LazyVim/LazyVim",
    -- stylua: ignore
    keys = {
      { "<leader>mo", function() require("overseer").run_task({ name = "openocd server" }) end, desc = "OpenOCD Server" },
      { "<leader>mf", function() require("overseer").run_task({ name = "openocd flash" }) end, desc = "Flash (OpenOCD)" },
    },
  },
}
