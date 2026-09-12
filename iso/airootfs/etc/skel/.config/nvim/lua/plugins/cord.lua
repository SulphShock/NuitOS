return {
  -- Discord presence, minecraft flavor. Lets everyone know you're in the mines.
  'vyfor/cord.nvim',
  event = 'VeryLazy',
  -- No build step: ':Cord update' needs network and fails on offline first
  -- boot. Run it once manually when online; lazy runs setup(opts) itself.
  opts = {
    display = {
      theme = 'minecraft',
      flavor = 'dark',
    },
  },
}
