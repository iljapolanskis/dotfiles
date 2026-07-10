-- <leader>gp: list open GitHub PRs and `gh pr checkout` the picked one.
-- Replaces the LazyVim snacks_picker defaults (gp = gh_pr open, gP = gh_pr all);
-- gP is disabled, its slot folds back into gp.
-- Data source: `gh pr list --json ...` (structured, like pr-files.lua).

-- author login shown dimmed after the title
local function pick()
  vim.system(
    { "gh", "pr", "list", "--json", "number,title,headRefName,author,isDraft", "--limit", "100" },
    { text = true },
    function(res)
      vim.schedule(function()
        if res.code ~= 0 then
          Snacks.notify.error("gh: " .. (res.stderr ~= "" and res.stderr or "not a repo / not authed"))
          return
        end
        local ok, prs = pcall(vim.json.decode, res.stdout)
        if not ok or #prs == 0 then
          Snacks.notify.warn("No open PRs")
          return
        end

        local items = {}
        for _, pr in ipairs(prs) do
          local draft = pr.isDraft and " [draft]" or ""
          items[#items + 1] = {
            text = ("#%d %s %s"):format(pr.number, pr.title, pr.headRefName), -- searchable
            number = pr.number,
            branch = pr.headRefName,
            title = pr.title,
            author = pr.author and pr.author.login or "?",
            comment = pr.headRefName .. draft,
          }
        end

        Snacks.picker.pick({
          source = "pr_checkout",
          title = "Checkout PR",
          items = items,
          preview = "none", -- items have no `file`; skip file preview
          format = function(item)
            return {
              { ("#%d "):format(item.number), "SnacksPickerGitBranch" },
              { item.title, "SnacksPickerLabel" },
              { "  " .. item.comment, "SnacksPickerComment" },
              { "  @" .. item.author, "SnacksPickerDimmed" },
            }
          end,
          confirm = function(picker, item)
            if not item then
              return
            end
            picker:close()
            Snacks.notify.info(("Checking out PR #%d…"):format(item.number))
            vim.system({ "gh", "pr", "checkout", tostring(item.number) }, { text = true }, function(co)
              vim.schedule(function()
                if co.code ~= 0 then
                  Snacks.notify.error("checkout failed: " .. (co.stderr ~= "" and co.stderr or "unknown"))
                else
                  Snacks.notify.info(("On PR #%d (%s)"):format(item.number, item.branch))
                end
              end)
            end)
          end,
        })
      end)
    end
  )
end

return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>gp", pick, desc = "Checkout PR" },
    { "<leader>gP", false }, -- fold gP into gp
  },
}
