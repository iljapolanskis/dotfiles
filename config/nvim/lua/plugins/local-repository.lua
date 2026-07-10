-- Snacks picker listing sub-projects under <root>/local-repository, opening the
-- chosen one in a new tab (tab-local cwd) so it stays isolated from other tabs.

local function pick()
  local root = LazyVim.root()
  local base = root .. "/local-repository"

  if vim.fn.isdirectory(base) == 0 then
    Snacks.notify.warn("No local-repository/ in " .. root)
    return
  end

  local items = {}
  for name, type in vim.fs.dir(base) do
    if type == "directory" then
      items[#items + 1] = { file = base .. "/" .. name, text = name, dir = true }
    end
  end
  if #items == 0 then
    Snacks.notify.warn("local-repository/ is empty")
    return
  end
  table.sort(items, function(a, b)
    return a.text < b.text
  end)

  Snacks.picker.pick({
    source = "local_repository",
    title = "Local Repositories",
    cwd = base,
    items = items,
    formatters = { file = { filename_only = true } },
    format = "file",
    confirm = function(picker, item)
      if not item then
        return
      end
      picker:close()
      vim.cmd.tabnew() -- open in new tab (keeps current project in other tabs)
      vim.cmd.tcd(item.file) -- tab-local cwd = picked project
      Snacks.explorer()
    end,
  })
end

vim.api.nvim_create_user_command("LocalRepo", pick, { desc = "Open a local-repository project in a new tab" })

return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>fl", pick, desc = "Local Repositories" },
  },
}
