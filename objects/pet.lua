local _, ICT = ...

local Pet = {}
ICT.Pet = Pet

-- Adds all the functions to the player.
function Pet:new(pet)
    setmetatable(pet, self)
    self.__index = self
    return pet
end

function Pet:fromPlayer(player)
    return self.player == player
end

function Pet:getName()
    return self.name
end

function Pet:isVisible()
    return ICT.db.options.pets[self.player:getFullName()][self.name]
end

function Pet:setVisible(v)
    ICT.db.options.pets[self.player:getFullName()][self.name] = v
end

function Pet:__eq(other)
    return self.player == other.player and self.name == other.name
end

function Pet:__lt(other)
    if self.player:getFullName() == other.player:getFullName() then
        return self.name < other.name
    end
    return self.player:getFullName() < other.player:getFullName()
end
