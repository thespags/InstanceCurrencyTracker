
local addOn, ICT = ...

local log = {
    usecolor = true,
    showtime = true,
    level = "error",
    prefix = "@Interface/AddOns/InstanceCurrencyTracker/"
}
ICT.log = log

local modes = {
  { name = "trace", color = "FFFF00FF", },
  { name = "debug", color = "FF0000FF", },
  { name = "info",  color = "FF00FF00", },
  { name = "warn",  color = "FFFFFF00", },
  { name = "error", color = "FFFFa500", },
  { name = "fatal", color = "FFFF0000", },
}

local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end

local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end

local concat = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = tostring(x)
  end
  return table.concat(t, " ")
end

local regex = log.prefix .. "([%w/]+).lua\"]:(%d+):"

for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(...)

    -- Return early if we're below the log level
    if i < levels[log.level] then
      return
    end

    local msg = concat(...)
    local source, line = debugstack(2):match(regex)
    source = source or "?"
    line = line or "?"
    local color = log.usecolor and x.color or "FFFFFFFF"
    local timestamp = log.showtime and date("%H:%M:%S") or ""
    print(string.format("|c%s[%-6s%s]|r %s:%s: %s", color, nameupper, timestamp, source, line, msg))
  end
end