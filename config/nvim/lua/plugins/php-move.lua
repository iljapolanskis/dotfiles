-- Make file moves update PHP namespaces + references. See util/php_move.lua.
--
-- Patches `Snacks.rename.on_rename_file` (the single entry point behind
-- `<leader>cR`, explorer `r` and explorer `m`) instead of rebinding keys, so
-- non-PHP renames keep stock behaviour.
return {
  {
    "folke/snacks.nvim",
    optional = true,
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          Snacks.rename.on_rename_file = require("util.php_move").on_rename_file
        end,
      })
    end,
  },
}
