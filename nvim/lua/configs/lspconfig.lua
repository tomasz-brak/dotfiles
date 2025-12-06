require("nvchad.configs.lspconfig").defaults()

<<<<<<< Updated upstream


local servers = { "html", "cssls", "clangd", "lua-language-server", "basedpyright", "rust_analyzer"}
=======
local servers = { "html", "cssls", "clangd", "lua-language-server", "texlab", "markdown", "markdown_inline"}
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
vim.lsp.config('basedpyright', {

})

=======
vim.lsp.config('texlab', {

})
>>>>>>> Stashed changes
-- read :h vim.lsp.config for changing options of lsp serversdf ffsdfsf
