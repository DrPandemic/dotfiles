-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>sG", function()
  local cwd = vim.fn.expand("%:p:h")
  if cwd == "" then
    cwd = vim.fn.getcwd()
  end
  LazyVim.pick("live_grep", { cwd = cwd })()
end, { desc = "Grep (File Dir)" })

vim.keymap.set("n", "<leader>ff", function()
  local cwd = vim.fn.expand("%:p:h")
  if cwd == "" then
    cwd = vim.fn.getcwd()
  end
  LazyVim.pick("files", { cwd = cwd })()
end, { desc = "Find Files (File Dir)" })

vim.keymap.set("n", "<leader>pf", function()
  local group = vim.api.nvim_create_augroup("PfStripPrefix", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "snacks_picker_input",
    once = true,
    callback = function(args)
      vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
        group = group,
        buffer = args.buf,
        callback = function()
          local line = vim.api.nvim_buf_get_lines(args.buf, 0, 1, false)[1] or ""
          local stripped = line:gsub("^areas/core/shopify/", "", 1)
          if stripped ~= line then
            vim.api.nvim_buf_set_lines(args.buf, 0, 1, false, { stripped })
            pcall(vim.api.nvim_win_set_cursor, 0, { 1, #stripped })
          end
        end,
      })
      vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        buffer = args.buf,
        once = true,
        callback = function()
          pcall(vim.api.nvim_del_augroup_by_id, group)
        end,
      })
    end,
  })
  LazyVim.pick("files", { root = false })()
end, { desc = "Find Files (cwd)" })

vim.keymap.set({ "n", "x" }, "<leader>*", "<leader>sw", { remap = true, desc = "Word or Selection (Root Dir)" })
vim.keymap.set("n", "<leader>/", "<leader>sg", { remap = true, desc = "Grep (Root Dir)" })
