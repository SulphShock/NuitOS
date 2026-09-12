return {
  { 'williamboman/mason.nvim', build = ':MasonUpdate', opts = {} },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    opts = { ensure_installed = { 'lua_ls', 'pyright', 'bashls' } },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'williamboman/mason-lspconfig.nvim' },
    config = function()
      vim.diagnostic.config({ virtual_text = true, signs = true, underline = true })

      vim.lsp.config('lua_ls', {
        settings = { Lua = { diagnostics = { globals = { 'vim' } } } },
      })
      vim.lsp.enable({ 'lua_ls', 'pyright', 'bashls' })

      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP keybinds',
        callback = function(args)
          local map = function(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = 'LSP: ' .. desc })
          end
          map('gd', vim.lsp.buf.definition, 'Definition')
          map('gD', vim.lsp.buf.declaration, 'Declaration')
          map('K', vim.lsp.buf.hover, 'Hover docs')
          map('gr', vim.lsp.buf.references, 'References')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
          map('<leader>fm', function() vim.lsp.buf.format({ async = true }) end, 'Format')
        end,
      })
    end,
  },
  {
    'saghen/blink.cmp',
    version = '*',
    opts = {},
  },
}
