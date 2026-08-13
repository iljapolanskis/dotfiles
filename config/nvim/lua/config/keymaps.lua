-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- grep on <leader>fg / <leader>fG (was <leader>sg / <leader>sG), drop git-files find

-- Folder-tiered file + text search. Tier order (module+config → vendor → rest)
-- and the mechanics live in lua/util/tiered.lua. <leader>fF / <leader>fG stay
-- untiered as an escape hatch.
local tiered = require("util.tiered")

vim.keymap.set("n", "<leader>ff", function()
  Snacks.picker.files({ finder = tiered.files_finder })
end, { desc = "Find Files (folder-tiered)" })
vim.keymap.set("n", "<leader><space>", function()
  Snacks.picker.files({ finder = tiered.files_finder })
end, { desc = "Find Files (folder-tiered)" })

vim.keymap.set("n", "<leader>fg", function()
  Snacks.picker.grep({ finder = tiered.grep_finder })
end, { desc = "Grep (folder-tiered)" })
vim.keymap.set("n", "<leader>fG", function()
  Snacks.picker.grep({ root = false })
end, { desc = "Grep (cwd)" })

-- gr inside XML + YAML config, keyed off the FQCN under the cursor -- the same
-- picker PHP's gr uses, which branches on filetype (lua/util/php_refs.lua).
-- Safe to bind plainly here: these buffers have no LSP client, so LazyVim's
-- LSP-filtered keymaps never claim the key.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "xml", "yaml" },
  callback = function(ev)
    vim.keymap.set("n", "gr", function()
      Snacks.picker.lsp_references()
    end, { buffer = ev.buf, desc = "References of PHP class" })
  end,
})

-- terminal in current file's directory
-- vim.keymap.set("n", "<leader>fD", function()
--   Snacks.terminal(nil, { cwd = vim.fn.expand("%:p:h") })
-- end, { desc = "Terminal (file dir)" })

-- buffer picker — nowait prevents which-key from delaying the picker open
-- require("which-key").add({
--   {
--     "<leader>b",
--     function()
--       Snacks.picker.buffers()
--     end,
--     desc = "Buffers",
--     nowait = true,
--   },
-- })
