require "nvchad.mappings"
-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

vim.keymap.del({ "n" }, "<leader>e")
map("n", "<leader>e", function()
  Snacks.explorer()
end)

map("n", "<leader>dp", "<cmd> DapToggleBreakpoint <cr>", { desc = "Add breakpoint for Debugger" })

map("n", "<leader>lpN", function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = "Go to previous diagnostic" })

map("n", "<leader>lpn", function () vim.diagnostic.jump({count=1, float=true}) end, { desc = "Go to next diagnostic"})

map("n", "<leader>ih", function () vim.lsp.inlay_hint.enable() end, {desc = "Enable inlay hints"})

map("n", "<leader>lpn", function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = "Go to next diagnostic" })

map("n", "<leader>dl", function()
  require("osv").launch { port = 8086 }
end, { desc = "launch lua Debugger" })

map("n", "<leader>dc", require("dap").continue, { desc = "Debugger Next" })

map("n", "<leader>ca", function()
  vim.lsp.buf.code_action()
end, { desc = "Code actions" })
