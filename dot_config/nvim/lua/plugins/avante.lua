return {
  "yetone/avante.nvim",
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- ⚠️ must add this setting! ! !
  build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    or "make",
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!
  enabled = false,
  ---@module 'avante'
  ---@type avante.Config
  opts = {
    instructions_file = "avante.md",
    provider = "claude",
    providers = {
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-sonnet-4-20250514",
        timeout = 30000, -- Timeout in milliseconds
        auth_type = "api",
        extra_request_body = {
          temperature = 0.75,
          max_tokens = 20480,
        },
      },
      vendors = {
        deepseek = {
          __inherited_from = "openai",
          api_key_name = "DEEPSEEK_API_KEY",
          endpoint = "https://api.deepseek.com",
          model = "deepseek-coder", -- Use V3/Coder for speed
        },
      },
      ---@type AvanteSupportedProvider
      gemini = {
        endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
        model = "gemini-2.0-flash",
        timeout = 30000, -- Timeout in milliseconds
        context_window = 1048576,
        use_ReAct_prompt = true,
        extra_request_body = {
          generationConfig = {
            temperature = 0.75,
          },
        },
      },
      ---@type AvanteSupportedProvider
      copilot = {
        endpoint = "https://api.githubcopilot.com",
        model = "gpt-4o-2024-11-20",
        proxy = nil, -- [protocol://]host[:port] Use this proxy
        allow_insecure = false, -- Allow insecure server connections
        timeout = 30000, -- Timeout in milliseconds
        context_window = 64000, -- Number of tokens to send to the model for context
        use_response_api = copilot_use_response_api, -- Automatically switch to Response API for GPT-5 Codex models
        support_previous_response_id = false, -- Copilot doesn't support previous_response_id, must send full history
        -- NOTE: Copilot doesn't support previous_response_id, always sends full conversation history including tool_calls
        -- NOTE: Response API doesn't support some parameters like top_p, frequency_penalty, presence_penalty
        extra_request_body = {
          -- temperature is not supported by Response API for reasoning models
          max_tokens = 20480,
        },
      },
    },

    acp_providers = {
      ["gemini-cli"] = {
        command = "gemini",
        args = { "--experimental-acp" },
        env = {
          NODE_NO_WARNINGS = "1",
          GEMINI_API_KEY = os.getenv("GEMINI_API_KEY"),
        },
        auth_method = "gemini-api-key",
      },
    },
    web_search_engine = {
      provider = "tavily",
      proxy = nil,
      providers = {
        tavily = {
          api_key_name = "TAVILY_API_KEY",
          extra_request_body = {
            include_answer = "basic",
          },
          ---@type WebSearchEngineProviderResponseBodyFormatter
          format_response_body = function(body)
            return body.answer, nil
          end,
        },
        serpapi = {
          api_key_name = "SERPAPI_API_KEY",
          extra_request_body = {
            engine = "google",
            google_domain = "google.com",
          },
          ---@type WebSearchEngineProviderResponseBodyFormatter
          format_response_body = function(body)
            if body.answer_box ~= nil and body.answer_box.result ~= nil then
              return body.answer_box.result, nil
            end
            if body.organic_results ~= nil then
              local jsn = vim
                .iter(body.organic_results)
                :map(function(result)
                  return {
                    title = result.title,
                    link = result.link,
                    snippet = result.snippet,
                    date = result.date,
                  }
                end)
                :take(10)
                :totable()
              return vim.json.encode(jsn), nil
            end
            return "", nil
          end,
        },
        searchapi = {
          api_key_name = "SEARCHAPI_API_KEY",
          extra_request_body = {
            engine = "google",
          },
          google = {
            api_key_name = "GOOGLE_SEARCH_API_KEY",
            engine_id_name = "GOOGLE_SEARCH_ENGINE_ID",
            extra_request_body = {},
            format_response_body = function(body)
              if body.items ~= nil then
                local jsn = vim
                  .iter(body.items)
                  :map(function(result)
                    return {
                      title = result.title,
                      link = result.link,
                      snippet = result.snippet,
                    }
                  end)
                  :take(10)
                  :totable()
                return vim.json.encode(jsn), nil
              end
              return "", nil
            end,
          },
        },
      },
    },

    ---Specify the behaviour of avante.nvim
    ---1. auto_focus_sidebar              : Whether to automatically focus the sidebar when opening avante.nvim. Default to true.
    ---2. auto_suggestions = false, -- Whether to enable auto suggestions. Default to false.
    ---3. auto_apply_diff_after_generation: Whether to automatically apply diff after LLM response.
    ---                                     This would simulate similar behaviour to cursor. Default to false.
    ---4. auto_set_keymaps                : Whether to automatically set the keymap for the current line. Default to true.
    ---                                     Note that avante will safely set these keymap. See https://github.com/yetone/avante.nvim/wiki#keymaps-and-api-i-guess for more details.
    ---5. auto_set_highlight_group        : Whether to automatically set the highlight group for the current line. Default to true.
    ---6. jump_result_buffer_on_finish = false, -- Whether to automatically jump to the result buffer after generation
    ---7. support_paste_from_clipboard    : Whether to support pasting image from clipboard. This will be determined automatically based whether img-clip is available or not.
    ---8. minimize_diff                   : Whether to remove unchanged lines when applying a code block
    ---9. enable_token_counting           : Whether to enable token counting. Default to true.
    ---10. auto_add_current_file          : Whether to automatically add the current file when opening a new chat. Default to true.
    behaviour = {
      auto_focus_sidebar = true,
      auto_suggestions = false, -- Experimental stage
      auto_suggestions_respect_ignore = false,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      jump_result_buffer_on_finish = false,
      support_paste_from_clipboard = false,
      minimize_diff = true,
      enable_token_counting = true,
      use_cwd_as_project_root = false,
      auto_focus_on_diff_view = false,
      ---@type boolean | string[] -- true: auto-approve all tools, false: normal prompts, string[]: auto-approve specific tools by name
      auto_approve_tool_permissions = true, -- Default: auto-approve all tools (no prompts)
      auto_check_diagnostics = true,
      allow_access_to_git_ignored_files = false,
      enable_fastapply = false,
      include_generated_by_commit_line = false, -- Controls if 'Generated-by: <provider/model>' line is added to git commit message
      auto_add_current_file = true, -- Whether to automatically add the current file when opening a new chat
      --- popup is the original yes,all,no in a floating window
      --- inline_buttons is the new inline buttons in the sidebar
      ---@type "popup" | "inline_buttons"
      confirmation_ui_style = "inline_buttons",
      --- Whether to automatically open files and navigate to lines when ACP agent makes edits
      ---@type boolean
      acp_follow_agent_locations = true,
    },
    --- @class AvanteRepoMapConfig
    repo_map = {
      ignore_patterns = { "%.git", "%.worktree", "__pycache__" }, -- ignore files matching these
      negate_patterns = {}, -- negate ignore files matching these.
    },
    --- Allows selecting code or other data in a buffer and ask LLM questions about it or
    --- to perform edits/transformations.
    --- @class AvanteSelectionConfig
    --- @field enabled boolean
    --- @field hint_display "delayed" | "immediate" | "none" When to show key map hints.
    selection = {
      enabled = true,
      hint_display = "delayed",
    },
    mappings = {
      ---@class AvanteConflictMappings
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      cancel = {
        normal = { "<C-c>", "<Esc>", "q" },
        insert = { "<C-c>" },
      },
      -- NOTE: The following will be safely set by avante.nvim
      ask = "<leader>aa",
      new_ask = "<leader>an",
      zen_mode = "<leader>az",
      edit = "<leader>ae",
      refresh = "<leader>ar",
      focus = "<leader>af",
      stop = "<leader>aS",
      toggle = {
        default = "<leader>at",
        debug = "<leader>ad",
        selection = "<leader>aC",
        suggestion = "<leader>as",
        repomap = "<leader>aR",
      },
      sidebar = {
        expand_tool_use = "<S-Tab>",
        next_prompt = "]p",
        prev_prompt = "[p",
        apply_all = "A",
        apply_cursor = "a",
        retry_user_request = "r",
        edit_user_request = "e",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
        toggle_code_window = "x",
        remove_file = "d",
        add_file = "@",
        close = { "q" },
        ---@alias AvanteCloseFromInput { normal: string | nil, insert: string | nil }
        ---@type AvanteCloseFromInput | nil
        close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
        ---@alias AvanteToggleCodeWindowFromInput { normal: string | nil, insert: string | nil }
        ---@type AvanteToggleCodeWindowFromInput | nil
        toggle_code_window_from_input = nil, -- e.g., { normal = "x", insert = "<C-;>" }
      },
      files = {
        add_current = "<leader>ac", -- Add current buffer to selected files
        add_all_buffers = "<leader>aB", -- Add all buffer files to selected files
      },
      select_model = "<leader>a?", -- Select model command
      select_history = "<leader>ah", -- Select history command
      select_acp_model = "<leader>aM", -- Select ACP agent model
      select_acp_mode = "<leader>am", -- Select ACP agent mode
      confirm = {
        focus_window = "<C-w>f",
        code = "c",
        resp = "r",
        input = "i",
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "nvim-mini/mini.pick", -- for file_selector provider mini.pick
    "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
    "ibhagwan/fzf-lua", -- for file_selector provider fzf
    "stevearc/dressing.nvim", -- for input provider dressing
    "folke/snacks.nvim", -- for input provider snacks
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
