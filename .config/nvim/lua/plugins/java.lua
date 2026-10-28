return {
  -- Debug Adapter Protocol (DAP) core & UI
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- Auto open/close debug UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Debugger Keybindings
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>B", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Debug: Conditional Breakpoint" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle DAP UI" })
    end,
  },

  -- Package manager ensuring JDTLS and debug adapters are installed
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "jdtls",
        "java-debug-adapter",
        "java-test",
      })
    end,
  },

  -- Java LSP & Debug Integration
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    config = function()
      local function attach_jdtls()
        local jdtls = require("jdtls")
        local mason_registry = require("mason-registry")

        -- 1. Locate Mason debug bundles
        local bundles = {}
        if mason_registry.is_installed("java-debug-adapter") then
          local java_debug_pkg = mason_registry.get_package("java-debug-adapter")
          local java_debug_path = java_debug_pkg:get_install_path()
          local debug_jar =
            vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true)
          if debug_jar ~= "" then
            table.insert(bundles, debug_jar)
          end
        end

        if mason_registry.is_installed("java-test") then
          local java_test_pkg = mason_registry.get_package("java-test")
          local java_test_path = java_test_pkg:get_install_path()
          local test_jars = vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar", true), "\n")
          for _, jar in ipairs(test_jars) do
            if jar ~= "" then
              table.insert(bundles, jar)
            end
          end
        end

        -- 2. Setup project workspace directory
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
        local workspace_dir = vim.fn.stdpath("data") .. "/site/java-workspaces/" .. project_name

        -- 3. Resolve JDTLS launcher and OS configuration
        if not mason_registry.is_installed("jdtls") then
          return
        end

        local jdtls_pkg = mason_registry.get_package("jdtls")
        local jdtls_path = jdtls_pkg:get_install_path()
        local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

        local os_config = "config_linux"
        if vim.fn.has("mac") == 1 then
          os_config = "config_mac"
        elseif vim.fn.has("win32") == 1 then
          os_config = "config_win"
        end

        -- 4. Server setup
        local config = {
          cmd = {
            "java",
            "-Declipse.application=org.eclipse.jdt.ls.core.id1",
            "-Dosgi.bundles.defaultStartLevel=4",
            "-Declipse.product=org.eclipse.jdt.ls.core.product",
            "-Dlog.level=ALL",
            "-Xmx1g",
            "--add-modules=ALL-SYSTEM",
            "--add-opens",
            "java.base/java.util=ALL-UNNAMED",
            "--add-opens",
            "java.base/java.lang=ALL-UNNAMED",
            "-jar",
            launcher_jar,
            "-configuration",
            jdtls_path .. "/" .. os_config,
            "-data",
            workspace_dir,
          },
          root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),
          init_options = {
            bundles = bundles,
          },
          settings = {
            java = {
              signatureHelp = { enabled = true },
              contentProvider = { preferred = "fernflower" },
            },
          },
          on_attach = function(_, bufnr)
            -- Initialize DAP integration
            jdtls.setup_dap({ hotcodereplace = "auto" })
            require("jdtls.dap").setup_dap_main_class_configs()

            -- Test runner keymaps
            local map_opts = { buffer = bufnr, desc = "Java Test" }
            vim.keymap.set("n", "<leader>tc", jdtls.test_class, map_opts)
            vim.keymap.set("n", "<leader>tm", jdtls.test_nearest_method, map_opts)
          end,
        }

        jdtls.start_or_attach(config)
      end

      -- Autocmd attached to Java files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = attach_jdtls,
      })

      -- Trigger immediately if a Java file is already open
      if vim.bo.filetype == "java" then
        attach_jdtls()
      end
    end,
  },
}
