-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic sane defaults
vim.g.mapleader = ' '
vim.opt.number = true
vim.opt.termguicolors = true

-- Load every plugin spec in lua/plugins/*.lua
require('lazy').setup('plugins')

-- Theme is managed by Omarchy via LazyVim plugin specs in each theme's neovim.lua
