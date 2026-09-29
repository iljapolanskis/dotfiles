-- Apply a `WorkspaceEdit` and actually persist it.
--
-- Two things `vim.lsp.util.apply_workspace_edit` does not do for you on 0.12:
--
--   1. WRITE. It loads each touched file into a buffer, edits it, and stops
--      there — `apply_text_edits` has no `:write` in it any more. So a rename
--      that touches 40 files leaves 40 modified hidden buffers, and every one of
--      those edits is lost the moment something discards the buffer. That is
--      exactly what a follow-up file rename does: `Snacks.rename._rename` calls
--      `nvim_buf_delete(from_buf, { force = true })`, which throws the unsaved
--      edits away and then re-adds the buffer by reading the *old* content off
--      disk. Net effect: references silently not updated, which is very hard to
--      tell apart from "the server didn't find them".
--   2. SURVIVE AUTOCMDS. A RenameFile op is applied with `keepalt saveas!`, which
--      fires BufWritePre. One erroring autocmd there — nvim-lint reaching for a
--      linter binary that isn't installed, conform's docker wrapper exiting
--      non-zero — throws straight out of the middle of the documentChanges loop.
--      Changes before the rename land, changes after it are dropped.
--
-- Suppressing the write autocmds is also just correct: these writes are
-- bookkeeping for a refactor, not edits the user made, so there is nothing to
-- lint or format about them.
local M = {}

local IGNORE = { "BufWritePre", "BufWrite", "BufWritePost", "FileWritePre", "FileWritePost" }

---@return table<integer, true>
local function dirty_buffers()
  local set = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified then
      set[buf] = true
    end
  end
  return set
end

--- Write every buffer the edit dirtied, and nothing else.
---@param before table<integer, true> buffers already modified before the edit
---@return integer written
local function write_touched(before)
  local written = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.bo[buf].modified
      and not before[buf]
      and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
    then
      local ok = pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd("noautocmd silent keepalt write")
      end)
      if ok then
        written = written + 1
      end
    end
  end
  return written
end

---@param edit lsp.WorkspaceEdit
---@param encoding string client offset encoding
---@param label? string prefix for the failure notification
---@return boolean ok
function M.apply(edit, encoding, label)
  -- Buffers the user left modified are theirs; don't write those.
  local before = dirty_buffers()
  local saved = vim.o.eventignore
  vim.opt.eventignore:append(IGNORE)

  local ok, err = pcall(vim.lsp.util.apply_workspace_edit, edit, encoding)
  write_touched(before)

  vim.o.eventignore = saved

  if not ok then
    vim.notify(
      (label or "LSP") .. ": edits applied with errors: " .. tostring(err),
      vim.log.levels.WARN,
      { title = "Rename" }
    )
  end
  return ok
end

--- Drop-in for `vim.lsp.handlers["textDocument/rename"]`.
---
--- Installed per-server (see plugins/php-lsp.lua, plugins/phpactor.lua) so that
--- EVERY rename entry point persists — LazyVim's `<leader>cr`, a code action
--- that renames, anything that goes through the client — not just the keymaps in
--- util.php_rename. The stock handler applies the edit and leaves N modified
--- hidden buffers behind, so a rename looks like it worked, and then didn't.
---@param err lsp.ResponseError?
---@param result lsp.WorkspaceEdit?
---@param ctx lsp.HandlerContext
function M.rename_handler(err, result, ctx)
  if err then
    return vim.notify("Rename failed: " .. tostring(err.message), vim.log.levels.ERROR)
  end
  if not result then
    return
  end
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  M.apply(result, client and client.offset_encoding or "utf-16", client and client.name)
end

return M
