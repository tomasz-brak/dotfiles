-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local map = vim.keymap.set

local noremap = { noremap = true }

-- Sane movement
map("i", "<C-h>", "<Left>", noremap)
map("i", "<C-l>", "<Right>", noremap)

-- Terminal

map({ "n", "i" }, "<A-h>", ":ToggleTerm direction=float <CR>", { desc = "Open terminal" })
map("t", "<esc><esc>", [[<C-\><C-n>]])

-- Cmake
map("n", "<C-r>", ":CMakeRun <CR>", { desc = "Run a cmake project" })

-- Neogen
map("n", "<leader>cg", ":Neogen", { desc = "Generate documentation" })
