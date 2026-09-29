-- Restore dap-ui's window sizes after something else in the layout moved them.
--
-- Opening a sidebar or split steals space from the debug windows, and dap-ui
-- doesn't claw it back on its own: it marks its windows winfixwidth/winfixheight
-- (nvim-dap-ui/lua/dapui/windows/layout.lua), but that's best-effort -- when a
-- split has nowhere else to take space from, a "fixed" window shrinks anyway.
local M = {}

-- Deliberately NOT `dapui.open({ reset = true })`, which is the public API for
-- this: it opens any *closed* layout as a side effect (dapui/init.lua), so it
-- would summon the whole debug UI on a plain <leader>e with no session running.
-- It also calls update_sizes() first, snapshotting the skewed sizes we're trying
-- to undo. WindowLayout:resize() one level down early-returns when the layout is
-- closed and restores each window's init_size, which is exactly the intent.
---@return boolean restored whether any open layout was resized
function M.reset()
  local ok, windows = pcall(require, "dapui.windows")
  if not ok then
    return false
  end

  -- dap-ui guards its own layout changes this way (local keep_cmdheight in
  -- dapui/init.lua): resizing windows can grow cmdheight, and nothing shrinks it
  -- back -- the cmdheight creep in nvim-dap-view#203.
  local cmdheight = vim.o.cmdheight
  local restored = false
  for _, layout in ipairs(windows.layouts) do
    if layout:is_open() then
      pcall(layout.resize, layout, { reset = true })
      restored = true
    end
  end
  vim.o.cmdheight = cmdheight

  return restored
end

--- Same, deferred to after the current window operation settles.
--- A picker's on_show fires while its layout is still being built, so resizing
--- inline gets overwritten by the splits that follow.
function M.reset_soon()
  vim.schedule(M.reset)
end

return M
