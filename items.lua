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

local x = {}
local function addEnchant(spellId, effectId, slots)
    for _, slot in pairs(slots) do
        x[effectId] = x[effectId] or {}
        x[effectId][slot] = ICT:getSpellLink(spellId) or L["Missing"]
    end
end

function ICT:getEnchant(effectId, slot)
    return x[effectId] and x[effectId][slot]
end

addEnchant(2832, 16, {5,7,8,10,20})
addEnchant(2833, 17, {5,7,8,10,20})
addEnchant(3974, 30, {16})
addEnchant(2831, 15, {5,7,8,10,20})
addEnchant(2605, 1, {16})
addEnchant(3231, 76, {15})
addEnchant(3975, 32, {16})
addEnchant(3976, 33, {16})
addEnchant(6476, 1436, {15})
addEnchant(6296, 36, {16})
addEnchant(7216, 43, {17})
addEnchant(7793, 723, {16})
addEnchant(7776, 246, {5,20})
addEnchant(7745, 241, {16})
addEnchant(7786, 249, {16})
addEnchant(7788, 250, {16})
addEnchant(8375, 906, {10})
addEnchant(7859, 255, {9})
addEnchant(7863, 66, {8})
addEnchant(7748, 242, {5,20})
addEnchant(7220, 37, {16})
addEnchant(7420, 41, {5,20})
addEnchant(7867, 247, {8})
addEnchant(7428, 924, {9})
addEnchant(7771, 783, {15})
addEnchant(7861, 256, {15})
addEnchant(7218, 34, {16})
addEnchant(7857, 254, {5,20})
addEnchant(7454, 65, {15})
addEnchant(7457, 66, {9})
addEnchant(7779, 247, {9})
addEnchant(7766, 243, {9})
addEnchant(7426, 44, {5,20})
addEnchant(7418, 41, {9})
addEnchant(7782, 248, {9})
addEnchant(9781, 463, {17})
addEnchant(7443, 24, {5,20})
addEnchant(9783, 464, {8})
addEnchant(10344, 18, {5,7,8,10,20})
addEnchant(29467, 2721, {3})
addEnchant(12460, 664, {16})
addEnchant(13631, 724, {17})
addEnchant(13695, 1897, {16})
addEnchant(13522, 804, {15})
addEnchant(13529, 943, {16})
addEnchant(13935, 904, {8})
addEnchant(13887, 856, {10})
addEnchant(13646, 925, {9})
addEnchant(13620, 2603, {10})
addEnchant(13622, 723, {9})
addEnchant(13648, 852, {9})
addEnchant(13890, 911, {8})
addEnchant(13905, 907, {17})
addEnchant(13501, 724, {9})
addEnchant(12459, 663, {16})
addEnchant(13380, 255, {16})
addEnchant(13503, 241, {16})
addEnchant(13939, 927, {9})
addEnchant(13378, 66, {17})
addEnchant(13612, 844, {10})
addEnchant(13635, 848, {15})
addEnchant(13841, 906, {10})
addEnchant(13815, 904, {10})
addEnchant(13607, 843, {5,20})
addEnchant(13941, 928, {5,20})
addEnchant(13419, 247, {15})
addEnchant(13626, 847, {5,20})
addEnchant(13817, 852, {17})
addEnchant(13485, 255, {17})
addEnchant(13464, 848, {17})
addEnchant(13421, 744, {15})
addEnchant(13947, 930, {10})
addEnchant(13661, 856, {9})
addEnchant(13822, 905, {9})
addEnchant(13898, 803, {16})
addEnchant(13794, 903, {15})
addEnchant(13663, 857, {5,20})
addEnchant(13836, 852, {8})
addEnchant(13933, 926, {17})
addEnchant(13700, 866, {5,20})
addEnchant(13687, 255, {8})
addEnchant(13536, 823, {9})
addEnchant(13917, 913, {5,20})
addEnchant(13943, 805, {16})
addEnchant(13538, 63, {5,20})
addEnchant(13931, 923, {9})
addEnchant(13945, 929, {9})
addEnchant(13637, 849, {8})
addEnchant(13640, 850, {5,20})
addEnchant(13693, 943, {16})
addEnchant(13689, 863, {17})
addEnchant(13642, 851, {9})
addEnchant(13915, 912, {16})
addEnchant(13846, 907, {9})
addEnchant(13617, 845, {10})
addEnchant(13937, 963, {16})
addEnchant(13644, 724, {8})
addEnchant(15402, 1508, {1,7})
addEnchant(15397, 1506, {1,7})
addEnchant(13882, 849, {15})
addEnchant(15400, 1507, {1,7})
addEnchant(13746, 884, {15})
addEnchant(13653, 853, {16})
addEnchant(13655, 854, {16})
addEnchant(13858, 908, {5,20})
addEnchant(15394, 1505, {1,7})
addEnchant(13948, 931, {10})
addEnchant(15340, 1483, {1,7})
addEnchant(13868, 909, {10})
addEnchant(13657, 2463, {15})
addEnchant(15463, 1532, {7})
addEnchant(13659, 851, {17})
addEnchant(13698, 865, {10})
addEnchant(15439, 1525, {7})
addEnchant(15391, 1504, {1,7})
addEnchant(15444, 1527, {7})
addEnchant(15427, 1523, {7})
addEnchant(15458, 1530, {7})
addEnchant(15404, 1509, {1,7})
addEnchant(16623, 1704, {17})
addEnchant(15406, 1510, {1,7})
addEnchant(14847, 1023, {16})
addEnchant(15441, 1526, {7})
addEnchant(15389, 1503, {1,7})
addEnchant(15446, 1528, {7})
addEnchant(15449, 1529, {7})
addEnchant(15490, 1543, {7})
addEnchant(15429, 1524, {7})
addEnchant(20016, 1890, {17})
addEnchant(20010, 1885, {9})
addEnchant(20015, 1889, {15})
addEnchant(20017, 929, {17})
addEnchant(20026, 1892, {5,20})
addEnchant(20028, 1893, {5,20})
addEnchant(20035, 1903, {16})
addEnchant(20013, 927, {10})
addEnchant(20036, 1904, {16})
addEnchant(19927, 803, {16})
addEnchant(20029, 1894, {16})
addEnchant(19932, 1341, {15})
addEnchant(20025, 1891, {5,20})
addEnchant(20008, 1883, {9})
addEnchant(20009, 1884, {9})
addEnchant(20012, 1887, {10})
addEnchant(20023, 1887, {8})
addEnchant(20014, 1888, {15})
addEnchant(20024, 851, {8})
addEnchant(19057, 1843, {5,7,8,10,20})
addEnchant(20020, 929, {8})
addEnchant(20011, 1886, {9})
addEnchant(22105, 1887, {10})
addEnchant(20033, 1899, {16})
addEnchant(20030, 1896, {16})
addEnchant(20031, 1897, {16})
addEnchant(20032, 1898, {16})
addEnchant(22101, 1887, {8})
addEnchant(20034, 1900, {16})
addEnchant(22844, 2544, {1,7})
addEnchant(22100, 1890, {17})
addEnchant(22779, 2523, {16})
addEnchant(22052, 1886, {9})
addEnchant(22089, 1892, {5,20})
addEnchant(22104, 927, {10})
addEnchant(22106, 931, {10})
addEnchant(22846, 2545, {1,7})
addEnchant(22095, 1897, {16})
addEnchant(22054, 1883, {9})
addEnchant(22102, 851, {8})
addEnchant(22597, 2486, {3})
addEnchant(22598, 2485, {3})
addEnchant(22051, 1885, {9})
addEnchant(22750, 2505, {16})
addEnchant(22053, 1884, {9})
addEnchant(22599, 2488, {3})
addEnchant(22593, 2483, {3})
addEnchant(22596, 2487, {3})
addEnchant(22840, 2543, {1,7})
addEnchant(22091, 1888, {15})
addEnchant(22092, 1889, {15})
addEnchant(22749, 2504, {16})
addEnchant(21931, 2443, {16})
addEnchant(22090, 1893, {5,20})
addEnchant(22594, 2484, {3})
addEnchant(23799, 2563, {16})
addEnchant(23800, 2564, {16})
addEnchant(24165, 2589, {1,7})
addEnchant(23142, 1894, {16})
addEnchant(22098, 929, {17})
addEnchant(22099, 926, {17})
addEnchant(23801, 2565, {9})
addEnchant(23143, 2504, {16})
addEnchant(23141, 1900, {16})
addEnchant(23144, 2505, {16})
addEnchant(23804, 2568, {16})
addEnchant(22094, 1896, {16})
addEnchant(22725, 2503, {5,7,8,10,20})
addEnchant(22103, 929, {8})
addEnchant(23803, 2567, {16})
addEnchant(24302, 846, {16})
addEnchant(24420, 2604, {3})
addEnchant(24161, 3755, {1,7})
addEnchant(24422, 2606, {3})
addEnchant(23802, 2650, {9})
addEnchant(24421, 2605, {3})
addEnchant(24162, 3754, {1,7})
addEnchant(24163, 2587, {1,7})
addEnchant(24164, 2588, {1,7})
addEnchant(24160, 2584, {1,7})
addEnchant(26019, 911, {8})
addEnchant(24167, 2590, {1,7})
addEnchant(24168, 2591, {1,7})
addEnchant(24149, 2583, {1,7})
addEnchant(25083, 910, {15})
addEnchant(26020, 909, {10})
addEnchant(25086, 2622, {15})
addEnchant(25081, 2619, {15})
addEnchant(25084, 2621, {15})
addEnchant(25079, 2617, {10})
addEnchant(25080, 2564, {10})
addEnchant(25082, 2620, {15})
addEnchant(25072, 2613, {10})
addEnchant(25073, 2614, {10})
addEnchant(25074, 2615, {10})
addEnchant(25078, 2616, {10})
addEnchant(27093, 2563, {16})
addEnchant(27120, 910, {15})
addEnchant(28163, 2682, {1,7})
addEnchant(27121, 2621, {15})
addEnchant(27122, 2622, {15})
addEnchant(28161, 2681, {1,7})
addEnchant(27837, 2646, {16})
addEnchant(28165, 2683, {1,7})
addEnchant(27104, 1898, {16})
addEnchant(26743, 2567, {16})
addEnchant(27116, 2566, {9})
addEnchant(27117, 863, {17})
addEnchant(27118, 2619, {15})
addEnchant(27119, 2620, {15})
addEnchant(27113, 2613, {10})
addEnchant(27114, 865, {10})
addEnchant(27115, 2565, {9})
addEnchant(27102, 1899, {16})
addEnchant(27107, 1891, {5,20})
addEnchant(27109, 2616, {10})
addEnchant(27108, 2615, {10})
addEnchant(26793, 2568, {16})
addEnchant(27110, 2614, {10})
addEnchant(27111, 2617, {10})
addEnchant(27112, 2564, {10})
addEnchant(26792, 2564, {16})
addEnchant(30187, 846, {10})
addEnchant(30190, 930, {10})
addEnchant(29480, 2716, {3})
addEnchant(29483, 2717, {3})
addEnchant(30183, 803, {16})
addEnchant(30229, 2646, {16})
addEnchant(29475, 2715, {3})
addEnchant(27961, 2662, {15})
addEnchant(27962, 2664, {15})
addEnchant(27964, 1898, {16})
addEnchant(27967, 963, {16})
addEnchant(27968, 2666, {16})
addEnchant(27971, 2667, {16})
addEnchant(27972, 2668, {16})
addEnchant(27975, 2669, {16})
addEnchant(27977, 2670, {16})
addEnchant(27981, 2671, {16})
addEnchant(27982, 2672, {16})
addEnchant(27984, 2673, {16})
addEnchant(28003, 2674, {16})
addEnchant(28004, 2675, {16})
addEnchant(27899, 2647, {9})
addEnchant(27905, 1891, {9})
addEnchant(27906, 2648, {9})
addEnchant(27911, 2650, {9})
addEnchant(27913, 2679, {9})
addEnchant(27914, 2649, {9})
addEnchant(27917, 2650, {9})
addEnchant(27920, 2929, {11})
addEnchant(27924, 2928, {11})
addEnchant(27926, 2930, {11})
addEnchant(27927, 2931, {11})
addEnchant(27944, 2653, {17})
addEnchant(27945, 2654, {17})
addEnchant(27946, 2655, {17})
addEnchant(27947, 1888, {17})
addEnchant(27948, 2656, {8})
addEnchant(27950, 2649, {8})
addEnchant(27951, 2657, {8})
addEnchant(27954, 2658, {8})
addEnchant(27957, 2659, {5,20})
addEnchant(27958, 3233, {5,20})
addEnchant(27960, 2661, {5,20})
addEnchant(29454, 2714, {17})
addEnchant(30250, 2722, {16})
addEnchant(30252, 2723, {16})
addEnchant(30255, 2523, {16})
addEnchant(30258, 2724, {16})
addEnchant(30260, 2724, {16})
addEnchant(31369, 2745, {7})
addEnchant(31370, 2746, {7})
addEnchant(31371, 2747, {7})
addEnchant(31372, 2748, {7})
addEnchant(32397, 2792, {5,7,8,10,20})
addEnchant(32398, 2793, {5,7,8,10,20})
addEnchant(32399, 2794, {5,7,8,10,20})
addEnchant(33990, 1144, {5,20})
addEnchant(33991, 3150, {5,20})
addEnchant(33992, 2933, {5,20})
addEnchant(33993, 2934, {10})
addEnchant(33994, 2935, {10})
addEnchant(33995, 684, {10})
addEnchant(33996, 1594, {10})
addEnchant(33997, 2937, {10})
addEnchant(33999, 2322, {10})
addEnchant(34001, 369, {9})
addEnchant(34002, 1593, {9})
addEnchant(34003, 2938, {15})
addEnchant(34004, 368, {15})
addEnchant(34005, 1257, {15})
addEnchant(34006, 1441, {15})
addEnchant(34007, 2939, {8})
addEnchant(34008, 2940, {8})
addEnchant(34009, 1071, {17})
addEnchant(34010, 3846, {16})
addEnchant(35441, 2998, {3})
addEnchant(35443, 2999, {1})
addEnchant(35445, 3001, {1})
addEnchant(35447, 3002, {1})
addEnchant(35452, 3003, {1})
addEnchant(35453, 3004, {1})
addEnchant(35454, 3005, {1})
addEnchant(35455, 3006, {1})
addEnchant(35456, 3007, {1})
addEnchant(35457, 3008, {1})
addEnchant(35458, 3009, {1})
addEnchant(35402, 2978, {3})
addEnchant(35403, 2979, {3})
addEnchant(35404, 2980, {3})
addEnchant(35405, 2981, {3})
addEnchant(35406, 2982, {3})
addEnchant(35407, 2983, {3})
addEnchant(35415, 2984, {5,7,8,10,20})
addEnchant(35416, 2985, {5,7,8,10,20})
addEnchant(35417, 2986, {3})
addEnchant(35418, 2987, {5,7,8,10,20})
addEnchant(35419, 2988, {5,7,8,10,20})
addEnchant(35420, 2989, {5,7,8,10,20})
addEnchant(35432, 2990, {3})
addEnchant(35433, 2991, {3})
addEnchant(35355, 2977, {3})
addEnchant(35434, 2992, {3})
addEnchant(35435, 2993, {3})
addEnchant(35436, 2994, {3})
addEnchant(35437, 2995, {3})
addEnchant(35438, 2996, {3})
addEnchant(35439, 2997, {3})
addEnchant(35791, 2343, {16})
addEnchant(35792, 2675, {16})
addEnchant(35793, 2673, {16})
addEnchant(35794, 2672, {16})
addEnchant(35795, 2671, {16})
addEnchant(35796, 2669, {16})
addEnchant(35797, 2666, {16})
addEnchant(35798, 963, {16})
addEnchant(35799, 2668, {16})
addEnchant(35800, 2670, {16})
addEnchant(36281, 2929, {11})
addEnchant(36282, 2928, {11})
addEnchant(36283, 2930, {11})
addEnchant(35801, 2667, {16})
addEnchant(35802, 1888, {17})
addEnchant(35803, 1071, {17})
addEnchant(36284, 2931, {11})
addEnchant(36285, 2664, {15})
addEnchant(36286, 2656, {8})
addEnchant(35804, 2654, {17})
addEnchant(35805, 2655, {17})
addEnchant(35806, 2940, {8})
addEnchant(35807, 2939, {8})
addEnchant(35808, 2658, {8})
addEnchant(35809, 2657, {8})
addEnchant(35488, 3010, {7})
addEnchant(35489, 3011, {7})
addEnchant(35810, 2649, {8})
addEnchant(35811, 1441, {15})
addEnchant(35812, 1257, {15})
addEnchant(35813, 368, {15})
addEnchant(35490, 3012, {7})
addEnchant(35814, 2938, {15})
addEnchant(35815, 2322, {10})
addEnchant(35816, 2937, {10})
addEnchant(35495, 3013, {7})
addEnchant(35817, 2935, {10})
addEnchant(35818, 2934, {10})
addEnchant(35819, 684, {10})
addEnchant(35820, 1594, {10})
addEnchant(35821, 2933, {5,20})
addEnchant(35822, 2376, {5,20})
addEnchant(35823, 1144, {5,20})
addEnchant(35824, 2661, {5,20})
addEnchant(35825, 2660, {5,20})
addEnchant(35826, 2659, {5,20})
addEnchant(37889, 3095, {1})
addEnchant(37891, 3096, {1})
addEnchant(39403, 369, {9})
addEnchant(39404, 1593, {9})
addEnchant(39405, 2617, {9})
addEnchant(39406, 2650, {9})
addEnchant(39407, 2648, {9})
addEnchant(39408, 2649, {9})
addEnchant(39409, 2679, {9})
addEnchant(39410, 1891, {9})
addEnchant(39411, 2647, {9})
addEnchant(42012, 2674, {16})
addEnchant(42687, 3223, {16})
addEnchant(42974, 3225, {16})
addEnchant(43005, 3225, {16})
addEnchant(42620, 3222, {16})
addEnchant(45697, 3269, {16})
addEnchant(44968, 2841, {1,3,5,7,8,10,20})
addEnchant(44769, 3260, {10})
addEnchant(44383, 3229, {17})
addEnchant(45028, 2662, {15})
addEnchant(48401, 3315, {})
addEnchant(48555, 3289, {})
addEnchant(48556, 3315, {})
addEnchant(48557, 3289, {})
addEnchant(47051, 2648, {15})
addEnchant(46578, 3273, {16})
addEnchant(46594, 1951, {5,20})
addEnchant(47103, 3289, {})
addEnchant(359639, 1593, {9})
addEnchant(359640, 910, {15})
addEnchant(359641, 2564, {10})
addEnchant(359642, 2567, {16})
addEnchant(359685, 3229, {17})
addEnchant(359847, 2621, {15})
addEnchant(359858, 2613, {10})
addEnchant(359895, 926, {17})
addEnchant(359949, 2620, {15})
addEnchant(359950, 2619, {15})
addEnchant(62256, 3850, {9})
addEnchant(62257, 3851, {16})
addEnchant(62447, 3853, {7})
addEnchant(44633, 1103, {16})
addEnchant(44484, 3231, {10})
addEnchant(44635, 2326, {9})
addEnchant(44488, 3234, {10})
addEnchant(44591, 1951, {15})
addEnchant(44494, 1400, {15})
addEnchant(44575, 3845, {9})
addEnchant(44645, 3839, {11})
addEnchant(44500, 983, {15})
addEnchant(44576, 3241, {16})
addEnchant(44506, 3238, {10})
addEnchant(44582, 3243, {15})
addEnchant(44509, 2381, {5,20})
addEnchant(44510, 3844, {16})
addEnchant(44588, 3245, {5,20})
addEnchant(44590, 1446, {15})
addEnchant(44524, 3239, {16})
addEnchant(44592, 3246, {10})
addEnchant(44593, 1147, {9})
addEnchant(44528, 1075, {8})
addEnchant(44595, 3247, {16})
addEnchant(44612, 3249, {10})
addEnchant(44489, 1952, {17})
addEnchant(44555, 1119, {9})
addEnchant(44623, 3252, {5,20})
addEnchant(44556, 1354, {15})
addEnchant(44508, 1147, {8})
addEnchant(44630, 3828, {16})
addEnchant(44631, 3256, {15})
addEnchant(47898, 3831, {15})
addEnchant(47899, 3296, {15})
addEnchant(47900, 3297, {5,20})
addEnchant(47901, 3232, {8})
addEnchant(47766, 1953, {5,20})
addEnchant(47715, 1119, {9})
addEnchant(50465, 3319, {16})
addEnchant(50901, 3325, {7})
addEnchant(50903, 3327, {7})
addEnchant(50906, 3329, {1,3,5,7,8,10,20})
addEnchant(50911, 3331, {7})
addEnchant(50913, 3332, {7})
addEnchant(50904, 3328, {7})
addEnchant(52639, 3290, {15})
addEnchant(53331, 3366, {16})
addEnchant(53342, 3367, {16})
addEnchant(53343, 3370, {16})
addEnchant(53344, 3368, {16})
addEnchant(54447, 3595, {16})
addEnchant(54793, 3601, {6})
addEnchant(55630, 3718, {7})
addEnchant(55631, 3719, {7})
addEnchant(55632, 3720, {7})
addEnchant(55769, 3728, {15})
addEnchant(55642, 3722, {15})
addEnchant(54998, 3603, {10})
addEnchant(54999, 3604, {10})
addEnchant(55076, 3607, {16})
addEnchant(57701, 3763, {9})
addEnchant(58126, 3775, {3})
addEnchant(58128, 3776, {3})
addEnchant(58129, 3777, {3})
addEnchant(57690, 3757, {9})
addEnchant(57692, 3759, {9})
addEnchant(57694, 3760, {9})
addEnchant(57696, 3761, {9})
addEnchant(59954, 3817, {1})
addEnchant(59771, 3793, {3})
addEnchant(59777, 3795, {1})
addEnchant(59778, 3796, {1})
addEnchant(59784, 3797, {1})
addEnchant(59927, 3806, {3})
addEnchant(59928, 3807, {3})
addEnchant(59929, 3875, {3})
addEnchant(59625, 3790, {16})
addEnchant(59932, 3876, {3})
addEnchant(59934, 3808, {3})
addEnchant(59936, 3809, {3})
addEnchant(59941, 3811, {3})
addEnchant(59636, 3791, {11})
addEnchant(59944, 3812, {1})
addEnchant(59946, 3814, {1})
addEnchant(59948, 3816, {1})
addEnchant(60623, 3826, {8})
addEnchant(60691, 3827, {16})
addEnchant(61120, 3838, {3})
addEnchant(61271, 3842, {1})
addEnchant(60707, 3833, {16})
addEnchant(60714, 3834, {16})
addEnchant(60582, 3823, {7})
addEnchant(60583, 3327, {7})
addEnchant(60668, 1603, {10})
addEnchant(60606, 3824, {8})
addEnchant(61117, 3835, {3})
addEnchant(60616, 1600, {9})
addEnchant(60763, 1597, {8})
addEnchant(61118, 3836, {3})
addEnchant(61119, 3837, {3})
addEnchant(62948, 3854, {16})
addEnchant(62959, 3855, {16})
addEnchant(63765, 3859, {15})
addEnchant(64579, 3870, {16})
addEnchant(64441, 3869, {16})
addEnchant(67839, 3878, {1})
addEnchant(70164, 3883, {16})
addEnchant(71692, 846, {10})
addEnchant(44119, 3228, {9})
addEnchant(44529, 3222, {10})
addEnchant(44598, 3231, {9})
addEnchant(44513, 3829, {10})
addEnchant(55634, 3721, {7})
addEnchant(48036, 3297, {5,20})
addEnchant(60609, 3825, {15})
addEnchant(60653, 1128, {17})
addEnchant(47672, 3294, {15})
addEnchant(60663, 1099, {15})
addEnchant(63746, 3858, {8})
addEnchant(44589, 983, {8})
addEnchant(59947, 3815, {1})
addEnchant(60692, 3832, {5,20})
addEnchant(59970, 3820, {1})
addEnchant(55002, 3605, {15})
addEnchant(56353, 3748, {17})
addEnchant(44483, 3230, {15})
addEnchant(50902, 3326, {7})
addEnchant(55777, 3730, {15})
addEnchant(60584, 3328, {7})
addEnchant(44625, 3253, {10})
addEnchant(59773, 3794, {3})
addEnchant(57691, 3758, {9})
addEnchant(53323, 3365, {16})
addEnchant(62384, 3852, {3})
addEnchant(59945, 3813, {1})
addEnchant(44616, 2661, {9})
addEnchant(44584, 3244, {8})
addEnchant(55016, 3606, {8})
addEnchant(62201, 3849, {17})
addEnchant(54736, 3599, {6})
addEnchant(56039, 3872, {7})
addEnchant(59955, 3818, {1})
addEnchant(54446, 3594, {16})
addEnchant(44621, 3251, {16})
addEnchant(56034, 3873, {7})
addEnchant(44636, 3840, {11})
addEnchant(55135, 3608, {16})
addEnchant(59621, 3789, {16})
addEnchant(53341, 3369, {16})
addEnchant(59960, 3819, {1})
addEnchant(57699, 3762, {9})
addEnchant(50909, 3330, {1,3,5,7,8,10,20})
addEnchant(59937, 3810, {3})
addEnchant(44492, 3236, {5,20})
addEnchant(60767, 2332, {9})
addEnchant(44596, 1262, {15})
addEnchant(57683, 3756, {9})
addEnchant(61468, 3843, {16})
addEnchant(44629, 3830, {16})
addEnchant(60581, 3822, {7})
addEnchant(63770, 3860, {10})
addEnchant(60621, 1606, {16})
addEnchant(59619, 3788, {16})
addEnchant(62158, 3847, {16})
addEnchant(55836, 3731, {16})
