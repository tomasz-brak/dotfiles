return {
  "nvim-neorg/neorg",
  build = ":Neorg sync-parsers",
  opts = {
    load = {
      ["core.defaults"] = {}, -- Loads default behaviour
      ["core.concealer"] = {}, -- Adds pretty icons to your documents
      ["core.dirman"] = { -- Manages Neorg workspaces
        config = {
          workspaces = {
            notes = "~/note",
          },
          default_workspace = "note",
        },
      },
      ["core.completion"] = {
        config = {
          engine = "nvim-cmp"
        }
      },
      ["core.integrations.nvim-cmp"] = {

      },
      ["core.latex.renderer"] = {
        config = {
render_on_enter = true,
        }
      }
    },
  },
}
