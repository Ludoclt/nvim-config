-- AZERTY layer (lua/config/azerty.lua).
---@param t SmokeTest
return function(t)
  local check = t.check

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
end
