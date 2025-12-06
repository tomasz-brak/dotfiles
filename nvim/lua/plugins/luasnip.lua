return {
  {
    "L3MON4D3/LuaSnip",
    -- follow latest v2.x releases:
    version = "v2.*",
    -- optional: build the faster JS regexp implementation
    build = "make install_jsregexp",
    event = "InsertEnter",
    dependencies = {
      -- latex snippets plugin (will be available when LuaSnip loads)
      "iurimateus/luasnip-latex-snippets.nvim",
    },
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

      -- Configure the latex snippets plugin. Use treesitter to avoid requiring vimtex,
      -- and allow the snippets to work in markdown files.
      local ok2, latex = pcall(require, "luasnip-latex-snippets")
      if ok2 and latex.setup then
        latex.setup {
          use_treesitter = true,     -- set to false if you prefer vimtex detection
          allow_on_markdown = true,  -- allow snippets in markdown
        }
      end

      -- Extra safety: ensure markdown filetype includes tex snippets (redundant if allow_on_markdown = true)
      pcall(function() luasnip.filetype_extend("markdown", { "tex" }) end)
    end,
  },
}
