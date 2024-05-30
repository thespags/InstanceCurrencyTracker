local _, ICT = ...
local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")

local isTournamentChainCompleted = function()
    -- Check for Death Knight and non Death Knight prereq quest.
    return C_QuestLog.IsQuestFlaggedCompleted(13794) or C_QuestLog.IsQuestFlaggedCompleted(13795)
end

local isExaltedTournamentFaction = function()
    -- Checks for Horde or Alliance Exalted, 8 is the reputation id for exalted.
    return 8 == select(3, GetFactionInfoByID(1124)) or 8 == select(3, GetFactionInfoByID(1094))
end

local isExaltedTournamentChampion = function()
    -- Check for Horde or Alliance Tournament Champion.
    return select(4, GetAchievementInfo(2816)) or select(4, GetAchievementInfo(2817))
end

local factionQuestName = function(hordeName, allianceName)
    return function(player)
        return player.faction == "Horde" and hordeName or player.faction == "Alliance" and allianceName or "Unknown"
    end
end

local function questName(id)
    return select(1, C_QuestLog.GetQuestInfo(id)) or "Unknown"
end

local factionQuestNameById = function(hordeId, allianceId)
    return function(player)
        return player.faction == "Horde" and questName(hordeId) or player.faction == "Alliance" and questName(allianceId) or "Unknown"
    end
end

local level80 = function(player)
    return player:isLevel(80)
end

local level25Sod = function(player)
    return Expansion.isSod(player) and player:isLevel(25)
end

-- All these quests appear to have the same name, but for fun or overkill, load the correct quest for the player.
local tournamentQuestName = function(nonDeathKnightAllianceId, deathKnightAllianceId, deathKnightHordeId, nonDeathKnightHordeId)
    return function(player)
        local questId
        if player.faction == "Horde" then
            questId = player.class == "DEATHKNIGHT" and deathKnightHordeId or nonDeathKnightHordeId
        elseif player.faction == "Alliance" then
            questId = player.class == "DEATHKNIGHT" and deathKnightAllianceId or nonDeathKnightAllianceId
        else
            return "Unknown"
        end
        return questName(questId)
    end
end

local dailyCataQuest = function(group ,questId, prereqId, faction)
    return {
        group = group,
        name = function() return questName(questId) end,
        ids = { questId },
        expansion = ICT.Cata,
        currencies = {},
        prereq = function() return C_QuestLog.IsQuestFlaggedCompleted(prereqId) end,
        faction = faction
    }
end

ICT.QuestGroups = {
    ["Hyjal"] = { name = C_Map.GetMapInfo(198).name, expansion = ICT.Cata },
    ["Deepholm"] = { name = C_Map.GetMapInfo(207).name, expansion = ICT.Cata },
    ["Uldum"] = { name = C_Map.GetMapInfo(249).name, expansion = ICT.Cata },
    ["Twilight Highlands"] = { name = C_Map.GetMapInfo(241).name, expansion = ICT.Cata },
    ["Jewelcrafting"] = { name = L["Jewelcrafting"], expansion = ICT.Cata },
    ["Cooking"] = { name = L["Cooking"], expansion = ICT.Cata },
    ["Fishing"] = { name = L["Fishing"], expansion = ICT.Cata },
    ["Justice Points"] = { name = C_CurrencyInfo.GetCurrencyInfo(395).name, expansion = ICT.Cata },
    ["Argent Tournament"] = { name = select(1, GetFactionInfoByID(1106)), expansion = ICT.WOTLK },
}

ICT.Quests = {
    ["Vigilance on Wings"] = dailyCataQuest("Hyjal", 29177, 25810),
    ["Fungal Fury"] = dailyCataQuest("Deepholm", 27050, 26709),
    ["Soft Rock"] = dailyCataQuest("Deepholm", 27049, 26709),
    ["Through Persistence"] = dailyCataQuest("Deepholm", 27051, 26709),
    ["Fear of Boring"] = dailyCataQuest("Deepholm", 27046, 26709),
    ["Motes"] = dailyCataQuest("Deepholm", 27047, 26709),
    ["Rotating Deepholm"] = {
        group = "Deepholm",
        name = ICT:returnX("Rotating Deepholm"),
        ids = { 26710 },
        expansion = ICT.Cata,
        currencies = {},
        prereq = function() return C_QuestLog.IsQuestFlaggedCompleted(26709) end,
    },
    ["Revered Rotating Deepholm"] = {
        group = "Deepholm",
        name = ICT:returnX("Revered Rotating Deepholm"),
        ids = { 28390 },
        expansion = ICT.Cata,
        currencies = {},
        prereq = function() return C_QuestLog.IsQuestFlaggedCompleted(26709) and 7 == select(3, GetFactionInfoByID(1171)) end,
    },
    ["Fire From the Sky"] = dailyCataQuest("Uldum", 28736, 28482),
    ["Thieving Little Pluckers"] = dailyCataQuest("Uldum", 28250, 28134),
    ["Beer Run"] = dailyCataQuest("Twilight Highlands", 28864, 28655, "Alliance"),
    ["Keeping the Dragonmaw at Bay"] = dailyCataQuest("Twilight Highlands", 28860, 28655, "Alliance"),
    ["Fight Like a Wildhammer"] = dailyCataQuest("Twilight Highlands", 28861, 28655, "Alliance"),
    ["Never Leave a Dinner Behind"] = dailyCataQuest("Twilight Highlands", 28862, 28655, "Alliance"),
    ["Warlord Halthar is Back"] = dailyCataQuest("Twilight Highlands", 28863, 28655, "Alliance"),
    ["Another Maw to Feed"] = dailyCataQuest("Twilight Highlands", 28873, 28133, "Horde"),
    ["Bring Down the High Shaman"] = dailyCataQuest("Twilight Highlands", 28875, 28133, "Horde"),
    ["Crushing the Wildhammer"] = dailyCataQuest("Twilight Highlands", 28871, 28133, "Horde"),
    ["Hook 'em High"] = dailyCataQuest("Twilight Highlands", 28874, 28133, "Horde"),
    ["Total War"] = dailyCataQuest("Twilight Highlands", 28872, 28133, "Horde"),
    ["Cata Jewelcrafting Daily"] = {
        group = "Jewelcrafting",
        name = ICT:returnX("Cata Jewelcrafting Daily"),
        ids = { 25154 },
        expansion = ICT.Cata,
        currencies = { [ICT.CataJewelcraftersToken] = 1 },
        prereq = function(player) return player:isJewelCrafter(475) end,
    },
    ["Cata Cooking Daily"] = {
        group = "Cooking",
        name = ICT:returnX("Cata Cooking Daily"),
        ids = { 26227, 26190 },
        expansion = ICT.Cata,
        currencies = { [ICT.ChefsAward] = 2 },
        prereq = function(player) return player:isLevel(10) and player:hasCooking() end,
        weekly = true
    },
    ["Cata Fishing Daily"] = {
        group = "Fishing",
        name = ICT:returnX("Cata Fishing Daily"),
        -- Fishing quests seem to be weird in being loaded, so provide a lot of ids for overkill.
        ids = {
            -- Darnassus
            29325, 29359, 29321, 29323, 29324,
            -- Stormwind
            26488, 26420, 26414, 26442, 26536,
            -- Orgrimmar
            26588, 26572, 26557, 26543, 26556 },
        expansion = ICT.Cata,
        currencies = {},
        prereq = function(player) return player:isLevel(10) and player:hasFishing() end,
    },
    ["Wotlk Raid Weekly"] = {
        group = "Justice Points",
        name = ICT:returnX("Wotlk Raid Weekly"),
        ids = { 24579 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.JusticePoints] = 138 },
        prereq = level80,
        weekly = true
    },
    -- ["ICC 25 Weekly"] = {
    --     name = ICT:returnX("ICC 25 Weekly"),
    --     ids = { 24876 },
    --     expansion = ICT.WOTLK,
    --     currencies = { [ICT.Frost] = 5 },
    --     prereq = level80,
    --     weekly = true
    -- },
    -- ["ICC 10 Weekly"] = {
    --     name = ICT:returnX("ICC 10 Weekly"),
    --     ids = { 24871 },
    --     expansion = ICT.WOTLK,
    --     currencies = { [ICT.Frost] = 5 },
    --     prereq = level80,
    --     weekly = true
    -- },
    ["Titan Rune Gamma Daily"] = {
        group = "Justice Points",
        name = ICT:returnX("Titan Rune Gamma Daily"),
        ids = { 78752 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.JusticePoints] = 34 },
        prereq = level80,
    },
    ["Wotlk Heroic Daily"] = {
        group = "Justice Points",
        name = ICT:returnX("Wotlk Heroic Daily"),
        expansion = ICT.WOTLK,
        -- ids = { 13245, 13246, 13247, 13248, 13249, 13250, 13251, 13252, 13253, 13254, 13255, 13256 }
        ids = { 78753 },
        currencies = { [ICT.JusticePoints] = 23 },
        prereq = level80,
    },
    ["Wotlk Jewelcrafting Daily"] = {
        group = "Jewelcrafting",
        name = ICT:returnX("Wotlk Jewelcrafting Daily"),
        ids = { 12958, 12959, 12960, 12961, 12962, 12963, },
        expansion = ICT.WOTLK,
        currencies = { [ICT.WotlkJewelcraftersToken] = 1 },
        prereq = function(player) return C_QuestLog.IsQuestFlaggedCompleted(13041) and player:isJewelCrafter(375) end,
    },
    ["Wotlk Cooking Daily"] = {
        group = "Cooking",
        name = ICT:returnX("Wotlk Cooking Daily"),
        ids = { 13112, 13113, 13114, 13115, 13116, 13100, 13101, 13103, 13102, 13107},
        expansion = ICT.WOTLK,
        -- Mustard Dogs drops 2, but that requires the ability to detect the active daily.
        currencies = { [ICT.Epicurean] = 1 },
        prereq = function(player) return player:isLevel(65) and player:hasCooking(350) end,
    },
    ["Wotlk Fishing Daily"] = {
        group = "Fishing",
        name = ICT:returnX("Wotlk Fishing Daily"),
        ids = { 13830, 13832, 13833, 13834, 13836 },
        expansion = ICT.WOTLK,
        currencies = {},
        prereq = function(player) return player:isLevel(70) and player:hasFishing() end,
    },
    -- List of the Horde or Alliance quest and class if necessary (e.g. DeathKnights have separate quests in some cases).
    ["Threat From Above"] = {
        group = "Argent Tournament",
        name = tournamentQuestName(13682, 13788, 13809, 13812),
        ids = { 13682, 13788, 13809, 13812 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.ChampionsSeal] = 2 },
        prereq = isTournamentChainCompleted
    },
    ["Battle Before The Citadel"] = {
        group = "Argent Tournament",
        name = tournamentQuestName(13861, 13864, 13862, 13863),
        ids = { 13861, 13862, 13863, 13864 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isTournamentChainCompleted
    },
    ["Among the Champions"] = {
        group = "Argent Tournament",
        name = tournamentQuestName(13790, 13793, 13811, 13814),
        ids = { 13790, 13793, 13811, 13814 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isTournamentChainCompleted
    },
    ["Taking Battle To The Enemy"] = {
        group = "Argent Tournament",
        name = tournamentQuestName(13789, 13791, 13810, 13813),
        ids = { 13789, 13791, 13810, 13813 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isTournamentChainCompleted
    },
    ["High Crusader Adelard"] = {
        group = "Argent Tournament",
        name = ICT:returnX("High Crusader Adelard"),
        ids = { 14101, 14102, 14104, 14105 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isExaltedTournamentFaction
    },
    ["Crusader Silverdawn"] = {
        group = "Argent Tournament",
        name = ICT:returnX("Crusader Silverdawn"),
        ids = { 14108, 14107 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isExaltedTournamentFaction,
    },
    ["Savinia Loresong"] = {
        group = "Argent Tournament",
        name = factionQuestName("Savinia Loresong", "Tylos Dawnrunner"),
        -- Breakfast Of Champions / Gormok Wants His Snobolds / What Do You Feed a Yeti, Anyway?
        ids = { 14076, 14092, 14090, 14141, 14112, 14145 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isExaltedTournamentChampion,
    },
    ["Narasi Snowdawn"] = {
        group = "Argent Tournament",
        name = factionQuestName("Narasi Snowdawn", "Girana the Blooded"),
        -- You've Really Done It This Time, Kul / A Leg Up / Rescue at Sea / Stop The Aggressors / The Light's Mercy
        ids = { 14096, 14142, 14074, 14143, 14136, 14152, 14080, 14140, 14077, 14144 },
        expansion = ICT.WOTLK,
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isExaltedTournamentChampion,
    },
    -- Season of Discovery.
    ["Ashenvale Weekly"] = {
        group = "SOD",
        name = factionQuestNameById(79098, 79090),
        ids = { 79098, 79090 },
        expansion = ICT.Vanilla,
        currencies = {},
        prereq = level25Sod,
        weekly = true
    }
}

-- Set the key on the value for convenient lookups to other tables, i.e. player infos.
for k, v in pairs(ICT.Quests) do
    v.key = k
    local quest = ICT.Quest:new(v)
    ICT.Quests[k] = quest:inExpansion() and quest or nil
end
