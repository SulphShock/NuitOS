-- NuitOS Neovim config
-- Theme: gruvbox dark hard — hardcoded in lua/plugins/colorscheme.lua

-- required before nvim-tree loads
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')
require('config.keymaps')
require('config.autocmds')

require('lazy').setup('plugins', {
  install = { colorscheme = { 'gruvbox' } },
  checker = { enabled = false },
})
