return {
  'goolord/alpha-nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  event = 'VimEnter',
  config = function()
    local alpha = require('alpha')
    local dashboard = require('alpha.themes.dashboard')

    dashboard.section.header.val = {
      "███████╗██╗   ██╗██╗     ██████╗ ██╗  ██╗    ███████╗██╗  ██╗ ██████╗  ██████╗██╗  ██╗",
      "██╔════╝██║   ██║██║     ██╔══██╗██║  ██║    ██╔════╝██║  ██║██╔═══██╗██╔════╝██║ ██╔╝",
      "███████╗██║   ██║██║     ██████╔╝███████║    ███████╗███████║██║   ██║██║     █████╔╝ ",
      "╚════██║██║   ██║██║     ██╔═══╝ ██╔══██║    ╚════██║██╔══██║██║   ██║██║     ██╔═██╗ ",
      "███████║╚██████╔╝███████╗██║     ██║  ██║    ███████║██║  ██║╚██████╔╝╚██████╗██║  ██╗",
      "╚══════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝    ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝",
    }
    dashboard.section.header.opts.hl = 'AlphaHeader'

    dashboard.section.buttons.val = {
      dashboard.button('e', '  New File', ':ene <BAR> startinsert <CR>'),
      dashboard.button('f', '  Find File', ':Telescope find_files<CR>'),
      dashboard.button('r', '  Recently Used Files', ':Telescope oldfiles<CR>'),
      dashboard.button('t', '  Find Text', ':Telescope live_grep<CR>'),
      dashboard.button('c', '  Configuration', ':e $MYVIMRC<CR>'),
      dashboard.button('q', '  Quit Neovim', ':qa<CR>'),
    }

    local function footer()
      local stats = require('lazy').stats()
      local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
      return '  NuitOS  ·  ' .. stats.count .. ' plugins in ' .. ms .. 'ms  ·  ' .. os.date('%d-%m-%Y %H:%M')
    end
    dashboard.section.footer.val = footer()
    dashboard.section.footer.opts.hl = 'AlphaFooter'

    dashboard.config.layout = {
      { type = 'padding', val = 4 },
      dashboard.section.header,
      { type = 'padding', val = 2 },
      dashboard.section.buttons,
      { type = 'padding', val = 1 },
      dashboard.section.footer,
    }

    alpha.setup(dashboard.config)

    -- gruvbox-matching colors for the dashboard
    vim.api.nvim_set_hl(0, 'AlphaHeader', { fg = '#fe8019', bold = true }) -- gruvbox orange
    vim.api.nvim_set_hl(0, 'AlphaFooter', { fg = '#928374', italic = true }) -- gruvbox gray

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'alpha',
      callback = function()
        vim.opt_local.cursorline = false
        vim.opt_local.foldenable = false
      end,
    })
  end,
}
