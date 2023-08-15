local addOnName, ICT = ...

local Cooldowns = {
    spells = {
        -- Start Vanilla
        -- Transmute
        [17564] = {label = "Transmute", prin},
        -- Mooncloth
        [18560] = {},
        -- End Vanilla/Start TBC
        -- Spellcloth
        [31373] = {},
        -- Shadowcloth
        [36686] = {},
        -- Primial Moonthcloth
        [26751] = {},
        -- Void Sphere
        [28028] = {},
        -- Brilliant Glass
        [47280] = {},
        -- End TBC/Start WOTLK
        -- Moonshroud
        [56001] = {},
        -- Ebonweave
        [56002] = {},
        -- Spellweave
        [56003] = {},
        -- Glacial Bag
        [56005] = {},
        -- Northrend Alchemy Research
        [60893] = {},
        -- Minor Inscription Research
        [61288] = {},
        -- Major Inscription Research
        [61177] = {},
        -- Icy Prism
        [62242] = {},
        -- Smelt Titanstell
        [55208] = {},
        -- End WOTLK
    },
    items = {
        -- Start Vanilla
        -- Salt Shaker (Note: Starting in WOTLK no, left here if we decide to support classic era...)
        [19566] = { duration = 0 },
        -- End Vanilla/Start WOTLK
        -- Mysterious Egg
        [39878] = { duration = 590400 },
        -- End WOTLK
    }
}
ICT.Cooldowns = Cooldowns

for k, v in pairs(Cooldowns.spells) do
    v.name, _, v.icon = GetSpellInfo(k)
    -- Converts ms to seconds
    v.duration = GetSpellBaseCooldown(k) / 1000
end
for k, v in pairs(Cooldowns.items) do
    v.icon = select(5, GetItemInfoInstant(k))
end

function Cooldowns:ConvertFrom32bitNegative(int32)
    -- Is a 32bit negative value?
    return int32 >= 0x80000000 / 1e3
    -- If so then convert.
    and int32 - 0x100000000 / 1e3
    -- If positive return original.
    or int32
end

function Cooldowns:GetTime64()
    return self:ConvertFrom32bitNegative(GetTime())
end

function Cooldowns:GetTimeLeft(start, duration)
    local now = self:GetTime64()
    local serverNow = GetServerTime()
    -- since start is relative to computer uptime it can be a negative if the cooldown started before you restarted your pc.
    start = self:ConvertFrom32bitNegative(start)
    if start > now then -- start negative 32b overflow while now is still negative (over 24d 20h 31m PC uptime)
        start = start - 0x100000000 / 1e3 -- adjust relative to negative now
    end
    return start - now + serverNow + duration
end

function Cooldowns:UpdateSpellData(player, spellId)
    -- local spellData = player.cooldowns[spellId] or {}
    local spellKnown = IsPlayerSpell(spellId)
    -- if inSpellId == transmuteId then
    --     for kId, _ in pairs(self.transmutes) do
    --         spellId=kId
    --         playerSpell=IsPlayerSpell(spellId)
    --         if playerSpell then break end
    --     end
    -- else
    --     spellId = inSpellId
    --     playerSpell = IsPlayerSpell(spellId)
    -- end

    if spellKnown then
        local start, duration = GetSpellCooldown(spellId)
        local info = self.spells[spellId]
        if not start then
            return
        end
        -- Check duration to filter out spell lock, wands and other CD triggers
        -- Is this needed?
        if start ~= 0 and duration ~= info.duration then
            return
        end
        player.cooldowns[spellId] = Cooldowns:new(info)
        player.cooldowns[spellId].expires = self:GetTimeLeft(start, duration)
    else
        -- Handles case if spell was known and no longer is.
        player.cooldowns[spellId] = nil
    end
end

-- Adds all the functions to the player.
function Cooldowns:new(spell)
    setmetatable(spell, self)
    self.__index = self
    return spell
end

function Cooldowns:cast(player)
    for _, p in pairs(player.professions) do
        if p.spellId ~= nil then
            CastSpellByID(p.spellId)
            for i = 1, GetNumTradeSkills() do
                if GetTradeSkillInfo(i) == self.name then
                    DoTradeSkill(i)
                    CloseTradeSkill()
                    return
                end
            end
        end
        CloseTradeSkill()
    end
    print(string.format("[%s] Not skill found: %s", self.name))
end