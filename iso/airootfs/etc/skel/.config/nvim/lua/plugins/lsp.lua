return {
  -- LSP: go-to-definition, hover docs, renames. Only wakes up for servers
  -- you've actually installed -- no server, no nagging. We like it that way.
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    -- Whole file needs nvim 0.11+; older builds just get no LSP.
    if not vim.lsp.config then
      return
    end

    vim.lsp.config('lua_ls', {
      settings = { Lua = { diagnostics = { globals = { 'vim' } } } },
    })
    vim.lsp.config('pyright', {})
    vim.lsp.config('bashls', {})

    -- The ISO ships none of these servers, so only enable what's installed.
    -- Otherwise every file open prints a spawn failure.
    if vim.fn.executable('lua-language-server') == 1 then
      vim.lsp.enable('lua_ls')
    end
    if vim.fn.executable('pyright-langserver') == 1 or vim.fn.executable('pyright') == 1 then
      vim.lsp.enable('pyright')
    end
    if vim.fn.executable('bash-language-server') == 1 then
      vim.lsp.enable('bashls')
    end

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(ev)
        local function opts(desc)
          return { desc = 'LSP: ' .. desc, buffer = ev.buf, silent = true }
        end
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts('Go to definition'))
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts('References'))
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts('Hover'))
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts('Rename'))
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts('Code action'))
        -- vim.diagnostic.jump is the 0.11+ API.
        if vim.diagnostic.jump then
          vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, opts('Prev diagnostic'))
          vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, opts('Next diagnostic'))
        else
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts('Prev diagnostic'))
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts('Next diagnostic'))
        end
      end,
    })
  end,
}
