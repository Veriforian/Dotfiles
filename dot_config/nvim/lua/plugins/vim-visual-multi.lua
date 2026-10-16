return {
  {
    "mg979/vim-visual-multi",
    branch = "master", -- use the master branch
    init = function()
      vim.g.VM_leader = "<C-m>"

      vim.g.VM_maps = {
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
        ["Select All"] = "<C-m><C-a>",
        ["Start Regex Search"] = "<C-m><C-/>",
        ["Add Cursor Down"] = "<C-m><C-j>",
        ["Add Cursor Up"] = "<C-m><C-k>",
        ["Add Cursor At Pos"] = "<C-m><C-p>",
        ["Visual Regex"] = "<C-m><C-/>",
        ["Visual All"] = "<C-m><C-A>",
        ["Visual Add"] = "<C-m><C-a>",
        ["Visual Find"] = "<C-m><C-f>",
        ["Visual Cursors"] = "<C-m><C-c>",
        ["Exit"] = "<C-c>",
      }
    end,
  },
}
