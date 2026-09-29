-- Move a PHP class and update its namespace + every reference.
--
-- Replaces `Snacks.rename.on_rename_file`, which powers `<leader>cR`, snacks
-- explorer `r` (rename) and `m` (move), and mini.files `r`. Three things are
-- wrong for PHP with the stock version:
--
--   1. ORDER. Snacks follows the LSP spec: send `workspace/willRenameFiles`
--      BEFORE touching the fs, so the server computes edits against the old
--      file. phpactor doesn't work that way — its FileRenamer reads the *new*
--      URI off disk to rewrite the namespace declaration, so a pre-move request
--      dies with `TextDocumentNotFound`. It needs the file moved first, i.e.
--      `didRenameFiles` semantics behind a `willRenameFiles` method name.
--   2. SILENCE. Snacks ignores `resp.err` and a nil response, so a phpactor
--      exception or a timeout looks identical to a successful no-op rename.
--   3. DIRECTORIES. See `expand()`.
--
-- On top of that we move the mirrored `*Test.php`, see `find_twins()`. That part
-- is also reachable on its own as `rename_test_twin()`, which `<leader>cn`
-- (util.php_rename) calls after a phpactor class rename.
--
-- Other servers keep the spec order. Only phpactor is moved after the rename.
--
-- Also note phpactor is the ONLY client here that can do this: intelephense
-- advertises no `workspace.fileOperations` at all (even licenced), which is why
-- `<leader>cR` didn't exist before — LazyVim gates that key on the method.
local M = {}

-- Post-rename clients: need the file at its new path before they can answer.
local AFTER_RENAME = { phpactor = true }

-- Snacks hardcodes 1000ms, which a cold phpactor index blows through on a big
-- project. The request is synchronous, so this is also the freeze ceiling.
local TIMEOUT_MS = 10000
-- A directory move is one request carrying N files; phpactor walks its index
-- once per file, so give it room. Still bounded — this blocks the UI.
local TIMEOUT_PER_FILE_MS = 1000
local TIMEOUT_MAX_MS = 60000

local ROOT_MARKERS = { "composer.json", ".git" }

local function warn(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = "Move file" })
end

local function info(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "Move file" })
end

---@param path string
---@return string # `/a/b/Foo.php` -> `Foo`
local function stem(path)
  return vim.fn.fnamemodify(path, ":t:r")
end

---@param from string
---@param to string
---@return table `FileRename`
local function pair(from, to)
  return { oldUri = vim.uri_from_fname(from), newUri = vim.uri_from_fname(to) }
end

--- Split the attached clients by when they can answer `willRenameFiles`.
---@return vim.lsp.Client[] before, vim.lsp.Client[] after
local function partition_clients()
  local before, after = {}, {}
  for _, c in ipairs(vim.lsp.get_clients()) do
    if c:supports_method("workspace/willRenameFiles") then
      table.insert(AFTER_RENAME[c.name] and after or before, c)
    end
  end
  return before, after
end

--- Ask one client for the edits and apply them.
---@param client vim.lsp.Client
---@param files table[] list of `FileRename`
local function will_rename(client, files)
  local timeout = math.min(TIMEOUT_MAX_MS, TIMEOUT_MS + #files * TIMEOUT_PER_FILE_MS)
  local resp = client:request_sync("workspace/willRenameFiles", { files = files }, timeout, 0)
  if not resp then
    return warn(client.name .. " timed out after " .. timeout .. "ms — references NOT updated")
  end
  if resp.err then
    return warn(client.name .. ": " .. tostring(resp.err.message))
  end
  if resp.result then
    -- Not `vim.lsp.util.apply_workspace_edit` directly: on 0.12 that leaves
    -- every touched file as an unsaved hidden buffer, and the twin rename below
    -- force-deletes buffers. See util.lsp_edit.
    require("util.lsp_edit").apply(resp.result, client.offset_encoding, client.name)
  end
end

--- Expand a rename into one `FileRename` per PHP file.
---
--- phpactor registers `willRename` for the glob `**/*.php` only, and derives the
--- FQCN from the path via composer's PSR-4 map, so a *directory* URI throws
--- `CouldNotConvertUriToClass` and the whole move updates nothing. nvim's
--- `supports_method` doesn't check registration globs, so the request goes out
--- anyway. Enumerate the moved tree instead.
---
--- Read from `to`: this runs after the fs move, so that's where the files are.
--- `from` is only needed as a string to derive the old FQCN.
---@param from string
---@param to string
---@return table[]
local function expand(from, to)
  if vim.fn.isdirectory(to) == 0 then
    return { pair(from, to) }
  end

  local files = {}
  for name, type in vim.fs.dir(to, { depth = 32 }) do
    if type == "file" and name:sub(-4) == ".php" then
      files[#files + 1] = pair(from .. "/" .. name, to .. "/" .. name)
    end
  end
  return files
end

--- Find the `*Test.php` covering a renamed class.
---
--- A test class is a separate symbol in a separate namespace (`Tests\Unit\…`),
--- so no LSP rename ever touches it — renaming `Foo` only fixes the `use` line
--- and `::class` *inside* `FooTest`, never `FooTest` itself.
---
--- Matched by filename, not by path: mirroring is not reliable in erp-stl-eu,
--- e.g. `module/Integration/CreditBureau/Bridge/Erp/Application/Service/Account/
--- ProcessPasswordChangerConfigs/ErpProcessPasswordChangerConfigsService.php` is
--- covered by `tests/unit/Integration/CreditBureau/Account/
--- ProcessPasswordChangerConfigs/ErpProcessPasswordChangerConfigsServiceTest.php`
--- — four path segments dropped. So the twin is renamed *in place*: it keeps its
--- directory, and therefore its namespace, and only the class name changes.
---@param dir string a directory inside the project, used to locate the root
---@param old string old class name
---@param new string new class name
---@return {from:string, to:string}[]
local function find_twins(dir, old, new)
  -- nothing to do for a pure directory move, and don't chase `FooTestTest`
  if old == new or old == "" or old:sub(-4) == "Test" then
    return {}
  end

  local root = vim.fs.root(dir, ROOT_MARKERS)
  if not root or vim.fn.isdirectory(root .. "/tests") == 0 then
    return {}
  end

  local twins = {}
  for _, hit in ipairs(vim.fs.find(old .. "Test.php", {
    path = root .. "/tests",
    type = "file",
    limit = 10,
  })) do
    twins[#twins + 1] = { from = hit, to = vim.fs.dirname(hit) .. "/" .. new .. "Test.php" }
  end
  return twins
end

--- Move the twins on disk.
---@param twins {from:string, to:string}[]
---@return table[] # `FileRename` for the ones that actually moved
local function move_twins(twins)
  local moved = {}
  for _, twin in ipairs(twins) do
    if Snacks.rename._rename(twin.from, twin.to) then
      moved[#moved + 1] = pair(twin.from, twin.to)
      info("Renamed test " .. vim.fs.basename(twin.from) .. " -> " .. vim.fs.basename(twin.to))
    end
  end
  return moved
end

--- Rename `<old>Test.php` to `<new>Test.php` and fix the class name inside it.
---
--- For `<leader>cn`, where phpactor has already renamed the class and moved its
--- file through the WorkspaceEdit, and only the twin is left over.
---@param old string old class name
---@param new string new class name
---@param dir? string directory to resolve the project root from (default: cwd)
function M.rename_test_twin(old, new, dir)
  local files = move_twins(find_twins(dir or vim.uv.cwd(), old, new))
  if #files == 0 then
    return
  end

  local _, after = partition_clients()
  for _, c in ipairs(after) do
    will_rename(c, files)
  end
  for _, c in ipairs(vim.lsp.get_clients()) do
    if c:supports_method("workspace/didRenameFiles") then
      c:notify("workspace/didRenameFiles", { files = files })
    end
  end
end

--- Drop-in for `Snacks.rename.on_rename_file`.
---@param from string
---@param to string
---@param rename? fun() performs the actual fs move
function M.on_rename_file(from, to, rename)
  local before, after = partition_clients()

  -- What actually happens on disk. Spec-abiding servers see it before the move.
  local moved = { pair(from, to) }
  for _, c in ipairs(before) do
    will_rename(c, moved)
  end

  if rename then
    rename()
  end

  -- Directory moves fan out to one entry per file; see expand().
  local files = expand(from, to)

  if vim.fn.isdirectory(to) == 0 then
    for _, twin in ipairs(move_twins(find_twins(vim.fs.dirname(to), stem(from), stem(to)))) do
      moved[#moved + 1] = twin
      files[#files + 1] = twin
    end
  end

  if #files > 0 then
    for _, c in ipairs(after) do
      will_rename(c, files)
    end
  end

  for _, c in ipairs(vim.lsp.get_clients()) do
    if c:supports_method("workspace/didRenameFiles") then
      c:notify("workspace/didRenameFiles", { files = moved })
    end
  end
end

return M
