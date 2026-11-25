-- Install every Mason package this config asks for, synchronously, then quit.
-- Run by scripts/smoke-test.sh so that the language server checks do not race
-- Mason's background installs:
--   nvim --headless -c "luafile tests/install-tools.lua"

local function main()
  require("lazy").load({ plugins = { "mason.nvim", "mason-lspconfig.nvim" } })
  local registry = require("mason-registry")

  local wanted, packages = {}, {}
  local failed = {}
  local refreshed = false
  local function install_all()
    -- The server -> package mapping comes from the registry: build it now.
    local to_package = require("mason-lspconfig").get_mappings().lspconfig_to_package
    for _, name in ipairs(LazyVim.opts("mason.nvim").ensure_installed or {}) do
      wanted[name] = true
    end
    for server, opts in pairs(LazyVim.opts("nvim-lspconfig").servers or {}) do
      local enabled = opts == true or (type(opts) == "table" and opts.enabled ~= false and opts.mason ~= false)
      if server ~= "*" and enabled then
        if to_package[server] then
          wanted[to_package[server]] = true
        else
          io.stdout:write("not installed by Mason: " .. server .. "\n")
        end
      end
    end
    for name in pairs(wanted) do
      local ok, pkg = pcall(registry.get_package, name)
      if not ok then
        failed[#failed + 1] = name .. " (not in the registry)"
      else
        packages[#packages + 1] = pkg
        -- LazyVim may already be installing it in the background: then just wait.
        if not pkg:is_installed() and not pkg:is_installing() then
          io.stdout:write("installing " .. name .. "\n")
          pkg:install({})
        end
      end
    end
  end
  -- The callback may run in a fast event, where plugins cannot be required.
  registry.refresh(vim.schedule_wrap(function()
    local ok, err = pcall(install_all)
    if not ok then
      failed[#failed + 1] = tostring(err)
    end
    refreshed = true
  end))
  local function busy()
    for _, pkg in ipairs(packages) do
      if pkg:is_installing() then
        return true
      end
    end
    return false
  end
  vim.wait(20 * 60 * 1000, function()
    return refreshed
  end, 200)
  vim.wait(1000, function()
    return false
  end)
  vim.wait(20 * 60 * 1000, function()
    return not busy()
  end, 500)
  for _, pkg in ipairs(packages) do
    if not pkg:is_installed() then
      failed[#failed + 1] = pkg.name .. " (install failed, see :MasonLog)"
    end
  end

  if #failed > 0 then
    io.stdout:write("Mason install failed: " .. table.concat(failed, ", ") .. "\n")
    vim.cmd("cquit! 1")
  end
  io.stdout:write(("Mason packages ready (%d wanted)\n"):format(vim.tbl_count(wanted)))
  vim.cmd("qall!")
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      local ok, err = pcall(main)
      if not ok then
        io.stdout:write("Mason install crashed: " .. tostring(err) .. "\n")
        vim.cmd("cquit! 1")
      end
    end)
  end,
})
