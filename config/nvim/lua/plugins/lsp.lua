return {

  {
    "williamboman/mason.nvim",
  },
  {
    "williamboman/mason-lspconfig.nvim",
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      ---@type lspconfig.options
      servers = {
        ts_ls = {},
        volar = {},
        ast_grep = {},
      },
      setup = {
        volar = function()
          require("lspconfig").volar.setup({
            -- add filetypes for typescript, javascript and vue
            filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
            init_options = {
              vue = {
                -- disable hybrid mode
                hybridMode = false,
              },
            },
          })
          return true
        end,
        vtsls = function()
          return true
        end,

        eslint = function()
          require("lspconfig").eslint.setup({
            --- ...
            on_attach = function(client, bufnr)
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                command = "EslintFixAll",
              })
            end,
          })
          return true
        end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
        ["*"] = function(server, opts)
          -- print("SERVER ", server)
        end,
      },
    },
  },
}
