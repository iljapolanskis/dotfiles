return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "light"
      -- contrast "" = medium (#fbf1c7) — same background as Ghostty's Gruvbox Light.
      -- "hard" = #f9f5d7, "soft" = #f2e5bc.
      require("gruvbox").setup({ contrast = "" })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
