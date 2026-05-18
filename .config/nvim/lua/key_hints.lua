-- key_hints.lua
-- Hooks into hardtime.nvim's callback to surface bad-habit hints in the guide.
-- Falls back to showing the most-used key for the current prefix when no
-- fresh hint is available.

local M = {}

local HINT_TTL_MS   = 8000
local current       = nil  -- { text = string, kind = "hardtime"|"freq", expires = ms }

local function now_ms() return vim.uv.now() end

--- Call once after hardtime is loaded (e.g. from a VeryLazy autocmd or
--- key_guide.lua). Safe to call when hardtime isn't installed.
function M.setup()
  local ok, ht_cfg = pcall(require, "hardtime.config")
  if not ok then return end

  local prev = ht_cfg.config.callback
  ht_cfg.config.callback = function(text)
    current = { text = text, kind = "hardtime", expires = now_ms() + HINT_TTL_MS }
    if prev then pcall(prev, text) end
  end
end

--- Returns { text, kind } for display, or nil if nothing to show.
--- Falls back to the top-frequency key for (mode, prefix) from key_stats.
---@param mode string
---@param prefix string
function M.get(mode, prefix)
  if current and now_ms() < current.expires then
    return current
  end
  current = nil

  -- Frequency fallback: show the single most-pressed key at this prefix.
  local ok, key_stats = pcall(require, "key_stats")
  if not ok then return nil end
  local top = key_stats.top(mode, prefix, 1)
  if top and top[1] then
    return {
      text = ("most used here: %s (%.0f presses)"):format(top[1].key, top[1].score),
      kind = "freq",
    }
  end

  return nil
end

return M
