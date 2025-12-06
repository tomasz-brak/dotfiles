require "nvchad.mappings"
-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

vim.keymap.del({"n"}, "<leader>e")
map("n", "<leader>e", function() Snacks.explorer() end)

map("n", "<leader>dp", "<cmd> DapToggleBreakpoint <cr>", { desc = "Add breakpoint for Debugger"})

map("n", "<leader>lpN", function () vim.diagnostic.jump({count=-1, float=true}) end, { desc = "Go to previous diagnostic"})

map("n", "<leader>lpn", function () vim.diagnostic.jump({count=1, float=true}) end, { desc = "Go to next diagnostic"})
