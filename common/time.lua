
local addOn, ICT = ...

local Colors = ICT.Colors
ICT.OneHour = 60 * 60
ICT.OneDay = ICT.OneHour * 24
ICT.OneWeek = ICT.OneDay * 7

function ICT:convertFrom32bitNegative(int32)
    -- Is a 32bit negative value?
    return int32 >= 0x80000000 / 1e3
    -- If so then convert.
    and int32 - 0x100000000 / 1e3
    -- If positive return original.
    or int32
end

function ICT:getTime64()
    return self:convertFrom32bitNegative(GetTime())
end

function ICT:getTimeLeft(start, duration)
    local now = self:getTime64()
    local serverNow = GetServerTime()
    -- since start is relative to computer uptime it can be a negative if the cooldown started before you restarted your pc.
    start = self:convertFrom32bitNegative(start)
    if start > now then -- start negative 32b overflow while now is still negative (over 24d 20h 31m PC uptime)
        start = start - 0x100000000 / 1e3 -- adjust relative to negative now
    end
    return start - now + serverNow + duration
end

function ICT:displayTime(time)
    if not time then
        return ""
    end
    local days = math.floor(time / ICT.OneDay)
    local hours = math.floor(time % ICT.OneDay / 3600)
    local minutes = math.floor(time % 3600 / 60)
    local seconds = math.floor(time % 60)
    if days == 0 then
        if hours == 0 then
            return string.format("%02d:%02d", minutes, seconds)
        end
        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end
    return string.format("%d:%02d:%02d:%02d", days, hours, minutes, seconds)
end

function ICT:countdown(expires, duration, startColor, endColor)
    if expires then
        local timeLeft = math.max(expires - GetServerTime(), 0)
        startColor = startColor or Colors.green
        endColor = endColor or Colors.red
        local color = duration and duration > 0 and Colors:gradient(startColor, endColor, timeLeft / duration) or endColor
        return timeLeft == 0 and "Ready" or self:displayTime(timeLeft), color
    end
    return "N/A"
end

function ICT:cancelTicker(ticker)
    if ticker and not ICT.frame:IsShown() then
        ticker:Cancel()
    end
end

-- Add one to handle DST differences and hope no servers' timezones overflow..
local timezone = (GetServerTime() - C_DateAndTime.GetServerTimeLocal()) / ICT.OneHour + 1
function ICT:timezone()
    return timezone
end