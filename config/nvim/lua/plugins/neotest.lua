-- neotest tuning for docker-wrapped PHP projects.
--
-- neotest-phpunit runs phpunit locally by default. We point it at a project's
-- `bin/nvim-phpunit` docker wrapper when one exists (see ~/work/erp-stl-eu),
-- else fall back to the plain binary so other PHP projects still work.
-- Configured here (not in a project .nvim.lua) so LazyVim constructs the
-- adapter exactly once — requiring it from exrc causes a load loop, and
-- plugin-spec `keys` beat exrc keymaps for lazy-loaded plugins.

-- Projects that split their test suite across separate phpunit configs (one
-- per directory) can't be run as a single neotest position — each dir must run
-- on its own so the wrapper selects the matching config. Keyed by project
-- basename.
local SPLIT_SUITE_DIRS = {
  ["erp-stl-eu"] = { "tests/unit", "tests/integration" },
}

return {
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = {
      adapters = {
        ["neotest-phpunit"] = {
          phpunit_cmd = function()
            local wrapper = LazyVim.root() .. "/bin/nvim-phpunit"
            if vim.fn.filereadable(wrapper) == 1 then
              return wrapper
            end
            return "vendor/bin/phpunit"
          end,
          -- Keep discovery (summary panel, run-all) out of dirs full of
          -- unrelated *Test.php. Setting this replaces the adapter default
          -- ({ ".git", "node_modules" }), so re-list those.
          filter_dirs = { ".git", "node_modules", "vendor", "local-repository" },
        },
      },
    },
    keys = {
      {
        "<leader>tT",
        function()
          local neotest = require("neotest")
          local root = LazyVim.root()
          local dirs = SPLIT_SUITE_DIRS[vim.fn.fnamemodify(root, ":t")]
          if dirs then
            for _, dir in ipairs(dirs) do
              neotest.run.run(root .. "/" .. dir)
            end
          else
            neotest.run.run(root)
          end
        end,
        desc = "Run All Tests",
      },
    },
  },
}
