-- key_stats.lua
-- Tracks normal-mode key usage to drive the key_guide heatmap.
--
-- Two ingestion paths:
--   1. vim.on_key — counts user-typed keys at top level (prefix ""). Skips
--      mapping-expanded / feedkeys events by requiring `typed` non-empty.
--   2. note_press(mode, prefix, key) — called by key_guide for keys it
--      consumed via getcharstr, so we get per-prefix counts.
-- The on_key path is paused while the guide is active so guide-consumed
-- physical keys aren't double-counted.

local M = {}

local DATA_DIR          = vim.fn.stdpath("data") .. "/key_guide"
local DATA_PATH         = DATA_DIR .. "/stats.json"
local HALF_LIFE_DAYS    = 60     -- count halves after this many idle days
local PRUNE_BELOW       = 0.05   -- drop entries that decay below this
local FLUSH_INTERVAL_MS = 30 * 1000

-- stats shape:
--   global = { [mode] = { [prefix] = { [key] = { count = N, last = ts } } } }
--   byft   = { [ft]   = { same as global } }
local stats        = nil
local dirty        = false
local paused       = false
local flush_timer  = nil
local on_key_ns    = vim.api.nvim_create_namespace("key_stats_on_key")

-- ── decay / persistence ────────────────────────────────────────────

local function now_ts() return os.time() end

local function decay(entry, now)
  if not entry.last or entry.last == 0 then return entry.count end
  local days = math.max(0, (now - entry.last) / 86400)
  return entry.count * (0.5 ^ (days / HALF_LIFE_DAYS))
end

local function walk_modes(modes, now)
  for mode, prefixes in pairs(modes) do
    for prefix, keys in pairs(prefixes) do
      for key, entry in pairs(keys) do
        entry.count = decay(entry, now)
        entry.last  = now
        if entry.count < PRUNE_BELOW then keys[key] = nil end
      end
      if next(keys) == nil then prefixes[prefix] = nil end
    end
    if next(prefixes) == nil then modes[mode] = nil end
  end
end

local function decay_all()
  local now = now_ts()
  walk_modes(stats.global, now)
  for ft, modes in pairs(stats.byft) do
    walk_modes(modes, now)
    if next(modes) == nil then stats.byft[ft] = nil end
  end
end

local function load_stats()
  if stats then return end
  stats = { global = {}, byft = {} }
  local fd = io.open(DATA_PATH, "r")
  if not fd then return end
  local content = fd:read("*a")
  fd:close()
  local ok, decoded = pcall(vim.json.decode, content)
  if ok and type(decoded) == "table" then
    stats.global = decoded.global or {}
    stats.byft   = decoded.byft   or {}
  end
  decay_all()
end

local function write_stats_now()
  if not stats then return end
  vim.fn.mkdir(DATA_DIR, "p")
  local encoded = vim.json.encode(stats)
  local fd = io.open(DATA_PATH, "w")
  if fd then
    fd:write(encoded)
    fd:close()
    dirty = false
  end
end

local function ensure_flush_timer()
  if flush_timer then return end
  flush_timer = vim.uv.new_timer()
  flush_timer:start(FLUSH_INTERVAL_MS, FLUSH_INTERVAL_MS, vim.schedule_wrap(function()
    if dirty then pcall(write_stats_now) end
  end))
end

-- ── bumping ────────────────────────────────────────────────────────

local function bump_in(modes, mode, prefix, key, now)
  modes[mode] = modes[mode] or {}
  modes[mode][prefix] = modes[mode][prefix] or {}
  local bucket = modes[mode][prefix]
  local entry  = bucket[key]
  if entry then
    entry.count = decay(entry, now) + 1
  else
    entry = { count = 1 }
  end
  entry.last  = now
  bucket[key] = entry
end

local function bump(mode, prefix, key, ft)
  load_stats()
  local now = now_ts()
  bump_in(stats.global, mode, prefix, key, now)
  if ft and ft ~= "" then
    stats.byft[ft] = stats.byft[ft] or {}
    bump_in(stats.byft[ft], mode, prefix, key, now)
  end
  dirty = true
  ensure_flush_timer()
end

-- ── public API ─────────────────────────────────────────────────────

--- Pause the on_key collector. Guide should set true on entry, false on exit.
function M.set_paused(p) paused = p end

--- Manual increment for keys the guide consumed via getcharstr.
function M.note_press(mode, prefix, key)
  if not mode or not key or key == "" then return end
  bump(mode, prefix or "", key, vim.bo.filetype)
end

--- Returns { [key] = score } for a (mode, prefix). opts.scope = "global"|"ft".
function M.get(mode, prefix, opts)
  load_stats()
  opts = opts or {}
  local map
  if opts.scope == "ft" then
    map = stats.byft[opts.ft or vim.bo.filetype]
  else
    map = stats.global
  end
  if not map or not map[mode] or not map[mode][prefix or ""] then return {} end
  local now    = now_ts()
  local result = {}
  for key, entry in pairs(map[mode][prefix or ""]) do
    result[key] = decay(entry, now)
  end
  return result
end

--- Returns top-N entries sorted by score descending.
function M.top(mode, prefix, n, opts)
  local scores = M.get(mode, prefix, opts)
  local list   = {}
  for key, score in pairs(scores) do list[#list + 1] = { key = key, score = score } end
  table.sort(list, function(a, b) return a.score > b.score end)
  if n then
    for i = #list, n + 1, -1 do list[i] = nil end
  end
  return list
end

--- Reset stats. scope: "global" | "ft" | "all".
function M.reset(scope)
  load_stats()
  if scope == "global" or scope == "all" then stats.global = {} end
  if scope == "ft" then
    stats.byft[vim.bo.filetype] = nil
  elseif scope == "all" then
    stats.byft = {}
  end
  dirty = true
  pcall(write_stats_now)
end

function M.flush() pcall(write_stats_now) end

-- ── setup ──────────────────────────────────────────────────────────

local did_setup = false
function M.setup()
  if did_setup then return end
  did_setup = true
  vim.on_key(function(_, typed)
    if paused then return end
    -- typed is empty for mapping expansions / feedkeys-fed bytes; skip those.
    if not typed or typed == "" then return end

    local mode_info = vim.api.nvim_get_mode()
    if mode_info.blocking then return end
    local mode = mode_info.mode:sub(1, 1)
    if mode ~= "n" then return end

    local token = vim.fn.keytrans(typed)
    if not token or token == "" then return end

    bump(mode, "", token, vim.bo.filetype)
  end, on_key_ns)

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function() pcall(write_stats_now) end,
  })
end

return M
