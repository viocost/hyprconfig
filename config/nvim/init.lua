-- bootstrap lazy.nvim, LazyVim and your plugins
--
require("config.lazy")

-- Put this in your init.lua or as a separate plugin
local function async_nvm_init()
  local uv = vim.loop

  -- Create the command to source nvm
  local shell = os.getenv("SHELL")
  local nvm_dir = os.getenv("NVM_DIR") or (os.getenv("HOME") .. "/.nvm")
  local cmd = string.format(
    [[
    export NVM_DIR="%s"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    env
  ]],
    nvm_dir
  )

  -- Spawn process async
  local handle
  local stdout = uv.new_pipe()
  local output = ""

  handle = uv.spawn(shell, {
    args = { "-c", cmd },
    stdio = { nil, stdout, nil },
  }, function()
    -- Schedule environment variable updates in the main loop
    vim.schedule(function()
      -- Parse and set all environment variables at once
      for line in output:gmatch("[^\r\n]+") do
        local name, value = line:match("^([^=]+)=(.+)$")
        if name and value then
          pcall(function()
            vim.env[name] = value
          end)
        end
      end
    end)

    -- Cleanup
    stdout:close()
    handle:close()
  end)

  -- Collect stdout
  uv.read_start(stdout, function(err, data)
    if err then
      print("Error reading nvm output:", err)
      return
    end
    if data then
      output = output .. data
    end
  end)
end

-- Call this function during startup
async_nvm_init()
