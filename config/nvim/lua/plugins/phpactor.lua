return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- `<leader>cr` (LazyVim's stock rename) walks every client with
        -- `textDocument/rename` in turn, skipping only those whose prepareRename
        -- returns nil. intelephense and phpactor both accept classes and
        -- members, so both would rename, one after the other. Pin it to
        -- intelephense — the better member/variable renamer — and give phpactor
        -- its own key below. Falls back to the stock behaviour off PHP.
        -- stylua: ignore
        ["*"] = {
          keys = {
            { "<leader>cr", function() require("util.php_rename").rename_symbol() end, desc = "Rename", has = "rename" },
          },
        },
        -- lang.php extra disables phpactor when lazyvim_php_lsp = "intelephense".
        -- Turn it back on, but only for refactors/code actions (see setup below).
        phpactor = {
          enabled = true,
          -- stylua: ignore
          keys = {
            { "<leader>cn", function() require("util.php_rename").rename_class() end, desc = "Rename Class + File", has = "rename" },
          },
        },
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
              -- Diagnostics are pushed, not requested: stripping capabilities
              -- below can't stop them, so phpactor would still analyse every
              -- edit (in a child process) only for the noop handler to discard
              -- it. Switch the analysis off at the source.
              ["language_server_worse_reflection.diagnostics.enable"] = false,
              ["language_server.diagnostics_on_open"] = false,
              ["language_server.diagnostics_on_update"] = false,
              ["language_server.diagnostics_on_save"] = false,
            },
            handlers = {
              -- intelephense owns diagnostics. Kept as a safety net behind the
              -- init_options above: a project .phpactor.json enabling phpstan/
              -- psalm/cs-fixer would otherwise leak diagnostics back in.
              ["textDocument/publishDiagnostics"] = function() end,
              -- persist the edits; see util.lsp_edit.
              ["textDocument/rename"] = function(...)
                return require("util.lsp_edit").rename_handler(...)
              end,
            },
            on_attach = function(client)
              -- intelephense owns completion/hover/definition/diagnostics.
              -- Strip everything from phpactor except code actions and rename.
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
              -- kept: codeActionProvider + executeCommandProvider (needed to APPLY actions)
              -- kept: renameProvider — phpactor's ClassRenamer returns a
              -- `RenameResult(oldUri, newUri)`, which the LSP layer turns into a
              -- RenameFile operation, so renaming a class also MOVES the file to
              -- its PSR-4 path. Intelephense emits TextEdits only, so its rename
              -- leaves `OldName.php` holding `class NewName`. Bound to
              -- `<leader>cn`; `<leader>cr` stays on intelephense.
              -- kept: workspace.fileOperations.willRename — phpactor advertises it for
              -- **/*.php and rewrites namespace + class name + references on move.
              -- intelephense has NO fileOperations at all (no move refactor), so this
              -- is the only client that can answer workspace/willRenameFiles. Stripping
              -- it made `<leader>cR` vanish (LazyVim gates that key on the method) and
              -- turned snacks explorer `r`/`m` into a plain fs rename.
            end,
          }))
          return true
        end,
      },
    },
  },
}
