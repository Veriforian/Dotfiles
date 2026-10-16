local function toggle_last_term()
  if vim.bo.buftype == "terminal" and vim.b.toggle_number then
    require("toggleterm").toggle(vim.b.toggle_number)
    return
  end

  local terms = require("toggleterm.terminal").get_all()
  if #terms == 0 then
    -- open new floatterm
    require("toggleterm").toggle(1, 0, LazyVim.root.get(), "float")
    return
  end

  -- Find most recent term to toggle
  local target_id = vim.g.last_active_term_id
  if not target_id then
    terms[1]:toggle()
    return
  end

  local found = false
  for _, t in ipairs(terms) do
    if t.id == target_id then
      found = true
      t:toggle()
      break
    end
  end

  if not found then
    terms[1]:toggle()
  end
end

return {
  "akinsho/toggleterm.nvim",
  lazy = true,
  cmd = { "ToggleTerm" },
  init = function()
    -- Most recent terminal tracking
    vim.api.nvim_create_autocmd({ "BufEnter", "TermEnter" }, {
      pattern = "term://*",
      callback = function()
        if vim.b.toggle_number then
          vim.g.last_active_term_id = vim.b.toggle_number
        end
      end,
    })
  end,
  keys = {
    { "<c-/>", toggle_last_term, mode = { "n", "t", "i" }, desc = "Toggle last focused terminal" },
    { "<c-_>", toggle_last_term, mode = { "n", "t", "i" }, desc = "which_key_ignore" },
    {
      "<leader>tf",
      function()
        local count = vim.v.count1
        require("toggleterm").toggle(count, 0, LazyVim.root.get(), "float")
      end,
      desc = "ToggleTerm (float root_dir)",
    },
    {
      "<leader>th",
      function()
        local count = vim.v.count1
        require("toggleterm").toggle(count, 15, LazyVim.root.get(), "horizontal")
      end,
      desc = "ToggleTerm (horizontal root_dir)",
    },
    {
      "<leader>tv",
      function()
        local count = vim.v.count1
        require("toggleterm").toggle(count, vim.o.columns * 0.4, LazyVim.root.get(), "vertical")
      end,
      desc = "ToggleTerm (vertical root_dir)",
    },
    {
      "<leader>tn",
      "<cmd>ToggleTermSetName<cr>",
      desc = "Set term name",
    },
    {
      "<leader>ts",
      "<cmd>TermSelect<cr>",
      desc = "Select term",
    },
    {
      "<leader>tt",
      function()
        require("toggleterm").toggle(1, 100, LazyVim.root.get(), "tab")
      end,
      desc = "ToggleTerm (tab root_dir)",
    },
    {
      "<leader>tT",
      function()
        require("toggleterm").toggle(1, 100, vim.loop.cwd(), "tab")
      end,
      desc = "ToggleTerm (tab cwd_dir)",
    },
  },
  opts = {
    -- size can be a number or function which is passed the current terminal
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      end
    end,
    hide_numbers = true, -- hide the number column in toggleterm buffers
    shade_filetypes = {},
    shade_terminals = false,
    start_in_insert = true,
    insert_mappings = true, -- whether or not the open mapping applies in insert mode
    terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
    persist_size = true,
    close_on_exit = true, -- close the terminal window when the process exits
    shell = vim.o.shell, -- change the default shell
    winblend = 0,
    title = false,
    float_opts = {
      border = "curved", -- or "single", "double", etc.
      winblend = 0, -- 0 = opaque, 100 = fully transparent. LazyVim default is 0.
      title = false,
      winbar = {
        enabled = false,
      },
      highlights = {
        border = "FloatBorder",
        background = "NONE", -- Explicitly set background for float
      },
    },
    winbar = {
      enabled = false,
      winblend = 0,
    },
  },
}
