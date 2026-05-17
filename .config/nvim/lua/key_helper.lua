-- Minimal which-key style bottom drawer.
-- Core loop: open float at bottom → read one char → navigate or execute → repeat.
-- Intentionally small so it's easy to extend.

local M = {}

local SEPARATOR = " → "
local MAX_DESC = 30

---@class KeyChild
---@field key string Key token, e.g. "f" or "<C-x>"
---@field desc string Description or rhs of the mapping
---@field group boolean Whether this key has further children

---@class WinState
---@field win integer? Window handle
---@field buf integer? Buffer handle

-- ── keymap querying ────────────────────────────────────────────────────────

---@param lhs string
---@return string
local function normalize_lhs(lhs)
  if vim.g.mapleader and vim.g.mapleader ~= "" then lhs = lhs:gsub("^" .. vim.pesc(vim.g.mapleader), "<leader>") end
  return lhs
end

--- First key token from a string: handles <C-x>, <leader>, plain chars.
---@param s string
---@return string
local function next_token(s) return s:match "^(<[^>]+>)" or s:sub(1, 1) end

--- Returns immediate children of prefix in mode.
---@param mode string Vim mode, e.g. "n", "v"
---@param prefix string Key prefix to look up children for
---@return KeyChild[]
local function get_children(mode, prefix)
  local keymaps = {}
  vim.list_extend(keymaps, vim.api.nvim_get_keymap(mode))
  vim.list_extend(keymaps, vim.api.nvim_buf_get_keymap(0, mode))

  local seen = {}
  local children = {}

  for _, km in ipairs(keymaps) do
    local lhs = normalize_lhs(km.lhs)
    if vim.startswith(lhs, prefix) and #lhs > #prefix then
      local key = next_token(lhs:sub(#prefix + 1))
      if key and not seen[key] then
        seen[key] = true
        local full = prefix .. key
        local is_group = false
        for _, km2 in ipairs(keymaps) do
          if vim.startswith(normalize_lhs(km2.lhs), full) and #normalize_lhs(km2.lhs) > #full then
            is_group = true
            break
          end
        end
        children[#children + 1] = {
          key = key,
          desc = km.desc or (type(km.rhs) == "string" and km.rhs ~= "" and km.rhs) or "[Lua]",
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

-- ── rendering ──────────────────────────────────────────────────────────────

---@param children KeyChild[]
---@param prefix string
---@return string[]
local function render(children, prefix)
  if #children == 0 then return { "", "  (no mappings for " .. prefix .. ")", "" } end

  local max_key = 0
  for _, item in ipairs(children) do
    max_key = math.max(max_key, #item.key)
  end

  -- column width: key + separator + group marker + desc
  local col_width = max_key + #SEPARATOR + 1 + MAX_DESC
  local ncols = math.max(1, math.floor((vim.o.columns - 4) / (col_width + 2)))
  local nrows = math.ceil(#children / ncols)

  local lines = { "", "  " .. prefix .. "…", "" }

  for row = 1, nrows do
    local parts = {}
    for col = 1, ncols do
      local item = children[(col - 1) * nrows + row]
      if item then
        local key_pad = string.rep(" ", max_key - #item.key) .. item.key
        local desc = item.desc
        if #desc > MAX_DESC then desc = desc:sub(1, MAX_DESC - 1) .. "…" end
        local marker = item.group and "+" or " "
        parts[#parts + 1] = key_pad .. SEPARATOR .. marker .. desc
      end
    end
    lines[#lines + 1] = "  " .. table.concat(parts, "  ")
  end

  table.insert(lines, "")
  return lines
end

-- ── window management ──────────────────────────────────────────────────────

---@type WinState
local w = { win = nil, buf = nil }

---@param lines string[]
local function open_win(lines)
  local height = #lines
  local row = vim.o.lines - height - vim.o.cmdheight - 1

  if not (w.buf and vim.api.nvim_buf_is_valid(w.buf)) then
    w.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[w.buf].bufhidden = "wipe"
    vim.bo[w.buf].filetype = "keyhelper"
  end

  vim.bo[w.buf].modifiable = true
  vim.api.nvim_buf_set_lines(w.buf, 0, -1, false, lines)
  vim.bo[w.buf].modifiable = false

  local cfg = {
    relative = "editor",
    row = row,
    col = 0,
    width = vim.o.columns,
    height = height,
    style = "minimal",
    focusable = false,
    noautocmd = true,
    zindex = 200,
  }

  if w.win and vim.api.nvim_win_is_valid(w.win) then
    vim.api.nvim_win_set_config(w.win, cfg)
  else
    w.win = vim.api.nvim_open_win(w.buf, false, cfg)
    vim.wo[w.win].winhighlight = "Normal:KeyHelperNormal,EndOfBuffer:KeyHelperNormal"
  end
end

local function close_win()
  if w.win and vim.api.nvim_win_is_valid(w.win) then pcall(vim.api.nvim_win_close, w.win, true) end
  w.win = nil
  w.buf = nil
end

-- ── main loop ──────────────────────────────────────────────────────────────

---@param mode? string Vim mode, defaults to "n"
---@param initial_prefix? string Starting prefix, defaults to ""
function M.start(mode, initial_prefix)
  mode = mode or "n"
  local prefix = initial_prefix or ""

  vim.api.nvim_set_hl(0, "KeyHelperNormal", { bg = "#1e1e2e", fg = "#cdd6f4", default = true })

  while true do
    local children = get_children(mode, prefix)
    open_win(render(children, prefix))
    vim.cmd.redraw()

    local ok, char = pcall(vim.fn.getcharstr)
    if not ok then
      -- interrupted (e.g. ctrl-c)
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
      -- strip last token from prefix
      local last = prefix:match "(<[^>]+>)$" or prefix:sub(-1)
      prefix = prefix:sub(1, #prefix - #last)
    else
      prefix = prefix .. key
      -- if no children, this is a leaf — execute and exit
      if #get_children(mode, prefix) == 0 then
        close_win()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(prefix, true, true, true), "mit", false)
        break
      end
    end
  end
end

return M
