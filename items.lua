local addOn, ICT = ...

local Player = ICT.Player

-- TODO check if this is available in wow db?
ICT.CheckSlotEnchant = {
	[INVSLOT_HEAD] = ICT:ReturnX(true),
	[INVSLOT_NECK] = ICT:ReturnX(false),
	[INVSLOT_SHOULDER] = ICT:ReturnX(true),
	[INVSLOT_BACK] = ICT:ReturnX(true),
	[INVSLOT_CHEST] = ICT:ReturnX(true),
	[INVSLOT_BODY] = ICT:ReturnX(false),
	[INVSLOT_TABARD] = ICT:ReturnX(false),
	[INVSLOT_WRIST] = ICT:ReturnX(true),
	[INVSLOT_HAND] = ICT:ReturnX(true),
	[INVSLOT_WAIST] = Player.isEngineer,
	[INVSLOT_LEGS] = ICT:ReturnX(true),
	[INVSLOT_FEET] = ICT:ReturnX(true),
	[INVSLOT_FINGER1] = Player.isEnchanter,
	[INVSLOT_FINGER2] = Player.isEnchanter,
	[INVSLOT_TRINKET1] = ICT:ReturnX(false),
	[INVSLOT_TRINKET2] = ICT:ReturnX(false),
	[INVSLOT_MAINHAND] = ICT:ReturnX(true),
    [INVSLOT_RANGED] = function(player, _, _) return player.class == "HUNTER" end,
	[INVSLOT_OFFHAND] = function(_, classId, subClassId) return classId == 4 and subClassId == 6 end,
}

ICT.CheckSlotSocket = {
	[INVSLOT_WRIST] = { check = Player.isBlacksmith, icon = 133273 },
	[INVSLOT_HAND] = { check = Player.isBlacksmith, icon = 132984 },
	[INVSLOT_WAIST] = { check = ICT:ReturnX(true), icon = 132525 },
}

-- From https://wowdev.wiki/DB/ItemBagFamily
-- Values align with 2^(n - 1), except for the 0 case.
ICT.BagFamily = {
    -- Generic
    [0] = { icon = "Interface\\Addons\\InstanceCurrencyTracker\\icons\\backpack", name = "General" },
    -- Arrows
    [1] = { icon = 41165, name = "Arrows" },
    -- Bullets
    [2] = { icon = 249175, name = "Bullets" },
    -- Soul Shards
    [4] = { icon = 134075, name = "Soul Shards" },
    -- Leathworking 
    [8] = { icon = 133611, name = select(1, GetSpellInfo(51302))},
    -- Inscription 
    [16] = { icon = 237171, name = select(1, GetSpellInfo(45357))},
    -- Herbalism
    [32] = { icon = 136246, name = select(1, GetSpellInfo(265820))},
    -- Enchanting 
    [64] = { icon = 136244, name = select(1, GetSpellInfo(51313))},
    -- Engineering
    [128] = { icon = 136243, name = select(1, GetSpellInfo(51306))},
    -- Jewelcrafting
    [512] = { icon = 134071, name = select(1, GetSpellInfo(51311))},
    -- Mining
    [1024] = { icon = 136248, name = select(1, GetSpellInfo(50310))},
}
