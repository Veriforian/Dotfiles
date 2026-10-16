-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
--- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_user_command("CopyPath", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

vim.api.nvim_create_user_command("CopyRelativePath", function(context)
  local full_path = vim.fn.expand("%:p")
  local project_marker = { "package.json", "index.js", "init.lua" } -- Adjust based on your project type
  local project_root = vim.fs.root(0, project_marker)
  if project_root == nil then
    vim.print("Could not find project root")
    return
  end
  local relative_path = string.gsub(string.format(".%s", full_path), project_root, "")
  vim.fn.setreg("+", relative_path)
  vim.print("Relative path copied to clipboard: " .. relative_path)
end, { nargs = 0, desc = "Copy relative path from project root to clipboard" })

-- Disable diagnostics for .env files
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.env*", "*.md" },
  group = vim.api.nvim_create_augroup("DisableDiagnostics", { clear = true }),
  callback = function()
    if vim.diagnostic.enable then
      -- Handling for newer nvim
      vim.diagnostic.enable(false, { bufnr = 0 })
    else
      -- Handling for older nvim
      ---@diagnostic disable: deprecated
      vim.diagnostic.disable(0)
    end
  end,
})

-- Prune orphaned ShaDa temp files (E138). Neovim leaves these behind when
-- killed mid-write; with many concurrent instances all 26 slots fill up.
-- Not an autocmd: this file is sourced on VeryLazy, i.e. after VimEnter has
-- already fired, so a VimEnter hook registered here would never run.
vim.schedule(function()
  local dir = vim.fn.stdpath("state") .. "/shada"
  local cutoff = os.time() - 86400 -- older than a day: no live nvim owns it
  for name, t in vim.fs.dir(dir) do
    if t == "file" and name:match("^main%.shada%.tmp%.%a$") then
      local p = dir .. "/" .. name
      local st = vim.uv.fs_stat(p)
      if st and st.mtime.sec < cutoff then
        vim.uv.fs_unlink(p)
      end
    end
  end
end)
