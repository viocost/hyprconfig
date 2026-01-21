return {
  {
    "hrsh7th/nvim-cmp",
  },
  {
    "folke/ts-comments.nvim",
    opts = {},
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },

  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "go",
        "gotmpl",
        "html",
        "javascript",
        "json",
        "latex",
        "lua",
        "markdown",
        "dockerfile",
        "vue",
        "scala",
        "scss",
        "svelte",
        "rust",
        "glimmer",
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
}
