require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

vim.keymap.del({"n"}, "<leader>e")
map("n", "<leader>e", function() Snacks.explorer() end)

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
