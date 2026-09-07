return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  opts = {
    ensure_installed = { 'lua', 'vim', 'vimdoc', 'bash', 'python', 'javascript', 'json', 'markdown' },
    highlight = { enable = true },
    indent = { enable = true },
  },
}
