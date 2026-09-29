-- Render the dbout result row under the cursor as a vertical name/value list.
--
-- dadbod-ui's own toggle (db_ui#dbout#toggle_layout, bound to `x` in
-- plugins/dadbod.lua) re-runs the query with psql's `\x` flag, which expands
-- *every* row in the result. This does one row, by parsing the aligned text
-- already on screen — no second query, so it works for joins, aggregates and
-- CTEs where there is no key to re-select by, and costs nothing.
local M = {}

-- A postgres/sqlserver rule (`---+---+---`) or a mysql one (`+---+---+`).
local RULE = "^[-+]+$"

-- Split a line into display columns at `bounds` (1-indexed display columns of
-- the rule's `+` characters). Uses `\zs` to split on character boundaries and
-- strdisplaywidth per character, so multibyte values stay aligned with the rule
-- drawn beneath the ASCII header.
local function slice(line, bounds)
  local out, cell, col, next_bound = {}, {}, 1, 1
  for _, ch in ipairs(vim.fn.split(line, "\\zs")) do
    if next_bound <= #bounds and col >= bounds[next_bound] then
      table.insert(out, table.concat(cell))
      cell, next_bound = {}, next_bound + 1
    else
      table.insert(cell, ch)
    end
    col = col + vim.fn.strdisplaywidth(ch)
  end
  table.insert(out, table.concat(cell))
  return out
end

-- Walk up from `lnum` to the nearest rule; the header is the line above it.
local function find_header(lnum)
  for l = lnum - 1, math.max(lnum - 5000, 1), -1 do
    local line = vim.fn.getline(l)
    if line:match(RULE) then
      return l - 1, line
    end
  end
end

function M.expand()
  if vim.bo.filetype ~= "dbout" then
    return vim.notify("Not a query result buffer", vim.log.levels.WARN)
  end

  local lnum = vim.fn.line(".")
  local row = vim.fn.getline(lnum)
  if row:match(RULE) or row:match("^%s*$") or row:match("^%(%d+ rows?%)$") then
    return vim.notify("Put the cursor on a data row", vim.log.levels.WARN)
  end

  local header_lnum, rule = find_header(lnum)
  if not header_lnum then
    return vim.notify("No column header found above the cursor", vim.log.levels.WARN)
  end

  local bounds, col = {}, 1
  for _, ch in ipairs(vim.fn.split(rule, "\\zs")) do
    if ch == "+" then
      table.insert(bounds, col)
    end
    col = col + vim.fn.strdisplaywidth(ch)
  end

  local names = slice(vim.fn.getline(header_lnum), bounds)
  local values = slice(row, bounds)

  local lines, name_lines, width = {}, {}, 0
  for i, name in ipairs(names) do
    -- A leading `+` (mysql) yields an empty first cell; drop those.
    name = vim.trim(name):gsub("^|", "")
    name = vim.trim(name)
    if name ~= "" then
      local value = vim.trim((values[i] or ""):gsub("^|", ""))
      if #lines > 0 then
        table.insert(lines, "")
      end
      table.insert(lines, name)
      name_lines[#lines - 1] = true -- 0-indexed, for the extmark below
      table.insert(lines, value == "" and "∅" or value)
      width = math.max(width, vim.fn.strdisplaywidth(name), vim.fn.strdisplaywidth(value))
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local ns = vim.api.nvim_create_namespace("dbout_row")
  for l in pairs(name_lines) do
    vim.api.nvim_buf_set_extmark(buf, ns, l, 0, { end_col = #lines[l + 1], hl_group = "Title" })
  end
  vim.bo[buf].modifiable = false

  local max_w = math.floor(vim.o.columns * 0.8)
  local win_w = math.min(math.max(width, 30), max_w)
  -- Wrapped values push the real height past #lines.
  local height = 0
  for _, l in ipairs(lines) do
    height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(l) / win_w))
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_w,
    height = math.min(height, math.floor(vim.o.lines * 0.8)),
    row = math.floor((vim.o.lines - math.min(height, vim.o.lines * 0.8)) / 2),
    col = math.floor((vim.o.columns - win_w) / 2),
    style = "minimal",
    border = "rounded",
    title = " row " .. lnum - header_lnum - 1 .. " ",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, nowait = true })
  end
end

return M
