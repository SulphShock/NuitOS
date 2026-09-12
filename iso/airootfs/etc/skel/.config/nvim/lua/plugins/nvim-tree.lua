return {
  -- The file tree: where Super+F takes you. Arrows to wander,
  -- f to bail out, n/a/dd/r for the usual file mischief.
  'nvim-tree/nvim-tree.lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  cmd = { 'NvimTreeToggle', 'NvimTreeOpen', 'NvimTreeClose', 'NvimTreeFocus', 'NvimTreeFindFile', 'NvimTreeFindFileToggle' },
  keys = {
    { '<leader>f', '<cmd>NvimTreeToggle<CR>', desc = 'Toggle file tree' },
    { '<D-f>', '<cmd>NvimTreeToggle<CR>', desc = 'Files (Super+F)' },
    { '<M-f>', '<cmd>NvimTreeToggle<CR>', desc = 'Files (Alt+F fallback)' },
  },
  opts = {
    on_attach = function(bufnr)
      local api = require('nvim-tree.api')
      local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- Defaults first, ours on top.
      api.config.mappings.default_on_attach(bufnr)

      vim.keymap.set('n', '<Up>', 'k', opts('Cursor up'))
      vim.keymap.set('n', '<Down>', 'j', opts('Cursor down'))
      vim.keymap.set('n', '<Left>', api.node.navigate.parent_close, opts('Close parent'))
      vim.keymap.set('n', '<Right>', api.node.open.edit, opts('Open'))
      vim.keymap.set('n', 'f', api.tree.close, opts('Close tree'))
      vim.keymap.set('n', 'n', api.fs.rename, opts('Rename'))
      vim.keymap.set('n', 'dd', api.fs.remove, opts('Delete'))
      vim.keymap.set('n', 'r', api.tree.reload, opts('Refresh'))
      vim.keymap.set('n', 'a', api.fs.create, opts('New file'))
    end,
    view = { width = 30 },
    renderer = {
      group_empty = true,
      icons = { show = { file = true, folder = true, folder_arrow = true, git = true } },
    },
  },
}
