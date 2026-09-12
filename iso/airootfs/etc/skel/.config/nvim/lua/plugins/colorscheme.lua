return {
  'morhetz/gruvbox',
  lazy = false,
  priority = 1000,
  config = function()
    vim.o.background = 'dark'
    vim.g.gruvbox_contrast_dark = 'hard' -- hardcoded: gruvbox dark hard
    vim.cmd.colorscheme('gruvbox')
  end,
}
