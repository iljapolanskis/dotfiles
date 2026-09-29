-- Which PHP toolchain owns a given buffer.
--
-- Two stacks coexist: phpcs/phpstan + php-cs-fixer (erp-stl-eu and friends) and
-- Mago (https://mago.carthage.software). A repo is "on Mago" when it has a
-- `mago.toml` and no phpstan config -- a stray `mago.toml` someone dropped in a
-- phpstan repo to try the CLI must not hijack that repo's editor tooling.
--
-- To migrate a repo: delete its phpstan config. To try Mago's CLI anywhere:
-- run it, nothing here changes.

local M = {}

local PHPSTAN_CONFIGS = { "phpstan.neon", "phpstan.neon.dist", "phpstan.dist.neon" }

---@param path string buffer path; empty for unnamed buffers
---@return string search root
local function search_path(path)
  return path ~= "" and path or vim.fn.getcwd()
end

---@param path string
---@return string|nil path to the phpstan config
function M.phpstan_config(path)
  return vim.fs.find(PHPSTAN_CONFIGS, { path = search_path(path), upward = true })[1]
end

---@param path string
---@return string|nil directory holding mago.toml, nil when the repo isn't on Mago
function M.mago_root(path)
  path = search_path(path)
  local config = vim.fs.find({ "mago.toml" }, { path = path, upward = true })[1]
  if not config or M.phpstan_config(path) then
    return nil
  end
  return vim.fs.dirname(config)
end

return M
