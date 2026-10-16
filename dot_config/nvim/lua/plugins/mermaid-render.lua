return {
  "folke/snacks.nvim",
  optional = true,
  init = function()
    local function render(buf)
      if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "mermaid" then
        return
      end
      local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      if vim.trim(content) == "" then
        return
      end

      local cache = Snacks.image.config.cache
      vim.fn.mkdir(cache, "p")
      local hash = vim.fn.sha256(content):sub(1, 8)
      local src = cache .. "/" .. hash .. "-content.chart.mmd"
      if vim.fn.filereadable(src) == 0 then
        local fd = assert(io.open(src, "w"))
        fd:write(content)
        fd:close()
      end

      Snacks.image.placement.clean(buf)
      local lines = vim.api.nvim_buf_line_count(buf)
      Snacks.image.placement.new(buf, src, {
        inline = true,
        pos = { lines, 0 },
        range = { lines, 0, lines, 0 },
        type = "chart",
        auto_resize = true,
      })
    end

    local debounced = {} ---@type table<number, fun()>

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "mermaid",
      callback = function(ev)
        local buf = ev.buf
        local Terminal = require("snacks.image.terminal")
        Terminal.detect(function()
          local env = Terminal.env()
          if not (env.placeholders or env.supported) then
            return
          end
          debounced[buf] = debounced[buf]
            or Snacks.util.debounce(function()
              render(buf)
            end, { ms = 200 })

          local group = vim.api.nvim_create_augroup("mermaid-render-" .. buf, { clear = true })
          vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "InsertLeave" }, {
            buffer = buf,
            group = group,
            callback = function()
              debounced[buf]()
            end,
          })
          vim.api.nvim_create_autocmd("BufWipeout", {
            buffer = buf,
            group = group,
            callback = function()
              debounced[buf] = nil
              Snacks.image.placement.clean(buf)
            end,
          })
          vim.schedule(function()
            render(buf)
          end)
        end)
      end,
    })
  end,
}
