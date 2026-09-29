-- Mago -- Rust PHP toolchain: formatter + linter + static analyzer.
-- https://mago.carthage.software/latest/en/
--
-- Opt-in per project. `util.php_tooling` decides which repos are on Mago and
-- which stay on php-cs-fixer + phpstan; see that module for the rule.

local php = require("util.php_tooling")

-- Mago resolves `mago.toml` from the workspace dir and does *not* search
-- upward, so every invocation has to be told where the root is.
local function workspace_arg()
  local root = php.mago_root(vim.api.nvim_buf_get_name(0))
  return "--workspace=" .. (root or vim.fn.getcwd())
end

--- Build an nvim-lint spec for a mago subcommand reporting in `emacs` format:
---   path/to/File.php:19:24:warning - rule-name: message
---@param subcommand string "lint" or "analyze"
local function mago_linter(subcommand)
  return {
    cmd = "mago",
    stdin = false,
    -- nvim-lint appends the buffer's absolute path, scoping the run to one file.
    append_fname = true,
    args = { workspace_arg, subcommand, "--reporting-format=emacs" },
    stream = "stdout",
    -- Mago exits non-zero when it finds issues; that is the normal case.
    ignore_exitcode = true,
    parser = require("lint.parser").from_pattern(
      "^([^:]+):(%d+):(%d+):(%a+) %- ([%w%-]+): (.*)$",
      -- The first capture is the file, deliberately *not* named "file":
      -- Mago prints paths relative to its workspace, which nvim-lint would
      -- compare against the buffer path relative to Neovim's cwd. Since we
      -- already pass a single file, there is nothing to filter out.
      { "_relpath", "lnum", "col", "severity", "code", "message" },
      {
        error = vim.diagnostic.severity.ERROR,
        warning = vim.diagnostic.severity.WARN,
        note = vim.diagnostic.severity.INFO,
        help = vim.diagnostic.severity.HINT,
      },
      { source = "mago " .. subcommand },
      { end_col_offset = 0 }
    ),
    -- LazyVim extension: skip this linter entirely outside Mago projects.
    condition = function(ctx)
      return php.mago_root(ctx.filename) ~= nil
    end,
  }
end

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        mago = {
          command = "mago",
          args = { "format", "--stdin-input", "--stdin-filepath", "$FILENAME" },
          stdin = true,
          cwd = require("conform.util").root_file({ "mago.toml" }),
          require_cwd = true,
        },
      },
      formatters_by_ft = {
        -- Overrides LazyVim's php extra, which hardcodes php_cs_fixer.
        php = function(bufnr)
          if php.mago_root(vim.api.nvim_buf_get_name(bufnr)) then
            return { "mago" }
          end
          return { "php_cs_fixer" }
        end,
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- Each entry self-filters via `condition`, so listing all three is safe:
        -- Mago repos run the two Mago passes, everything else runs phpstan.
        php = { "mago_lint", "mago_analyze", "phpstan" },
      },
      linters = {
        mago_lint = mago_linter("lint"),
        mago_analyze = mago_linter("analyze"),
      },
    },
  },
}
