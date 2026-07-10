return {
  {
    "LazyVim/LazyVim",
    keys = {
      {
        "<leader>tu",
        function()
          Snacks.terminal("make test-unit", { win = { position = "bottom", height = 0.4 } })
        end,
        desc = "PHPUnit: unit (docker)",
      },
      {
        "<leader>ti",
        function()
          Snacks.terminal("make test-integration", { win = { position = "bottom", height = 0.4 } })
        end,
        desc = "PHPUnit: integration (docker)",
      },
      {
        "<leader>tI",
        function()
          Snacks.terminal("make test-integration-fresh", { win = { position = "bottom", height = 0.4 } })
        end,
        desc = "PHPUnit: integration fresh DB",
      },
      {
        "<leader>tf",
        function()
          local rel = vim.fn.expand("%:.")
          local config = rel:match("^tests/integration/")
              and "tests/integration/phpunit.integration.xml"
            or "phpunit.xml.dist"
          Snacks.terminal(
            "docker compose run --rm --no-deps app vendor/bin/phpunit --configuration " .. config .. " " .. rel,
            { win = { position = "bottom", height = 0.4 } }
          )
        end,
        desc = "PHPUnit: current file (docker)",
      },
    },
  },
}
