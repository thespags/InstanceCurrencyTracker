local _, ICT = ...

local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Cooldown = ICT.Cooldown
local Expansion = ICT.Expansion
local log = ICT.log
ICT.Cooldowns = {}

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
    56005, -- Glacial Bag
    60893, -- Northrend Alchemy Research
    61288, -- Minor Inscription Research
    61177, -- Major Inscription Research
    62242, -- Icy Prism
    55208, -- Smelt Titansteel
    -- End WOTLK/Start Cata
    78866, -- Transmute: Living Elements
    80243, -- Transmute: Truegold
    80244, -- Transmute: Pyrium Bar
    73478, -- Fire Prism
    75141, -- Dream of Skywall
    75142, -- Dream of Deepholm
    75144, -- Dream of Hyjal
    75145, -- Dream of Ragnaros
    75146, -- Dream of Azshara
    -- End Cata
}
local items = {
    -- Start Vanilla
    [15846] = { skillLine = 0, expansion = 0, maxExpansion = 1}, -- Salt Shaker (CD removed in WOTLK)
    [211527] =  { skillLine = 0, expansion = 0, maxExpansion = 0}, -- Sleeping Bag only SOD
    -- End Vanilla/Start WOTLK
    [40768] = { toy = true }, -- MollE
    [48933] = { toy = true }, -- Wormhole
    [49040] = {}, -- Jeeves
    -- [39878] = { skillLine = 0, expansion = 2 }, -- Mysterious Egg, doesn't work because it's a tooltip.
    -- [43499] = { skillLine = 0, expansion = 2 }, -- Iron Boot Flask
    -- End WOTLK
}

local function inExpansion(info)
    return info and info.expansionId and Expansion.active(info.expansionId)
end

for _, id in pairs(spells) do
    local v = {}
    v.id = id

    local info = LibTradeSkillRecipes:GetInfoBySpellId(id)
    if inExpansion(info) then
        v.skillLine = info.categoryId
        v.expansion = info.expansionId
        local name, _, icon = GetSpellInfo(id)
        v.icon = info.itemId and select(5, GetItemInfoInstant(info.itemId)) or icon
        v.spellName = name
        -- Remove transmute prefix, trying to ignore languages by just using :, 
        -- in the future we may have non transmutes with :.
        local i = name:find(":")
        if i then
            name = string.sub(name, i + 2)
            v.transmute = true
        end
        v.name = name
        v.link = GetSpellLink(id)

        -- Converts ms to seconds
        v.duration = GetSpellBaseCooldown(id) / 1000
        if v.duration > 0 then
            ICT.Cooldowns[id] = Cooldown:new(v)
            -- print(string.format("|T%s:14|t %s = %s", v.icon, v.spellName, v.duration))
        else
            -- print("skipping ".. v.spellName)
        end
    end
end

for id, v in pairs(items) do
    local info = LibTradeSkillRecipes:GetInfoByItemId(id)
    if inExpansion(info) or (Expansion.active(v.expansion) and Expansion.max(v.maxExpansion)) then
        v.id = id
        v.skillLine = v.skillLine or info[1].categoryId
        if not v.skillLine then
            log.error(L["Cooldown missing skillLine: %s"], id)
        end
        v.expansion = v.expansion or info[1].expansionId
        if not v.expansion then
            log.error(L["Cooldown missing expansion: %s"], id)
        end
        -- Default values until loaded.
        v.name = tostring(id)
        v.icon = "134400"
        v.link = id
        local item = Item:CreateFromItemID(id)
        item:ContinueOnItemLoad(function()
            v.name = item:GetItemName()
            v.itemName = v.name
            local i = v.name:find(":")
            if i then
                v.name = string.sub(v.name, i + 2)
            end
            v.icon = item:GetItemIcon()
            v.link = item:GetItemLink()
            -- Make sure function is loaded.
            if ICT.UpdateDisplay then
                ICT.UpdateDisplay()
            end
        end)
        ICT.Cooldowns[id] = Cooldown:new(v)
    end
end

-- local scanningTooltip = CreateFrame("GameTooltip", "ICTScanningTooltip", nil, "GameTooltipTemplate")
-- scanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE" )

-- local function parseReagents(unit)
--     scanningTooltip:ClearLines()
--     scanningTooltip:SetSpellByID(unit)
--     return _G["ICTScanningTooltipTextLeft2"]:GetText()
-- end

-- local function scanTooltip(unit)
--     print(unit)
--     scanningTooltip:ClearLines()
--     scanningTooltip:SetSpellByID(unit)
    
--     local i=1
--     while _G["ICTScanningTooltipTextLeft" .. i] do
--         local text = _G["ICTScanningTooltipTextLeft" .. i]:GetText()
--         if text and text ~= "" then print(text) end
--         i = i + 1
--     end
-- end

-- local function addReagents(tooltip)
--     local _, itemLink = tooltip:GetItem()
--     if itemLink == nil then
--         return
--     end
--     local itemId = GetItemInfoInstant(itemLink)
--     local info = LibTradeSkillRecipes:GetInfoByItemId(itemId)
--     local spellId = info and info[1] and info[1].spellId
--     if spellId then
--         local line = parseReagents(spellId)
--         tooltip:AddLine(line)
--     end
-- end

-- GameTooltip:HookScript("OnTooltipSetItem", addReagents)
-- ItemRefTooltip:HookScript("OnTooltipSetItem", addReagents)