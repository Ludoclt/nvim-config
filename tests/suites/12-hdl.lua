-- Verilog / SystemVerilog and VHDL (lua/plugins/hdl.lua).
---@param t SmokeTest
return function(t)
  local check = t.check

  --- Diagnostics of the current buffer from `source`, optionally on a line.
  local function diags(source, lnum)
    return vim.tbl_filter(function(d)
      return (d.source or ""):find(source, 1, true) and (lnum == nil or d.lnum == lnum)
    end, vim.diagnostic.get(0))
  end
  local function messages()
    return table.concat(
      vim.tbl_map(function(d)
        return ("%s:%d %s"):format(d.source or "?", d.lnum + 1, d.message)
      end, vim.diagnostic.get(0)),
      " | "
    )
  end

  -- Verilog / SystemVerilog ----------------------------------------------
  local dir = t.sample("verilog")
  check("verilog files use the systemverilog parser", vim.treesitter.language.get_lang("verilog") == "systemverilog")

  vim.cmd.edit("top.sv")
  check("format on save off without .verible-format", vim.b.autoformat == false)

  if t.has("Verilator reports the width mismatch", "verilator") then
    check(
      "Verilator reports the width mismatch",
      t.wait(20000, function()
        return #diags("verilator", 13) > 0
      end),
      messages()
    )
    check("Verilator finds counter.sv next to top.sv", not messages():find("Cannot find", 1, true), messages())
  end

  if t.has("verible attaches", "verible-verilog-ls") then
    check(
      "verible attaches",
      t.wait(30000, function()
        return vim.lsp.get_clients({ bufnr = 0, name = "verible" })[1]
      end)
    )
    vim.api.nvim_buf_set_lines(0, 5, 6, false, { "  logic [7:0] count;   " })
    check(
      "verible reports style issues (trailing spaces)",
      t.wait(20000, function()
        return #diags("verible", 5) > 0
      end),
      messages()
    )
    vim.cmd("silent edit!")

    vim.cmd("VeribleFilelist")
    local list = vim.uv.fs_stat(dir .. "/verible.filelist") and vim.fn.readfile(dir .. "/verible.filelist") or {}
    check(
      ":VeribleFilelist lists the sources",
      vim.tbl_contains(list, "counter.sv") and vim.tbl_contains(list, "top.sv")
    )
    local client = t.wait(30000, function()
      local c = vim.lsp.get_clients({ bufnr = 0, name = "verible" })[1]
      return c and c.initialized and c
    end)
    t.wait(2000, function()
      return false
    end)
    if client then
      vim.api.nvim_win_set_cursor(0, { 8, 3 })
      vim.lsp.buf.definition()
      check(
        "go to definition across files (verible.filelist)",
        t.wait(15000, function()
          return vim.fn.expand("%:t") == "counter.sv"
        end),
        "in " .. vim.fn.expand("%:t")
      )
    end
  end

  vim.cmd("Template verilog")
  check(
    ":Template verilog copies the starter files",
    vim.uv.fs_stat(dir .. "/.rules.verible_lint")
      and vim.uv.fs_stat(dir .. "/.verible-format")
      and vim.uv.fs_stat(dir .. "/verilator.f")
  )
  if t.has("verible-verilog-format applies .verible-format", "verible-verilog-format") then
    vim.cmd("silent! %bwipeout!")
    vim.cmd.edit("counter.sv")
    check("format on save on with .verible-format", vim.b.autoformat == nil)
    require("conform").format({ bufnr = 0, timeout_ms = 10000 })
    check(
      "verible-verilog-format applies .verible-format",
      vim.api.nvim_buf_get_lines(0, 7, 8, false)[1]:match("^    always_ff"),
      vim.api.nvim_buf_get_lines(0, 7, 8, false)[1]
    )
  end

  -- VHDL -------------------------------------------------------------------
  vim.cmd("silent! %bwipeout!")
  dir = t.sample("vhdl")
  if t.has("vhdl_ls attaches without vhdl_ls.toml", "vhdl_ls") then
    vim.cmd.edit("blinky.vhd")
    check(
      "vhdl_ls attaches without vhdl_ls.toml",
      t.wait(30000, function()
        return vim.lsp.get_clients({ bufnr = 0, name = "vhdl_ls" })[1]
      end)
    )
    vim.api.nvim_buf_set_lines(0, 21, 22, false, { "  led <= undefined_sig;" })
    check(
      "vhdl_ls reports an undeclared signal",
      t.wait(20000, function()
        return #diags("vhdl", 21) > 0
      end),
      messages()
    )
    -- vhdl_ls exits when it cannot find its ieee/std libraries.
    check("vhdl_ls found the standard libraries", vim.lsp.get_clients({ name = "vhdl_ls" })[1] ~= nil)
    vim.cmd("silent edit!")
  end
  vim.cmd.edit(dir .. "/blinky.vhd")
  vim.cmd("silent write")
  t.wait(3000, function()
    return false
  end)
  check("no VSG lint without a VSG config", #diags("vsg") == 0, messages())

  vim.cmd("Template vhdl")
  check(
    ":Template vhdl copies the starter files",
    vim.uv.fs_stat(dir .. "/vhdl_ls.toml") and vim.uv.fs_stat(dir .. "/vsg_config.yaml")
  )
  if t.has("VSG formats VHDL", "vsg") then
    vim.cmd("silent! %bwipeout!")
    local lines = vim.fn.readfile(dir .. "/blinky.vhd")
    lines[13] = lines[13]:gsub("signal", "SIGNAL")
    vim.fn.writefile(lines, dir .. "/blinky.vhd")
    vim.cmd.edit("blinky.vhd")
    check("format on save on with vsg_config.yaml", vim.b.autoformat == nil)
    require("conform").format({ bufnr = 0, timeout_ms = 30000 })
    local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    check(
      "VSG formats VHDL (keywords to lowercase)",
      text:find("\n%s*signal counter") and not text:find("SIGNAL", 1, true),
      text:match("[^\n]*counter :[^\n]*")
    )
    vim.cmd("silent write")
    check(
      "VSG reports the issues it cannot fix (process labels)",
      t.wait(20000, function()
        return #diags("vsg") > 0
      end),
      messages()
    )
  end
end
