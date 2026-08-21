return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections.lualine_b = vim.tbl_filter(function(component)
        if type(component) == "string" then
          return component ~= "branch"
        end
        if type(component) == "table" and component[1] == "branch" then
          return false
        end
        return true
      end, opts.sections.lualine_b or {})
    end,
  },
}
