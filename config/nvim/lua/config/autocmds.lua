-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Yanking from an LSP hover float (K K yy) grabs the raw markdown source:
-- `__Api\\Foo\\Bar::create__`. Rewrite the register to what the float shows:
-- bold markers dropped, markdown escapes (`\\`, `\_`, ...) resolved. Lines
-- inside ``` fences are code and kept verbatim -- a PHP `'\\'` must survive.
local function hover_plain(line)
  local escaped = {}
  line = line:gsub("\\(%p)", function(c)
    escaped[#escaped + 1] = c
    return "\1"
  end)
  line = line:gsub("%*%*", ""):gsub("__", "")
  local i = 0
  return (line:gsub("\1", function()
    i = i + 1
    return escaped[i]
  end))
end

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("hover_yank_plain", { clear = true }),
  callback = function()
    -- noice renders hover into ft=noice; the native float sets w:lsp_floating_bufnr.
    if vim.bo.filetype ~= "noice" and vim.w.lsp_floating_bufnr == nil then
      return
    end
    local ev = vim.v.event
    if ev.operator ~= "y" then
      return
    end
    local first = vim.api.nvim_buf_get_mark(0, "[")[1]
    local in_fence = false
    for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, first - 1, false)) do
      if l:match("^%s*```") then
        in_fence = not in_fence
      end
    end
    local lines = {}
    for _, l in ipairs(ev.regcontents) do
      if l:match("^%s*```") then
        in_fence = not in_fence
        lines[#lines + 1] = l
      else
        lines[#lines + 1] = in_fence and l or hover_plain(l)
      end
    end
    local regs = { ev.regname ~= "" and ev.regname or '"', "0" }
    if vim.o.clipboard:find("unnamedplus") then
      regs[#regs + 1] = "+"
    end
    for _, r in ipairs(regs) do
      vim.fn.setreg(r, lines, ev.regtype)
    end
  end,
})
