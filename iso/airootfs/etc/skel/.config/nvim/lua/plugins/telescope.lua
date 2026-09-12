return {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'Telescope',
  keys = {
    { '<leader>ff', '<cmd>Telescope find_files<CR>', desc = 'Find files' },
    { '<leader>fg', '<cmd>Telescope live_grep<CR>', desc = 'Grep text' },
    { '<leader>fb', '<cmd>Telescope buffers<CR>', desc = 'Buffers' },
    { '<leader>fr', '<cmd>Telescope oldfiles<CR>', desc = 'Recent files' },
    { '<leader>fh', '<cmd>Telescope help_tags<CR>', desc = 'Help tags' },
  },
  opts = {},
}
