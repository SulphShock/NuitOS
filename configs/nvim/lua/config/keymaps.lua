local map = vim.keymap.set

map('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
map('n', '<leader>w', '<cmd>w<CR>', { desc = 'Save' })
map('n', '<leader>q', '<cmd>qa<CR>', { desc = 'Quit all' })

-- window navigation
map('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
map('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
map('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
map('n', '<C-l>', '<C-w>l', { desc = 'Window right' })

-- move lines/blocks with Alt+j/k
map('n', '<A-j>', ':m .+1<CR>==', { silent = true, desc = 'Move line down' })
map('n', '<A-k>', ':m .-2<CR>==', { silent = true, desc = 'Move line up' })
map('v', '<A-j>', ":m '>+1<CR>gv=gv", { silent = true, desc = 'Move selection down' })
map('v', '<A-k>', ":m '<-2<CR>gv=gv", { silent = true, desc = 'Move selection up' })
