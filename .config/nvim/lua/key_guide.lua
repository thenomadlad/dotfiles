-- key_guide.lua
-- Interactive prefix navigator with live keyboard heatmap.
-- Left panel: which-key style column list. Right panel: QWERTY keyboard highlighting available keys.
-- Core loop: open float at bottom → read one char → navigate or execute → repeat.

local M               = {}

-- ── constants ──────────────────────────────────────────────────────────────

local SEPARATOR       = " → "
local MAX_DESC        = 30

local KEYBOARD_LAYOUT = {
  { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
  { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]" },
  { "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'" },
  { "z", "x", "c", "v", "b", "n", "m", ",", ".", "/" },
}
local ROW_OFFSETS     = { 0, 1, 2, 3 }
local KBD_WIDTH       = 49                      -- widest row: 12 keys × 4 chars + 1 offset
local KBD_HEIGHT      = 4                       -- number of keyboard rows
local GUTTER          = 2                       -- spaces between list and keyboard panels
local MIN_COLS_KBD    = KBD_WIDTH + GUTTER + 20 -- 71: minimum columns to show keyboard

-- shifted character for each symbol key (letters just use :upper())
local SHIFT_MAP       = {
  ["1"] = "!",
  ["2"] = "@",
  ["3"] = "#",
  ["4"] = "$",
  ["5"] = "%",
  ["6"] = "^",
  ["7"] = "&",
  ["8"] = "*",
  ["9"] = "(",
  ["0"] = ")",
  ["-"] = "_",
  ["="] = "+",
  ["["] = "{",
  ["]"] = "}",
  [";"] = ":",
  ["'"] = '"',
  [","] = "<",
  ["."] = ">",
  ["/"] = "?",
}

local KBD_NS          = vim.api.nvim_create_namespace("key_guide_kbd")

-- ── highlights ─────────────────────────────────────────────────────────────

local function setup_highlights()
  -- Resolve String's fg at setup time so we can pair it with bold=true.
  -- (nvim_set_hl ignores extra attrs when `link` is set, so we do it manually.)
  local string_fg = vim.api.nvim_get_hl(0, { name = "String", link = false }).fg
  vim.api.nvim_set_hl(0, "KeyGuideNormal", { bg = "#1e1e2e", fg = "#cdd6f4", default = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdBracketUsed", { link = "String", default = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdLetterUsed", { fg = string_fg, bold = true, default = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdBracketFree", { link = "NonText", default = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdLetterFree", { link = "Comment", default = true })
end

-- ── keymap querying ────────────────────────────────────────────────────────

---@param lhs string
---@return string
local function normalize_lhs(lhs)
  if vim.g.mapleader and vim.g.mapleader ~= "" then
    lhs = lhs:gsub("^" .. vim.pesc(vim.g.mapleader), "<leader>")
  end
  return lhs
end

--- First key token from a string: handles <C-x>, <leader>, plain chars.
---@param s string
---@return string
local function next_token(s) return s:match "^(<[^>]+>)" or s:sub(1, 1) end

--- Returns immediate children of prefix in mode (global + buffer-local maps).
---@param mode string Vim mode, e.g. "n", "v"
---@param prefix string Key prefix to look up children for
---@return KeyChild[]
local function get_children(mode, prefix)
  local keymaps = {}
  vim.list_extend(keymaps, vim.api.nvim_get_keymap(mode))
  vim.list_extend(keymaps, vim.api.nvim_buf_get_keymap(0, mode))

  local seen     = {}
  local children = {}

  for _, km in ipairs(keymaps) do
    local lhs = normalize_lhs(km.lhs)
    if vim.startswith(lhs, prefix) and #lhs > #prefix then
      local key = next_token(lhs:sub(#prefix + 1))
      if key and not seen[key] then
        seen[key]      = true
        local full     = prefix .. key
        local is_group = false
        for _, km2 in ipairs(keymaps) do
          if vim.startswith(normalize_lhs(km2.lhs), full) and #normalize_lhs(km2.lhs) > #full then
            is_group = true
            break
          end
        end
        children[#children + 1] = {
          key   = key,
          desc  = km.desc or (type(km.rhs) == "string" and km.rhs ~= "" and km.rhs) or "[Lua]",
          group = is_group,
        }
      end
    end
  end

  table.sort(children, function(a, b)
    if a.group ~= b.group then return a.group end
    return a.key:lower() < b.key:lower()
  end)

  return children
end

-- ── keyboard panel ─────────────────────────────────────────────────────────

--- Build keyboard ASCII lines and raw highlight entries from children.
--- Each key is rendered as [xX] — 4 chars — with lower and upper highlighted independently.
--- Highlights use 0-indexed line (within kbd block) and 0-indexed byte column offsets.
---@param children KeyChild[]
---@return string[], table[]
local function build_kbd_lines(children)
  -- case-sensitive: "a" and "A" are distinct entries
  local mapped = {}
  for _, child in ipairs(children) do
    if #child.key == 1 then mapped[child.key] = true end
  end

  local lines      = {}
  local highlights = {}

  for row_idx, row in ipairs(KEYBOARD_LAYOUT) do
    local line   = string.rep(" ", ROW_OFFSETS[row_idx])
    local line_0 = #lines -- 0-indexed line within this block

    for _, key in ipairs(row) do
      local shifted               = key:match("^%l$") and key:upper() or (SHIFT_MAP[key] or key)
      local lo_map                = mapped[key] == true
      local hi_map                = mapped[shifted] == true
      local any_map               = lo_map or hi_map

      local br_hl                 = any_map and "KeyGuideKbdBracketUsed" or "KeyGuideKbdBracketFree"
      local lo_hl                 = lo_map and "KeyGuideKbdLetterUsed" or "KeyGuideKbdLetterFree"
      local hi_hl                 = hi_map and "KeyGuideKbdLetterUsed" or "KeyGuideKbdLetterFree"

      local cs                    = #line -- 0-indexed byte col of the opening bracket
      highlights[#highlights + 1] = { line = line_0, cs = cs, ce = cs + 1, group = br_hl }
      highlights[#highlights + 1] = { line = line_0, cs = cs + 1, ce = cs + 2, group = lo_hl }
      highlights[#highlights + 1] = { line = line_0, cs = cs + 2, ce = cs + 3, group = hi_hl }
      highlights[#highlights + 1] = { line = line_0, cs = cs + 3, ce = cs + 4, group = br_hl }

      line                        = line .. "[" .. key .. shifted .. "]"
    end

    lines[#lines + 1] = line
  end

  return lines, highlights
end

-- ── rendering ──────────────────────────────────────────────────────────────

--- Build combined buffer lines and absolute buffer highlights.
--- Buffer structure (0-indexed):
---   line 0: blank
---   line 1: "  <prefix>…"  (header)
---   line 2: blank
---   lines 3..(3+body_height-1): merged list + keyboard body
---   last line: blank footer
---@param children KeyChild[]
---@param prefix string
---@return string[], table[]
local function render(children, prefix)
  local show_kbd   = vim.o.columns >= MIN_COLS_KBD
  local list_width = show_kbd and (vim.o.columns - KBD_WIDTH - GUTTER) or (vim.o.columns - 4)

  -- ── list panel ──────────────────────────────────────────────────────────
  local max_key    = 0
  for _, item in ipairs(children) do max_key = math.max(max_key, #item.key) end
  local col_width = max_key + #SEPARATOR + 1 + MAX_DESC
  local ncols     = math.max(1, math.floor((list_width - 4) / (col_width + 2)))
  local nrows     = (#children == 0) and 1 or math.ceil(#children / ncols)

  local list_body = {}
  if #children == 0 then
    list_body[1] = "  (no mappings for " .. prefix .. ")"
  else
    for row = 1, nrows do
      local parts = {}
      for col = 1, ncols do
        local item = children[(col - 1) * nrows + row]
        if item then
          local key_pad = string.rep(" ", max_key - #item.key) .. item.key
          local desc    = item.desc
          if #desc > MAX_DESC then desc = desc:sub(1, MAX_DESC - 1) .. "…" end
          local marker      = item.group and "+" or " "
          parts[#parts + 1] = key_pad .. SEPARATOR .. marker .. desc
        end
      end
      list_body[#list_body + 1] = "  " .. table.concat(parts, "  ")
    end
  end

  -- ── keyboard panel ──────────────────────────────────────────────────────
  local kbd_lines, kbd_hl_raw = {}, {}
  if show_kbd then kbd_lines, kbd_hl_raw = build_kbd_lines(children) end

  -- ── merge into single buffer lines ──────────────────────────────────────
  local body_height = math.max(nrows, show_kbd and KBD_HEIGHT or 0)

  local function lpad(s, width)
    if #s >= width then return s:sub(1, width) end
    return s .. string.rep(" ", width - #s)
  end

  local lines = { "", "  " .. prefix .. "…", "" }

  for i = 1, body_height do
    local left  = list_body[i] or ""
    local right = (show_kbd and kbd_lines[i]) or ""
    if show_kbd then
      lines[#lines + 1] = lpad(left, list_width) .. string.rep(" ", GUTTER) .. right
    else
      lines[#lines + 1] = left
    end
  end
  lines[#lines + 1] = "" -- footer blank

  -- ── translate keyboard highlights to absolute buffer coordinates ─────────
  -- Keyboard block starts at buffer line 3 (0-indexed), col offset = list_width + GUTTER
  local highlights  = {}
  local kbd_col_off = show_kbd and (list_width + GUTTER) or 0
  for _, hl in ipairs(kbd_hl_raw) do
    highlights[#highlights + 1] = {
      line  = 3 + hl.line,
      cs    = kbd_col_off + hl.cs,
      ce    = kbd_col_off + hl.ce,
      group = hl.group,
    }
  end

  return lines, highlights
end

-- ── window management ──────────────────────────────────────────────────────

---@class WinState
---@field win integer?
---@field buf integer?
local w = { win = nil, buf = nil }

---@param lines string[]
---@param highlights table[]
local function open_win(lines, highlights)
  local max_height = math.max(1, vim.o.lines - vim.o.cmdheight - 2)
  local height     = math.min(#lines, max_height)
  local row        = math.max(0, vim.o.lines - height - vim.o.cmdheight - 1)

  if not (w.buf and vim.api.nvim_buf_is_valid(w.buf)) then
    w.buf                   = vim.api.nvim_create_buf(false, true)
    vim.bo[w.buf].bufhidden = "wipe"
    vim.bo[w.buf].filetype  = "keyguide"
  end

  vim.bo[w.buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(w.buf, KBD_NS, 0, -1)
  vim.api.nvim_buf_set_lines(w.buf, 0, -1, false, lines)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(w.buf, KBD_NS, hl.group, hl.line, hl.cs, hl.ce)
  end
  vim.bo[w.buf].modifiable = false

  local cfg = {
    relative  = "editor",
    row       = row,
    col       = 0,
    width     = vim.o.columns,
    height    = height,
    style     = "minimal",
    focusable = false,
    noautocmd = true,
    zindex    = 200,
  }

  if w.win and vim.api.nvim_win_is_valid(w.win) then
    vim.api.nvim_win_set_config(w.win, cfg)
  else
    w.win = vim.api.nvim_open_win(w.buf, false, cfg)
    vim.wo[w.win].winhighlight = "Normal:KeyGuideNormal,EndOfBuffer:KeyGuideNormal"
  end
end

local function close_win()
  if w.win and vim.api.nvim_win_is_valid(w.win) then
    pcall(vim.api.nvim_win_close, w.win, true)
  end
  w.win = nil
  w.buf = nil
end

-- ── main loop ──────────────────────────────────────────────────────────────

---@param mode? string Vim mode, defaults to "n"
---@param initial_prefix? string Starting prefix, defaults to ""
function M.start(mode, initial_prefix)
  mode         = mode or "n"
  local prefix = initial_prefix or ""

  setup_highlights()

  while true do
    local children          = get_children(mode, prefix)
    local lines, highlights = render(children, prefix)
    open_win(lines, highlights)
    vim.cmd.redraw()

    local ok, char = pcall(vim.fn.getcharstr)
    if not ok then
      close_win()
      break
    end

    local key = vim.fn.keytrans(char)

    if key == "<Esc>" then
      close_win()
      break
    elseif key == "<BS>" then
      if prefix == initial_prefix then
        close_win()
        break
      end
      local last = prefix:match "(<[^>]+>)$" or prefix:sub(-1)
      prefix = prefix:sub(1, #prefix - #last)
    else
      prefix = prefix .. key
      if #get_children(mode, prefix) == 0 then
        close_win()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(prefix, true, true, true), "mit", false)
        break
      end
    end
  end
end

return M
