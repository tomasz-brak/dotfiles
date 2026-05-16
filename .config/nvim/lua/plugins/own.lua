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
        "ltex-ls-plus",
        "codelldb",
        "basedpyright",
        "clangd",
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
        "texlab",
        "tex-fmt",
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
      vim.g.vimtex_view_zathura_options = "--synctex-editor-command --synctex-forward"

      vim.g.vimtex_compiler_method = "generic"
      vim.g.vimtex_compiler_generic = {
        command = "ls @tex | entr -n -c tectonic /_ --synctex --keep-logs",
      }
    end,
  },
  {
    "stevearc/overseer.nvim",
    ---@module 'overseer'
    ---@type overseer.SetupOpts
    opts = {
      templates = { "builtin" },
    },
    config = function(_, opts)
      local overseer = require("overseer")
      overseer.setup(opts)

      overseer.register_template({
        name = "Run Project",
        builder = function()
          if vim.fn.filereadable("CMakeLists.txt") == 1 then
            return {
              cmd = { "nvim" },
              args = { "--server", vim.v.servername, "--remote-send", "<cmd>CMakeRun<cr>" },
            }
          elseif vim.bo.filetype == "python" then
            local target = vim.fn.filereadable("app.py") == 1 and "app.py" or "main.py"
            return { cmd = { "python3" }, args = { target } }
          elseif vim.bo.filetype == "go" then
            return { cmd = { "go" }, args = { "run", "." } }
          elseif vim.bo.filetype == "tex" then
            return {
              cmd = { "nvim" },
              args = { "--server", vim.v.servername, "--remote-send", "<cmd>VimtexCompile<cr>" },
            }
          end
          return nil
        end,
        condition = {
          callback = function()
            return vim.bo.filetype == "python"
              or vim.bo.filetype == "go"
              or vim.bo.filetype == "tex"
              or vim.fn.filereadable("CMakeLists.txt") == 1
          end,
        },
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- Use tex-fmt for LaTeX and related files
        tex = { "tex-fmt" },
        plaintex = { "tex-fmt" },
        bib = { "tex-fmt" },
      },
      formatters = {
        ["tex-fmt"] = {
          command = "tex-fmt",
          -- tex-fmt reads from stdin by default when no file is provided,
          -- but for conform it's best to explicitly handle it if needed.
          -- Standard usage for tex-fmt as a filter:
          args = { "--stdin" },
          stdin = true,
        },
      },
    },
  },
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      -- add options here
      -- or leave it empty to use the default settings
    },
    keys = {
      -- suggested keymap
      { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  },
  {
    "jhofscheier/ltex-utils.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      dictionary = {
        -- Dictionaries will be saved as 'en-US.txt' and 'pl-PL.txt' in this path
        path = vim.fn.stdpath("cache") .. "/ltex/",
        filename = function(lang)
          return lang .. ".txt"
        end,
        use_vim_dict = false,
        vim_cmd_output = false,
      },
      rule_ui = {
        modify_rule_key = "<CR>",
        delete_rule_key = "d",
        cleanup_rules_key = "c",
        goto_key = "g",
        previewer_line_number = true,
        previewer_wrap = true,
        telescope = { bufnr = 0 },
      },
      diagnostics = {
        debounce_time_ms = 500,
        diags_false_pos = true,
        diags_disable_rules = true,
      },
      -- Matches your preferred backend
      backend = "ltex_plus",
    },
    config = function(_, opts)
      require("ltex-utils").setup(opts)

      require("lspconfig").ltex_plus.setup({
        settings = {
          ltex = {
            language = "pl-PL", -- Default language
          },
        },
        on_attach = function(client, bufnr)
          -- Optional: Create a command to toggle between English and Polish
          vim.api.nvim_buf_create_user_command(bufnr, "LtexLangPolish", function()
            client.config.settings.ltex.language = "pl-PL"
            client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
          end, {})

          vim.api.nvim_buf_create_user_command(bufnr, "LtexLangEnglish", function()
            client.config.settings.ltex.language = "en-US"
            client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
          end, {})
        end,
      })
    end,
  },
}
