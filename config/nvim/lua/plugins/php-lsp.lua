return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          -- Fixed cache dir (default is a random os.tmpdir() path). Predictable →
          -- clear a stale index with: rm -rf ~/.cache/nvim/intelephense
          init_options = {
            storagePath = vim.fn.stdpath("cache") .. "/intelephense",
          },
          settings = {
            intelephense = {
              files = {
                -- Bumped from 1MB default so large generated vendor files
                -- (e.g. IDE helpers, big autoload maps) still get indexed.
                maxSize = 5000000,
                -- replaces defaults entirely, so re-list them + add project dirs
                exclude = {
                  -- intelephense defaults
                  "**/.git/**",
                  "**/.svn/**",
                  "**/.hg/**",
                  "**/CVS/**",
                  "**/.DS_Store/**",
                  "**/node_modules/**",
                  "**/bower_components/**",
                  "**/vendor/**/{Tests,tests}/**",
                  "**/.history/**",
                  "**/vendor/**/vendor/**",
                  -- project excludes
                  "**/data/**",
                  "**/build/**",
                  "**/cache/**",
                  "**/storage/**",
                  "**/migrations-archive/**",
                  "**/public/build/**",
                  "**/tests/_output/**",
                  "**/.drift/**",
                  "**/.context/**",
                },
              },
              references = {
                -- Default excludes ALL of vendor/** from find-references results,
                -- so `gr` on a vendored class returns nothing (defs still work —
                -- separate index). See bmewburn/vscode-intelephense#1253, #3314.
                -- Override to only skip vendor tests + nested vendor, matching
                -- files.exclude so refs cover the indexed set.
                exclude = {
                  "**/vendor/**/{Tests,tests}/**",
                  "**/vendor/**/vendor/**",
                },
              },
              completion = {
                propertyCase = "camel",
                parameterCase = "camel",
              },
              inlayHint = {
                returnTypes = true,
                parameterNames = true,
              },
            },
          },
        },
      },
    },
  },
}
