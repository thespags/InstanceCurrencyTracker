local addOnName, ICT = ...

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
