return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  { "arcticicestudio/nord-vim" },
  { "LazyVim/LazyVim", opts = { colorscheme = "onedark" } },
  {
    "navarasu/onedark.nvim",
    config = function()
      require("onedark").setup({
        style = "darker",
        transparent = true,
        floats = "transparent",
        sidebars = "transparent",
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
        highlights = {
          NormalFloat = { bg = "NONE" },
          FloatBorder = { bg = "NONE" },
        },
      })

      local function set_normal_float_highlight()
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = set_normal_float_highlight,
      })
    end,
  },
}
