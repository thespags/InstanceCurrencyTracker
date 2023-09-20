local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Reset = {}
ICT.Reset = Reset

function Reset:new(name, f)
    f = f or (function() end)
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

function Reset:reset()
    local timestamp = GetServerTime()
    if self:expires() and self:expires() < timestamp then
        ICT:print(L["%s reset, updating info."], self:getName())
        for _, player in pairs(ICT.db.players) do
            self.func(player)
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

ICT.ResetInfo = {
    [1] = Reset:new("Daily", ICT.Player.dailyReset),
    [3] = Reset:new("3 Day"),
    [5] = Reset:new("5 Day"),
    [7] = Reset:new("Weekly", ICT.Player.weeklyReset),
}

for k, v in pairs(ICT.ResetInfo) do
    v.id = k
end

local Difficulty = {}

function Difficulty:new(name, visible)
    local difficulty = { name = name, visible = visible}
    setmetatable(difficulty, self)
    self.__index = self
    return difficulty
end

function Difficulty:getName()
    return self.name
end

function Difficulty:isVisible()
    return (self.visible and self.visible()) or ICT.db.options.difficulty[self.id]
end

function Difficulty:setVisible(v)
    ICT.db.options.difficulty[self.id] = v
end

function Difficulty:__eq(other)
    return self.id == other.id
end

function Difficulty:__lt(other)
    return self.id < other.id
end

ICT.DifficultyInfo = {
    Difficulty:new("Normal"),
    Difficulty:new("Heroic"),
    Difficulty:new("Titan Runed: Alpha"),
    Difficulty:new("Titan Runed: Beta"),
}

for k, v in pairs(ICT.DifficultyInfo) do
    v.id = k
end

ICT.RaidDifficulty = {
    Difficulty:new("Raid", function() return true end)
}

for k, v in pairs(ICT.RaidDifficulty) do
    v.id = k
end
