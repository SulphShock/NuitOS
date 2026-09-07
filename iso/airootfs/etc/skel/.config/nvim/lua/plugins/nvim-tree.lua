return {
  'nvim-tree/nvim-tree.lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  keys = {
    { '<leader>f', '<cmd>NvimTreeToggle<CR>', desc = 'Toggle file tree' },
  },
  opts = {
    on_attach = function(bufnr)
      local api = require('nvim-tree.api')
      local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      api.config.mappings.default_on_attach(bufnr) -- keep all defaults, including r

      vim.keymap.set('n', 'w', function() vim.cmd('normal! k') end, opts('Up'))
      vim.keymap.set('n', 's', function() vim.cmd('normal! j') end, opts('Down'))
      vim.keymap.set('n', 'd', api.node.open.edit, opts('Open/Edit'))
      vim.keymap.set('n', 'a', api.node.navigate.parent_close, opts('Close/Parent'))
      vim.keymap.set('n', 'e', api.fs.rename, opts('Rename'))
    end,
    view = { width = 30 },
    renderer = { group_empty = true },
  },
}
