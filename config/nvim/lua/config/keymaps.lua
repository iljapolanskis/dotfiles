-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- grep on <leader>fg / <leader>fG (was <leader>sg / <leader>sG), drop git-files find

-- Folder-priority grep: run TWO ripgrep passes through one live picker finder.
-- Pass 1 searches only the priority dirs (globbed anywhere in the tree) and
-- paints first; pass 2 searches everything *except* those dirs. Priority hits
-- also get a score_add so the matcher keeps them on top after re-sorting.
--   - first-paint order  → you see module hits before rg finishes crawling
--   - score_add          → module hits stay pinned top even as you type
-- Higher score = higher tier. Edit PRIORITY_DIRS to taste.
local PRIORITY_DIRS = { "module", "config", "vendor" }
local PRIORITY_BONUS = 1000

-- rg glob matching a dir name anywhere in the tree (e.g. "**/module/**").
local function dir_globs(negate)
  local globs = {}
  for _, dir in ipairs(PRIORITY_DIRS) do
    globs[#globs + 1] = (negate and "!" or "") .. "**/" .. dir .. "/**"
  end
  return globs
end

-- Custom finder: chains two grep procs into the picker's streaming callback.
---@param opts snacks.picker.grep.Config
---@param ctx snacks.picker.finder.ctx
local function tiered_grep_finder(opts, ctx)
  local grep = require("snacks.picker.source.grep")
  local function pass(negate)
    local pass_opts = vim.tbl_deep_extend("force", {}, opts, { glob = dir_globs(negate) })
    return grep.grep(pass_opts, ctx)
  end
  local search_priority = pass(false)
  local search_rest = pass(true)
  ---@async
  return function(cb)
    search_priority(function(item)
      item.score_add = (item.score_add or 0) + PRIORITY_BONUS
      cb(item)
    end)
    search_rest(cb)
  end
end

vim.keymap.set("n", "<leader>fg", function()
  Snacks.picker.grep({ finder = tiered_grep_finder })
end, { desc = "Grep (folder-priority)" })
vim.keymap.set("n", "<leader>fG", function()
  Snacks.picker.grep({ root = false })
end, { desc = "Grep (cwd)" })

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
