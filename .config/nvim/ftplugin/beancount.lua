-- nvim-treesitter's "main" branch dropped the old highlight.enable auto-attach
-- mechanism, so starting Treesitter highlighting here is what actually turns
-- it on for this filetype now that vim-beancount's regex syntax is gone.
pcall(vim.treesitter.start)

-- Merge duplicate postings: lines with the same account and same currency
-- are summed into the first occurrence; the rest are deleted. Postings that
-- share an account but differ in currency are left as separate lines.

local function parse_posting(line)
  local account, amount, currency = line:match("^%s*([%w:]+)%s+([%-%+]?[%d,]*%.?%d*)%s+(%a+)%s*$")
  if account and amount ~= "" then
    local frac = amount:match("%.(%d+)$")
    return account, tonumber((amount:gsub(",", ""))), currency, frac and #frac or 0
  end
  account = line:match("^%s*([%w:]+)%s*$")
  if account then
    return account, nil, nil, 0
  end
  return nil
end

local function transaction_bounds(lnum)
  local start = lnum
  while start > 1 and not vim.fn.getline(start):match("^%d%d%d%d%-%d%d%-%d%d") do
    start = start - 1
  end
  local last = vim.fn.line "$"
  local finish = start
  while finish < last do
    local nxt = vim.fn.getline(finish + 1)
    if nxt:match "^%s*$" or nxt:match "^%d%d%d%d%-%d%d%-%d%d" then break end
    finish = finish + 1
  end
  return start, finish
end

local function format_posting(account, amount, currency, decimals)
  if not amount then return string.format("  %s", account) end
  return string.format("  %s  %." .. decimals .. "f %s", account, amount, currency)
end

local function merge_range(line1, line2)
  local new_lines = {}
  local pending = {}
  local slot_of = {}

  for lnum = line1, line2 do
    local raw = vim.fn.getline(lnum)
    local account, amount, currency, decimals = parse_posting(raw)
    if account then
      local key = account .. "\1" .. (currency or "")
      local slot = slot_of[key]
      if slot then
        local g = pending[key]
        if amount ~= nil then g.amount = (g.amount or 0) + amount end
        g.decimals = math.max(g.decimals, decimals or 0)
        new_lines[slot] = format_posting(g.account, g.amount, g.currency, g.decimals)
      else
        table.insert(new_lines, raw)
        slot_of[key] = #new_lines
        pending[key] = { account = account, amount = amount, currency = currency, decimals = decimals or 0 }
      end
    else
      table.insert(new_lines, raw)
    end
  end

  local merged_count = (line2 - line1 + 1) - #new_lines
  if merged_count <= 0 then
    vim.notify("beancount merge: no duplicate accounts found", vim.log.levels.INFO)
    return
  end

  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, new_lines)
  vim.notify(string.format("beancount merge: merged %d duplicate posting(s)", merged_count), vim.log.levels.INFO)
end

vim.api.nvim_buf_create_user_command(
  0,
  "BeancountMerge",
  function(opts) merge_range(opts.line1, opts.line2) end,
  { range = true }
)

vim.keymap.set("n", "<leader>bp", function()
  local start, finish = transaction_bounds(vim.fn.line ".")
  merge_range(start + 1, finish)
end, { buffer = true, desc = "Beancount: merge duplicate accounts in transaction" })

vim.keymap.set(
  "v",
  "<leader>bp",
  ":BeancountMerge<CR>",
  { buffer = true, silent = true, desc = "Beancount: merge duplicate accounts in selection" }
)

-- Sort postings within each transaction: accounts alphabetically, with the
-- no-amount balancing posting pinned last. Per-posting metadata/comments
-- (siblings of `posting` in the tree, not children) travel with the posting
-- they immediately follow.
-- Node ranges end at the (row, col) just past the node's last byte. Statement-
-- level nodes (posting, transaction) end at col 0 of the following line, but
-- inline nodes (key_value, comment) end mid-line — normalize both to "row
-- index one past the node's last line" so it's safe to use as an exclusive
-- bound for nvim_buf_get_lines/nvim_buf_set_lines.
local function node_line_end(node)
  local _, _, erow, ecol = node:range()
  if ecol > 0 then erow = erow + 1 end
  return erow
end

local function sort_postings_in_transaction(txn_node, bufnr)
  local groups = {}
  local current

  for child in txn_node:iter_children() do
    local ctype = child:type()
    if ctype == "posting" then
      current = { posting = child, extra = {} }
      table.insert(groups, current)
    elseif current and (ctype == "key_value" or ctype == "comment") then
      table.insert(current.extra, child)
    end
  end

  if #groups < 2 then return end

  local overall_start, overall_end
  for _, g in ipairs(groups) do
    local last_node = g.extra[#g.extra] or g.posting
    local srow = select(1, g.posting:range())
    local erow = node_line_end(last_node)
    g.start_row, g.end_row = srow, erow
    g.lines = vim.api.nvim_buf_get_lines(bufnr, srow, erow, false)
    local account_node = g.posting:field("account")[1]
    g.account = account_node and vim.treesitter.get_node_text(account_node, bufnr) or ""
    g.has_amount = #g.posting:field("amount") > 0
    overall_start = overall_start and math.min(overall_start, srow) or srow
    overall_end = overall_end and math.max(overall_end, erow) or erow
  end

  table.sort(groups, function(a, b)
    if a.has_amount ~= b.has_amount then return a.has_amount end
    return a.account < b.account
  end)

  local new_lines = {}
  for _, g in ipairs(groups) do
    vim.list_extend(new_lines, g.lines)
  end

  vim.api.nvim_buf_set_lines(bufnr, overall_start, overall_end, false, new_lines)
end

local function sort_all_transactions()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "beancount")
  if not ok then
    vim.notify("beancount sort: Treesitter parser not installed, run :TSInstall beancount", vim.log.levels.ERROR)
    return
  end

  local root = parser:parse()[1]:root()
  local txn_nodes = {}
  for child in root:iter_children() do
    if child:type() == "transaction" then table.insert(txn_nodes, child) end
  end

  for i = #txn_nodes, 1, -1 do
    sort_postings_in_transaction(txn_nodes[i], bufnr)
  end
end

vim.keymap.set("n", "<leader>=", function()
  sort_all_transactions()
  vim.cmd [[%!autobean-format --sort --indent "  " -]]
end, { buffer = true, silent = true, desc = "Beancount: sort postings, sort entries by date, format" })

-- Section banner: "; ── <label> ──────...──" padded to a fixed column.
local BANNER_WIDTH = 68

vim.keymap.set("n", "<leader>bb", function()
  vim.ui.input({ prompt = "Banner label: " }, function(label)
    if not label or label == "" then return end
    local prefix = "; ── " .. label .. " "
    local pad = math.max(0, BANNER_WIDTH - vim.fn.strwidth(prefix))
    local banner = prefix .. string.rep("─", pad)
    local row = vim.fn.line "."
    vim.api.nvim_buf_set_lines(0, row, row, false, { banner })
    vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
  end)
end, { buffer = true, desc = "Beancount: insert section banner" })
