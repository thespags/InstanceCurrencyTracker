local addOnName, ICT = ...

local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")

local spells = {
    -- Start Vanilla
    11479, -- Iron -> Gold
    11480, -- Mithril -> Truesilver
    17187, -- Arcanite (no cooldown in WOTLK)
    17561, -- Earth -> Water
    17562, -- Water -> Air
    17559, -- Air -> Fire
    17560, -- Fire -> Earth
    17563, -- Undeath -> Water
    17564, -- Water -> Undeath
    17565, -- Life -> Earth
    17566, -- Earth -> Life
    25146, -- Elemental Fire
    18560, -- Mooncloth
    -- End Vanilla/Start TBC
    32765, -- Earthstorm Diamond
    32766, -- Skyfire Diamond
    29688, -- Primal Might
    28567, -- Primal Earth -> Water
    28569, -- Primal Water -> Air
    28566, -- Primal Air -> Fire
    28568, -- Primal Fire -> Earth
    28580, -- Primal Shadow -> Water
    28581, -- Primal Water -> Shadow
    28584, -- Primal Life -> Earth
    28585, -- Primal Earth -> Life
    28582, -- Primal Mana -> Fire
    28583, -- Primal Fire -> Mana
    31373, -- Spellcloth
    36686, -- Shadowcloth
    26751, -- Primial Moonthcloth
    28028, -- Void Sphere
    47280, -- Brilliant Glass
    -- End TBC/Start WOTLK
    60350, -- Titanium
    57427, -- Earhtsiege Diamond
    57425, -- Skyflare Diamond
    66658, -- Ametrine
    66659, -- Cardinal Ruby
    66660, -- King's Amber
    66662, -- Dreadstone
    66663, -- Majestic Zircon
    66664, -- Eye of Zul
    53777, -- Eternal Air -> Earth
    53781, -- Eternal Earth -> Air
    53776, -- Eternal Air -> Water
    53783, -- Eternal Water -> Air
    53779, -- Eternal Shadow -> Earth
    53782, -- Eternal Earth -> Shadow
    53773, -- Eternal Life -> Fire
    53775, -- Eternal Fire -> Life
    53774, -- Eternal Fire -> Water
    53784, -- Eternal Water -> Fire
    53771, -- Eternal Life -> Shadow
    53780, -- Eternal Shadow -> Life
    56001, -- Moonshroud
    56002, -- Ebonweave
    56003, -- Spellweave
    56005,  -- Glacial Bag
    60893, -- Northrend Alchemy Research
    61288, -- Minor Inscription Research
    61177, -- Major Inscription Research
    62242, -- Icy Prism
    55208, -- Smelt Titansteel
    -- End WOTLK
}
local items = {
    -- Start Vanilla
    -- [19567] = { duration = 259200 }, -- Salt Shaker (no cooldown in WOTLK)
    -- End Vanilla/Start WOTLK
    [40768] = {}, -- MollE
    [48933] = {}, -- Wormhole
    [49040] = {}, -- Jeeves
    [39878] = { skillId = 0, expansion = 2 }, -- Mysterious Egg
    -- [43499] = { skillId = 0, expansion = 2 }, -- Iron Boot Flask
    -- End WOTLK
}
local Cooldown = {}
ICT.Cooldown = Cooldown
ICT.Cooldowns = {}

function Cooldown:update(player)
    for id, v in pairs(ICT.Cooldowns) do
        if v:getSpell() then
            local spellKnown = IsPlayerSpell(id)
            if spellKnown then
                local start, duration = GetSpellCooldown(id)
                player.cooldowns[id] = player.cooldowns[id] or Cooldown:new(v)
                -- Check duration to filter out spell lock, wands and other CD triggers
                player.cooldowns[id].expires = start ~= 0 and duration == v.info.duration and ICT:GetTimeLeft(start, duration) or 0
            else
                -- Handles case if spell was known and no longer is.
                player.cooldowns[id] = nil
            end
        elseif v:getItem() then
            if GetItemCount(id, true) > 0 and C_PlayerInfo.CanUseItem(id) then
                player.cooldowns[id] = player.cooldowns[id] or Cooldown:new(v)
                local start, duration = C_Container.GetItemCooldown(id)
                player.cooldowns[id].expires = start ~= 0 and duration > 0 and ICT:GetTimeLeft(start, duration) or 0
            else
                -- Handles case item is gone. Doesn't handle not being able to use item.
                player.cooldowns[id] = nil
            end
        end
    end
end

function Cooldown:new(info)
    local t = { ["info"] = info }
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
        for _, p in pairs(player.professions) do
            if p.spellId ~= nil then
                CastSpellByID(p.spellId)
                for i = 1, GetNumTradeSkills() do
                    if GetTradeSkillInfo(i) == self:getSpell() then
                        DoTradeSkill(i)
                        CloseTradeSkill()
                        return
                    end
                end
            end
            CloseTradeSkill()
        end
        ICT:print("No skill found: %s", self:getSpell())
    end
end

function Cooldown:getSkillId()
    return self.info.skillId
end

function Cooldown:getSpell()
    return self.info.spellName
end

function Cooldown:getItem()
    return self.info.itemName
end

function Cooldown:getNameWithIcon()
    return string.format("|T%s:14|t%s", self.info.icon, self.info.name)
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
    if self.info.skillId == other.info.skillId then
        if self.info.expansion == other.info.expansion then
            return self.info.name < other.info.name
        end
        return self.info.expansion > other.info.expansion
    end
    return self.info.skillId < other.info.skillId
end

for _, id in pairs(spells) do
    local v = {}
    v.id = id

    local info = LibTradeSkillRecipes:GetInfoBySpellId(id)
    v.skillId = info.categoryId
    v.expansion = info.expansionId
    local name, _, icon = GetSpellInfo(id)
    v.icon = info.itemId and select(5, GetItemInfoInstant(info.itemId)) or icon
    v.spellName = name
    -- Remove transmute prefix.
    if name:find("Transmute:") then
        name = string.match(name, "Transmute: (.*)")
        v.transmute = true
    end
    v.name = name

    -- Converts ms to seconds
    v.duration = GetSpellBaseCooldown(id) / 1000
    if v.duration > 0 then
        ICT.Cooldowns[id] = Cooldown:new(v)
        -- print(string.format("|T%s:14|t %s = %s", v.icon, v.spellName, v.duration))
    else
        -- print("skipping ".. v.spellName)
    end
end

for id, v in pairs(items) do
    v.id = id

    v.icon = select(5, GetItemInfoInstant(id))
    local info = LibTradeSkillRecipes:GetInfoByItemId(id)
    v.skillId = v.skillId or info[1].categoryId
    if not v.skillId then
        ICT:print("Missing skillId: " .. id)
    end
    v.expansion = v.expansion or info[1].expansionId
    if not v.expansion then
        ICT:print("Missing expansion: " .. id)
    end
    -- Default values until loaded.
    v.name = id
    v.icon = "134400"
    local item = Item:CreateFromItemID(id)
    item:ContinueOnItemLoad(function()
        v.name = item:GetItemName()
        v.itemName = v.name
        if v.name:find("Wormhole Generator:") then
            v.name = string.match(v.name, "Wormhole Generator: (.*)")
        end
        v.icon = item:GetItemIcon()
        ICT:UpdateDisplay()
    end)
    ICT.Cooldowns[id] = Cooldown:new(v)
end