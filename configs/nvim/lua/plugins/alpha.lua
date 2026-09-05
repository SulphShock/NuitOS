return {
  "goolord/alpha-nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "nvim-lua/plenary.nvim", -- required by telescope
    "nvim-telescope/telescope.nvim",
  },
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Your custom ASCII Art
    dashboard.section.header.val = {
      "███████╗██╗   ██╗██╗     ██████╗ ██╗  ██╗    ███████╗██╗  ██╗ ██████╗  ██████╗██╗  ██╗",
      "██╔════╝██║   ██║██║     ██╔══██╗██║  ██║    ██╔════╝██║  ██║██╔═══██╗██╔════╝██║ ██╔╝",
      "███████╗██║   ██║██║     ██████╔╝███████║    ███████╗███████║██║   ██║██║     █████╔╝ ",
      "╚════██║██║   ██║██║     ██╔═══╝ ██╔══██║    ╚════██║██╔══██║██║   ██║██║     ██╔═██╗ ",
      "███████║╚██████╔╝███████╗██║     ██║  ██║    ███████║██║  ██║╚██████╔╝╚██████╗██║  ██╗",
      "╚══════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝    ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝",
    }

    -- Set the highlight group for the ASCII art (makes it pop!)
    dashboard.section.header.opts.hl = "AlphaHeader"

    -- Dashboard Menu Buttons
    dashboard.section.buttons.val = {
      dashboard.button("e", "  New File", ":ene <BAR> startinsert <CR>"),
      dashboard.button("f", "󰈞  Find File", ":Telescope find_files<CR>"),
      dashboard.button("r", "󰄉  Recently Used Files", ":Telescope oldfiles<CR>"),
      dashboard.button("t", "󰊄  Find Text", ":Telescope live_grep<CR>"),
      dashboard.button("c", "  Configuration", ":e $MYVIMRC<CR>"),
      dashboard.button("q", "󰅚  Quit Neovim", ":qa<CR>"),
    }

    -- Footer
    local function footer()
      local total_plugins = #vim.tbl_keys(require("lazy").plugins())
      local datetime = os.date(" %d-%m-%Y   %H:%M:%S")
      return "  Neovim Loaded " .. total_plugins .. " plugins  " .. datetime
    end

    dashboard.section.footer.val = footer()
    dashboard.section.footer.opts.hl = "AlphaFooter"

    -- Layout configuration (spacing between elements)
    dashboard.config.layout = {
      { type = "padding", val = 4 },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      { type = "padding", val = 1 },
      dashboard.section.footer,
    }

    -- Setup Alpha
    alpha.setup(dashboard.config)

    -- Autocmd to hide folds and cursorline on the dashboard
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "alpha",
      callback = function()
        vim.opt_local.cursorline = false
        vim.opt_local.foldenable = false
      end,
    })
  end,
}
