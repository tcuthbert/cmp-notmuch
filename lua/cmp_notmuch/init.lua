local cmp = require('cmp')
local luv = require('luv')
local debug = require('cmp.utils.debug')
local M = {}

M.new = function()
  local self = setmetatable({}, { __index = M })
  return self
end

M.get_keyword_pattern = function()
  return [=[^[^:]*\(To\|From\|[CBc]\+\):\s\?\zs\w\+]=]
end

local pipes = function()
  local stdin = luv.new_pipe(false)
  local stdout = luv.new_pipe(false)
  local stderr = luv.new_pipe(false)
  return { stdin, stdout, stderr }
end

local trim = function(str)
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

local line = function(str)
  local s, e, cap = string.find(str, '\n')
  if not s then
    return nil, str
  end
  local l = string.sub(str, 1, s - 1)
  local rest = string.sub(str, e + 1)
  return l, rest
end

local result = function(words)
  local items = {}
  for _, w in ipairs(words) do
    table.insert(items, { label = w })
  end
  return { items = items, isIncomplete = true }
end

local function map(f, xs)
  local ret = {}
  for _, x in ipairs(xs) do
    table.insert(ret, f(x))
  end
  return ret
end

M.complete = function(self, request, callback)
  local q = string.sub(request.context.cursor_before_line, request.offset)
  local args = { 'address', '--deduplicate=address', q }
  do
    if request.option.domains then
      local domains = request.option.domains
      for _, d in ipairs(domains) do
        d = 'from:' .. d
        table.insert(args, d)
      end
    end
    if request.option.ignored_senders then
      local senders = map(
        function(x)
          return 'not from:' .. x
        end, request.option.ignored_senders
      )
      args = vim.tbl_extend("keep", args, senders)
    end
  end
  local stdioe = pipes()
  local handle, pid
  local buf = ''
  local words = {}
  do
    local spawn_params = {
      args = args,
      stdio = stdioe
    }
    handle, pid = luv.spawn('notmuch', spawn_params, function(code, signal)
      stdioe[1]:close()
      stdioe[2]:close()
      stdioe[3]:close()
      handle:close()
      local xs = words
      if vim.regex(self.get_keyword_pattern()) then
        callback(result(xs))
      end
    end)
    if handle == nil then
      debug.log(string.format("start `%s` failed: %s", cmd, pid))
    end
    luv.read_start(stdioe[2], function(err, chunk)
      assert(not err, err)
      if chunk then
        buf = buf .. chunk
      end
      while true do
        local l, rest = line(buf)
        if l == nil then
          break
        end
        buf = rest
        local w = trim(l)
        if w ~= '' then
          table.insert(words, w)
        end
      end
    end)
  end
end

return M
