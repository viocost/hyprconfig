vim.api.nvim_create_user_command("DiffviewToggle", function()
  local diffview_open = false
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == "DiffviewFiles" then
      diffview_open = true
      break
    end
  end

  if diffview_open then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen")
  end
end, {})
