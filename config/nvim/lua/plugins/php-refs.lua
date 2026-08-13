-- Make `gr` also find PHP classes in xml/yml/yaml config. See util/php_refs.lua.
--
-- Patches the `lsp_references` SOURCE rather than the keymap: LazyVim binds `gr`
-- via `Snacks.keymap.set{ lsp = ... }` on a 100ms debounce, which clobbers
-- anything an LspAttach handler sets. Non-PHP/XML buffers fall through to stock
-- behaviour.
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          lsp_references = {
            -- Lazy requires: this spec is evaluated before util/ is on the path.
            finder = function(opts, ctx)
              return require("util.php_refs").finder(opts, ctx)
            end,
            search = function()
              return require("util.php_refs").search()
            end,
          },
        },
      },
    },
  },
}
