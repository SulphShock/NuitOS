return {
  -- The look: morhetz gruvbox, dark and hard. Like the rest of NuitOS.
  'morhetz/gruvbox',
  lazy = false,
  priority = 1000,
  config = function()
    vim.o.background = 'dark'
    vim.g.gruvbox_contrast_dark = 'hard'
    vim.g.gruvbox_invert_selection = 0
    -- Loud failure: a silent pcall leaves default colors and a mystery.
    local ok, err = pcall(vim.cmd, 'colorscheme gruvbox')
    if not ok then
      vim.schedule(function()
        vim.notify('gruvbox colorscheme failed: ' .. tostring(err), vim.log.levels.ERROR)
      end)
    end
  end,
}
