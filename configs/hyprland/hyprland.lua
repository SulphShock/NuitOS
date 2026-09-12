local mainMod = "SUPER"

-- Load keybindings
require("bindings")

-- Gaps: slim margin around windows at the screen edge
hl.config({
  general = {
    gaps_out = 4,
  },
  decoration = {
    rounding = 5,
  },
})
