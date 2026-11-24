-- :Template {name}: copy starter project files from templates/{name}/ into
-- the current directory. Existing files are never overwritten.

local M = {}

M.dir = vim.fs.joinpath(vim.fn.stdpath("config"), "templates")

function M.names()
  local names = {}
  for name, kind in vim.fs.dir(M.dir) do
    if kind == "directory" then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

---@param name string
function M.copy(name)
  local src = vim.fs.joinpath(M.dir, name)
  if vim.fn.isdirectory(src) == 0 then
    return LazyVim.error(("No template %q. Available: %s"):format(name, table.concat(M.names(), ", ")))
  end
  local copied, skipped = {}, {}
  for file, kind in vim.fs.dir(src, { depth = math.huge }) do
    local to = vim.fs.joinpath(vim.fn.getcwd(), file)
    if kind == "directory" then
      vim.fn.mkdir(to, "p")
    elseif vim.uv.fs_stat(to) then
      skipped[#skipped + 1] = file
    else
      vim.fn.mkdir(vim.fs.dirname(to), "p")
      vim.uv.fs_copyfile(vim.fs.joinpath(src, file), to)
      copied[#copied + 1] = file
    end
  end
  local msg = ("Copied: %s"):format(#copied > 0 and table.concat(copied, ", ") or "nothing")
  if #skipped > 0 then
    msg = msg .. ("\nKept existing: %s"):format(table.concat(skipped, ", "))
  end
  LazyVim.info(msg, { title = "Template " .. name })
end

function M.setup()
  vim.api.nvim_create_user_command("Template", function(cmd)
    M.copy(cmd.args)
  end, {
    nargs = 1,
    complete = function()
      return M.names()
    end,
    desc = "Copy starter project files into the current directory",
  })
end

return M
