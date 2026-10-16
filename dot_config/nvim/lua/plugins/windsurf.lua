return {
  "Exafunction/windsurf.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
  },
  enabled = false,
  config = function()
    require("codeium").setup({
      enable_cmp_source = false,
      virtual_text = {
        enabled = true,
        -- These are the defaults
        manual = false,
        filetypes = {},
        default_filetype_enabled = true,
        idle_delay = 75,
        virtual_text_priority = 65535,
        map_keys = true,
        accept_fallback = nil,
        key_bindings = {
          accept = "<C-k>",
          accept_word = "<C-l>",
          accept_line = "<C-;>",
          clear = "<C-j>",
          next = "<M-]>",
          prev = "<M-[>",
          complete = "<C-i>",
        },
      },
    })
  end,
}
