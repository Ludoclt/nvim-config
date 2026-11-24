-- C / C++, CMake and make.
--
-- The LazyVim extras enabled in lazyvim.json bring clangd (with
-- clangd_extensions and the codelldb debugger), neocmakelsp, cmakelint and
-- cmake-tools. This file adds:
--   * build keymaps under <leader>m, the same for CMake and Makefile projects
--   * make tasks (overseer) with compile errors in the quickfix list
--   * `bear -- make` to get compile_commands.json for Makefile projects
--   * cmake-format, and treesitter parsers for make, asm, linker scripts...

-- cmake-tools works on the current directory: so does the CMake check.
local function is_cmake()
  return vim.uv.fs_stat(vim.fs.joinpath(vim.uv.cwd(), "CMakeLists.txt")) ~= nil
end

--- Run a cmake-tools command, loading the plugin first if needed.
local function cmake(cmd)
  require("lazy").load({ plugins = { "cmake-tools.nvim" } })
  vim.cmd(cmd)
end

--- Run an overseer task by name, or by tag when `name` is nil.
local function task(opts)
  require("overseer").run_task(opts, function(t, err)
    if not t and err then
      LazyVim.warn(err, { title = "Build" })
    end
  end)
end

--- Build: CMake (target "all" until another is picked with <leader>mT), or make.
local function build()
  if not is_cmake() then
    return task({ name = "make" })
  end
  require("lazy").load({ plugins = { "cmake-tools.nvim" } })
  local ct = require("cmake-tools")
  if ct.get_build_target() then
    vim.cmd("CMakeBuild")
  else
    ct.build({ target = "all" })
  end
end

-- Compile errors and warnings go to the quickfix list: )q / (q to walk them.
local quickfix = { "on_output_quickfix", open_on_exit = "failure", items_only = true }

return {
  {
    "stevearc/overseer.nvim",
    opts = function()
      local overseer = require("overseer")
      local jobs = tostring(vim.uv.available_parallelism())

      -- `make` (default target) and `bear -- make`, for any Makefile above the cwd.
      overseer.register_template({
        name = "make (default target)",
        generator = function(search, cb)
          local makefile = vim.fs.find("Makefile", { upward = true, type = "file", path = search.dir })[1]
          if not makefile then
            return cb("No Makefile found")
          end
          local cwd = vim.fs.dirname(makefile)
          cb({
            {
              name = "make",
              tags = { overseer.TAG.BUILD },
              builder = function()
                return { cmd = { "make", "-j" .. jobs }, cwd = cwd, components = { quickfix, "default" } }
              end,
            },
            {
              name = "bear -- make",
              desc = "Rebuild and write compile_commands.json for clangd",
              builder = function()
                return {
                  cmd = { "bear", "--", "make", "-B", "-j" .. jobs },
                  cwd = cwd,
                  components = { quickfix, "default" },
                }
              end,
            },
          })
        end,
      })

      -- Targets listed by overseer's own make provider ("make <target>").
      overseer.add_template_hook({ module = "^make$" }, function(defn, util)
        util.add_component(defn, quickfix)
      end)
    end,
  },

  {
    "Civitasv/cmake-tools.nvim",
    optional = true,
    opts = {
      cmake_build_directory = "build/${variant:buildType}",
      -- Run CMake through overseer like make: same task list (<leader>ow), and
      -- compile errors in the quickfix list. cmake-tools' own quickfix
      -- executor also breaks when a quickfix window is already open.
      cmake_executor = {
        name = "overseer",
        opts = {
          new_task_opts = { components = { quickfix, "default" } },
          on_new_task = function() end,
        },
      },
    },
  },

  -- cmake-format (installed by the cmake extra through cmakelang)
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = { formatters_by_ft = { cmake = { "cmake_format" } } },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "c", "cpp", "make", "asm", "linkerscript", "devicetree", "doxygen" } },
  },

  {
    "folke/which-key.nvim",
    optional = true,
    opts = { spec = { { "<leader>m", group = "build" } } },
  },

  {
    "LazyVim/LazyVim",
    -- stylua: ignore
    keys = {
      { "<leader>mm", build, desc = "Build" },
      { "<leader>mc", function() if is_cmake() then cmake("CMakeClean") else task({ name = "make clean" }) end end, desc = "Clean" },
      { "<leader>mr", function() if is_cmake() then cmake("CMakeRun") else vim.cmd("OverseerRun") end end, desc = "Run (CMake target or task)" },
      { "<leader>md", function() cmake("CMakeDebug") end, desc = "Debug (CMake target)" },
      { "<leader>mg", function() cmake("CMakeGenerate") end, desc = "CMake Configure" },
      { "<leader>mt", function() cmake("CMakeSelectBuildType") end, desc = "CMake Build Type" },
      { "<leader>mT", function() cmake("CMakeSelectBuildTarget") end, desc = "CMake Build Target" },
      { "<leader>ml", function() cmake("CMakeSelectLaunchTarget") end, desc = "CMake Launch Target" },
      { "<leader>mb", function() task({ name = "bear -- make" }) end, desc = "compile_commands.json (bear -- make)" },
    },
  },
}
