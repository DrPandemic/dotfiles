return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          projects = {
            dev = {
              "~/world/trees/main/src/areas/core",
              "~/world/trees/root/src/areas/core",
              "~/world/trees/ws0/src/areas/core",
              "~/world/trees/ws1/src/areas/core",
            },
            transform = function(item)
              local tree, project = item.file:match("/trees/([^/]+)/.*/([^/]+)$")
              if tree and project then
                item.label = tree .. "/" .. project
              end
            end,
          },
        },
      },
    },
  },
}
