-- phpcs, the fourth PHP diagnostic channel.
--
-- LazyVim's lang.php extra pushes the none-ls phpcs builtin into `opts.sources`
-- from an opts *function*, so it survives any table-level override -- overriding
-- nvim-lint in php-mago.lua removed phpcs from that runner but left this one
-- firing in every PHP buffer, Mago repos included.
--
-- Re-register it behind a condition: only repos shipping a phpcs ruleset get
-- sniff diagnostics. Mago repos have none, so they go quiet.
local PHPCS_CONFIGS = { "phpcs.xml", "phpcs.xml.dist", ".phpcs.xml", ".phpcs.xml.dist" }

return {
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")

      opts.sources = vim.tbl_filter(function(source)
        -- phpcsfixer goes for good: conform owns PHP formatting (php-mago.lua).
        return source.name ~= "phpcs" and source.name ~= "phpcsfixer"
      end, opts.sources or {})

      table.insert(
        opts.sources,
        nls.builtins.diagnostics.phpcs.with({
          condition = function(utils)
            return utils.root_has_file(PHPCS_CONFIGS)
          end,
        })
      )
    end,
  },
}
