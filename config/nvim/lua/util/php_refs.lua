-- Unified references for PHP and its XML/YAML config. One picker, two passes,
-- branching on filetype for how the symbol is resolved:
--
--   php   -> <cword>        textDocument/references      + rg over xml/yml/yaml
--   xml   -> FQCN under     workspace/symbol, then       + rg over xml/yml/yaml
--   yaml     the cursor     references at that class
--   other -> stock lsp.references, no second pass
--
-- intelephense never sees XML, so config files can't appear in LSP results and
-- an XML buffer has no position to ask about -- hence the workspace/symbol hop
-- and the rg pass. Emit order is tier order, score_mul sinks the weaker tier
-- once you type (see util/tiered.lua).
--
-- Wired in via plugins/php-refs.lua, which patches snacks' `lsp_references`
-- SOURCE. Rebinding `gr` doesn't work in PHP buffers: LazyVim registers it via
-- `Snacks.keymap.set{ lsp = ... }`, whose applier is debounced 100ms, so it
-- overwrites anything an LspAttach handler sets.
local M = {}

local PHP_CLIENT = "intelephense"

-- Config-only; PHP files are pass 1's job.
M.GLOBS = { "*.xml", "*.yml", "*.yaml" }

-- `ignored = true` (--no-ignore) is what pulls gitignored vendor/ back in. It
-- also un-ignores the junk below, hence the explicit excludes.
M.EXCLUDE = {
  "**/node_modules/**",
  "**/var/cache/**",
  "**/build/**",
  "**/data/**",
  "**/public/build/**",
}

-- Multiplier, not an offset -- the matcher drops items scoring <= 0.
M.GREP_MUL = 0.9

--- FQCN the XML/YAML branch resolved, or nil for the PHP/stock branches. Set by
--- M.search(), read by M.finder(). Has to be captured: M.search() runs in
--- Filter.new() while the source buffer is still current, the finder runs after
--- the prompt window has taken over.
M._xml_fqcn = nil

--- FQCN under the cursor, or nil.
local function fqcn_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local function word(c)
    return c ~= "" and c:match("[%w_\\]") ~= nil
  end
  if not word(line:sub(col, col)) then
    return nil
  end
  -- Quotes aren't word chars, so this expands to the whole attribute value.
  local s, e = col, col
  while word(line:sub(s - 1, s - 1)) do
    s = s - 1
  end
  while word(line:sub(e + 1, e + 1)) do
    e = e + 1
  end
  local fqcn = line:sub(s, e):gsub("^\\", "")
  -- Require a separator, else this fires on `strategy="IDENTITY"` and friends.
  return fqcn:find("\\") and fqcn or nil
end

--- Exact match for `fqcn` in a workspace/symbol result. intelephense reports the
--- namespace separately as containerName, so recombine before comparing.
---@param result lsp.SymbolInformation[]?
local function find_symbol(result, fqcn)
  for _, sym in ipairs(result or {}) do
    local full = sym.containerName and (sym.containerName .. "\\" .. sym.name) or sym.name
    if full:gsub("^\\", "") == fqcn then
      return sym
    end
  end
end

--- FQCN of a class name in the current PHP buffer, or nil if `word` isn't one.
--- Config files always name classes in full, so a short name is the wrong grep
--- term for them -- `Lead` matches the namespace segment of every
--- `...\Domain\Lead\LeadInfo`. Lowercase words are property/method names
--- (`<field name="country">`), which config does write bare; they get nil.
local function php_fqcn(word)
  if not word:match("^%u") then
    return nil
  end
  local ns, declared
  for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, 300, false)) do
    local imported = l:match("^%s*use%s+([%w_\\]+\\" .. word .. ")%s*;")
    if imported then
      return imported
    end
    local aliased, alias = l:match("^%s*use%s+([%w_\\]+)%s+as%s+([%w_]+)%s*;")
    if alias == word then
      return aliased
    end
    ns = ns or l:match("^%s*namespace%s+([%w_\\]+)%s*;")
    -- Lua patterns have no alternation, so test each keyword.
    for _, kw in ipairs({ "class", "interface", "trait", "enum" }) do
      declared = declared or l:match("%f[%a]" .. kw .. "%s+" .. word .. "%f[^%w_]") ~= nil
    end
  end
  return ns and declared and (ns .. "\\" .. word) or nil
end

--- Grep pattern, resolved as `opts.search`. Word-bounded at both ends, so
--- `...\Lead\Lead` doesn't match inside `...\Lead\LeadInfo`. Backslashes are
--- escaped for rg's regex.
local function pattern(term)
  return "\\b" .. term:gsub("\\", "\\\\") .. "\\b"
end

function M.search()
  M._xml_fqcn = nil
  local ft = vim.bo.filetype

  if ft == "php" then
    local word = vim.fn.expand("<cword>")
    if word == "" then
      return ""
    end
    return pattern(php_fqcn(word) or word)
  elseif ft == "xml" or ft == "yaml" then
    local fqcn = fqcn_under_cursor()
    if not fqcn then
      return ""
    end
    M._xml_fqcn = fqcn
    return pattern(fqcn)
  end

  return "" -- grep.grep() returns an empty finder on a blank search
end

--- Byte column of `short` as a standalone identifier in `line`, or nil.
--- %f[..] is Lua's frontier pattern: a zero-width word boundary.
local function find_ident(line, short)
  local s = line:find("%f[%w_]" .. short .. "%f[^%w_]")
  return s and (s - 1) or nil
end

--- LSP pass for XML/YAML: FQCN -> workspace/symbol -> references at the class.
---
--- Runs in snacks' finder coroutine, which is a FAST EVENT CONTEXT -- most of
--- the vim API is illegal there. So LSP calls go through snacks' `lsp.request()`
--- (defers to the main loop, suspends until the reply lands), direct vim calls
--- go through `main()`, and waiting uses `async:sleep()` rather than `vim.wait()`
--- so the UI stays responsive.
---@param opts snacks.picker.lsp.Config
---@param fqcn string
local function xml_references(opts, fqcn)
  local lsp = require("snacks.picker.source.lsp")
  local Async = require("snacks.picker.util.async")
  local short = fqcn:match("([^\\]+)$")

  ---@async
  return function(cb)
    local async = Async.running()
    local function main(fn)
      return async:schedule(fn)
    end
    local function warn(msg)
      main(function()
        vim.notify(msg, vim.log.levels.WARN, { title = "PHP references" })
      end)
    end

    local client = main(function()
      return vim.lsp.get_clients({ name = PHP_CLIENT })[1]
    end)
    if not client then
      return warn(PHP_CLIENT .. " is not running")
    end

    local hit
    lsp.request(client, "workspace/symbol", function()
      return { query = short }
    end, function(_, result)
      hit = hit or find_symbol(result, fqcn)
    end)
    if not hit then
      return warn("Not in the " .. PHP_CLIENT .. " index: " .. fqcn)
    end

    -- Load the target without showing it: bufload fires BufReadPost/FileType,
    -- so lspconfig attaches and the server gets its didOpen. textDocument/*
    -- needs the document open, not displayed.
    local buf = main(function()
      local b = vim.fn.bufadd(vim.uri_to_fname(hit.location.uri))
      vim.fn.bufload(b)
      return b
    end)

    local attached = false
    for _ = 1, 40 do
      attached = main(function()
        return #vim.lsp.get_clients({ bufnr = buf, name = PHP_CLIENT }) > 0
      end)
      if attached then
        break
      end
      async:sleep(50)
    end
    if not attached then
      return warn(PHP_CLIENT .. " did not attach to " .. fqcn)
    end

    -- workspace/symbol ranges start at the declaration keyword, not the name,
    -- and references there return nothing. Scan forward for the identifier.
    local pos = main(function()
      local from = hit.location.range.start.line
      for i, text in ipairs(vim.api.nvim_buf_get_lines(buf, from, from + 20, false)) do
        local col = find_ident(text, short)
        if col then
          local line = from + i - 1
          -- LSP columns are in the server's offset encoding, not bytes.
          return { line = line, character = vim.lsp.util.character_offset(buf, line, col, client.offset_encoding) }
        end
      end
    end)
    if not pos then
      return warn("Could not locate " .. short .. " in its own declaration")
    end

    lsp.request(client, "textDocument/references", function()
      return {
        textDocument = { uri = vim.uri_from_bufnr(buf) },
        position = pos,
        context = { includeDeclaration = opts.include_declaration ~= false },
      }
    end, function(c, result)
      -- LSP handler, so the main loop -- vim API is fine here.
      local items = vim.lsp.util.locations_to_items(result or {}, c.offset_encoding)
      lsp.fix_locs(items)
      local bufmap = lsp.bufmap()
      for _, loc in ipairs(items) do
        cb({
          text = loc.filename .. " " .. loc.text,
          buf = bufmap[loc.filename],
          file = loc.filename,
          pos = { loc.lnum, loc.col - 1 },
          end_pos = loc.end_lnum and loc.end_col and { loc.end_lnum, loc.end_col - 1 } or nil,
          line = loc.text,
        })
      end
    end)
  end
end

---@param opts snacks.picker.lsp.Config
---@param ctx snacks.picker.finder.ctx
function M.finder(opts, ctx)
  local lsp = require("snacks.picker.source.lsp")
  local grep = require("snacks.picker.source.grep")

  if ctx.filter.search == "" then
    return lsp.references(opts, ctx) -- unhandled filetype, or nothing resolvable
  end
  local lsp_pass = M._xml_fqcn and xml_references(opts, M._xml_fqcn) or lsp.references(opts, ctx)

  -- grep.grep() reads its pattern from ctx.filter.search, so it rides on
  -- M.search(). Clone both: grep.grep() writes ctx._opts via ctx:opts(), which
  -- must not leak into the LSP pass. The clones are __index-inherited.
  local gctx = ctx:clone()
  gctx.filter = ctx.filter:clone()
  local grep_pass = grep.grep(
    vim.tbl_deep_extend("force", {}, opts, {
      glob = M.GLOBS,
      exclude = M.EXCLUDE,
      ignored = true,
      hidden = false,
      live = false,
    }),
    gctx
  )

  ---@async
  return function(cb)
    lsp_pass(cb)
    grep_pass(function(item)
      item.score_mul = (item.score_mul or 1) * M.GREP_MUL
      cb(item)
    end)
  end
end

return M
