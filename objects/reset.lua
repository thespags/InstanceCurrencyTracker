local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local Reset = {}
ICT.Reset = Reset

function Reset:new(name, f)
    local reset = { name = name, func = f}
    setmetatable(reset, self)
    self.__index = self
    return reset
end

function Reset:getName()
    return self.name
end

function Reset:isVisible()
    return ICT.db.options.reset[self.id]
end

function Reset:setVisible(v)
    ICT.db.options.reset[self.id] = v
end

function Reset:duration()
    return self.id * ICT.OneDay
end

function Reset:expires()
    return ICT.db.reset[self.id]
end

function Reset:isVisibleAndActive()
    return self:isVisible() and self:expires()
end

function Reset:reset()
    local timestamp = GetServerTime()
    if self:expires() and self:expires() < timestamp then
        ICT:print(L["%s reset, updating info."], self:getName())
        for _, player in pairs(ICT.db.players) do
            _ = self.func and self.func(player)
        end
        -- There doesn't seem to be an API to get 3 or 5 day reset so recalculate from the last known piece.
        -- Keep going until we have a time in the future, the player may have not logged in a while.
        -- Less math to avoid an off by 1 error.
        while self:expires() < timestamp do
            ICT.db.reset[self.id] = self:expires() + self:duration()
        end
    end
end

function Reset:__eq(other)
    return self.id == other.id
end

function Reset:__lt(other)
    return self.id < other.id
end

ICT.Resets = {
    [1] = Reset:new("Daily", function(v) ICT.Player.dailyReset(v) end),
    [3] = Reset:new("3 Day"),
    [5] = Reset:new("5 Day"),
    [7] = Reset:new("Weekly", function(v) ICT.Player.weeklyReset(v) end),
}

for k, v in pairs(ICT.Resets) do
    v.id = k
end
