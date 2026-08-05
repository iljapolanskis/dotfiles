-- Folder-tiered picker finders for snacks (files + grep).
--
-- Each finder runs one ripgrep pass PER TIER, chained into a single live
-- picker finder, so results paint in tier order:
--   1. module/ + config/
--   2. vendor/
--   3. everything else
--
-- Each tier's pass includes its own dirs and negates every earlier tier's
-- dirs, so a path like vendor/x/module/y is emitted once (in tier 1) and not
-- again in tier 2.
--
-- Ordering vs scoring:
--   - snacks' matcher defaults to `sort_empty = false`, so with an empty
--     prompt the list is literally the finder's emit order — pass order alone
--     puts module/ on the first screen.
--   - once you type, the matcher sorts by score. `mul` below is applied as
--     `score_mul` (matcher does `score = score * score_mul`). It's 1 for every
--     tier right now, i.e. a no-op knob: drop a tier's mul below 1 to sink it
--     while typing. Use a multiplier, not a negative offset — the matcher
--     drops items whose final score is <= 0, so an offset can make a tier
--     vanish instead of sink.
local M = {}

-- Tier order = emit order. Edit to taste; anything not listed lands in the
-- implicit final tier.
M.TIERS = {
  { dirs = { "module", "config" }, mul = 1 },
  { dirs = { "vendor" }, mul = 1 },
}
M.REST_MUL = 1

-- Never searched, in any tier. Matched anywhere in the tree, so this kills
-- module/foo/build/ too, not just a top-level build/.
M.EXCLUDE_DIRS = { "build" }

-- rg glob matching a dir name anywhere in the tree (e.g. "**/module/**").
local function glob(dir, negate)
  return (negate and "!" or "") .. "**/" .. dir .. "/**"
end

-- Globs for tier `i`: include its own dirs, negate all earlier tiers' dirs
-- plus the always-excluded ones. For the implicit final tier (i > #TIERS),
-- every listed dir is negated, leaving "everything else".
---@return string[]
local function tier_globs(i)
  local out = {}
  for _, dir in ipairs(M.TIERS[i] and M.TIERS[i].dirs or {}) do
    out[#out + 1] = glob(dir)
  end
  for t = 1, i - 1 do
    for _, dir in ipairs(M.TIERS[t].dirs) do
      out[#out + 1] = glob(dir, true)
    end
  end
  for _, dir in ipairs(M.EXCLUDE_DIRS) do
    out[#out + 1] = glob(dir, true)
  end
  return out
end

-- Chain one pass per tier, tagging each tier's items with its multiplier.
---@param pass fun(globs: string[]): fun(cb: fun(item: snacks.picker.finder.Item))
local function chain(pass)
  local searches = {} ---@type {search: fun(cb: fun(item: snacks.picker.finder.Item)), mul: number}[]
  for i = 1, #M.TIERS + 1 do
    searches[i] = { search = pass(tier_globs(i)), mul = M.TIERS[i] and M.TIERS[i].mul or M.REST_MUL }
  end
  ---@async
  return function(cb)
    for _, tier in ipairs(searches) do
      tier.search(function(item)
        item.score_mul = (item.score_mul or 1) * tier.mul
        cb(item)
      end)
    end
  end
end

---@param opts snacks.picker.grep.Config
---@param ctx snacks.picker.finder.ctx
function M.grep_finder(opts, ctx)
  local grep = require("snacks.picker.source.grep")
  return chain(function(globs)
    -- Assign after the merge: tbl_deep_extend merges list-likes index-wise,
    -- which would leave stale entries from a longer configured glob list.
    local pass_opts = vim.tbl_deep_extend("force", {}, opts)
    pass_opts.glob = globs
    return grep.grep(pass_opts, ctx)
  end)
end

---@param opts snacks.picker.files.Config
---@param ctx snacks.picker.finder.ctx
function M.files_finder(opts, ctx)
  local files = require("snacks.picker.source.files")
  return chain(function(globs)
    -- The files source only renders `opts.exclude` into globs, so positive
    -- includes have to go through `opts.args`. Only rg takes repeated -g
    -- globs (fd takes a single positional pattern), hence cmd = "rg".
    local args = vim.deepcopy(opts.args or {})
    for _, g in ipairs(globs) do
      vim.list_extend(args, { "-g", g })
    end
    local pass_opts = vim.tbl_deep_extend("force", {}, opts, { cmd = "rg" })
    pass_opts.args = args
    return files.files(pass_opts, ctx)
  end)
end

return M
