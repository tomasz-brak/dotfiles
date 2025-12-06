require("nvchad.configs.lspconfig").defaults()



local servers = { "html", "cssls", "clangd", "lua-language-server", "basedpyright", "rust_analyzer"}
vim.lsp.enable(servers)

-- use vim.lsp.config('clang') style as requested
vim.lsp.config('clang', {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    "--header-insertion=never",
    "--extra-arg=-std=c++26", -- ensure clangd parses as C++26
  },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  settings = {
    ['clangd'] = {},
  },
})

vim.lsp.config('basedpyright', {

})

-- read :h vim.lsp.config for changing options of lsp serversdf ffsdfsf
