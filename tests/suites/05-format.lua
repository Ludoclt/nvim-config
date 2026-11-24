-- Format on save rule (lua/config/format.lua).
---@param t SmokeTest
return function(t)
  local check = t.check

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
  check("no config: off", not format.has_config(project("bare", {}), "c"))
  local clang = project("clang", { [".clang-format"] = "BasedOnStyle: LLVM" })
  check(".clang-format: on for C", format.has_config(clang, "c"))
  check(".clang-format: off for Python", not format.has_config(clang, "python"))
  check("Cargo.toml: on for Rust", format.has_config(project("rust", { ["Cargo.toml"] = "[package]" }), "rust"))
  local ruff = project("ruff", { ["pyproject.toml"] = "[tool.ruff]" })
  check("pyproject with [tool.ruff]: on", format.has_config(ruff, "python"))
  local py = project("py", { ["pyproject.toml"] = "[project]" })
  check("pyproject without formatter: off", not format.has_config(py, "python"))
  check("unlisted filetype: off", not format.has_config(clang, "sh"))

  local bare = vim.fs.joinpath(project("bare2", {}), "main.c")
  vim.fn.writefile({ "int main(void){return 0;}" }, bare)
  vim.cmd.edit(bare)
  check("buffer without config gets autoformat=false", vim.b.autoformat == false)
  local clang_c = vim.fs.joinpath(project("clang2", { [".clang-format"] = "BasedOnStyle: LLVM" }), "main.c")
  vim.fn.writefile({ "int main(void){return 0;}" }, clang_c)
  vim.cmd.edit(clang_c)
  check("buffer with config inherits the global setting", vim.b.autoformat == nil)
  vim.fn.delete(root, "rf")
end
