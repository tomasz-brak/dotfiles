local snacks = require("snacks")
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
map("n", "<C-R>", ":CMakeRun <CR>", { desc = "Run a cmake project" })

-- Neogen
map("n", "<leader>cg", ":Neogen", { desc = "Generate documentation" })

------------
-- Snacks --
------------
---- explorer
map("n", "<leader>e", function()
  snacks.explorer()
end, { desc = "explorer snacks (cwd)" })
map("n", "<leader>E", function()
  snacks.explorer({ cwd = LazyVim.root() })
end, { desc = "explorer snacks (root dir)" })
-- Main Search (<leader><leader>) - Use CWD instead of LSP root
map("n", "<leader><leader>", function()
  snacks.picker.files({ cwd = vim.uv.cwd() })
end, { desc = "Find Files (cwd)" })

-- Grep Search
map("n", "<leader>sg", function()
  snacks.picker.grep({ cwd = vim.uv.cwd() })
end, { desc = "Grep (cwd)" })

map("n", "<leader>sG", function()
  snacks.picker.grep({ cwd = LazyVim.root() })
end, { desc = "Grep (Root Dir)" })

-- Word Search
map("n", "<leader>sw", function()
  snacks.picker.grep_word({ cwd = vim.uv.cwd() })
end, { desc = "Visual selection or word (cwd)" })

map("n", "<leader>sW", function()
  snacks.picker.grep_word({ cwd = LazyVim.root() })
end, { desc = "Visual selection or word (Root Dir)" })

------------
-- Snacks --
------------
---- explorer
map("n", "<leader>e", function()
  snacks.explorer({ cwd = vim.uv.cwd() })
end, { desc = "Explorer Snacks (cwd)" })

map("n", "<leader>E", function()
  snacks.explorer({ cwd = LazyVim.root() })
end, { desc = "Explorer Snacks (Root Dir)" })

--------------
-- Neo-Tree --
--------------
-- If you use Neo-tree alongside or instead of Snacks explorer
map("n", "<leader>fe", function()
  require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
end, { desc = "Explorer NeoTree (cwd)" })

map("n", "<leader>fE", function()
  require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
end, { desc = "Explorer NeoTree (Root Dir)" })

---------------
-- Telescope --
---------------
-- Fallback in case Telescope extra is enabled instead of Snacks picker
map("n", "<leader>ff", function()
  require("telescope.builtin").find_files({ cwd = vim.uv.cwd() })
end, { desc = "Find Files (cwd)" })

map("n", "<leader>fF", function()
  require("telescope.builtin").find_files({ cwd = LazyVim.root() })
end, { desc = "Find Files (Root Dir)" })
