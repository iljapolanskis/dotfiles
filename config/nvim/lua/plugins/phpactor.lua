return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- lang.php extra disables phpactor when lazyvim_php_lsp = "intelephense".
        -- Turn it back on, but only for refactors/code actions (see setup below).
        phpactor = { enabled = true },
      },
      setup = {
        phpactor = function(_, opts)
          require("lspconfig").phpactor.setup(vim.tbl_deep_extend("force", opts, {
            init_options = {
              -- replaces defaults entirely, so re-list them + add project dirs.
              -- phpactor globs are root-anchored: /dir/**/*
              ["indexer.exclude_patterns"] = {
                -- phpactor defaults
                "/vendor/**/Tests/**/*",
                "/vendor/**/tests/**/*",
                "/vendor/composer/**/*",
                "/vendor/rector/**/stubs/**/*",
                "/var/cache/**/*",
                -- project excludes
                "/node_modules/**/*",
                "/data/**/*",
                "/build/**/*",
                "/cache/**/*",
                "/storage/**/*",
                "/migrations-archive/**/*",
                "/public/build/**/*",
                "/tests/_output/**/*",
                "/.drift/**/*",
                "/.context/**/*",
              },
            },
            handlers = {
              -- diagnostics arrive as a notification, not a capability.
              -- intelephense owns diagnostics; drop phpactor's entirely.
              ["textDocument/publishDiagnostics"] = function() end,
            },
            on_attach = function(client)
              -- intelephense owns completion/hover/definition/diagnostics.
              -- Strip everything from phpactor except code actions.
              local c = client.server_capabilities
              c.completionProvider = nil
              c.hoverProvider = nil
              c.definitionProvider = nil
              c.typeDefinitionProvider = nil
              c.implementationProvider = nil
              c.referencesProvider = nil
              c.documentSymbolProvider = nil
              c.workspaceSymbolProvider = nil
              c.signatureHelpProvider = nil
              c.renameProvider = nil
              c.documentHighlightProvider = nil
              c.documentFormattingProvider = nil
              c.documentRangeFormattingProvider = nil
              c.semanticTokensProvider = nil
              c.selectionRangeProvider = nil
              c.inlineValueProvider = nil
              c.foldingRangeProvider = nil
              c.callHierarchyProvider = nil
              c.colorProvider = nil
              c.codeLensProvider = nil
              c.documentLinkProvider = nil
              c.declarationProvider = nil
              -- willRenameFiles lives under workspace.fileOperations
              if c.workspace then
                c.workspace.fileOperations = nil
              end
              -- kept: codeActionProvider + executeCommandProvider (needed to APPLY actions)
            end,
          }))
          return true
        end,
      },
    },
  },
}
