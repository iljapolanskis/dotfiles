return {
  "mfussenegger/nvim-dap",
  optional = true,
  -- `opts` (not `config`) so LazyVim's dap.core config still runs; adapter `php`
  -- is auto-registered by mason-nvim-dap, only the docker path mapping is missing.
  opts = function(_, opts)
    require("dap").configurations.php = {
      {
        type = "php",
        request = "launch", -- vscode-php-debug: "launch" = listen for incoming xdebug
        name = "Listen for Xdebug (docker)",
        port = 9003,
        pathMappings = {
          ["/app"] = "${workspaceFolder}", -- container root -> local project root
        },
      },
    }
    return opts
  end,
}
