-- Black & White Gradient Theme for Neovim
-- Utilizes a 10-step grayscale gradient to create depth.

local M = {}

-- The Gradient Palette (Background to Foreground)
local palette = {
    bg           = '#080808', -- Pure-ish black background
    bg_alt       = '#0e0e0e', -- Slightly lighter for UI panels
    bg_highlight = '#161616', -- Cursorline / Selections
    
    -- The Grayscale Gradient Steps
    gray_1       = '#2a2a2a', -- Fades, borders, non-text
    gray_2       = '#404040', -- Comments (darkest text)
    gray_3       = '#595959', -- Punctuation, operators
    gray_4       = '#7a7a7a', -- Variables, identifiers
    gray_5       = '#9a9a9a', -- Functions
    gray_6       = '#bababa', -- Types, classes
    gray_7       = '#dadada', -- Constants, numbers
    white        = '#ffffff', -- Keywords, strings (highest contrast)
}

function M.setup()
    vim.cmd('hi clear')
    if vim.fn.exists('syntax_on') then
        vim.cmd('syntax reset')
    end
    vim.g.colors_name = 'bw-gradient'

    local hi = function(group, opts)
        opts = opts or {}
        vim.api.nvim_set_hl(0, group, {
            fg = opts.fg,
            bg = opts.bg,
            sp = opts.sp,
            bold = opts.bold,
            italic = opts.italic,
            underline = opts.underline,
            undercurl = opts.undercurl,
            reverse = opts.reverse,
        })
    end

    -- Base UI Elements
    hi('Normal', { fg = palette.gray_6, bg = palette.bg })
    hi('NormalNC', { fg = palette.gray_6, bg = palette.bg_alt })
    hi('Cursor', { fg = palette.bg, bg = palette.white })
    hi('CursorLine', { bg = palette.bg_highlight })
    hi('CursorColumn', { bg = palette.bg_highlight })
    hi('LineNr', { fg = palette.gray_2 })
    hi('CursorLineNr', { fg = palette.gray_6, bold = true })
    hi('SignColumn', { bg = palette.bg })
    hi('VertSplit', { fg = palette.gray_1, bg = palette.bg })
    hi('MatchParen', { bg = palette.gray_3, bold = true })
    hi('StatusLine', { fg = palette.gray_7, bg = palette.bg_highlight })
    hi('StatusLineNC', { fg = palette.gray_3, bg = palette.bg_alt })
    hi('Pmenu', { fg = palette.gray_6, bg = palette.bg_alt })
    hi('PmenuSel', { fg = palette.bg, bg = palette.gray_6 })
    hi('PmenuSbar', { bg = palette.bg_alt })
    hi('PmenuThumb', { bg = palette.gray_3 })
    hi('Search', { fg = palette.bg, bg = palette.gray_5 })
    hi('IncSearch', { fg = palette.bg, bg = palette.white, bold = true })
    hi('Visual', { bg = palette.gray_3 })
    hi('NonText', { fg = palette.gray_1 })
    hi('Whitespace', { fg = palette.gray_1 })
    hi('Folded', { fg = palette.gray_4, bg = palette.bg_alt })
    hi('Title', { fg = palette.white, bold = true })
    hi('Directory', { fg = palette.gray_6 })

    -- Syntax (Gradient Mapping)
    -- Darkest (Gray 2) to Brightest (White) based on syntax importance
    hi('Comment', { fg = palette.gray_2, italic = true })
    hi('Conceal', { fg = palette.gray_3 })
    hi('Constant', { fg = palette.gray_7 })
    hi('String', { fg = palette.white }) -- Brightest to make strings pop
    hi('Character', { fg = palette.white })
    hi('Boolean', { fg = palette.gray_7, bold = true })
    hi('Number', { fg = palette.gray_7 })
    hi('Float', { fg = palette.gray_7 })
    
    hi('Identifier', { fg = palette.gray_4 })
    hi('Function', { fg = palette.gray_5 })
    
    hi('Statement', { fg = palette.white, bold = true }) -- Keywords
    hi('Conditional', { fg = palette.white, bold = true })
    hi('Repeat', { fg = palette.white, bold = true })
    hi('Label', { fg = palette.white, bold = true })
    hi('Operator', { fg = palette.gray_3 })
    hi('Keyword', { fg = palette.white, bold = true })
    hi('Exception', { fg = palette.white, bold = true })
    
    hi('PreProc', { fg = palette.gray_6 })
    hi('Include', { fg = palette.gray_6 })
    hi('Define', { fg = palette.gray_6 })
    hi('Macro', { fg = palette.gray_6 })
    
    hi('Type', { fg = palette.gray_6 })
    hi('StorageClass', { fg = palette.gray_6 })
    hi('Structure', { fg = palette.gray_6 })
    hi('Typedef', { fg = palette.gray_6 })
    
    hi('Special', { fg = palette.gray_5, italic = true })
    hi('SpecialChar', { fg = palette.gray_6 })
    hi('Tag', { fg = palette.white, bold = true })
    hi('Delimiter', { fg = palette.gray_3 })
    hi('SpecialComment', { fg = palette.gray_4, italic = true })
    hi('Debug', { fg = palette.gray_5 })
    
    hi('Underlined', { fg = palette.gray_5, underline = true })
    hi('Error', { fg = palette.white, bg = palette.gray_2, undercurl = true })
    hi('Todo', { fg = palette.bg, bg = palette.gray_6, bold = true })

    -- Treesitter (Modern Neovim syntax)
    hi('@comment', { fg = palette.gray_2, italic = true })
    hi('@keyword', { fg = palette.white, bold = true })
    hi('@function', { fg = palette.gray_5 })
    hi('@string', { fg = palette.white })
    hi('@variable', { fg = palette.gray_4 })
    hi('@constant', { fg = palette.gray_7 })
    hi('@type', { fg = palette.gray_6 })
    hi('@operator', { fg = palette.gray_3 })
    hi('@punctuation', { fg = palette.gray_3 })
    hi('@number', { fg = palette.gray_7 })

    -- LSP Diagnostics (Kept grayscale, using styles to differentiate)
    hi('DiagnosticError', { fg = palette.white, bold = true })
    hi('DiagnosticWarn', { fg = palette.gray_7, bold = true })
    hi('DiagnosticInfo', { fg = palette.gray_5, italic = true })
    hi('DiagnosticHint', { fg = palette.gray_4, italic = true })
    hi('DiagnosticUnderlineError', { sp = palette.white, undercurl = true })
    hi('DiagnosticUnderlineWarn', { sp = palette.gray_7, undercurl = true })
    hi('DiagnosticUnderlineInfo', { sp = palette.gray_5, undercurl = true })
    hi('DiagnosticUnderlineHint', { sp = palette.gray_4, undercurl = true })

    -- Git Signs (Standard plugin)
    hi('GitSignsAdd', { fg = palette.gray_4 })
    hi('GitSignsChange', { fg = palette.gray_6 })
    hi('GitSignsDelete', { fg = palette.white })
end

-- Run the setup
M.setup()

return M
