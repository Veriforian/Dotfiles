return {
  "mfussenegger/nvim-dap",
  recommended = true,
  desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",

  dependencies = {
    "rcarriga/nvim-dap-ui",
    -- virtual text for the debugger
    {
      "theHamsta/nvim-dap-virtual-text",
      opts = {},
    },
  },

  -- stylua: ignore
  keys = {
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
    { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
    { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>dj", function() require("dap").down() end, desc = "Down" },
    { "<leader>dk", function() require("dap").up() end, desc = "Up" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
    { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    { "<leader>ds", function() require("dap").session() end, desc = "Session" },
    { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
  },

  config = function()
    -- load mason-nvim-dap here, after all adapters have been setup
    if LazyVim.has("mason-nvim-dap.nvim") then
      require("mason-nvim-dap").setup(LazyVim.opts("mason-nvim-dap.nvim"))
    end

    -- Highlights
    vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
    for name, sign in pairs(LazyVim.config.icons.dap) do
      sign = type(sign) == "table" and sign or { sign }
      vim.fn.sign_define(
        "Dap" .. name,
        { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
      )
    end

    -- setup dap config by VsCode launch.json file
    local dap = require("dap")
    local vscode = require("dap.ext.vscode")

    -- Hijack nvim-dap-ui listener
    local dapui = require("dapui")
    dap.listeners.after.event_initialized["dapui_config"] = function()
      local session = dap.session()
      if session and session.config.type == "go_tui" then
        return -- Opens ternimal, not dapui
      end

      dapui.open()
    end

    -- Custom Adapters
    local Terminal = require("toggleterm.terminal").Terminal

    -- GO TUI
    dap.adapters.go_tui = function(callback, config)
      local cmd = config.preLaunchTaskCmd or "make debug-server"
      local tui_term = Terminal:new({
        id = 99,
        cmd = cmd,
        direction = "float",
        close_on_exit = true,
        float_opts = {
          border = "curved",
          winblend = 0,
        },
        on_open = function()
          vim.cmd("startinsert!")
        end,
      })

      -- Wait for Go to compile, then yield back to DAP to execute the attach
      -- 5000ms allows 'make debug-server' time to compile and bind the port
      vim.defer_fn(function()
        tui_term:open()
        callback({
          type = "server",
          host = config.host or "127.0.0.1",
          port = config.port or 38697,
        })
      end, 2500)
    end

    vscode.type_to_filetypes = {
      go_tui = { "go" },
    }
  end,
}
