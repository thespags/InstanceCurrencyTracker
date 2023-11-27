
local addOn, ICT = ...

local log = {
    usecolor = true,
    showtime = true,
    level = "error",
    prefix = "@Interface/AddOns/InstanceCurrencyTracker/"
}
ICT.log = log

log.modes = {
  { name = "trace", color = "FFFF00FF", },
  { name = "debug", color = "FF00a5FF", },
  { name = "info",  color = "FF00FF00", },
  { name = "warn",  color = "FFFFFF00", },
  { name = "error", color = "FFFFa500", },
  { name = "fatal", color = "FFFF0000", },
}

local levels = {}
for i, v in ipairs(log.modes) do
  levels[v.name] = i
end

local regex = log.prefix .. "([%w/]+).lua\"]:(%d+):"


for i, x in ipairs(log.modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(message, ...)

    -- Return early if we're below the log level
    if i < levels[ICT.db.logLevel or log.level] then
      return
    end

    local text = string.format(message, ...)
    local source, line = debugstack(2):match(regex)
    source = source or "?"
    line = line or "?"
    local color = log.usecolor and x.color or "FFFFFFFF"
    local timestamp = log.showtime and date("%H:%M:%S") or ""
    print(string.format("|c%s[%-6s%s]|r %s:%s: %s", color, nameupper, timestamp, source, line, text))
  end
end