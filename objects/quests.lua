local addOnName, ICT = ...

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

local level80 = function(player)
    return player:isLevel(80)
end

local level25 = function(player)
    return player:isLevel(25)
end

local isJewelCrafter = function(player)
    return C_QuestLog.IsQuestFlaggedCompleted(13041) and player:isJewelCrafter(375)
end

local hasCooking = function(player)
    return player:isLevel(65) and player:hasCooking(350)
end

local hasFishing = function(player)
    return player:isLevel(70) and player:hasFishing()
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
        return select(1, C_QuestLog.GetQuestInfo(questId)) or "Unknnown"
    end
end

local function questId(id)
    return function()
        return select(1, C_QuestLog.GetQuestInfo(id)) or "Unknnown"
    end
end

ICT.Quests = {
    ["Raid Weekly"] = {
        name = ICT:returnX("Raid Weekly"),
        ids = { 24579 },
        currencies = { [ICT.Frost] = 10, [ICT.Triumph] = 5 },
        prereq = level80,
        weekly = true
    },
    ["ICC 25 Weekly"] = {
        name = ICT:returnX("ICC 25 Weekly"),
        ids = { 24876 },
        currencies = { [ICT.Frost] = 5 },
        prereq = level80,
        weekly = true
    },
    ["ICC 10 Weekly"] = {
        name = ICT:returnX("ICC 10 Weekly"),
        ids = { 24871 },
        currencies = { [ICT.Frost] = 5 },
        prereq = level80,
        weekly = true
    },
    ["Titan Rune Gamma Daily"] = {
        name = ICT:returnX("Titan Rune Gamma Daily"),
        ids = { 78752 },
        currencies = { [ICT.Frost] = 3 },
        prereq = level80,
    },
    ["Heroic Daily"] = {
        name = ICT:returnX("Heroic Daily"),
        -- ids = { 13245, 13246, 13247, 13248, 13249, 13250, 13251, 13252, 13253, 13254, 13255, 13256 }
        ids = { 78753 },
        currencies = { [ICT.Frost] = 2 },
        prereq = level80,
    },
    ["Jewelcrafting Daily"] = {
        name = ICT:returnX("Jewelcrafting Daily"),
        ids = { 12958, 12959, 12960, 12961, 12962, 12963, },
        currencies = { [ICT.JewelcraftersToken] = 1 },
        prereq = isJewelCrafter,
    },
    ["Cooking Daily"] = {
        name = ICT:returnX("Cooking Daily"),
        ids = { 13112, 13113, 13114, 13115, 13116, 13100, 13101, 13103, 13102, 13107},
        -- Mustard Dogs drops 2, but that requires the ability to detect the active daily.
        currencies = { [ICT.Epicurean] = 1 },
        prereq = hasCooking,
    },
    ["Fishing Daily"] = {
        name = ICT:returnX("Fishing Daily"),
        ids = { 13830, 13832, 13833, 13834, 13836 },
        currencies = {},
        prereq = hasFishing,
    },
    -- List of the Horde or Alliance quest and class if necessary (e.g. DeathKnights have separate quests in some cases).
    ["Threat From Above"] = {
        name = tournamentQuestName(13682, 13788, 13809, 13812),
        ids = { 13682, 13788, 13809, 13812 },
        currencies = { [ICT.ChampionsSeal] = 2 },
        prereq = isTournamentChainCompleted
    },
    ["Battle Before The Citadel"] = {
        name = tournamentQuestName(13861, 13864, 13862, 13863),
        ids = { 13861, 13862, 13863, 13864 },
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isTournamentChainCompleted
    },
    ["Among the Champions"] = {
        name = tournamentQuestName(13790, 13793, 13811, 13814),
        ids = { 13790, 13793, 13811, 13814 },
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isTournamentChainCompleted
    },
    ["Taking Battle To The Enemy"] = {
        name = tournamentQuestName(13789, 13791, 13810, 13813),
        ids = { 13789, 13791, 13810, 13813 },
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isTournamentChainCompleted
    },
    ["High Crusader Adelard"] = {
        name = ICT:returnX("High Crusader Adelard"),
        ids = { 14101, 14102, 14104, 14105 },
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isExaltedTournamentFaction
    },
    ["Crusader Silverdawn"] = {
        name = ICT:returnX("Crusader Silverdawn"),
        ids = { 14108, 14107 },
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isExaltedTournamentFaction,
    },
    ["Savinia Loresong"] = {
        name = factionQuestName("Savinia Loresong", "Tylos Dawnrunner"),
        -- Breakfast Of Champions / Gormok Wants His Snobolds / What Do You Feed a Yeti, Anyway?
        ids = { 14076, 14092, 14090, 14141, 14112, 14145 },
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isExaltedTournamentChampion,
    },
    ["Narasi Snowdawn"] = {
        name = factionQuestName("Narasi Snowdawn", "Girana the Blooded"),
        -- You've Really Done It This Time, Kul / A Leg Up / Rescue at Sea / Stop The Aggressors / The Light's Mercy
        ids = { 14096, 14142, 14074, 14143, 14136, 14152, 14080, 14140, 14077, 14144 },
        currencies = { [ICT.ChampionsSeal] = 1 },
        prereq = isExaltedTournamentChampion,
    },
    -- Season of Discovery.
    ["Ashenvale Weekly"] = {
        name = questId(79098),
        ids = { 79098 },
        currencies = {},
        prereq = level25,
        weekly = true
    }
}

-- Set the key on the value for convenient lookups to other tables, i.e. player infos.
for k, v in pairs(ICT.Quests) do
    v.key = k
    local quest = ICT.Quest:new(v)
    ICT.Quests[k] = quest:inExpansion() and quest or nil
end
