-- Override for lazyvim.plugins.extras.lang.sql (vim-dadbod-ui).
--
-- Everything is set at module-body level, not in an `init` function: lazy.nvim
-- overrides function fields like `init`/`config` instead of merging them, so an
-- `init` here would silently drop everything the extra's own init sets
-- (db_ui_save_location, use_nerd_fonts, execute_on_save, ...).

-- Pin the `public` schema. dadbod-ui has no pin option: schema order comes from
-- the adapter's schemes_query and the `expanded` flags are in-memory only, so
-- they reset every session. Emulate it on the `DBUIOpened` hook by expanding the
-- connection, sorting public to the front of the schema list, and opening it.
--
-- Cost: this connects to every configured DB when the drawer opens, instead of
-- lazily on first expand. Fine for one local connection; drop the `expanded`
-- lines and keep only the sort if a slow remote connection is ever added.
local PINNED_SCHEMA = "public"

vim.api.nvim_create_autocmd("User", {
  pattern = "DBUIOpened",
  desc = "Pin the " .. PINNED_SCHEMA .. " schema to the top of the dbui drawer, expanded",
  callback = function()
    vim.cmd(([[
      let s:drawer = db_ui#drawer#get()
      for s:db in values(s:drawer.dbui.dbs)
        if !s:db.schema_support | continue | endif
        let s:db.expanded = 1
        call s:drawer.toggle_db(s:db)
        let s:db.schemas.expanded = 1
        if index(s:db.schemas.list, '%s') > -1
          call filter(s:db.schemas.list, {_, v -> v !=# '%s'})
          call insert(s:db.schemas.list, '%s')
          let s:db.schemas.items['%s'].expanded = 1
        endif
      endfor
      call s:drawer.render()
    ]]):format(PINNED_SCHEMA, PINNED_SCHEMA, PINNED_SCHEMA, PINNED_SCHEMA))
  end,
})

-- Hide noise schemas. Vim regexes, matched with unanchored match(), so `^pg_`
-- covers pg_catalog/pg_toast/pg_temp_*.
vim.g.db_ui_hide_schemas = { [[^pg_]], [[^information_schema$]] }

-- Own the result-buffer mappings. dadbod-ui binds `<leader>R` (toggle layout)
-- buffer-local with <nowait>, which shadows the `<leader>R` http prefix from
-- http.lua inside every result buffer -- <nowait> means `<leader>Rs` and friends
-- never get the chance to resolve. Its hasmapto() guard doesn't help: it only
-- checks whether that <Plug> is already mapped, not the key.
--
-- So disable its dbout keys and rebind them here without a leader. The <Plug>
-- mappings and the `ic` text object are defined above that guard in
-- ftplugin/dbout.vim, so all of the functionality survives.
vim.g.db_ui_disable_mappings_dbout = 1

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  desc = "Result buffer mappings",
  callback = function(ev)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, nowait = true, desc = desc })
    end

    -- Expand just the row under the cursor, by parsing the aligned text already
    -- in the buffer -- no second query. See util/dbout_row.lua.
    map("<CR>", function()
      require("util.dbout_row").expand()
    end, "Expand row under cursor")

    -- dadbod-ui's own toggle: re-runs the query with psql's `\x`, expanding
    -- every row in the result.
    map("x", "<Plug>(DBUI_ToggleResultLayout)", "Toggle expanded layout (all rows)")

    -- Carried over from ftplugin/dbout.vim, unchanged.
    map("<C-]>", "<Plug>(DBUI_JumpToForeignKey)", "Jump to foreign table")
    map("yh", "<Plug>(DBUI_YankHeader)", "Yank column headers")
    vim.keymap.set("n", "vic", "<Plug>(DBUI_YankCellValue)", { buffer = ev.buf, nowait = true })
  end,
})

return {}
