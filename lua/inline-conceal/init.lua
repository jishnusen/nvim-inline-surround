local M = {}

M.ns = vim.api.nvim_create_namespace("inline_conceal")

local last_row = nil
local buf_conceals = {}

local function replace_in_line(line, conceals)
  local res = {}
  local matchset = {}

  i = 0
  for _,p in ipairs(conceals) do
    local m,c = unpack(p)
    for s, _, e in line:gmatch(m) do
      if not matchset[s] then
        table.insert(res, {c, s, e-2})
      end
      matchset[s] = true
    end
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
    for k,l in pairs(M.symbol_map) do
      opts.extra_symbol_map[k] = opts.extra_symbol_map[k] or {}
      for _,p in ipairs(l) do
        table.insert(opts.extra_symbol_map[k], p)
      end
    end
    M.symbol_map = opts.extra_symbol_map
  end
  for k,l in pairs(M.symbol_map) do
    for i,p in ipairs(l) do
      M.symbol_map[k][i][1] = "()(" .. M.symbol_map[k][i][1] .. M.terminal_map[k] .. ")()"
    end
  end

  vim.api.nvim_set_decoration_provider(
    M.ns,
    {
      on_win = function(_, win, buf, top, bot)
        if buf_conceals[buf] == nil then buf_conceals[buf] = {} end
        local symbols = M.symbol_map[vim.bo[buf].filetype]
        if symbols == nil then return end

        local cr,cc = unpack(vim.api.nvim_win_get_cursor(0))

        local lines = vim.api.nvim_buf_get_lines(buf, top, bot+1, true)
        for row = top, bot do
          if buf == vim.fn.bufnr() and row == cr-1 then goto skiprow end
          local line = lines[row - top + 1]
          if buf_conceals[buf][row] == nil then
            buf_conceals[buf][row] = replace_in_line(line, symbols)
          end
          for _,match in ipairs(buf_conceals[buf][row]) do
            local r,s,e = unpack(match)
            vim.api.nvim_buf_set_extmark(buf, M.ns, row, s - 1, {
              end_row = row,
              end_col = e,
              hl_mode = "combine",
              conceal = r,
              ephemeral = true,
            })
          end
          ::skiprow::
        end
      end,
      on_line = function(_, win, buf, row)
        if buf ~= vim.fn.bufnr() then return end
        local cr,cc = unpack(vim.api.nvim_win_get_cursor(0))
        if cr-1 ~= row then return end
        local line = vim.api.nvim_buf_get_lines(buf, row, row+1, true)[1]

        local symbols = M.symbol_map[vim.bo[buf].filetype]
        if symbols == nil then return end

        buf_conceals[buf][row] = replace_in_line(line, symbols)
        for _,match in ipairs(buf_conceals[buf][row]) do
          local r,s,e = unpack(match)
          if s <= cc+1 and cc+1 <= e then goto skipmatch end
          vim.api.nvim_buf_set_extmark(buf, M.ns, row, s - 1, {
            end_row = row,
            end_col = e,
            conceal = r,
            ephemeral = true,
          })
          ::skipmatch::
        end
      end,
    }
  )
end

return M
