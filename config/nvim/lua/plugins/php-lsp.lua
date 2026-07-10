return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          settings = {
            intelephense = {
              files = {
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
