local addOnName, ICT = ...

local Cooldowns = {
    spells = {
        -- Start Vanilla
        -- Iron -> Gold
        [11479] = { expansion = 0, transmute = true, icon = 133217 },
        -- Mithril -> Truesilver
        [11480] = { expansion = 0, transmute = true, icon = 133222 },
        -- Arcanite (no cooldown in WOTLK)
        [17187] = { expansion = 0, transmute = true, icon = 134459 },
        -- Earth -> Water
        [17561] = { expansion = 0, transmute = true, icon = 136007 },
        -- Water -> Air
        [17562] = { expansion = 0, transmute = true, icon = 136022 },
        -- Air -> Fire
        [17559] = { expansion = 0, transmute = true, icon = 135830 },
        -- Fire -> Earth
        [17560] = { expansion = 0, transmute = true, icon = 136102 },
        -- Undeath -> Water
        [17563] = { expansion = 0, transmute = true, icon = 136007 },
        -- Water -> Undeath
        [17564] = { expansion = 0, transmute = true, icon = 136195 },
        -- Life -> Earth
        [17565] = { expansion = 0, transmute = true, icon = 136102 },
        -- Earth -> Life
        [17566] = { expansion = 0, transmute = true, icon = 136006 },
        -- Elemental Fire
        [25146] = { expansion = 0, transmute = true, icon = 135805 },
        -- Salt Shaker (no cooldown in WOTLK)
        [19566] = { expansion = 0, icon = 132836 },
        -- Mooncloth
        [18560] = { expansion = 0, icon = 132895 },
        -- End Vanilla/Start TBC
        -- Earthstorm Diamond
        [32765] = { expansion = 1, transmute = true, icon = 134097 },
        -- Skyfire Diamond
        [32766] = { expansion = 1, transmute = true, icon = 134098 },
        -- Primal Might
        [29688] = { expansion = 1, transmute = true, icon = 136050 },
        -- Primal Earth -> Water
        [28567] = { expansion = 1, transmute = true, icon = 132852 },
        -- Primal Water -> Air
        [28569] = { expansion = 1, transmute = true, icon = 132845},
        -- Primal Air -> Fire
        [28566] = { expansion = 1, transmute = true, icon = 132847 },
        -- Primal Fire -> Earth
        [28568] = { expansion = 1, transmute = true, icon = 132846},
        -- Primal Shadow -> Water
        [28580] = { expansion = 1, transmute = true, icon = 132852 },
        -- Primal Water -> Shadow
        [28581] = { expansion = 1, transmute = true, icon = 132851},
        -- Primal Life -> Earth
        [28584] = { expansion = 1, transmute = true, icon = 132846 },
        -- Primal Earth -> Life
        [28585] = { expansion = 1, transmute = true, icon = 132848 },
        -- Primal Mana -> Fire
        [28582] = { expansion = 1, transmute = true, icon = 132847},
        -- Primal Fire -> Mana
        [28583] = { expansion = 1, transmute = true, icon = 132849 },
        -- Spellcloth
        [31373] = { expansion = 1, icon = 132910 },
        -- Shadowcloth
        [36686] = { expansion = 1, icon = 132887 },
        -- Primial Moonthcloth
        [26751] = { expansion = 1, icon = 132897 },
        -- Void Sphere
        [28028] = { expansion = 1, icon = 132886 },
        -- Brilliant Glass
        [47280] = { expansion = 1, icon = 134096 },
        -- End TBC/Start WOTLK
        -- Titanium
        [60350] = { expansion = 2, transmute = true, icon = 237045 },
        -- Earhtsiege Diamond
        [57427] = { expansion = 2, transmute = true, icon = 237243 },
        -- Skyflare Diamond
        [57425] = { expansion = 2, transmute = true, icon = 237235 },
        -- Ametrine
        [66658] = { expansion = 2, transmute = true, icon = 237221 },
        -- Cardinal Ruby
        [66659] = { expansion = 2, transmute = true, icon = 237220 },
        -- King's Amber
        [66660] = { expansion = 2, transmute = true, icon = 237224 },
        -- Dreadstone
        [66662] = { expansion = 2, transmute = true, icon = 237219 },
        -- Majestic Zircon
        [66663] = { expansion = 2, transmute = true, icon = 237223 },
        -- Eye of Zul
        [66664] = { expansion = 2, transmute = true, icon = 237222 },
        -- Eternal Air -> Earth
        [53777] = { expansion = 2, transmute = true, icon = 237008 },
        -- Eternal Earth -> Air
        [53781] = { expansion = 2, transmute = true, icon = 237007 },
        -- Eternal Air -> Water
        [53776] = { expansion = 2, transmute = true, icon = 237012 },
        -- Eternal Water -> Air
        [53783] = { expansion = 2, transmute = true, icon = 237007 },
        -- Eternal Shadow -> Earth
        [53779] = { expansion = 2, transmute = true, icon = 237008 },
        -- Eternal Earth -> Shadow
        [53782] = { expansion = 2, transmute = true, icon = 237011 },
        -- Eternal Life -> Fire
        [53773] = { expansion = 2, transmute = true, icon = 237009 },
        -- Eternal Fire -> Life
        [53775] = { expansion = 2, transmute = true, icon = 237010 },
        -- Eternal Fire -> Water
        [53774] = { expansion = 2, transmute = true, icon = 237012 },
        -- Eternal Water -> Fire
        [53784] = { expansion = 2, transmute = true, icon = 237009 },
        -- Eternal Life -> Shadow
        [53771] = { expansion = 2, transmute = true, icon = 237011 },
        -- Eternal Shadow -> Life
        [53780] = { expansion = 2, transmute = true, icon = 237010 },
        -- Moonshroud
        [56001] = { expansion = 2, icon = 237025 },
        -- Ebonweave
        [56002] = { expansion = 2, icon = 237022 },
        -- Spellweave
        [56003] = { expansion = 2, icon = 237026 },
        -- Glacial Bag
        [56005] = { expansion = 2, icon = 133666 },
        -- Northrend Alchemy Research
        [60893] = { expansion = 2, icon = 136240 },
        -- Minor Inscription Research
        [61288] = { expansion = 2, icon = 237171 },
        -- Major Inscription Research
        [61177] = { expansion = 2, icon = 237171 },
        -- Icy Prism
        [62242] = { expansion = 2, icon = 134095 },
        -- Smelt Titanstell
        [55208] = { expansion = 2, icon = 237046 },
        -- End WOTLK
    },
    items = {
        -- Start Vanilla
        -- End Vanilla/Start WOTLK
        -- Mysterious Egg
        [39878] = { expansion = 2, duration = 590400 },
        -- End WOTLK
    }
}
ICT.Cooldowns = Cooldowns

-- Note: The spell's icon doesn't match the icon of the item created.
-- We could use LibRecipes but that library is not complete,
-- so instead we hand code all icons.
for k, v in pairs(Cooldowns.spells) do
    v.id = k

    local name = GetSpellInfo(k)
    v.spellName = name
    -- Remove transmute prefix.
    if name:find(":") then
        name = string.match(name, ".*: (.*)")
    end
    v.name = name

    -- Converts ms to seconds
    v.duration = GetSpellBaseCooldown(k) / 1000
    if v.duration <= 0 then
        Cooldowns.spells[k] = nil
    end
    -- print(string.format("|T%s:14|t %s = %s", v.icon, v.name, v.duration))
end

for k, v in pairs(Cooldowns.items) do
    v.icon = select(5, GetItemInfoInstant(k))
    -- print(string.format("|T%s:14|t egg = %s", v.icon, v.duration))
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

function Cooldowns:updateCooldowns(player)
    for k, v in pairs(player.cooldowns) do
        
        player.cooldowns[k] = Cooldowns:new(v)
    end
    for spellId, info in pairs(Cooldowns.spells) do
        -- local spellData = player.cooldowns[spellId] or {}
        local spellKnown = IsPlayerSpell(spellId)

        if spellKnown then
            local start, duration = GetSpellCooldown(spellId)
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
                if GetTradeSkillInfo(i) == self.spellName then
                    DoTradeSkill(i)
                    CloseTradeSkill()
                    return
                end
            end
        end
        CloseTradeSkill()
    end
    print(string.format("[%s] No skill found: %s", addOnName, self.spellName))
end

function ICT.CooldownSort(a, b)
    if a.expansion == b.expansion then
        return a.name < b.name
    end
    return a.expansion > b.expansion
end