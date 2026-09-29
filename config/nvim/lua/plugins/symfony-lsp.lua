-- Symfony Language Tools (official): route names, templates, service IDs,
-- translation keys, env vars, Messenger/events/Doctrine relations.
--
-- A companion, not a PHP server: on plain PHP symbols it answers nil for hover,
-- definition, references and prepareRename, so nothing merges with intelephense.
-- On route/template strings intelephense answers nil and this one owns them.
-- No capability strip needed; `<leader>cr` (util.php_rename) reaches it for
-- route names because intelephense's prepareRename declines string literals.
--
-- Per-project opt-in lives in the repo's `.nvim.lua` (exrc, :trust-gated):
--
--   vim.g.symfony_lsp = {
--     trust = true, -- let it boot the app (runtime indexing, code lenses)
--     php = { "docker", "compose", "exec", "-T", "php", "php" }, -- optional
--   }
--
-- Read at client start, not here: exrc runs before LazyVim configures servers,
-- so a `vim.lsp.config()` call from `.nvim.lua` would be overwritten by ours.

--- Nearest composer.json that requires symfony/framework-bundle. Laminas apps
--- pulling in Symfony components (console, yaml, ...) don't match, so the
--- server never starts there instead of idling and answering nil.
---@type table<string, boolean>
local is_symfony = {}

local function symfony_root(bufnr, on_dir)
  local root = vim.fs.root(bufnr, "composer.json")
  if not root then
    return
  end
  if is_symfony[root] == nil then
    local ok, json = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(root .. "/composer.json"), "\n"))
    end)
    is_symfony[root] = ok and type(json.require) == "table" and json.require["symfony/framework-bundle"] ~= nil
  end
  if is_symfony[root] then
    on_dir(root)
  end
end

local function project()
  return vim.g.symfony_lsp or {}
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        symfony_lsp = {
          root_dir = symfony_root,
          handlers = {
            -- persist the edits; see util.lsp_edit. A route rename touches PHP
            -- and Twig files, which the stock handler leaves unsaved.
            ["textDocument/rename"] = function(...)
              return require("util.lsp_edit").rename_handler(...)
            end,
          },
          before_init = function(params)
            local p = project()
            local init = params.initializationOptions or {}
            -- Never run application code unless the repo opted in.
            init.workspaceTrust = p.trust == true
            if p.php then
              init.phpCommand = p.php
            end
            params.initializationOptions = init
          end,
          on_init = function(client)
            local php = project().php
            if php then
              client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
                symfonyLsp = { phpCommand = php },
              })
              client:notify("workspace/didChangeConfiguration", { settings = client.settings })
            end
          end,
          on_attach = function(_, bufnr)
            -- Lenses (event -> listeners, message -> handlers, entity ->
            -- repository) come from the booted container, so they only appear
            -- in trusted repos. `grx` runs the one under the cursor.
            -- Enablement is client flag (default on) AND buffer flag (default
            -- off), so it's the buffer that needs switching on; a client_id
            -- filter would only set the flag that's already on. Scoping to the
            -- buffers this server attaches to keeps LazyVim's global codelens
            -- option off everywhere else. No other PHP client here offers
            -- lenses (phpactor's codeLensProvider is stripped).
            vim.lsp.codelens.enable(true, { bufnr = bufnr })
          end,
        },
      },
    },
  },
}
