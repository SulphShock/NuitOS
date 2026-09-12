return {
  -- Treesitter: pretty colors for code. Parsers install on demand with
  -- :TSInstallNuit -- go grab a drink while it compiles, you've earned it.
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    local langs = { 'lua', 'vim', 'vimdoc', 'bash', 'python', 'javascript', 'json', 'markdown' }

    -- Parsers install only on demand: auto-install shells out to the
    -- tree-sitter CLI and spams ENOENT on machines without it.
    vim.api.nvim_create_user_command('TSInstallNuit', function()
      vim.notify('Installing treesitter parsers (needs tree-sitter-cli + a C compiler)...', vim.log.levels.INFO)
      require('nvim-treesitter').install(langs)
    end, {})

    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        -- Missing parsers just mean no highlighting, not an error.
        pcall(vim.treesitter.start)
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
