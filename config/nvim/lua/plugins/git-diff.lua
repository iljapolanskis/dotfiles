-- Override <leader>gd (Snacks git_diff / "Git Diff (hunks)").
-- Default runs `git diff`, which only shows TRACKED files and ignores no folders.
-- This wrapper: (1) marks untracked files intent-to-add so they show as hunks,
-- (2) excludes noisy folders via git pathspec.
return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>gd",
      function()
        -- Folders to hide from the diff picker.
        local exclude = { "vendor", "node_modules", ".git", "local-repository" }

        -- Make untracked files appear as added hunks (intent-to-add).
        -- Harmless: undo with `git reset`. Comment out if you don't want this.
        local root = Snacks.git.get_root()
        if root then
          vim.system({ "git", "-C", root, "add", "-N", "--", "." }):wait()
        end

        -- `--` + `:(exclude)<path>` is git pathspec magic to drop folders.
        local cmd_args = { "--", "." }
        for _, dir in ipairs(exclude) do
          table.insert(cmd_args, ":(exclude)" .. dir)
        end

        Snacks.picker.git_diff({ cmd_args = cmd_args })
      end,
      desc = "Git Diff (hunks, +untracked)",
    },
  },
}
