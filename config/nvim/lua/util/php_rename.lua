-- Split `textDocument/rename` between the two PHP servers.
--
-- Both answer the method, and they are good at different halves of it:
--
--   intelephense  methods, properties, constants, variables. Emits TextEdits
--                 only — it has no file operations at all, so renaming a class
--                 through it leaves `OldName.php` containing `class NewName`
--                 and quietly breaks PSR-4.
--   phpactor      classes, interfaces, traits, enums. Its ClassRenamer returns
--                 a `RenameResult(oldUri, newUri)` alongside the edits, which
--                 becomes a RenameFile operation in the WorkspaceEdit — the
--                 file follows the class. References come from phpactor's own
--                 index, which does cover `tests/`.
--
-- `vim.lsp.buf.rename()` walks every rename-capable client in attach order and
-- skips only those whose prepareRename returns nil. Both of these accept classes
-- and members, so unpinned they'd both rename in turn. Pin each key to one
-- server. Servers that decline PHP symbols (symfony_lsp: nil prepareRename, but
-- it owns route names) stay in the `<leader>cr` chain and just get skipped.
--
-- Caveat worth knowing before reaching for `<leader>cn`: phpactor's
-- `ClassRenamer::createNewName()` pops the last segment of the FQCN and glues
-- the *old* namespace back on, so a rename can never change the namespace.
-- Changing a namespace means moving the file — `<leader>cR`.
local M = {}

local CLASS_SERVER = "phpactor"

--- `<leader>cr` — members and variables. Anything but phpactor.
--- Off PHP (one rename client, not phpactor) this is stock `vim.lsp.buf.rename`.
function M.rename_symbol()
  local has_other = false
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0, method = "textDocument/rename" })) do
    if c.name ~= CLASS_SERVER then
      has_other = true
      break
    end
  end

  -- Don't filter phpactor out if it is the only thing that can answer.
  if not has_other then
    return vim.lsp.buf.rename()
  end

  return vim.lsp.buf.rename(nil, {
    filter = function(client)
      return client.name ~= CLASS_SERVER
    end,
  })
end

--- `<leader>cn` — class/interface/trait/enum. Renames the file too.
---
--- Hand-rolled rather than `vim.lsp.buf.rename(nil, { name = ... })` so we get a
--- completion callback: phpactor's WorkspaceEdit moves the class file, but the
--- mirrored `FooTest` is a different symbol in a different namespace and no
--- server will ever touch it. util.php_move picks it up afterwards.
function M.rename_class()
  local client = vim.lsp.get_clients({
    bufnr = 0,
    name = CLASS_SERVER,
    method = "textDocument/rename",
  })[1]
  if not client then
    return vim.notify("[LSP] " .. CLASS_SERVER .. " not attached", vim.log.levels.WARN)
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local old = vim.fn.expand("<cword>")
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))

  vim.ui.input({ prompt = "Rename class: ", default = old }, function(new)
    if not new or new == "" or new == old then
      return
    end

    local params = vim.lsp.util.make_position_params(win, client.offset_encoding) --[[@as lsp.RenameParams]]
    params.newName = new

    client:request("textDocument/rename", params, function(err, result)
      if err then
        return vim.notify(CLASS_SERVER .. ": " .. tostring(err.message), vim.log.levels.ERROR)
      end
      if not result then
        -- phpactor reports CouldNotRename via window/showMessage and returns an
        -- empty edit, so there is nothing useful to add here.
        return
      end
      -- The WorkspaceEdit moves the class file; see util.lsp_edit for why that
      -- needs protecting from write autocmds.
      require("util.lsp_edit").apply(result, client.offset_encoding, CLASS_SERVER)
      require("util.php_move").rename_test_twin(old, new, dir)
    end, bufnr)
  end)
end

return M
