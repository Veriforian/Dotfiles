return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    explorer = {
      follow = false,
      hidden = true,
      ignored = true,
      exclude = { ".git", "coverage" },
    },
    picker = {
      hidden = true,
      ignored = true,
      exclude = { ".git", "coverage" },
    },
    terminal = {
      winbar = {
        enabled = false,
      },
    },
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true,
        float = true,
        render_all = true,
      },
    },
  },
}
