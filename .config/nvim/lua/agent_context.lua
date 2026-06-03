-- Yank @filepath:line references for coding agents (Cursor, etc.)

local M = {}

local function buf_path()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return "[No Name]"
  end
  local rel = vim.fn.fnamemodify(name, ":.")
  if rel ~= "" and rel:sub(1, 1) ~= "/" then
    return rel
  end
  return vim.fn.fnamemodify(name, ":~")
end

local function yank(text)
  vim.fn.setreg('"', text)
  vim.fn.setreg('+', text)
end

function M.yank_line()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  yank(string.format("@%s:%d", buf_path(), line))
end

function M.yank_range()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local ref
  if start_line == end_line then
    ref = string.format("@%s:%d", buf_path(), start_line)
  else
    ref = string.format("@%s:%d-%d", buf_path(), start_line, end_line)
  end
  yank(ref)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

return M
