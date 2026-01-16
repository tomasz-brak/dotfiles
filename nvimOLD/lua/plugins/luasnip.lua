return {
  {
    "L3MON4D3/LuaSnip",
    -- follow latest v2.x releases:
    version = "v2.*",
    -- optional: build the faster JS regexp implementation
    build = "make install_jsregexp",
    event = "InsertEnter",
    dependencies = {},
    config = function()
      local ok, luasnip = pcall(require, "luasnip")
      if not ok then
        return
      end

      -- Enable autosnippets the supported way:
      -- (README: require("luasnip").config.setup { enable_autosnippets = true })
      luasnip.config.setup {
        enable_autosnippets = true,
      }

      luasnip.filetype_extend("markdown", { "tex" })
    end,
  },
  {
    "evesdropper/luasnip-latex-snippets.nvim",
    lazy = false
  },
}
