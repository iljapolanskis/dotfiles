-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_php_lsp = "intelephense"
vim.g.snacks_animate = false

vim.o.exrc = true -- load per-project .nvim.lua files

-- Tabs are used per-project (see :LocalRepo), not for file navigation, so label
-- each tab by its tab-local cwd (project name) instead of the active file.
function _G.project_tabline()
  local s = ""
  for i = 1, vim.fn.tabpagenr("$") do
    local name = vim.fn.fnamemodify(vim.fn.getcwd(-1, i), ":t")
    local hl = i == vim.fn.tabpagenr() and "%#TabLineSel#" or "%#TabLine#"
    s = s .. hl .. "%" .. i .. "T " .. i .. ": " .. (name ~= "" and name or "[no name]") .. " "
  end
  return s .. "%#TabLineFill#%T"
end
vim.o.tabline = "%!v:lua.project_tabline()"

-- Don't re-equalize the whole window tree on every split open/close. Default-on
-- `equalalways` is what makes the dap-ui layout jump when <leader>e or <c-/>
-- opens a window: dap-ui marks its windows winfixwidth/winfixheight, but that's
-- only best-effort and gets overridden when a whole row is fixed. With this off,
-- a new split only takes space from its own parent frame and gives it back on
-- close, leaving the debug layout alone.
vim.o.equalalways = false
