-- phpstan. The `php` filetype list lives in php-mago.lua, which owns all three
-- PHP linters; this file only configures phpstan itself.
return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        phpstan = {
          -- Only in repos that actually configure phpstan -- otherwise every
          -- PHP buffer spawns a linter that errors out on a missing config.
          condition = function(ctx)
            return require("util.php_tooling").phpstan_config(ctx.filename) ~= nil
          end,
        },
      },
    },
  },
}
