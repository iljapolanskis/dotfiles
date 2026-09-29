return {
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>R", "", desc = "+http" },
      { "<leader>Rs", desc = "Send request" },
      { "<leader>Ra", desc = "Send all requests" },
      { "<leader>Rr", desc = "Replay last request" },
      { "<leader>Re", desc = "Select environment" },
      { "<leader>Rf", desc = "Find request" },
      { "<leader>Rb", desc = "Scratchpad" },
    },
    opts = {
      global_keymaps = true,
      global_keymaps_prefix = "<leader>R",
      kulala_keymaps = true,
      default_env = "dev",
      display_mode = "split",
      split_direction = "vertical",
      -- .http files reference *.docker hosts with self-signed certs
      additional_curl_options = { "--insecure" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { "http", "graphql" })
    end,
  },
}
