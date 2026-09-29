-- Snippet behaviour that blink.cmp's JSON engine can't express on its own.
--
-- Snippets live in config/nvim/snippets/<filetype>.json (blink scans
-- stdpath("config")/snippets by default). That engine has no per-snippet
-- conditions and no way to compute a value, so both happen here through the
-- snippets provider's transform_items hook:
--
--   1. scope gating   - hide structural snippets where they can't legally go
--   2. __NS__ marker  - replace with the PSR-4 namespace for the current file
--
-- Scopes (php):
--   file   -> only at top level (class/interface/enum/trait declarations)
--   member -> only inside a class body (methods, constructors)
-- Labels not listed below are never filtered (friendly-snippets stays intact).
local scopes = {
  php = {
    file = { "sh", "sc", "sac", "si", "st", "se", "ses", "su" },
    member = { "sctor", "sm" },
  },
}

-- label -> scope, flattened per filetype
local scope_of = {}
for ft, groups in pairs(scopes) do
  scope_of[ft] = {}
  for scope, labels in pairs(groups) do
    for _, label in ipairs(labels) do
      scope_of[ft][label] = scope
    end
  end
end

-- Class bodies are `declaration_list`; statement bodies are `compound_statement`.
-- Anything with neither ancestor is top level.
local function scope_at_cursor(ctx)
  local ok, node = pcall(vim.treesitter.get_node, {
    bufnr = ctx.bufnr,
    pos = { ctx.cursor[1] - 1, ctx.cursor[2] },
  })
  if not ok or not node then return nil end

  while node do
    local t = node:type()
    if t == "compound_statement" then return "statement" end
    if t == "declaration_list" then return "member" end
    node = node:parent()
  end
  return "file"
end

-- Flatten autoload.psr-4 + autoload-dev.psr-4 into {prefix, dir} pairs,
-- longest dir first so src/Foo wins over src for a file under src/Foo.
local function psr4_maps(composer)
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(composer), "\n"))
  if not ok then return {} end

  local maps = {}
  for _, key in ipairs({ "autoload", "autoload-dev" }) do
    local psr4 = vim.tbl_get(decoded, key, "psr-4") or {}
    for prefix, dirs in pairs(psr4) do
      for _, dir in ipairs(type(dirs) == "string" and { dirs } or dirs) do
        table.insert(maps, { prefix = prefix:gsub("\\+$", ""), dir = dir:gsub("/+$", "") })
      end
    end
  end

  table.sort(maps, function(a, b) return #a.dir > #b.dir end)
  return maps
end

-- Re-read composer.json only when the file's directory changes. transform_items
-- runs on every keystroke, so this must not touch disk in the common case.
local ns_cache = {}

local function psr4_namespace(path)
  local dir = vim.fs.dirname(path)
  if ns_cache[dir] ~= nil then return ns_cache[dir] or nil end

  local composer = vim.fs.find("composer.json", { path = dir, upward = true, type = "file" })[1]
  local namespace = false

  if composer then
    local root = vim.fs.dirname(composer)
    local relative = vim.fs.dirname(path):sub(#root + 2)

    for _, map in ipairs(psr4_maps(composer)) do
      local under = map.dir == "" and relative or relative:match("^" .. vim.pesc(map.dir) .. "/?(.*)$")
      if under then
        namespace = map.prefix
        if under ~= "" then namespace = namespace .. "\\" .. under:gsub("/", "\\") end
        break
      end
    end
  end

  ns_cache[dir] = namespace
  return namespace or nil
end

-- Substitute the marker, or drop the namespace line entirely when the file
-- isn't under a PSR-4 root (scratch files, plain scripts).
local function substitute_namespace(text, namespace)
  if namespace then
    -- \ is an escape character in LSP snippet syntax, so double it
    return (text:gsub("__NS__", (namespace:gsub("\\", "\\\\"):gsub("%%", "%%%%"))))
  end

  local kept = {}
  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    if line:find("__NS__", 1, true) then
      table.remove(kept) -- the blank line above it
    else
      table.insert(kept, line)
    end
  end
  return table.concat(kept, "\n")
end

-- blink carries the snippet body twice: insertText and textEdit.newText.
-- Accepting uses textEdit, so both must be rewritten.
local function apply_namespace(item, path)
  if not item.insertText or not item.insertText:find("__NS__", 1, true) then return end

  local namespace = path ~= "" and psr4_namespace(path) or nil
  item.insertText = substitute_namespace(item.insertText, namespace)
  if item.textEdit and item.textEdit.newText then
    item.textEdit.newText = substitute_namespace(item.textEdit.newText, namespace)
  end
end

return {
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        providers = {
          snippets = {
            transform_items = function(ctx, items)
              local path = vim.api.nvim_buf_get_name(ctx.bufnr)
              local ft_scopes = scope_of[vim.bo[ctx.bufnr].filetype]
              if not ft_scopes then return items end

              local here = scope_at_cursor(ctx)

              local kept = {}
              for _, item in ipairs(items) do
                local want = ft_scopes[item.label]
                if here == nil or want == nil or want == here then
                  apply_namespace(item, path)
                  table.insert(kept, item)
                end
              end
              return kept
            end,
          },
        },
      },
    },
  },
}
