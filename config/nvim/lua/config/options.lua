-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.title = true
local opt = vim.opt
-- require("flow").setup({})
-- vim.cmd("colorscheme flow")

vim.opt.listchars = {
  tab = "> ",
  trail = " ",
  nbsp = "+",
}
vim.opt.clipboard = "unnamedplus"
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(_, result, ctx, config)
  local diagnostics = result.diagnostics or {}
  local filtered_diagnostics = {}
  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic.code ~= -32603 then
      table.insert(filtered_diagnostics, diagnostic)
    end
  end
  result.diagnostics = filtered_diagnostics
  vim.lsp.diagnostic.on_publish_diagnostics(nil, result, ctx, config)
end
