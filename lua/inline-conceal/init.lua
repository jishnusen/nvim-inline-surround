local M = {}

M.ns = vim.api.nvim_create_namespace("inline_conceal")

local function replace_in_line(line, conceals, terminal)
  local res = {}

  i = 0
  while i <= #line do
    local fs,fe,conc = nil,nil,nil

    for _,p in ipairs(conceals) do
      local m,c = unpack(p)
      local s,e = string.find(line, m .. terminal, i)
      if s == nil then s,e = string.find(line, m .. "$", i)
      else e = e - 1 end
      if s ~= nil and (fs == nil or s < fs) then
        fs = s
        fe = e
        conc = c
      end
    end

    if conc ~= nil then
      table.insert(res, {conc, fs, fe})
      i = fe
      goto gotmatch
    end

    i = #line+1
    ::gotmatch::
  end

  return res
end

M.terminal_map = {
  tex = "[^%w%^_]"
}
M.symbol_map = {
  tex = require("inline-conceal.syntax.tex")
}

function M.setup(opts)
  if opts.symbol_map then M.symbol_map = opts.symbol_map end
  if opts.terminal_map then M.terminal_map = opts.terminal_map end
  if opts.extra_symbol_map then
    for k,l in pairs(opts.extra_symbol_map) do
      M.symbol_map[k] = M.symbol_map[k] or {}
      for _,p in ipairs(l) do
        table.insert(M.symbol_map[k], p)
      end
    end
  end

  vim.api.nvim_set_decoration_provider(
    M.ns,
    {
      on_win = function(_, win, buf, top, bot)
        local symbols = M.symbol_map[vim.bo[buf].filetype]
        local terminal = M.terminal_map[vim.bo[buf].filetype]
        if symbols == nil or terminal == nil then return end

        local lines = vim.api.nvim_buf_get_lines(buf, top, bot+1, true)
        local cr,cc = unpack(vim.api.nvim_win_get_cursor(0))
        for row = top, bot do
          local line = lines[row - top + 1]
          for _,match in ipairs(replace_in_line(line, symbols, terminal)) do
            local r,s,e = unpack(match)

            if row == cr-1 and s <= cc+1 and cc+1 <= e then goto skipmatch end
            vim.api.nvim_buf_set_extmark(buf, M.ns, row, s - 1, {
              end_row = row,
              end_col = e,
              hl_mode = "combine",
              conceal = r,
              ephemeral = true,
            })
            ::skipmatch::
          end
        end
      end,
    }
  )
end

return M
