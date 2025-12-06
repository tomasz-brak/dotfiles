return {
  "mason-org/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      "rust-analyzer",
      "clangd",
      "codelldb",
      "pyright",
      "debugpy",

    },
  },
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "neovim/nvim-lspconfig",
  },
}
