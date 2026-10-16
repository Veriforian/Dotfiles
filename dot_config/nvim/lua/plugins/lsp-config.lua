return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.servers = opts.servers or {}
    opts.servers["*"] = opts.servers["*"] or {}
    opts.servers["*"].keys = opts.servers["*"].keys or {}
    vim.list_extend(opts.servers["*"].keys, {
      {
        "<leader>ad",
        "<cmd>FzfLua lsp_definitions     jump1=true ignore_current_line=true<cr>",
        desc = "Goto Definition",
        has = "definition",
      },
      {
        "<leader>ar",
        "<cmd>FzfLua lsp_references      jump1=true ignore_current_line=true<cr>",
        desc = "References",
        nowait = true,
      },
      {
        "<leader>aI",
        "<cmd>FzfLua lsp_implementations jump1=true ignore_current_line=true<cr>",
        desc = "Goto Implementation",
      },
      {
        "<leader>ay",
        "<cmd>FzfLua lsp_typedefs        jump1=true ignore_current_line=true<cr>",
        desc = "Goto T[y]pe Definition",
      },
    })

    local gopls = type(opts.servers.gopls) == "table" and opts.servers.gopls or {}
    opts.servers.gopls = vim.tbl_deep_extend("force", gopls, {
      settings = {
        gopls = {
          analyses = {
            ["local"] = "gitlab.com/trazi-ventures/white-label/services/standards",
            unusedparams = true,
          },
          staticcheck = true,
          completeUnimported = true,
          usePlaceholders = true,
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
        },
      },
    })

    opts.lsp = { signature = { auto_open = { enabled = false } } }
  end,
}
-- return {
--   "neovim/nvim-lspconfig",
--   opts = function(_, opts)
--     opts.servers = {
--       ["*"] = {
--         keys = {
--           {
--             "<leader>ad",
--             "<cmd>FzfLua lsp_definitions     jump1=true ignore_current_line=true<cr>",
--             desc = "Goto Definition",
--             has = "definition",
--           },
--           {
--             "<leader>ar",
--             "<cmd>FzfLua lsp_references      jump1=true ignore_current_line=true<cr>",
--             desc = "References",
--             nowait = true,
--           },
--           {
--             "<leader>aI",
--             "<cmd>FzfLua lsp_implementations jump1=true ignore_current_line=true<cr>",
--             desc = "Goto Implementation",
--           },
--           {
--             "<leader>ay",
--             "<cmd>FzfLua lsp_typedefs        jump1=true ignore_current_line=true<cr>",
--             desc = "Goto T[y]pe Definition",
--           },
--         },
--       },
--       gopls = {
--         settings = {
--           gopls = {
--             ["local"] = "gitlab.com/trazi-ventures/white-label/services/standards",
--             analyses = {
--               unusedparams = true,
--             },
--             staticcheck = true,
--             completeUnimported = true,
--             usePlaceholders = true,
--             hints = {
--               assignVariableTypes = true,
--               compositeLiteralFields = true,
--               compositeLiteralTypes = true,
--               constantValues = true,
--               functionTypeParameters = true,
--               parameterNames = true,
--               rangeVariableTypes = true,
--             },
--           },
--         },
--       },
--     }
--     opts.lsp = {
--       signature = { auto_open = {
--         enabled = false,
--       } },
--     }
--   end,
-- }
