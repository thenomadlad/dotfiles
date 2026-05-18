-- key_guide.lua
-- Blocking prefix navigator with keyboard heatmap (which-key style).
-- Captures input via getcharstr(), shows nui panels, replays the completed sequence.

local M               = {}

local Layout          = require("nui.layout")
local Popup           = require("nui.popup")
local key_stats       = require("key_stats")
local key_hints       = require("key_hints")
key_stats.setup()

-- Defer hardtime hook until plugins are loaded; safe no-op if not installed.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once    = true,
  callback = function() pcall(key_hints.setup) end,
})
-- Also attempt immediately in case this loads after VeryLazy has already fired.
pcall(key_hints.setup)

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
local KBD_WIDTH       = 49 -- widest row: offset 1 + 12 keys × 4 chars
local KBD_HEIGHT      = 4

local WIDE_MIN        = 120 -- cols for: left-list | kbd | right-list
local NARROW_MIN      = 71  -- cols for: stacked-lists | kbd

local LIST_MAX_WIDE   = 10  -- items shown per side in wide mode
local LIST_MAX_NARROW = 5   -- items per stacked panel in narrow mode

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

local LEFT_KEYS       = {}
do
  local bases = { "1", "2", "3", "4", "5", "6",
    "q", "w", "e", "r", "t",
    "a", "s", "d", "f", "g",
    "z", "x", "c", "v", "b" }
  for _, k in ipairs(bases) do
    LEFT_KEYS[k] = true
    LEFT_KEYS[k:match("^%l$") and k:upper() or (SHIFT_MAP[k] or k)] = true
  end
end

-- Built-in normal-mode actions that don't appear in nvim_get_keymap. User
-- mappings take precedence; this just fills in the gaps so the heatmap and
-- lists reflect what vim itself does at a given prefix.
local DEFAULT_VIM_KEYS = {
  [""] = {
    -- motion
    h = "left",
    j = "down",
    k = "up",
    l = "right",
    w = "next word",
    W = "next WORD",
    b = "prev word",
    B = "prev WORD",
    e = "end of word",
    E = "end of WORD",
    ["0"] = "line start",
    ["$"] = "line end",
    ["^"] = "first non-blank",
    H = "screen top",
    M = "screen middle",
    L = "screen bottom",
    G = "buffer end",
    ["%"] = "match pair",
    ["{"] = "prev paragraph",
    ["}"] = "next paragraph",
    -- search
    n = "next match",
    N = "prev match",
    ["*"] = "search word fwd",
    ["#"] = "search word back",
    ["/"] = "search fwd",
    ["?"] = "search back",
    f = "find char",
    F = "find char back",
    t = "till char",
    T = "till char back",
    [";"] = "repeat f/t",
    [","] = "reverse f/t",
    -- edit
    d = "delete (op)",
    c = "change (op)",
    y = "yank (op)",
    p = "paste after",
    P = "paste before",
    x = "delete char",
    X = "delete char back",
    s = "substitute char",
    S = "substitute line",
    r = "replace char",
    R = "Replace mode",
    ["~"] = "toggle case",
    J = "join lines",
    u = "undo",
    ["."] = "repeat",
    -- insert/visual
    i = "insert",
    I = "insert at start",
    a = "append",
    A = "append at end",
    o = "open below",
    O = "open above",
    v = "Visual",
    V = "Visual line",
    -- cmdline
    [":"] = "command",
  },
}

local KBD_NS = vim.api.nvim_create_namespace("key_guide_kbd")

-- ── highlights ─────────────────────────────────────────────────────────────

local function setup_highlights()
  vim.api.nvim_set_hl(0, "KeyGuideNormal", { bg = "#1e1e2e", fg = "#cdd6f4", default = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdBracketUsed", { link = "String", default = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdBracketFree", { link = "NonText", default = true })

  -- Letter tiers by usage frequency (within the current prefix).
  --   Unused = key has no mapping/default action
  --   Cold   = mapped but never pressed
  --   Cool   = low frequency
  --   Normal = mid frequency
  --   Warm   = high
  --   Hot    = top of the distribution
  vim.api.nvim_set_hl(0, "KeyGuideKbdLetterUnused", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdLetterCold", { link = "Function", default = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdLetterCool", { link = "String", default = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdLetterNormal", { link = "String", default = true, bold = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdLetterWarm", { link = "Type", default = true, bold = true })
  vim.api.nvim_set_hl(0, "KeyGuideKbdLetterHot", { link = "WarningMsg", default = true, bold = true })
  -- Hint footer
  vim.api.nvim_set_hl(0, "KeyGuideHintHardtime", { link = "WarningMsg", default = true })
  vim.api.nvim_set_hl(0, "KeyGuideHintFreq", { link = "Comment", default = true })
end

-- ── keymap querying ────────────────────────────────────────────────────────

local function normalize_lhs(lhs)
  if vim.g.mapleader and vim.g.mapleader ~= "" then
    lhs = lhs:gsub("^" .. vim.pesc(vim.g.mapleader), "<leader>")
  end
  return lhs
end

--- Map a raw getcharstr() byte to the token used in prefix strings.
--- Direct byte comparison for the leader is more reliable than keytrans.
local function normalize_key(raw)
  if vim.g.mapleader and vim.g.mapleader ~= "" and raw == vim.g.mapleader then
    return "<leader>"
  end
  return vim.fn.keytrans(raw)
end

local function next_token(s) return s:match "^(<[^>]+>)" or s:sub(1, 1) end

local function get_children(mode, prefix)
  local keymaps = {}
  vim.list_extend(keymaps, vim.api.nvim_get_keymap(mode))
  vim.list_extend(keymaps, vim.api.nvim_buf_get_keymap(0, mode))

  local seen, children = {}, {}
  for _, km in ipairs(keymaps) do
    local lhs = normalize_lhs(km.lhs)
    if vim.startswith(lhs, prefix) and #lhs > #prefix then
      local key = next_token(lhs:sub(#prefix + 1))
      if key and not seen[key] then
        seen[key]    = true
        local full   = prefix .. key
        local is_grp = false
        for _, km2 in ipairs(keymaps) do
          if vim.startswith(normalize_lhs(km2.lhs), full) and #normalize_lhs(km2.lhs) > #full then
            is_grp = true; break
          end
        end
        children[#children + 1] = {
          key        = key,
          desc       = km.desc or (type(km.rhs) == "string" and km.rhs ~= "" and km.rhs) or "[Lua]",
          group      = is_grp,
          is_default = false,
        }
      end
    end
  end

  -- Merge in built-in vim keys (normal mode only). User mappings already in
  -- `seen` win; this only fills the gaps.
  if mode == "n" then
    local defaults = DEFAULT_VIM_KEYS[prefix]
    if defaults then
      for key, desc in pairs(defaults) do
        if not seen[key] then
          seen[key] = true
          children[#children + 1] = { key = key, desc = desc, group = false, is_default = true }
        end
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

-- ── heatmap tier bucketing ─────────────────────────────────────────────────

-- Given a { key → score } map, return { key → tier_hl_suffix } where suffix
-- is one of: Hot / Warm / Normal / Cool / Cold / Unused.
-- Tier boundaries are computed from the distribution so they adapt to each
-- prefix rather than a fixed global threshold.
local function compute_tiers(mapped_keys, scores)
  -- Collect scores for keys that actually appear as children (mapped).
  local values = {}
  for key in pairs(mapped_keys) do
    local s = scores[key] or 0
    values[#values + 1] = s
  end
  table.sort(values)

  local n = #values
  -- Percentile thresholds: top 10% hot, next 25% warm, next 40% normal, rest cool.
  local function pct(p) return values[math.max(1, math.floor(n * p))] or 0 end
  local hot_min  = pct(0.90)
  local warm_min = pct(0.65)
  local norm_min = pct(0.25)
  -- Any score > 0 is at least Cool; zero means Cold (mapped but never pressed).

  local tiers = {}
  for key in pairs(mapped_keys) do
    local s = scores[key] or 0
    local t
    if     hot_min  > 0 and s >= hot_min  then t = "Hot"
    elseif warm_min > 0 and s >= warm_min then t = "Warm"
    elseif norm_min > 0 and s >= norm_min then t = "Normal"
    elseif s > 0                           then t = "Cool"
    else                                        t = "Cold"
    end
    tiers[key] = "KeyGuideKbdLetter" .. t
  end
  return tiers
end

local function build_kbd_lines(children, scores)
  scores = scores or {}
  local mapped = {}
  for _, child in ipairs(children) do
    if #child.key == 1 then mapped[child.key] = true end
  end

  local tiers = compute_tiers(mapped, scores)

  local lines, highlights = {}, {}
  for row_idx, row in ipairs(KEYBOARD_LAYOUT) do
    local line   = string.rep(" ", ROW_OFFSETS[row_idx])
    local line_0 = #lines

    for _, key in ipairs(row) do
      local shifted = key:match("^%l$") and key:upper() or (SHIFT_MAP[key] or key)
      local lo_map  = mapped[key] == true
      local hi_map  = mapped[shifted] == true
      local any_map = lo_map or hi_map

      local br_hl = any_map and "KeyGuideKbdBracketUsed" or "KeyGuideKbdBracketFree"
      local lo_hl = tiers[key]     or (lo_map and "KeyGuideKbdLetterCold" or "KeyGuideKbdLetterUnused")
      local hi_hl = tiers[shifted] or (hi_map and "KeyGuideKbdLetterCold" or "KeyGuideKbdLetterUnused")

      local cs                    = #line
      highlights[#highlights + 1] = { line = line_0, cs = cs, ce = cs + 1, group = br_hl }
      highlights[#highlights + 1] = { line = line_0, cs = cs + 1, ce = cs + 2, group = lo_hl }
      highlights[#highlights + 1] = { line = line_0, cs = cs + 2, ce = cs + 3, group = hi_hl }
      highlights[#highlights + 1] = { line = line_0, cs = cs + 3, ce = cs + 4, group = br_hl }

      line = line .. "[" .. key .. shifted .. "]"
    end
    lines[#lines + 1] = line
  end
  return lines, highlights
end

-- ── list rendering ─────────────────────────────────────────────────────────

local function bucket(children)
  local left, right = {}, {}
  for _, c in ipairs(children) do
    if #c.key == 1 and LEFT_KEYS[c.key] then
      left[#left + 1] = c
    else
      right[#right + 1] = c
    end
  end
  return left, right
end

-- Sort by: hint_count desc → custom before default → score desc → key asc.
local function sort_children(children, scores, hint_counts)
  local sorted = {}
  for _, c in ipairs(children) do sorted[#sorted + 1] = c end
  table.sort(sorted, function(a, b)
    local ha = hint_counts and (hint_counts[a.key] or 0) or 0
    local hb = hint_counts and (hint_counts[b.key] or 0) or 0
    if ha ~= hb then return ha > hb end
    if a.is_default ~= b.is_default then return not a.is_default end
    local sa = scores and (scores[a.key] or 0) or 0
    local sb = scores and (scores[b.key] or 0) or 0
    if sa ~= sb then return sa > sb end
    return a.key:lower() < b.key:lower()
  end)
  return sorted
end

local function top_n(list, n)
  local r = {}
  for i = 1, math.min(n, #list) do r[i] = list[i] end
  return r
end

local function compute_list_rows(children, width)
  if #children == 0 then return 1 end
  local max_key = 0
  for _, c in ipairs(children) do max_key = math.max(max_key, #c.key) end
  local cw   = max_key + #SEPARATOR + 1 + MAX_DESC
  local ncol = math.max(1, math.floor(width / (cw + 2)))
  return math.ceil(#children / ncol)
end

--- Returns at most max_height lines.
--- opts.show_header (default true): prepend the "  <prefix>…" header line.
local function render_list_lines(children, width, max_height, prefix, opts)
  local show_header = not (opts and opts.show_header == false)
  local lines       = show_header and { "  " .. prefix .. "…" } or {}
  local item_limit  = show_header and (max_height - 1) or max_height

  if #children == 0 then
    if show_header then lines[#lines + 1] = "  (none)" end
    return lines
  end

  local max_key = 0
  for _, c in ipairs(children) do max_key = math.max(max_key, #c.key) end
  local cw   = max_key + #SEPARATOR + 1 + MAX_DESC
  local ncol = math.max(1, math.floor(width / (cw + 2)))
  local nrow = math.ceil(#children / ncol)

  for row = 1, math.min(nrow, item_limit) do
    local parts = {}
    for col = 1, ncol do
      local item = children[(col - 1) * nrow + row]
      if item then
        local key_pad = string.rep(" ", max_key - #item.key) .. item.key
        local desc    = item.desc
        if #desc > MAX_DESC then desc = desc:sub(1, MAX_DESC - 1) .. "…" end
        parts[#parts + 1] = key_pad .. SEPARATOR .. (item.group and "+" or " ") .. desc
      end
    end
    lines[#lines + 1] = "  " .. table.concat(parts, "  ")
  end
  return lines
end

-- ── popup helpers ──────────────────────────────────────────────────────────

local function make_popup()
  return Popup {
    border      = "none",
    focusable   = false,
    zindex      = 200,
    win_options = {
      winhighlight = "Normal:KeyGuideNormal,EndOfBuffer:KeyGuideNormal",
    },
    buf_options = {
      bufhidden = "wipe",
      filetype  = "keyguide",
    },
  }
end

local function fill_popup(popup, lines, highlights)
  local buf = popup.bufnr
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(buf, KBD_NS, 0, -1)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  if highlights then
    for _, hl in ipairs(highlights) do
      vim.api.nvim_buf_add_highlight(buf, KBD_NS, hl.group, hl.line, hl.cs, hl.ce)
    end
  end
  vim.bo[buf].modifiable = false
end

--- Append a hint footer line to an already-filled list popup.
local function append_hint_footer(popup, hint, width)
  if not hint then return end
  local buf = popup.bufnr
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  local hl  = hint.kind == "hardtime" and "KeyGuideHintHardtime" or "KeyGuideHintFreq"
  local prefix_str = hint.kind == "hardtime" and "  hint: " or "  "
  local text = prefix_str .. hint.text
  if width and #text > width then text = text:sub(1, width - 1) .. "…" end
  vim.bo[buf].modifiable = true
  local last = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_buf_set_lines(buf, last, last, false, { text })
  vim.api.nvim_buf_add_highlight(buf, KBD_NS, hl, last, 0, -1)
  vim.bo[buf].modifiable = false
end

local function shift_kbd_hl(raw, offset)
  local out = {}
  for _, hl in ipairs(raw) do
    out[#out + 1] = { line = hl.line + offset, cs = hl.cs, ce = hl.ce, group = hl.group }
  end
  return out
end

-- ── layout state ───────────────────────────────────────────────────────────

local panels = {
  layout = nil,
  height = 0,
  row = 0,
  mode = nil,
  list1 = nil,
  kbd = nil,
  list2 = nil
}

-- Autocmds waiting to reopen the guide after fed keys settle. Lives in an
-- augroup so we can clear all of them in one shot.
local RESUME_AUGROUP = vim.api.nvim_create_augroup("KeyGuideResume", { clear = true })

local function clear_pending_resume()
  vim.api.nvim_clear_autocmds({ group = RESUME_AUGROUP })
end

local function compute_row(height)
  local lines_below = vim.fn.line("w$") - vim.fn.line(".")
  if lines_below < height then return 0 end
  return math.max(0, vim.o.lines - height - vim.o.cmdheight - 1)
end

local function layout_mode(cols)
  if cols >= WIDE_MIN then
    return "wide"
  elseif cols >= NARROW_MIN then
    return "narrow"
  else
    return "minimal"
  end
end

local function close_panels()
  if panels.layout then
    pcall(function() panels.layout:unmount() end)
  end
  panels.layout = nil; panels.height = 0; panels.row = 0; panels.mode = nil
  panels.list1  = nil; panels.kbd = nil; panels.list2 = nil
end

local function open_panels(children, prefix, vim_mode)
  close_panels()

  local cols                = vim.o.columns
  local max_h               = math.max(1, vim.o.lines - vim.o.cmdheight - 2)
  local mode                = layout_mode(cols)

  local scores              = key_stats.get(vim_mode or "n", prefix)
  local left_ch, right_ch   = bucket(children)
  local kbd_raw, kbd_hl_raw = build_kbd_lines(children, scores)

  local function kbd_panel_lines(h)
    local top_pad = math.max(0, math.floor((h - KBD_HEIGHT) / 2))
    local ls = {}
    for _ = 1, top_pad do ls[#ls + 1] = "" end
    for _, l in ipairs(kbd_raw) do ls[#ls + 1] = l end
    while #ls < h do ls[#ls + 1] = "" end
    return ls, shift_kbd_hl(kbd_hl_raw, top_pad)
  end

  local hc   = key_hints.hint_counts
  local hint = key_hints.get(vim_mode or "n", prefix)
  local height, box
  local lp, kp, rp

  if mode == "wide" then
    -- Left: top LIST_MAX_WIDE left-hand keys; Right: top LIST_MAX_WIDE right-hand keys.
    -- height = LIST_MAX_WIDE items + 1 header + 1 hint footer
    local lw      = math.floor((cols - KBD_WIDTH) / 2)
    local rw      = cols - KBD_WIDTH - lw
    local left_s  = top_n(sort_children(left_ch,  scores, hc), LIST_MAX_WIDE)
    local right_s = top_n(sort_children(right_ch, scores, hc), LIST_MAX_WIDE)
    height = math.min(LIST_MAX_WIDE + 2, max_h)
    local row = compute_row(height)
    lp = make_popup(); kp = make_popup(); rp = make_popup()
    box = Layout.Box({
      Layout.Box(lp, { size = lw }),
      Layout.Box(kp, { size = KBD_WIDTH }),
      Layout.Box(rp, { size = rw }),
    }, { dir = "row" })
    panels.layout = Layout(
      { relative = "editor", position = { row = row, col = 0 }, size = { width = cols, height = height } },
      box)
    panels.height = height; panels.row = row; panels.mode = mode
    panels.list1 = lp; panels.kbd = kp; panels.list2 = rp
    panels.layout:mount()
    fill_popup(lp, render_list_lines(left_s,  lw, height - 1, prefix))
    append_hint_footer(lp, hint, lw)
    fill_popup(rp, render_list_lines(right_s, rw, height, prefix))
    local kl, kh = kbd_panel_lines(height); fill_popup(kp, kl, kh)

  elseif mode == "narrow" then
    -- Two panels stacked vertically to the left of the keyboard.
    -- Top: first LIST_MAX_NARROW items (with prefix header).
    -- Bottom: next LIST_MAX_NARROW items (no header) + hint footer.
    local lw      = cols - KBD_WIDTH
    local all_s   = sort_children(children, scores, hc)
    local top_s   = top_n(all_s, LIST_MAX_NARROW)
    local bot_s   = {}
    for i = LIST_MAX_NARROW + 1, math.min(LIST_MAX_NARROW * 2, #all_s) do
      bot_s[#bot_s + 1] = all_s[i]
    end
    -- Each stacked panel: LIST_MAX_NARROW items + 1 extra (header or footer)
    local half_h  = LIST_MAX_NARROW + 1
    height = math.min(math.max(half_h * 2, KBD_HEIGHT), max_h)
    local row = compute_row(height)
    lp = make_popup(); rp = make_popup(); kp = make_popup()
    box = Layout.Box({
      Layout.Box({
        Layout.Box(lp, { grow = 1 }),
        Layout.Box(rp, { grow = 1 }),
      }, { dir = "col", size = lw }),
      Layout.Box(kp, { size = KBD_WIDTH }),
    }, { dir = "row" })
    panels.layout = Layout(
      { relative = "editor", position = { row = row, col = 0 }, size = { width = cols, height = height } },
      box)
    panels.height = height; panels.row = row; panels.mode = mode
    panels.list1 = lp; panels.list2 = rp; panels.kbd = kp
    panels.layout:mount()
    local top_h = math.ceil(height / 2)
    local bot_h = math.floor(height / 2)
    fill_popup(lp, render_list_lines(top_s, lw, top_h, prefix))
    fill_popup(rp, render_list_lines(bot_s, lw, bot_h - 1, prefix, { show_header = false }))
    append_hint_footer(rp, hint, lw)
    local kl, kh = kbd_panel_lines(height); fill_popup(kp, kl, kh)

  else -- minimal: single list, no keyboard
    local all_s = top_n(sort_children(children, scores, hc), LIST_MAX_WIDE)
    height = math.min(LIST_MAX_WIDE + 2, max_h)
    local row = compute_row(height)
    lp = make_popup()
    box = Layout.Box(lp, {})
    panels.layout = Layout(
      { relative = "editor", position = { row = row, col = 0 }, size = { width = cols, height = height } },
      box)
    panels.height = height; panels.row = row; panels.mode = mode
    panels.list1 = lp; panels.kbd = nil; panels.list2 = nil
    panels.layout:mount()
    fill_popup(lp, render_list_lines(all_s, cols, height - 1, prefix))
    append_hint_footer(lp, hint, cols)
  end
end

--- Fast path: reuse mounted popups, refill buffers, and reflow position/size if needed.
local function refresh_panels(children, prefix, vim_mode)
  local cols                = vim.o.columns
  local max_h               = math.max(1, vim.o.lines - vim.o.cmdheight - 2)
  local mode                = panels.mode

  local scores              = key_stats.get(vim_mode or "n", prefix)
  local left_ch, right_ch   = bucket(children)
  local kbd_raw, kbd_hl_raw = build_kbd_lines(children, scores)

  local function kbd_panel_lines(h)
    local top_pad = math.max(0, math.floor((h - KBD_HEIGHT) / 2))
    local ls = {}
    for _ = 1, top_pad do ls[#ls + 1] = "" end
    for _, l in ipairs(kbd_raw) do ls[#ls + 1] = l end
    while #ls < h do ls[#ls + 1] = "" end
    return ls, shift_kbd_hl(kbd_hl_raw, top_pad)
  end

  local function reflow(new_h)
    local new_row = compute_row(new_h)
    if new_h ~= panels.height or new_row ~= panels.row then
      panels.height = new_h
      panels.row    = new_row
      panels.layout:update {
        position = { row = new_row, col = 0 },
        size     = { width = cols, height = new_h },
      }
    end
  end

  local hc   = key_hints.hint_counts
  local hint = key_hints.get(vim_mode or "n", prefix)

  if mode == "wide" then
    local lw      = math.floor((cols - KBD_WIDTH) / 2)
    local rw      = cols - KBD_WIDTH - lw
    local left_s  = top_n(sort_children(left_ch,  scores, hc), LIST_MAX_WIDE)
    local right_s = top_n(sort_children(right_ch, scores, hc), LIST_MAX_WIDE)
    local h = math.min(LIST_MAX_WIDE + 2, max_h)
    reflow(h)
    fill_popup(panels.list1, render_list_lines(left_s,  lw, h - 1, prefix))
    append_hint_footer(panels.list1, hint, lw)
    fill_popup(panels.list2, render_list_lines(right_s, rw, h, prefix))
    local kl, kh = kbd_panel_lines(h); fill_popup(panels.kbd, kl, kh)

  elseif mode == "narrow" then
    local lw    = cols - KBD_WIDTH
    local all_s = sort_children(children, scores, hc)
    local top_s = top_n(all_s, LIST_MAX_NARROW)
    local bot_s = {}
    for i = LIST_MAX_NARROW + 1, math.min(LIST_MAX_NARROW * 2, #all_s) do
      bot_s[#bot_s + 1] = all_s[i]
    end
    local h     = math.min(math.max((LIST_MAX_NARROW + 1) * 2, KBD_HEIGHT), max_h)
    reflow(h)
    local top_h = math.ceil(h / 2)
    local bot_h = math.floor(h / 2)
    fill_popup(panels.list1, render_list_lines(top_s, lw, top_h, prefix))
    fill_popup(panels.list2, render_list_lines(bot_s, lw, bot_h - 1, prefix, { show_header = false }))
    append_hint_footer(panels.list2, hint, lw)
    local kl, kh = kbd_panel_lines(h); fill_popup(panels.kbd, kl, kh)

  else
    local all_s = top_n(sort_children(children, scores, hc), LIST_MAX_WIDE)
    local h = math.min(LIST_MAX_WIDE + 2, max_h)
    reflow(h)
    fill_popup(panels.list1, render_list_lines(all_s, cols, h - 1, prefix))
    append_hint_footer(panels.list1, hint, cols)
  end
end

-- ── public API ─────────────────────────────────────────────────────────────

--- Open the key guide for `initial_prefix` and enter a blocking input loop.
---
--- Each keypress either drills into a subgroup (if children exist at that prefix)
--- or closes the guide and replays the full raw sequence so Neovim executes it.
--- ESC or Ctrl-C cancels without replaying anything.
---
---@param mode?           string vim mode ("n", "v", …), defaults to "n"
---@param initial_prefix? string starting prefix shown on open, defaults to ""
function M.start(mode, initial_prefix)
  mode           = mode or "n"
  initial_prefix = initial_prefix or ""

  -- Cancel any stale resume autocmd from a prior invocation.
  clear_pending_resume()

  -- While inside the guide we consume keys via getcharstr; pause the on_key
  -- collector so those aren't double-counted (the guide calls note_press
  -- explicitly with the right prefix).
  key_stats.set_paused(true)

  local norm_prefix = initial_prefix
  -- Raw bytes typed inside the loop. Does NOT include bytes for initial_prefix
  -- (those were already consumed by whatever keymap triggered M.start).
  local raw_bytes   = ""

  setup_highlights()

  local ch = get_children(mode, norm_prefix)
  if panels.layout and layout_mode(vim.o.columns) == panels.mode then
    refresh_panels(ch, norm_prefix, mode)
  else
    open_panels(ch, norm_prefix, mode)
  end
  vim.cmd("redraw!")

  while true do
    local ok, char = pcall(vim.fn.getcharstr)

    -- ESC (\27) or any error (e.g. Ctrl-C) cancels the guide.
    if not ok or char == "\27" then
      close_panels()
      vim.cmd("redraw!")
      key_stats.set_paused(false)
      return
    end

    local norm_char = normalize_key(char)
    key_stats.note_press(mode, norm_prefix, norm_char)
    local candidate = norm_prefix .. norm_char
    local next_ch   = get_children(mode, candidate)

    if #next_ch > 0 then
      -- Subgroup: drill down, fast-refresh the panels.
      norm_prefix = candidate
      raw_bytes   = raw_bytes .. char
      if layout_mode(vim.o.columns) ~= panels.mode or not panels.layout then
        open_panels(next_ch, norm_prefix, mode)
      else
        refresh_panels(next_ch, norm_prefix, mode)
      end
      vim.cmd("redraw!")
    else
      -- Leave panels mounted: in-place moves (j/k/etc.) stay flicker-free.
      -- ModeChanged below will close them only if we leave normal mode.
      local prefix_raw = initial_prefix:gsub("<leader>", vim.g.mapleader or "")
      local full = prefix_raw .. raw_bytes .. char
      if full ~= "" then
        vim.api.nvim_feedkeys(full, "m", true)
      end

      clear_pending_resume()

      -- Hide panels when the fed keys put us into insert / cmdline / fzf / etc.
      vim.api.nvim_create_autocmd("ModeChanged", {
        group = RESUME_AUGROUP,
        callback = function()
          if vim.fn.mode() ~= "n" then close_panels() end
        end,
      })

      -- Resume the input loop once neovim is idle back in normal mode.
      -- Keep the stats collector paused all the way through — if we unpause
      -- here, a key the user types before the scheduled M.start runs would
      -- get counted by both on_key and the new note_press call.
      vim.api.nvim_create_autocmd("SafeState", {
        group = RESUME_AUGROUP,
        callback = function()
          if vim.fn.mode() ~= "n" then return end
          clear_pending_resume()
          vim.schedule(function() M.start(mode, initial_prefix) end)
        end,
      })
      return
    end
  end
end

return M
