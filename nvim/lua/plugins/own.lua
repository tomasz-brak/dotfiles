return {
  -- change trouble config
  {
    "folke/trouble.nvim",
    -- opts will be merged with the parent spec
    opts = { use_diagnostic_signs = true },
  },

  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
    },
    -- change some options
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },

  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        basedpyright = {},
      },
    },
  },

  -- for typescript, LazyVim also includes extra specs to properly setup lspconfig,
  -- treesitter, mason and typescript.nvim. So instead of the above, you can use:

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },

  -- add any tools you want to have installed below
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "basedpyright",
        "clangd",
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
        "texlab",
      },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {--[[ things you want to change go here]]
    },
  },
  {
    "danymat/neogen",
    config = true,
    -- Uncomment next line if you want to follow only stable versions
    -- version = "*"
  },
  {
    "mfussenegger/nvim-dap",
    enabled = true,
  },
  {
    "rcarriga/nvim-dap-ui",
    enabled = true,
    -- virtual text for the debugger
    {
      "theHamsta/nvim-dap-virtual-text",
      opts = {},
    },
  },
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    lazy = false,
    opts = {},
    keys = {
      { "<leader>ci", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose Theirs(incoming)" },
      { "<leader>co", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose Ours(existing)" },
      { "<leader>cb", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose Both(incoming + existing)" },
      { "<leader>cn", "<cmd>GitConflictChooseNone<cr>", desc = "Choose None(Nothing)" },
    },
  },
  { "mini.ai", disable = true },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            scope = {
              patterns = { ".git", "lua", "CMakeLists.txt", "package.json" },
            },

            auto_close = true,
            root = false,
            layout = {
              layout = {
                position = "right",
                width = 0.15,
              },
            },
          },
        },
      },
    },
  },
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      vim.g.vimtex_view_general_viewer = "zathura"

      vim.g.vimtex_compiler_method = "generic"
      vim.g.vimtex_compiler_generic = {
        command = "ls *.tex | entr -n -c tectonic /_ --synctex --keep-logs",
      }
    end,
  },
}
