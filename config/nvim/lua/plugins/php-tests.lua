-- Keep the terminal open after the run and land in normal mode, so test
-- output stays readable/scrollable (and file paths jumpable).
-- `.open()` (not the reusing `Snacks.terminal()`) forces a fresh run on every
-- press; `bufhidden = "wipe"` clears the dead buffer when the window closes.
local function runner(cmd)
  Snacks.terminal.open(cmd, {
    start_insert = false,
    auto_insert = false,
    auto_close = false,
    win = { position = "bottom", height = 0.4, bo = { bufhidden = "wipe" } },
  })
end

return {
  {
    "LazyVim/LazyVim",
    keys = {
      {
        "<leader>tu",
        function()
          runner("make test-unit")
        end,
        desc = "PHPUnit: unit (docker)",
      },
      {
        "<leader>ti",
        function()
          runner("make test-integration")
        end,
        desc = "PHPUnit: integration (docker)",
      },
      {
        "<leader>tI",
        function()
          runner("make test-integration-fresh")
        end,
        desc = "PHPUnit: integration fresh DB",
      },
      {
        "<leader>tf",
        function()
          local rel = vim.fn.expand("%:.")
          local config = rel:match("^tests/integration/") and "tests/integration/phpunit.integration.xml"
            or "phpunit.xml.dist"
          runner("docker compose run --rm --no-deps app vendor/bin/phpunit --configuration " .. config .. " " .. rel)
        end,
        desc = "PHPUnit: current file (docker)",
      },
    },
  },
}
