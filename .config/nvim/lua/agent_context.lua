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

local function build_github_url(start_line, end_line)
  local remote = vim.fn.trim(vim.fn.system("git remote get-url origin"))
  if vim.v.shell_error ~= 0 or remote == "" then
    vim.notify("No git remote found", vim.log.levels.WARN)
    return nil
  end
  remote = remote:gsub("^git@github%.com:", "https://github.com/")
  remote = remote:gsub("^ssh://git@github%.com/", "https://github.com/")
  remote = remote:gsub("%.git$", "")

  local branch = vim.fn.trim(vim.fn.system("git branch --show-current"))
  if branch == "" then
    branch = vim.fn.trim(vim.fn.system("git rev-parse HEAD"))
  end

  local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
  local abs_path = vim.api.nvim_buf_get_name(0)
  local rel_path = abs_path:sub(#git_root + 2)

  if start_line == end_line then
    return string.format("%s/blob/%s/%s#L%d", remote, branch, rel_path, start_line)
  else
    return string.format("%s/blob/%s/%s#L%d-L%d", remote, branch, rel_path, start_line, end_line)
  end
end

function M.yank_line()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  yank(string.format("@%s:%d", buf_path(), line))
end

function M.yank_range(start_line, end_line)
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
end

function M.yank_github_line()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local url = build_github_url(line, line)
  if url then yank(url) end
end

function M.yank_github_range(start_line, end_line)
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local url = build_github_url(start_line, end_line)
  if url then yank(url) end
end

return M
