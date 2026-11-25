-- Verilog / SystemVerilog and VHDL.
--
-- Verilog / SystemVerilog:
--   * verible-verilog-ls: syntax and style lint (rules from .rules.verible_lint,
--     searched upward), symbols, go to definition across the files listed in
--     verible.filelist (`:VeribleFilelist` writes it).
--   * Verilator --lint-only (nvim-lint): semantic checks verible does not do,
--     such as widths, undriven or unused signals, missing modules. Modules are
--     looked up next to the file, and a verilator.f found upward is passed
--     with -f (include dirs, defines, other source dirs).
--   * verible-verilog-format (conform), with flags from .verible-format.
-- VHDL:
--   * vhdl_ls (rust_hdl): syntax and semantic analysis, go to definition.
--     Libraries come from vhdl_ls.toml; without it, the open file is analysed
--     against the standard libraries.
--   * VSG, when a VSG config exists: formats (conform) and reports the style
--     issues it cannot fix (nvim-lint).

local function find_up(names, path)
  return vim.fs.find(names, { upward = true, path = path, stop = vim.uv.os_homedir(), type = "file" })[1]
end

-- Verilator, recomputed for each lint: its arguments depend on the file.
local function verilator()
  local linter = vim.deepcopy(require("lint.linters.verilator"))
  local dir = vim.fn.expand("%:p:h")
  local args = { "-sv", "-Wall", "--timing", "--bbox-sys", "--bbox-unsup", "--lint-only", "-y", dir }
  local file = find_up({ "verilator.f" }, dir)
  if file then
    vim.list_extend(args, { "-f", file })
  end
  linter.args = args
  -- Paths inside verilator.f are relative to it.
  linter.cwd = file and vim.fs.dirname(file) or dir
  return linter
end

--- :VeribleFilelist: list the project's Verilog/SystemVerilog sources in
--- verible.filelist, so that go to definition works across files.
local function write_filelist()
  local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
  local patterns = { "*.sv", "*.svh", "*.v", "*.vh" }
  local git = vim.system(vim.list_extend({ "git", "ls-files", "--" }, patterns), { cwd = root, text = true }):wait()
  local files = git.code == 0 and vim.split(vim.trim(git.stdout), "\n", { trimempty = true }) or {}
  if #files == 0 then
    for name, kind in vim.fs.dir(root, { depth = 10 }) do
      if kind == "file" and (name:match("%.svh?$") or name:match("%.vh?$")) then
        files[#files + 1] = name
      end
    end
  end
  table.sort(files)
  vim.fn.writefile(files, vim.fs.joinpath(root, "verible.filelist"))
  LazyVim.info(("verible.filelist: %d files in %s"):format(#files, root), { title = "Verible" })
  for _, client in ipairs(vim.lsp.get_clients({ name = "verible" })) do
    client:stop()
  end
  vim.defer_fn(function()
    vim.cmd("silent! edit")
  end, 500)
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "systemverilog", "vhdl" } },
    init = function()
      vim.treesitter.language.register("systemverilog", { "verilog", "systemverilog" })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.api.nvim_create_user_command("VeribleFilelist", write_filelist, {
        desc = "Write verible.filelist from the project's Verilog sources",
      })
    end,
    opts = {
      servers = {
        verible = {
          cmd = { "verible-verilog-ls", "--rules_config_search" },
        },
        vhdl_ls = {
          -- Also start without a vhdl_ls.toml (single files, small projects).
          workspace_required = false,
          root_markers = { "vhdl_ls.toml", ".git" },
        },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "vsg" } },
  },

  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local format = require("config.format")
      opts.linters_by_ft = vim.tbl_extend("force", opts.linters_by_ft or {}, {
        verilog = { "verilator" },
        systemverilog = { "verilator" },
        vhdl = { "vsg" },
      })
      opts.linters = opts.linters or {}
      opts.linters.verilator = verilator
      -- VSG only in projects with a VSG config, and with that config.
      opts.linters.vsg = {
        cmd = "vsg",
        stdin = true,
        args = {
          "-of",
          "syntastic",
          "--stdin",
          "-c",
          function()
            return find_up(format.rule("vhdl").files, vim.fn.expand("%:p:h"))
          end,
        },
        stream = "stdout",
        ignore_exitcode = true,
        parser = require("lint.linters.vsg")().parser,
        condition = function(ctx)
          return format.has_config(ctx.dirname, "vhdl")
        end,
      }
    end,
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        verilog = { "verible" },
        systemverilog = { "verible" },
        vhdl = { "vsg" },
      },
      formatters = {
        -- VSG exits with 1 when issues it cannot fix remain: keep its fixes.
        vsg = { exit_codes = { 0, 1 } },
        verible = {
          prepend_args = function(_, ctx)
            local flags = find_up({ ".verible-format" }, ctx.dirname)
            return flags and { "--flagfile=" .. flags } or {}
          end,
        },
      },
    },
  },
}
