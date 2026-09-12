-- NuitOS nvim -- gruvbox hard, Super+F files, zero drama.
-- Poke around, break things, it's all fixable. That's what backups are for.
-- Bootstrap lazy.nvim
local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not uv.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' '
vim.o.background = 'dark'
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.signcolumn = 'yes'
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.pumheight = 10
vim.opt.showmode = false
vim.opt.laststatus = 3
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

-- No clipboard in headless/ssh; leave it alone there.
if vim.fn.has('clipboard') == 1 or os.getenv('WAYLAND_DISPLAY') or os.getenv('DISPLAY') then
  vim.opt.clipboard:append('unnamedplus')
end

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true, desc = 'Clear search highlight' })

-- Super+F opens files. Hyprland only takes Super+Shift+F and Ghostty passes
-- the rest through, but if Super ever stops arriving, Space+f does the same.
vim.keymap.set({ 'n', 'v', 'i', 't' }, '<D-f>', '<cmd>NvimTreeToggle<CR>', { desc = 'Files' })
vim.keymap.set('n', '<M-f>', '<cmd>NvimTreeToggle<CR>', { desc = 'Files' })
vim.keymap.set('n', '<leader>f', '<cmd>NvimTreeToggle<CR>', { desc = 'Files' })

require('lazy').setup('plugins')
