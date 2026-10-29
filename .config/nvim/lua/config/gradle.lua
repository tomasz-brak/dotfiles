local M = {}

-- Cached list of common tasks as fallback / quick access
local DEFAULT_GRADLE_TASKS = {
  { task = "runClient", desc = "Run Minecraft client" },
  { task = "runServer", desc = "Run Minecraft server" },
  { task = "build", desc = "Assembles and tests this project" },
  { task = "clean", desc = "Deletes the build directory" },
  { task = "classes", desc = "Assembles main classes" },
  { task = "testClasses", desc = "Assembles test classes" },
  { task = "genSources", desc = "Generate Minecraft sources (Fabric/NeoForge)" },
}

-- Discover Gradle root directory and wrapper
function M.get_gradle_info()
  local root_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "gradlew", "gradlew.bat" }
  local root = vim.fs.root(0, root_markers) or vim.uv.cwd()
  local is_win = vim.fn.has("win32") == 1
  local wrapper_name = is_win and "gradlew.bat" or "gradlew"
  local wrapper_path = vim.fs.joinpath(root, wrapper_name)
  local cmd = vim.uv.fs_stat(wrapper_path) and wrapper_path or "gradle"
  return root, cmd
end

-- Pick and run a Gradle task
function M.pick_gradle_task(on_select)
  local root, cmd = M.get_gradle_info()
  local items = {}
  local seen = {}

  local function add_item(t, d)
    if not seen[t] then
      seen[t] = true
      table.insert(items, { text = t, task = t, desc = d or "" })
    end
  end

  for _, def in ipairs(DEFAULT_GRADLE_TASKS) do
    add_item(def.task, def.desc)
  end

  local function show_picker()
    table.insert(items, { text = "<manual input>", task = "__custom__", desc = "Type a custom task name" })
    local snacks = package.loaded["snacks"] or _G.Snacks
    if snacks and snacks.picker then
      snacks.picker.pick({
        title = "Gradle Tasks (" .. vim.fs.basename(root) .. ")",
        items = items,
        format = function(item)
          return {
            { item.text, "SnacksPickerLabel" },
            { item.desc ~= "" and ("  " .. item.desc) or "", "SnacksPickerComment" },
          }
        end,
        confirm = function(picker, item)
          picker:close()
          if not item then return end
          if item.task == "__custom__" then
            vim.ui.input({ prompt = "Gradle task: " }, function(input)
              if input and input:match("%S") then
                on_select(input:match("^%s*(.-)%s*$"), root, cmd)
              end
            end)
          else
            on_select(item.task, root, cmd)
          end
        end,
      })
    else
      local formatted = {}
      for _, it in ipairs(items) do
        table.insert(formatted, it.desc ~= "" and string.format("%s - %s", it.text, it.desc) or it.text)
      end
      vim.ui.select(formatted, { prompt = "Select Gradle Task:" }, function(choice, idx)
        if not idx then return end
        local selected = items[idx]
        if selected.task == "__custom__" then
          vim.ui.input({ prompt = "Gradle task: " }, function(input)
            if input and input:match("%S") then
              on_select(input:match("^%s*(.-)%s*$"), root, cmd)
            end
          end)
        else
          on_select(selected.task, root, cmd)
        end
      end)
    end
  end

  -- Query project tasks asynchronously in background to populate any custom/mod tasks
  vim.fn.jobstart({ cmd, "--console=plain", "-q", "tasks", "--all" }, {
    cwd = root,
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          local task_name, desc = line:match("^([%a%d%-_:]+)%s*-%s*(.*)$")
          if task_name then
            add_item(task_name, desc)
          end
        end
      end
    end,
    on_exit = function()
      vim.schedule(show_picker)
    end,
  })
end

-- Run a task via Overseer
function M.run_gradle_task(task_name, root, cmd)
  local overseer = require("overseer")
  local task = overseer.new_task({
    name = "gradle " .. task_name,
    cmd = { cmd },
    args = vim.split(task_name, "%s+"),
    cwd = root,
    components = {
      { "on_output_quickfix", open_on_exit = "failure" },
      { "open_output", on_start = "always", direction = "horizontal", focus = false },
      "default",
    },
  })
  task:start()
end

-- Wait for a TCP port to open before executing a callback
local function wait_for_port(port, timeout_ms, interval_ms, on_ready, on_timeout)
  local start = vim.uv.now()
  local timer = vim.uv.new_timer()

  local function check()
    local done = false
    local function finish(err)
      if done then return end
      if not err then
        done = true
        timer:stop()
        timer:close()
        vim.schedule(on_ready)
      else
        if (vim.uv.now() - start) >= timeout_ms then
          done = true
          timer:stop()
          timer:close()
          vim.schedule(on_timeout)
        end
      end
    end

    -- Try IPv6 loopback (::1) first (standard for modern JVMs on Windows)
    local tcp6 = vim.uv.new_tcp()
    tcp6:connect("::1", port, function(err6)
      tcp6:close()
      if not err6 then
        finish(nil)
      else
        -- Fallback to IPv4 127.0.0.1
        local tcp4 = vim.uv.new_tcp()
        tcp4:connect("127.0.0.1", port, function(err4)
          tcp4:close()
          finish(err4)
        end)
      end
    end)
  end

  timer:start(500, interval_ms, check)
end

-- Debug run a task: launches with JVM debug args, then auto-attaches DAP
function M.debug_gradle_task(task_name, root, cmd)
  local dap = require("dap")
  local overseer = require("overseer")
  local port = 5005

  -- Ensure Java attach config exists in dap
  dap.configurations.java = dap.configurations.java or {}
  local has_attach = false
  for _, cfg in ipairs(dap.configurations.java) do
    if cfg.request == "attach" and (cfg.port == port or cfg.port == 5005) then
      has_attach = true
      break
    end
  end
  if not has_attach then
    table.insert(dap.configurations.java, 1, {
      type = "java",
      request = "attach",
      name = "Attach to Gradle JVM (5005)",
      hostName = "::1",
      port = port,
    })
  end

  local args = vim.split(task_name, "%s+")
  table.insert(args, "--debug-jvm")

  local task = overseer.new_task({
    name = "gradle debug " .. task_name,
    cmd = { cmd },
    args = args,
    cwd = root,
    components = {
      { "open_output", on_start = "always", direction = "horizontal", focus = false },
      "default",
    },
  })
  task:start()

  -- Wait for Gradle JVM to bind to port 5005, then connect DAP and trigger DAP UI
  vim.notify("Starting Gradle task with --debug-jvm. Waiting for JVM on port " .. port .. "...", vim.log.levels.INFO)

  wait_for_port(port, 120000, 500, function()
    vim.notify("JVM debug socket ready! Attaching debugger...", vim.log.levels.INFO)
    dap.run({
      type = "java",
      request = "attach",
      name = "Attach to Gradle JVM (5005)",
      hostName = "::1",
      port = port,
    })
  end, function()
    vim.notify("Timed out waiting for JVM socket on port " .. port, vim.log.levels.WARN)
  end)
end

return M
