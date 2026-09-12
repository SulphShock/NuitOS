return {
  { 'folke/which-key.nvim', event = 'VeryLazy', opts = {} },
  { 'windwp/nvim-autopairs', event = 'InsertEnter', opts = {} },
  { 'numToStr/Comment.nvim', event = 'VeryLazy', opts = {} },
  { 'lewis6991/gitsigns.nvim', event = 'BufReadPre', opts = {} },
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = { options = { theme = 'gruvbox' } },
  },
}
