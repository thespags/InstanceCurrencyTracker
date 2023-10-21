local addOnName, ICT = ...

local Cooldown = {}
ICT.Cooldown = Cooldown

function Cooldown:update(player)
    for id, v in pairs(ICT.Cooldowns) do
        if v:getSpell() then
            local spellKnown = IsPlayerSpell(id)
            if spellKnown then
                local start, duration = GetSpellCooldown(id)
                player.cooldowns[id] = player.cooldowns[id] or Cooldown:new(v.info)
                -- Check duration to filter out spell lock, wands and other CD triggers
                player.cooldowns[id].expires = start ~= 0 and duration == v.info.duration and ICT:getTimeLeft(start, duration) or 0
            else
                -- Handles case if spell was known and no longer is.
                player.cooldowns[id] = nil
            end
        elseif v:getItem() then
            local available = (v:isToy() and PlayerHasToy(id) and C_ToyBox.IsToyUsable(id))
                or (GetItemCount(id, true) > 0 and C_PlayerInfo.CanUseItem(id))
            if available then
                player.cooldowns[id] = player.cooldowns[id] or Cooldown:new(v.info)
                local start, duration = C_Container.GetItemCooldown(id)
                player.cooldowns[id].expires = start ~= 0 and duration > 0 and ICT:getTimeLeft(start, duration) or 0
            else
                player.cooldowns[id] = nil
            end
        end
    end
end

function Cooldown:new(info)
    local t = { info = info }
    setmetatable(t, self)
    self.__index = self
    return t
end

function Cooldown:fromExpansion(expansion)
    return self.info.expansion == expansion
end

function Cooldown:getName()
    return self.info.name
end

function Cooldown:cast(player)
    if self:getSpell() then
        ICT:castTradeSkill(player, self:getSkillLine(), self:getSpell())
    end
end

function Cooldown:getSkillLine()
    return self.info.skillLine
end

function Cooldown:getSpell()
    return self.info.spellName
end

function Cooldown:getItem()
    return self.info.itemName
end

function Cooldown:isToy()
    return self.info.toy
end

function Cooldown:getNameWithIcon()
    self.nameWithIcon = self.nameWithIcon or string.format("|T%s:14|t%s", self.info.icon, self.info.name)
    return self.nameWithIcon
end

function Cooldown:isVisible()
    return ICT.db.options.displayCooldowns[self.info.id]
end

function Cooldown:setVisible(v)
    ICT.db.options.displayCooldowns[self.info.id] = v
end

function Cooldown:__eq(other)
    return self.info.name == other.info.name
end

function Cooldown:__lt(other)
    if self.info.skillLine == other.info.skillLine then
        if self.info.expansion == other.info.expansion then
            return self.info.name < other.info.name
        end
        return self.info.expansion > other.info.expansion
    end
    return self.info.skillLine < other.info.skillLine
end