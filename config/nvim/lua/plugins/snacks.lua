-- Pad every line to equal display width so the dashboard's per-line
-- centering (formats.header align = "center") can't shear the art.
local function pad_lines(art)
  local lines = vim.split(art, "\n")
  local max = 0
  for _, line in ipairs(lines) do
    max = math.max(max, vim.fn.strdisplaywidth(line))
  end
  for i, line in ipairs(lines) do
    lines[i] = line .. string.rep(" ", max - vim.fn.strdisplaywidth(line))
  end
  return table.concat(lines, "\n")
end

local function random_ascii_header()
  local art_dir = vim.fn.stdpath("config") .. "/lua/ascii"
  local files = vim.split(vim.fn.glob(art_dir .. "/*.lua"), "\n", { trimempty = true })
  if #files == 0 then
    return ""
  end
  math.randomseed(os.time())
  local chosen = files[math.random(#files)]
  local fn = loadfile(chosen)
  return fn and pad_lines(fn() or "") or ""
end

return {
  { "akinsho/bufferline.nvim", enabled = false },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>ss", false },
      { "<leader>sS", false },
      -- stylua: ignore
      { "<leader>fs", function() Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP Symbols" },
      -- stylua: ignore
      { "<leader>fS", function() Snacks.picker.lsp_workspace_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP Workspace Symbols" },
    },
    opts = {
      picker = {
        sources = {
          explorer = {
            layout = {
              layout = {
                position = "right",
                width = 60,
              },
            },
            hidden = true,
            ignored = true,
          },
          files = {
            hidden = true, -- show dotfiles in fuzzy finder
            ignored = true, -- show gitignored files
          },
          grep = {
            hidden = true, -- grep dotfiles too
            ignored = true, -- grep gitignored files (e.g. vendor/)
          },
        },
      },
      dashboard = {
        preset = {
          header = random_ascii_header(),
          -- Delete any line to remove that button.
          -- stylua: ignore
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
  },
}
