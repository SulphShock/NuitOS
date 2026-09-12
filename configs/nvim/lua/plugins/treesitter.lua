return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').setup({
      install_dir = vim.fn.stdpath('data') .. '/site',
    })
    local langs = {
      'lua', 'vim', 'vimdoc', 'bash', 'python',
      'javascript', 'json', 'markdown', 'markdown_inline',
    }
    require('nvim-treesitter').install(langs)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = langs,
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}
