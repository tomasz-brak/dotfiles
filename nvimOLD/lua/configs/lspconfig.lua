require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "clangd", "lua-language-server", "basedpyright", "rust_analyzer", "gopls", "texlab"}
vim.lsp.enable(servers)

-- use vim.lsp.config('clang') style as requested
vim.lsp.config('clang', {
  cmd = {
  },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  settings = {
    ['clangd'] = {},
  },
})

vim.lsp.config('basedpyright', {

})

vim.lsp.config('texlab', {

})



