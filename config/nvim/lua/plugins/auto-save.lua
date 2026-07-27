return {
  {
    "okuuva/auto-save.nvim",
    version = "^1.0.0",
    cmd = "ASToggle", -- lazy-load on command (used by the keymap)
    event = { "BufLeave", "FocusLost" }, -- lazy-load on the immediate-save triggers
    opts = {
      -- Only save on immediate events (leaving buffer, losing focus, quit, suspend).
      -- No debounced saves while typing / on InsertLeave / TextChanged.
      trigger_events = {
        immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" },
        defer_save = {},
        cancel_deferred_save = {},
      },
      -- enabled = true is the default, so autosave is on at startup
    },
    keys = {
      { "<leader>uv", "<cmd>ASToggle<CR>", desc = "Toggle autosave" },
    },
  },

  -- Statusline component: how long ago the current file was last written to disk.
  -- Reads the file's real mtime, so it is per-buffer and reflects any write
  -- (autosave, manual :w, or an external edit) rather than a global timestamp.
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local function has_file()
        return vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= ""
      end
      local component = {
        function()
          local mtime = vim.fn.getftime(vim.api.nvim_buf_get_name(0))
          if mtime < 0 then
            return "" -- new buffer, not written to disk yet
          end
          -- Whole calendar days between the save and now (midnight-to-midnight).
          local function midnight(t)
            local dt = os.date("*t", t)
            dt.hour, dt.min, dt.sec = 0, 0, 0
            return os.time(dt)
          end
          local days = math.floor((midnight(os.time()) - midnight(mtime)) / 86400)
          if days >= 1 then
            return ("󰆓 saved %d day%s ago"):format(days, days == 1 and "" or "s")
          end
          local d = os.time() - mtime
          if d < 30 then
            return "󰆓 saved just now"
          elseif d < 300 then -- 5 min
            return "󰆓 saved recently"
          elseif d < 1800 then -- 30 min
            return "󰆓 saved a while ago"
          else
            return "󰆓 saved at " .. os.date("%H:%M", mtime)
          end
        end,
        cond = has_file,
        color = "Comment",
      }
      table.insert(opts.sections.lualine_x, 1, component)
    end,
  },
}
