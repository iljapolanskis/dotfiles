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
      -- Float, not the default bottom split (snacks/terminal.lua: `position =
      -- cmd and "float" or "bottom"`). A bottom split lands in the same region
      -- as dap-ui's window stack and shoves it around; a float is outside the
      -- window tree, so <c-/> costs zero layout while debugging.
      terminal = {
        -- `border = "solid"` is a 1-cell blank ring drawn in FloatBorder, and
        -- gruvbox gives FloatBorder the same bg as NormalFloat (#ebdbb2), so the
        -- ring reads as padding, not a frame: text no longer butts against the
        -- window edge. Neovim floats only ever have one border ring, so this
        -- trades the rounded line for the gap; the float still separates from the
        -- buffer because its bg differs from Normal (#fbf1c7).
        win = { position = "float", border = "solid" },
      },
      picker = {
        sources = {
          explorer = {
            layout = {
              layout = {
                position = "right",
                width = 80,
              },
            },
            hidden = true,
            ignored = true,
            -- The sidebar is a real split, so it takes its 60 columns off the
            -- debug windows on open and hands them back on close -- both
            -- directions leave dap-ui skewed. Snap it back each way (no-op when
            -- no debug layout is open). Explorer's own source wraps on_close but
            -- chains to ours (snacks/picker/source/explorer.lua).
            on_show = function()
              require("util.dap_layout").reset_soon()
            end,
            on_close = function()
              require("util.dap_layout").reset_soon()
            end,
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
