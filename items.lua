local addOn, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Player = ICT.Player

ICT.CheckSlotEnchant = {
	[INVSLOT_HEAD] = ICT:returnX(true),
	[INVSLOT_NECK] = ICT:returnX(false),
	[INVSLOT_SHOULDER] = ICT:returnX(true),
	[INVSLOT_BACK] = ICT:returnX(true),
	[INVSLOT_CHEST] = ICT:returnX(true),
	[INVSLOT_BODY] = ICT:returnX(false),
	[INVSLOT_TABARD] = ICT:returnX(false),
	[INVSLOT_WRIST] = ICT:returnX(true),
	[INVSLOT_HAND] = ICT:returnX(true),
	[INVSLOT_WAIST] = function(player) return Expansion.isWOTLK() and player:isEngineer() end,
	[INVSLOT_LEGS] = ICT:returnX(true),
	[INVSLOT_FEET] = ICT:returnX(true),
	[INVSLOT_FINGER1] = function(player) return Expansion.active(ICT.TBC) and player:isEnchanter() end,
	[INVSLOT_FINGER2] = function(player) return Expansion.active(ICT.TBC) and player:isEnchanter() end,
	[INVSLOT_TRINKET1] = ICT:returnX(false),
	[INVSLOT_TRINKET2] = ICT:returnX(false),
	[INVSLOT_MAINHAND] = ICT:returnX(true),
    [INVSLOT_RANGED] = function(player, _, _) return player.class == "HUNTER" end,
	[INVSLOT_OFFHAND] = function(_, classId, subClassId) return classId == 4 and subClassId == 6 end,
}

ICT.CheckSlotSocket = Expansion.isWOTLK() and {
	[INVSLOT_WRIST] = { check = Player.isBlacksmith, icon = 133273 },
	[INVSLOT_HAND] = { check = Player.isBlacksmith, icon = 132984 },
	[INVSLOT_WAIST] = { check = ICT:returnX(true), icon = 132525 },
} or {}

ICT.ItemTypeToSlot = {
	[INVTYPE_HEAD] = 1,
	[INVTYPE_NECK] = 2,
	[INVTYPE_SHOULDER] = 3,
	[INVTYPE_BODY] = 4,
	[INVTYPE_CHEST] = 5,
	[INVTYPE_WAIST] = 6,
	[INVTYPE_LEGS] = 7,
	[INVTYPE_FEET] = 8,
	[INVTYPE_WRIST] = 9,
	[INVTYPE_HAND] = 10,
	[INVTYPE_FINGER] = 11,
	[INVTYPE_TRINKET] = 13,
    [INVTYPE_CLOAK] = 15,
    [INVTYPE_WEAPONMAINHAND] = 16,
    [INVTYPE_WEAPONOFFHAND] = 16,
    [INVTYPE_2HWEAPON] = 16,
    [INVTYPE_SHIELD] = 17,
    [INVTYPE_RANGED] = 16,
    [INVTYPE_THROWN] = 16,
    [INVTYPE_TABARD] = 19,
}
ICT.SlotToItemType = tInvert(ICT.ItemTypeToSlot)

-- From https://wowdev.wiki/DB/ItemBagFamily
-- Values align with 2^(n - 1), except for the 0 case.
ICT.BagFamily = {
    -- Generic
    [0] = { icon = "Interface\\Addons\\InstanceCurrencyTracker\\icons\\backpack", name = L["General"] },
    -- Arrows
    [1] = { icon = 132382, name = L["Arrows"] },
    -- Bullets
    [2] = { icon = 249175, name = L["Bullets"] },
    -- Soul Shards
    [4] = { icon = 134075, name = L["Soul Shards"] },
    -- Leathworking 
    [8] = { icon = 133611, name = L["Leatherworking"] },
    -- Inscription 
    [16] = { icon = 237171, name = L["Inscription"] },
    -- Herbalism
    [32] = { icon = 136246, name = L["Herbalism"] },
    -- Enchanting 
    [64] = { icon = 136244, name = L["Enchanting"] },
    -- Engineering
    [128] = { icon = 136243, name = L["Engineering"] },
    -- Jewelcrafting
    [512] = { icon = 134071, name = L["Jewelcrafting"] },
    -- Mining
    [1024] = { icon = 136248, name = L["Mining"] },
}

function ICT:addGems(k, item, missingOnly)
    local gemTotal = 0
    local text = {}
    for _, gem in pairs(item.gems) do
        _ = not missingOnly and tinsert(text, string.format("|T%s:%s|t", gem, ICT.UI.iconSize))
        gemTotal = gemTotal + 1
    end
    -- Add '?' if you are missing ids.
    for _=gemTotal + 1,item.socketTotals do
        tinsert(text, string.format("|T134400:%s|t", ICT.UI.iconSize))
    end
    if gemTotal < item.socketTotals and item.extraSocket then
        tinsert(text, string.format("|T%s:%s|t", ICT.CheckSlotSocket[k].icon, ICT.UI.iconSize))
    end
    return table.concat(text)
end