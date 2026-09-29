-- Manual escape hatch for a skewed debug layout. Same code path <leader>e runs
-- automatically (lua/util/dap_layout.lua) -- kept for splits that have no hook,
-- e.g. a bare :split or :vsplit.
return {
  "rcarriga/nvim-dap-ui",
  optional = true,
  -- stylua: ignore
  keys = {
    { "<leader>dR", function() require("util.dap_layout").reset() end, desc = "Dap UI (reset layout)" },
  },
}
