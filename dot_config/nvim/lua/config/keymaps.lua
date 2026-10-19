-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move highlighted things
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Allow keeping current yank when putting
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Copy to shared clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Delete without replacing cur yank
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- <C-c> mimics esc
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("x", "<C-c>", "<Esc>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>*", "*``")

-- <leader>l is a "lazy" prefix: LazyVim maps it straight to :Lazy, which made
-- <leader>ld (lazydocker.lua) wait for a timeout. Lazy moves to <leader>ll.
pcall(vim.keymap.del, "n", "<leader>l")
vim.keymap.set("n", "<leader>ll", "<cmd>Lazy<cr>", { desc = "Lazy" })
pcall(function()
  require("which-key").add({ { "<leader>l", group = "lazy" } })
end)

-- Place lines without goin i mode
vim.keymap.set("n", "<leader>o", "o<Esc>k")
vim.keymap.set("n", "<leader>O", "O<Esc>j")

-- Get rid of EX mode
vim.keymap.set("n", "Q", "<nop>")

-- Unsetting defaults that conflict with preferred plugins
vim.keymap.set("n", "<C-m>", "<nop>")
vim.keymap.set("n", "<C-d>", "<nop>")
vim.keymap.set("v", "<C-m>", "<nop>")
vim.keymap.set("v", "<C-d>", "<nop>")

vim.keymap.set("t", "<C-c>", "<C-c><C-c>", { desc = "Exit terminal insert mode" })

vim.api.nvim_set_keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { noremap = true, silent = true })

-- Scroll
local neoscroll = require("neoscroll")
local keymap = {
  -- Native Kitty
  ["<F13>"] = function()
    neoscroll.ctrl_u({ duration = 150 })
  end,
  ["<F14>"] = function()
    neoscroll.ctrl_d({ duration = 150 })
  end,
  -- Tmux kitty overrides
  ["<F15>"] = function()
    neoscroll.ctrl_u({ duration = 150 })
  end,
  ["<F16>"] = function()
    neoscroll.ctrl_d({ duration = 150 })
  end,
  ["<C-b>"] = function()
    neoscroll.ctrl_b({ duration = 250 })
  end,
  ["<C-f>"] = function()
    neoscroll.ctrl_f({ duration = 250 })
  end,
  ["<C-y>"] = function()
    neoscroll.scroll(-0.1, { move_cursor = false, duration = 40 })
  end,
  ["<C-e>"] = function()
    neoscroll.scroll(0.1, { move_cursor = false, duration = 40 })
  end,
  ["zt"] = function()
    neoscroll.zt({ half_win_duration = 150 })
  end,
  ["zz"] = function()
    neoscroll.zz({ half_win_duration = 150 })
  end,
  ["zb"] = function()
    neoscroll.zb({ half_win_duration = 150 })
  end,
}
local modes = { "n", "v", "x" }
for key, func in pairs(keymap) do
  vim.keymap.set(modes, key, func)
end
