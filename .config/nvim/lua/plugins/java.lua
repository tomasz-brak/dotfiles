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

      -- Ensure dap.adapters.java is always defined
      dap.adapters.java = function(callback, _)
        local ok, jdtls_util = pcall(require, "jdtls.util")
        local bufnr = vim.api.nvim_get_current_buf()
        if not ok or not jdtls_util then
          callback({ type = "server", host = "127.0.0.1", port = 5005 })
          return
        end

        jdtls_util.execute_command({ command = "vscode.java.startDebugSession" }, function(err, port)
          if err or not port then
            vim.notify("Could not start JDTLS debug session: " .. vim.inspect(err or "nil port"), vim.log.levels.WARN)
            callback({ type = "server", host = "127.0.0.1", port = 5005 })
            return
          end

          callback({
            type = "server",
            host = "127.0.0.1",
            port = port,
          })
        end, bufnr)
      end

      -- Ensure default remote attach configuration exists
      dap.configurations.java = dap.configurations.java or {}
      table.insert(dap.configurations.java, {
        type = "java",
        request = "attach",
        name = "Debug (Attach) - Port 5005",
        hostName = "::1",
        port = 5005,
      })

      -- Hot reload: Compile workspace and apply changed bytecode classes
      local function hot_reload()
        local ok, jdtls = pcall(require, "jdtls")
        if not ok then
          vim.notify("jdtls is not loaded", vim.log.levels.WARN)
          return
        end

        vim.notify("Triggering hot reload (incremental build)...", vim.log.levels.INFO)
        jdtls.compile("incremental", function()
          local dap = require("dap")
          local session = dap.session()
          if session then
            session:request("redefineClasses", nil, function(err)
              if err then
                vim.notify("Hot reload failed: " .. vim.inspect(err), vim.log.levels.ERROR)
              else
                vim.notify("Hot reload applied successfully!", vim.log.levels.INFO)
              end
            end)
          else
            vim.notify("Workspace compiled (no active DAP debug session to hot-swap).", vim.log.levels.INFO)
          end
        end)
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
      vim.keymap.set("n", "<leader>hr", hot_reload, { desc = "Debug: Hot Reload / Redefine Classes" })
      vim.keymap.set("n", "<leader>rh", hot_reload, { desc = "Debug: Hot Reload / Redefine Classes" })
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
          -- Only add the main test plugin jar, not test framework runners (which causes OSGi refresh error)
          local test_jar = vim.fn.glob(java_test_path .. "/extension/server/com.microsoft.java.test.plugin-*.jar", true)
          if test_jar ~= "" then
            table.insert(bundles, test_jar)
          end
        end

        -- 2. Setup project workspace directory anchored to repository root
        local root_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", ".git" }
        local root_dir = require("jdtls.setup").find_root(root_markers) or vim.fs.root(0, root_markers) or vim.uv.cwd()
        local project_name = vim.fs.basename(root_dir)
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

        -- Optional lombok support
        local vmargs = {
          "-Declipse.application=org.eclipse.jdt.ls.core.id1",
          "-Dosgi.bundles.defaultStartLevel=4",
          "-Declipse.product=org.eclipse.jdt.ls.core.product",
          "-Dlog.level=ALL",
          "-Xmx3g", -- Expanded heap memory for heavy Minecraft mod workspaces
          "--add-modules=ALL-SYSTEM",
          "--add-opens",
          "java.base/java.util=ALL-UNNAMED",
          "--add-opens",
          "java.base/java.lang=ALL-UNNAMED",
        }
        local lombok_jar = vim.fn.glob(jdtls_path .. "/lombok.jar")
        if lombok_jar ~= "" then
          table.insert(vmargs, "-javaagent:" .. lombok_jar)
        end

        local cmd = { "java" }
        vim.list_extend(cmd, vmargs)
        vim.list_extend(cmd, {
          "-jar",
          launcher_jar,
          "-configuration",
          jdtls_path .. "/" .. os_config,
          "-data",
          workspace_dir,
        })

        -- 4. LSP capabilities (Crucial for blink.cmp completion support)
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        local ok_blink, blink = pcall(require, "blink.cmp")
        if ok_blink then
          capabilities = blink.get_lsp_capabilities(capabilities)
        end

        -- 5. Detect and register installed JDK runtimes (Adoptium 21, 25, 27)
        local runtimes = {}
        local gradle_jdks = vim.fn.expand("$USERPROFILE/.gradle/jdks")
        if vim.fn.isdirectory(gradle_jdks .. "/eclipse_adoptium-25-amd64-windows.2") == 1 then
          table.insert(runtimes, {
            name = "JavaSE-25",
            path = gradle_jdks .. "/eclipse_adoptium-25-amd64-windows.2",
            default = true,
          })
        end
        if vim.fn.isdirectory(gradle_jdks .. "/eclipse_adoptium-21-amd64-windows.2") == 1 then
          table.insert(runtimes, {
            name = "JavaSE-21",
            path = gradle_jdks .. "/eclipse_adoptium-21-amd64-windows.2",
          })
        end

        -- 6. Server setup
        local config = {
          cmd = cmd,
          root_dir = root_dir,
          capabilities = capabilities,
          init_options = {
            bundles = bundles,
            extendedClientCapabilities = jdtls.extendedClientCapabilities,
          },
          settings = {
            java = {
              signatureHelp = { enabled = true },
              contentProvider = { preferred = "fernflower" },
              completion = {
                favoriteStaticMembers = {
                  "org.junit.Assert.*",
                  "org.junit.Assume.*",
                  "org.junit.jupiter.api.Assertions.*",
                  "org.junit.jupiter.api.Assumptions.*",
                  "org.junit.jupiter.api.DynamicContainer.*",
                  "org.junit.jupiter.api.DynamicTest.*",
                  "org.mockito.Mockito.*",
                  "org.mockito.ArgumentMatchers.*",
                  "java.util.Objects.requireNonNull",
                  "java.util.Objects.requireNonNullElse",
                },
                filteredTypes = {
                  "com.sun.*",
                  "io.micrometer.shaded.*",
                  "java.awt.*",
                  "jdk.*",
                  "sun.*",
                },
                importOrder = {
                  "java",
                  "javax",
                  "com",
                  "org",
                },
              },
              sources = {
                organizeImports = {
                  starThreshold = 9999,
                  staticStarThreshold = 9999,
                },
              },
              codeGeneration = {
                toString = {
                  template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
                },
                useBlocks = true,
              },
              configuration = {
                updateBuildConfiguration = "interactive",
                runtimes = #runtimes > 0 and runtimes or nil,
              },
              referencesCodeLens = {
                enabled = true,
              },
              references = {
                includeDecompiledSources = true,
              },
              inlayHints = {
                parameterNames = {
                  enabled = "all",
                },
              },
              import = {
                gradle = {
                  enabled = true,
                  wrapper = { enabled = true },
                  annotationProcessing = { enabled = true },
                },
                maven = { enabled = true },
              },
            },
          },
          on_attach = function(_, bufnr)
            -- Initialize DAP integration
            jdtls.setup_dap({ hotcodereplace = "auto" })
            pcall(require("jdtls.dap").setup_dap_main_class_configs)

            -- Java Test & utility keymaps
            local map_opts = { buffer = bufnr, desc = "Java Test" }
            vim.keymap.set("n", "<leader>tc", jdtls.test_class, map_opts)
            vim.keymap.set("n", "<leader>tm", jdtls.test_nearest_method, map_opts)
            vim.keymap.set("n", "<leader>co", jdtls.organize_imports, { buffer = bufnr, desc = "Organize Imports" })
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
