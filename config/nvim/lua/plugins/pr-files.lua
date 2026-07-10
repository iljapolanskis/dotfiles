-- Snacks picker showing files changed in the current GitHub PR as a tree.
-- Data source: `gh pr view --json files` (structured, faster than `gh pr diff`).

-- changeType -> single-char git-style status shown as a comment
local STATUS = { ADDED = "A", MODIFIED = "M", DELETED = "D", RENAMED = "R" }

-- changeType -> highlight group for the filename. Snacks git-status groups link
-- to sane colors (Added=green, DiagnosticWarn=yellow, Removed=red). Renamed has
-- no distinct color by default, so define a blue one lazily.
local CHANGE_HL = {
  ADDED = "SnacksPickerGitStatusAdded",
  MODIFIED = "SnacksPickerGitStatusModified",
  DELETED = "SnacksPickerGitStatusDeleted",
  RENAMED = "PrFileRenamed",
}
vim.api.nvim_set_hl(0, "PrFileRenamed", { link = "DiagnosticInfo", default = true })

-- Build snacks picker items with the tree fields (parent/last/sort) that the
-- `file` formatter needs to render branch glyphs. Mirrors the shape produced by
-- snacks' own explorer source.
local function build_items(files)
  local root = { sort = "" }
  local dirs = { [""] = root }
  local items = {}

  local function get_dir(path)
    if dirs[path] then
      return dirs[path]
    end
    local parent_path = path:match("(.+)/[^/]+$") or ""
    local parent = get_dir(parent_path)
    local name = path:match("[^/]+$")
    local item = {
      file = path,
      text = path,
      dir = true,
      parent = parent,
      sort = parent.sort .. "!" .. name .. " ", -- dirs sort before files
    }
    dirs[path] = item
    items[#items + 1] = item
    return item
  end

  for _, f in ipairs(files) do
    local dir = f.path:match("(.+)/[^/]+$") or ""
    local parent = get_dir(dir)
    local name = f.path:match("[^/]+$")
    items[#items + 1] = {
      file = f.path,
      text = f.path,
      parent = parent,
      change = f.changeType,
      sort = parent.sort .. "#" .. name .. " ",
      comment = ("+%d -%d [%s]"):format(f.additions, f.deletions, STATUS[f.changeType] or f.changeType),
    }
  end

  table.sort(items, function(a, b)
    return a.sort < b.sort
  end)

  -- Mark the last child of each parent. Items are sorted ascending, so walking
  -- backwards the first hit for a given parent is its visually-last sibling.
  local seen = {}
  for i = #items, 1, -1 do
    local p = items[i].parent
    if not seen[p] then
      items[i].last = true
      seen[p] = true
    end
  end

  return items
end

local function pick()
  vim.system({ "gh", "pr", "view", "--json", "files" }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        Snacks.notify.error("gh: " .. (res.stderr ~= "" and res.stderr or "not a PR / not authed"))
        return
      end
      local ok, data = pcall(vim.json.decode, res.stdout)
      if not ok or not data.files or #data.files == 0 then
        Snacks.notify.warn("No changed files in current PR")
        return
      end

      -- Resolve repo root so relative paths render/open correctly.
      local root = vim.fs.root(0, ".git") or vim.fn.getcwd()

      Snacks.picker.pick({
        source = "pr_files",
        title = "PR Changed Files",
        cwd = root,
        items = build_items(data.files),
        tree = true,
        sort = { fields = { "sort" } },
        formatters = { file = { filename_only = true } },
        -- Color the filename by change type. Reuse the built-in file formatter,
        -- then recolor the name segment (hl "SnacksPickerFile").
        format = function(item, picker)
          local ret = Snacks.picker.format.file(item, picker)
          local hl = not item.dir and CHANGE_HL[item.change]
          if hl then
            for _, seg in ipairs(ret) do
              if seg[2] == "SnacksPickerFile" then
                seg[2] = hl
              end
            end
          end
          return ret
        end,
        -- Deleted files no longer exist on disk — don't try to open them.
        confirm = function(picker, item, action)
          if item and item.change == "DELETED" then
            Snacks.notify.warn("File deleted in PR")
            return
          end
          require("snacks.picker.actions").jump(picker, item, action)
        end,
      })
    end)
  end)
end

return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>fP", pick, desc = "PR changed files (tree)" },
  },
}
