-- Add plenary.nvim (submodule) to the runtime path
local plenary_path = vim.fn.fnamemodify("./third_party/plenary.nvim", ":p")
if vim.loop.fs_stat(plenary_path) then
  vim.opt.runtimepath:append(plenary_path)
else
  error("plenary.nvim not found. Did you initialize submodules?")
end

-- Add the plugin being tested to the runtime path
local plugin_path = vim.fn.fnamemodify(".", ":p")
vim.opt.runtimepath:append(plugin_path)

-- Manually load the required plugins
vim.cmd([[runtime! plugin/plenary.vim]])
vim.cmd([[runtime! plugin/load_present.lua]])


-- Set minimal settings for tests
vim.cmd([[set noswapfile]])
vim.cmd([[set noundofile]])
vim.cmd([[set nobackup]])
vim.cmd([[set nowritebackup]])
