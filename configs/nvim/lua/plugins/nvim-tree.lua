return {
  'nvim-tree/nvim-tree.lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  keys = {
    -- NOTE: plain 'f' per spec — this disables the f{char} find motion
    { 'f', function() require('nvim-tree.api').tree.toggle() end, desc = 'File tree open/close' },
    { '<leader>e', '<cmd>NvimTreeToggle<CR>', desc = 'File tree (alt)' },
  },
  opts = {
    on_attach = function(bufnr)
      local api = require('nvim-tree.api')
      local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      api.config.mappings.default_on_attach(bufnr) -- keep defaults, then override

      -- arrow key navigation
      vim.keymap.set('n', '<Up>',    api.node.navigate.sibling.previous, opts('Previous item'))
      vim.keymap.set('n', '<Down>',  api.node.navigate.sibling.next,     opts('Next item'))
      vim.keymap.set('n', '<Left>',  api.node.navigate.parent_close,     opts('Close folder'))
      vim.keymap.set('n', '<Right>', api.node.open.edit,                 opts('Open'))

      -- your file operations
      vim.keymap.set('n', 'n',  api.fs.rename,    opts('Rename'))
      vim.keymap.set('n', 'dd', api.fs.remove,    opts('Delete'))
      vim.keymap.set('n', 'r',  api.tree.reload,  opts('Refresh'))
      vim.keymap.set('n', 'a',  api.fs.create,    opts('New file/folder'))
    end,
    view = { width = 30 },
    renderer = { group_empty = true },
  },
}
