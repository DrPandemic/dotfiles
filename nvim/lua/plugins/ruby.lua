return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rubocop = {
          enabled = false,
        },
        ruby_lsp = {
          cmd = function(dispatchers, config)
            local cmd = vim.fn.executable("shadowenv") == 1 and { "shadowenv", "exec", "--", "ruby-lsp" }
              or { "ruby-lsp" }
            return vim.lsp.rpc.start(
              cmd,
              dispatchers,
              config and config.root_dir and { cwd = config.cmd_cwd or config.root_dir }
            )
          end,
        },
      },
    },
  },
}
