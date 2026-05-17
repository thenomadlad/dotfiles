local M = {}

---@class KeyHighlight
---@field group string Highlight group name
---@field pos integer[] {line, col, len} as expected by matchaddpos

local KEYBOARD_LAYOUT = {
  { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
  { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]" },
  { "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'" },
  { "z", "x", "c", "v", "b", "n", "m", ",", ".", "/" },
}

local ROW_OFFSETS = { 0, 1, 2, 3 }

local MODE_NAMES = {
  n = "Normal",
  v = "Visual",
  x = "Visual Block",
  s = "Select",
  o = "Operator-pending",
  i = "Insert",
  t = "Terminal",
  c = "Command",
}

--- Returns a map of single key → description for all mappings under prefix.
---@param mode string Vim mode, e.g. "n", "v"
---@param prefix string Key prefix, e.g. "<leader>"
---@return table<string, string>
local function get_mapped_keys(mode, prefix)
  local maps = {}
  local search_prefix = prefix:match "^<leader>" and (vim.g.mapleader .. prefix:sub(9)) or prefix
  local pattern = vim.pesc(search_prefix)

  for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
    local lhs = keymap.lhs or ""
    local key = lhs:match("^" .. pattern .. "(%w)")
    if key then maps[key:lower()] = keymap.desc or keymap.rhs or "[Lua]" end
  end

  return maps
end

local function setup_highlights()
  vim.api.nvim_set_hl(0, "KeyVisualBracketUsed", { link = "DiagnosticOk", default = true })
  vim.api.nvim_set_hl(0, "KeyVisualLetterUsed", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "KeyVisualBracketFree", { link = "NonText", default = true })
  vim.api.nvim_set_hl(0, "KeyVisualLetterFree", { link = "Comment", default = true })
end

--- Builds display lines and highlight positions for the keyboard layout.
---@param maps table<string, string>
---@return string[], KeyHighlight[]
local function build_lines(maps)
  local lines = {}
  local highlights = {}

  for row_idx, row in ipairs(KEYBOARD_LAYOUT) do
    local line = string.rep(" ", ROW_OFFSETS[row_idx])
    local line_num = #lines + 1

    for _, key in ipairs(row) do
      local pos = #line + 1
      local mapped = maps[key] ~= nil
      local bracket_hl = mapped and "KeyVisualBracketUsed" or "KeyVisualBracketFree"
      local letter_hl = mapped and "KeyVisualLetterUsed" or "KeyVisualLetterFree"

      table.insert(highlights, { group = bracket_hl, pos = { line_num, pos, 1 } })
      table.insert(highlights, { group = letter_hl, pos = { line_num, pos + 1, 1 } })
      table.insert(highlights, { group = bracket_hl, pos = { line_num, pos + 2, 1 } })

      line = line .. "[" .. key .. "]"
    end

    table.insert(lines, line)
  end

  return lines, highlights
end

--- Returns the pixel width of the widest keyboard row.
---@return integer
local function compute_width()
  local max = 0
  for i, row in ipairs(KEYBOARD_LAYOUT) do
    local w = (#row * 3) + ROW_OFFSETS[i]
    if w > max then max = w end
  end
  return max
end

--- Returns the key character under the cursor, or nil if not over a key.
---@return string?
local function get_key_at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2] + 1

  if row < 1 or row > #KEYBOARD_LAYOUT then return nil end

  local key_idx = math.floor((col - ROW_OFFSETS[row] - 1) / 3)
  local layout_row = KEYBOARD_LAYOUT[row]

  if key_idx >= 0 and key_idx < #layout_row then return layout_row[key_idx + 1] end
end

---@param lines string[]
---@param highlights KeyHighlight[]
---@param maps table<string, string>
---@param mode string
---@param prefix string
---@return integer win Window handle
local function open_float(lines, highlights, maps, mode, prefix)
  local info_lines = {
    "",
    string.format("Mode: %s   Prefix: %s", MODE_NAMES[mode] or mode:upper(), prefix),
    "",
    "hover over a key to see its mapping",
  }
  local all_lines = vim.list_extend(vim.list_slice(lines), info_lines)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, all_lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false

  local width = compute_width()
  local ui = vim.api.nvim_list_uis()[1]

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.max(width, 40),
    height = #all_lines,
    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - #all_lines) / 2),
    style = "minimal",
    border = "rounded",
  })

  for _, hl in ipairs(highlights) do
    vim.fn.matchaddpos(hl.group, { hl.pos })
  end

  local hint_line = #all_lines
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      local key = get_key_at_cursor()
      local msg = key and (maps[key] and (key .. " → " .. maps[key]) or "no mapping: " .. key)
        or "hover over a key to see its mapping"
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, hint_line - 1, hint_line, false, { msg })
      vim.bo[buf].modifiable = false
    end,
  })

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })

  return win
end

---@param mode? string Vim mode, defaults to "n"
---@param prefix? string Key prefix, defaults to "<leader>"
function M.show(mode, prefix)
  mode = mode or "n"
  prefix = prefix or "<leader>"
  setup_highlights()
  local maps = get_mapped_keys(mode, prefix)
  local lines, highlights = build_lines(maps)
  open_float(lines, highlights, maps, mode, prefix)
end

return M
