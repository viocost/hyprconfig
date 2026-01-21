-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local unset = vim.keymap.del

-- emacs goodies
map({ "i" }, "<C-f>", "<Right>", { noremap = true, silent = true })
map({ "i" }, "<C-b>", "<Left>", { noremap = true, silent = true })

-- Window management
map({ "n", "x" }, "<leader>wv", "<Space>|", { remap = true, desc = "Split vertical" })
map({ "n", "x" }, "<leader>wq", "<Space>wd", { remap = true, desc = "Close window" })

map({ "n" }, "<leader>wh", "<C-w>h", { remap = true, desc = "Focus to window on left" })
map({ "n" }, "<leader>wl", "<C-w>l", { remap = true, desc = "Focus to window on right" })
map({ "n" }, "<leader>wj", "<C-w>j", { remap = true, desc = "Focus to window on bottom" })
map({ "n" }, "<leader>wk", "<C-w>k", { remap = true, desc = "Focus to window on top" })

map({ "v" }, "<C-_>", "gc", { noremap = true, silent = true })

-- Vimspector
map({ "n" }, "<leader>ds", ":call vimspector#Launch()<CR>", { remap = true, desc = "Start debugging" })
map({ "n" }, "<leader>dr", ":call vimspector#Restart()<CR>", { remap = true, desc = "Retart " })
map({ "n" }, "<leader>dc", ":call vimspector#Continue()<CR>", { remap = true, desc = "Setp out" })
map({ "n" }, "<leader>dR", ":call vimspector#Reset()<CR>", { remap = true, desc = "Reset" })
map({ "n" }, "<leader>dx", ":call vimspector#ClearBreakpoints()<CR>", { remap = true, desc = "Clear all breakpoints" })
map({ "n" }, "<leader>db", ":call vimspector#ToggleBreakpoint()<CR>", { remap = true, desc = "Toggle breakpoit" })
map({ "n" }, "<leader>dn", ":call vimspector#StepOver()<CR>", { remap = true, desc = "Step over" })
map({ "n" }, "<leader>di", ":call vimspector#StepInto()<CR>", { remap = true, desc = "Step into" })
map({ "n" }, "<leader>do", ":call vimspector#StepOut()<CR>", { remap = true, desc = "Setp out" })

map(
  { "n" },
  "gd",
  "<cmd>lua vim.lsp.buf.definition()<CR>",
  { noremap = true, silent = true, desc = "LSP goto definition" }
)
map({ "n" }, "<C-y>", "<cmd>let @+=expand('%')<CR>", { noremap = true, silent = true, desc = "Copy buffer path" })
map(
  { "n" },
  "gD",
  "<cmd>lua vim.lsp.buf.declaration()<CR>",
  { noremap = true, silent = true, desc = "LSP goto declaration" }
)

map("n", "*", function()
  require("telescope-live-grep-args.shortcuts").grep_word_under_cursor({ quote = false, postfix = "" })
end, { remap = true, desc = "Grep word under the cursor" })

map("v", "*", function()
  require("telescope-live-grep-args.shortcuts").grep_visual_selection({ quote = false, postfix = "" })
end, { remap = true, desc = "Grep word under the cursor" })

-- This fixes weird mapping on searching through results, "n" now cycles forward as expected
map({ "n" }, "n", "n", { remap = true, silent = true })

-- Jump to matching parent
map({ "n", "v" }, "<Tab>", "%", { noremap = true, silent = true })

map({ "n", "i" }, "<C-_>", "<C-->", { remap = true, silent = true })

map({ "n" }, "<leader>pp", function()
  require("telescope").extensions.projects.projects({})
end, { desc = "Search projects" })

map({ "n" }, "<leader>pa", "<cmd>ProjectRoot<cr>", { desc = "Add cwd as project root" })
map(
  { "n" },
  "<leader>pl",
  "<cmd>lua print(vim.api.nvim_buf_get_name(0));<cr>",
  { desc = "Print current file full path" }
)

-- iedit TODO
map({ "n" }, "<C-j>", "<Plug>(VM-Add-Cursor-Down)", { remap = true, desc = "Cursor down" })
map({ "n" }, "<C-k>", "<Plug>(VM-Add-Cursor-Up)", { remap = true, desc = "Cursor up" })

map({ "n" }, "<leader>;", "<Plug>(VM-Select-All)", { remap = true, desc = "Select all words", silent = true })
map({ "v" }, "<leader>;", "<Plug>(VM-Visual-All)", { remap = true, desc = "Select all words", silent = true })

-- map({ "n" }, "<leader>gg", "<leader>gG", { remap = true, desc = "Lazygit" })
map({ "n" }, "<leader>gg", "<CMD>Neogit<CR>", { remap = true, desc = "Neogit" })
map({ "n" }, "<leader>gd", "<CMD>DiffviewToggle<CR>", { remap = true, desc = "Diffview" })
map({ "n" }, "<leader>gb", "<CMD>BlameToggle virtual<CR>", { remap = true, desc = "Blame" })

-- buffer

map({ "n" }, "<leader>b[", "<CMD>bp<CR>", { remap = true, desc = "Previous buffer" })
map({ "n" }, "<leader>b]", "<CMD>bn<CR>", { remap = true, desc = "Next buffer" })
map({ "n" }, "<leader>bk", "<leader>bd", { remap = true, desc = "Kill current buffer" })
map({ "n" }, "<leader>bK", "<leader>bD", { remap = true, desc = "Kill current buffer (Force)" })
map({ "n" }, "<leader>bb", "<leader>be", { remap = true, desc = "Buffer explorer" })
unset("n", ";")
unset("v", ";")

unset("n", "t")
unset("v", "t")

map({ "n" }, "t", '<cmd>lua require("viedit").toggle_single()<CR>', {
  desc = "viedit mode",
})

map({ "v" }, "t", '<cmd>lua require("viedit").toggle_single()<CR>', {
  desc = "viedit mode",
})

map({ "n" }, "<C-;>", '<cmd>lua require("viedit").toggle_single()<CR>', {
  desc = "viedit mode",
})

map({ "n" }, ";", '<cmd>lua require("viedit").toggle_all()<CR>', {
  desc = "viedit mode",
})

map({ "v" }, ";", '<cmd>lua require("viedit").toggle_all()<CR>', {
  desc = "viedit mode",
})

map({ "n" }, "<leader>rr", '<cmd>lua require("viedit").reload()<CR>', {
  desc = "vedit mode reload",
})

map({ "n" }, "<leader>rf", '<cmd>lua require("viedit").restrict_to_function()<CR>', {
  desc = "restrict to function",
})

vim.api.nvim_create_user_command("Q", "qa", {})
vim.cmd([[cnoreabbrev <expr> q getcmdtype() == ':' && getcmdline() == 'q' ? 'Q' : 'q']])
