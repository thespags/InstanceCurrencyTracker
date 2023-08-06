local addOnName, ICT = ...

ICT.Quests = {}
local Quests = ICT.Quests

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

local level80 = function()
    return UnitLevel("Player") == ICT.MaxLevel
end

local getProfessionRank = function(player, id)
    local icon = select(3, GetSpellInfo(id))
    for _, v in pairs(player.professions or {}) do
        if v.icon == icon then
            return v.rank
        end
    end
    return -1
end

local isJewelCrafter = function(player)
    return C_QuestLog.IsQuestFlaggedCompleted(13041) and getProfessionRank(player, 51311) >= 375
end

local isCook = function(player)
    return UnitLevel("Player") >= 65 and getProfessionRank(player, 51296) >= 350
end

-- All these quests appear to have the same name, but for fun or overkill, load the correct quest for the player.
local tournamentQuestName = function(nonDeathKnightAllianceID, deathKnightAllianceID, deathKnightHordeID, nonDeathKnightHordeID)
    return function(player)
        local questID
        if player.faction == "Horde" then
            questID = player.class == "DEATHKNIGHT" and deathKnightHordeID or nonDeathKnightHordeID
        elseif player.faction == "Alliance" then
            questID = player.class == "DEATHKNIGHT" and deathKnightAllianceID or nonDeathKnightAllianceID
        else
            return "Unknown"
        end
        return select(1, C_QuestLog.GetQuestInfo(questID))
    end
end

ICT.QuestInfo = {
    -- This counts the quest and bag together, instead of separately.
    ["Heroic Daily Dungeon"] = {
        name = ICT:ReturnX("Heroic Daily Dungeon"),
        ids = { 13245, 13246, 13247, 13248, 13249, 13250, 13251, 13252, 13253, 13254, 13255, 13256 },
        seals = 5,
        tokenId = ICT.Triumph,
        prereq = level80,
    },
    ["Normal Daily Dungeon"] = {
        name = ICT:ReturnX("Normal Daily Dungeon"),
        ids = { 13240, 13241, 13243, 13244 },
        seals = 2,
        tokenId = ICT.Conquest,
        prereq = level80,
    },
    ["Jewelcrafting Daily"] = {
        name = ICT:ReturnX("Jewelcrafting Daily"),
        ids = { 12958, 12959, 12960, 12961, 12962, 12963, },
        seals = 1,
        tokenId = ICT.JewelcraftersToken,
        prereq = isJewelCrafter,
    },
    ["Cooking Daily"] = {
        name = ICT:ReturnX("Cooking Daily"),
        ids = { 13112, 13113, 13114, 13115, 13116, 13100, 13101, 13103, 13102, 13107},
        -- Mustard Dogs drops 2, but that requires the ability to detect the active daily.
        seals = 1,
        tokenId = ICT.Epicurean,
        prereq = isCook,
    },
    -- List of the Horde or Alliance quest and class if necessary (e.g. DeathKnights have separate quests in some cases).
    ["Threat From Above"] = {
        name = tournamentQuestName(13682, 13788, 13809, 13812),
        ids = { 13682, 13788, 13809, 13812 },
        seals = 2,
        tokenId = ICT.ChampionsSeal,
        prereq = isTournamentChainCompleted
    },
    ["Battle Before The Citadel"] = {
        name = tournamentQuestName(13861, 13864, 13862, 13863),
        ids = { 13861, 13862, 13863, 13864 },
        seals = 1,
        tokenId = ICT.ChampionsSeal,
        prereq = isTournamentChainCompleted
    },
    ["Among the Champions"] = {
        name = tournamentQuestName(13790, 13793, 13811, 13814),
        ids = { 13790, 13793, 13811, 13814 },
        seals = 1,
        tokenId = ICT.ChampionsSeal,
        prereq = isTournamentChainCompleted
    },
    ["Taking Battle To The Enemy"] = {
        name = tournamentQuestName(13789, 13791, 13810, 13813),
        ids = { 13789, 13791, 13810, 13813 },
        seals = 1,
        tokenId = ICT.ChampionsSeal,
        prereq = isTournamentChainCompleted
    },
    ["High Crusader Adelard"] = {
        name = ICT:ReturnX("High Crusader Adelard"),
        ids = { 14101, 14102, 14104, 14105 },
        seals = 1,
        tokenId = ICT.ChampionsSeal,
        prereq = isExaltedTournamentFaction
    },
    ["Crusader Silverdawn"] = {
        name = ICT:ReturnX("Crusader Silverdawn"),
        ids = { 14108, 14107}, 
        seals = 1,
        tokenId = ICT.ChampionsSeal,
        prereq = isExaltedTournamentFaction,
    },
    ["Savinia Loresong"] = {
        name = factionQuestName("Savinia Loresong", "Tylos Dawnrunner"),
        -- Breakfast Of Champions / Gormok Wants His Snobolds / What Do You Feed a Yeti, Anyway?
        ids = { 14076, 14092, 14090, 14141, 14112, 14145 },
        seals = 1,
        tokenId = ICT.ChampionsSeal,
        prereq = isExaltedTournamentChampion,
    },
    ["Narasi Snowdawn"] = {
        name = factionQuestName("Narasi Snowdawn", " Girana the Blooded"),
        -- You've Really Done It This Time, Kul / A Leg Up / Rescue at Sea / Stop The Aggressors / The Light's Mercy
        ids = { 14096, 14142, 14074, 14143, 14136, 14152, 14080, 14140, 14077, 14144 },
        seals = 1,
        tokenId = ICT.ChampionsSeal,
        prereq = isExaltedTournamentChampion,
    }
}
-- Set the key on the value for convenient lookups to other tables, i.e. player infos.
for k, v in pairs(ICT.QuestInfo) do
    v.key = k
end

-- As far as I can tell, WOW groups daily quests, i.e. we could check a single quest of the group to check completed.
-- However, to be overly cautious check all quests in the groups looking for any true value.
function Quests:IsDailyCompleted(quest)
    for _, id in pairs(quest.ids) do
        if C_QuestLog.IsQuestFlaggedCompleted(id) then
            return true
        end
    end
    return false
end

function Quests:TokenFilter(tokenId)
    return function(v) return v.tokenId == tokenId end
end

function Quests:CalculateAvailableDaily(tokenId)
    return function(player)
        local emblems = 0
        for _, v in ICT:fpairsByValue(ICT.QuestInfo, self:TokenFilter(tokenId)) do
            emblems = emblems + (v.prereq and not self:IsDailyCompleted(v) and v.seals or 0)
        end
        return emblems
    end
end

function Quests:CalculateMaxDaily(tokenId)
    return function(player)
        local emblems = 0
        for _, v in ICT:fpairsByValue(ICT.QuestInfo, self:TokenFilter(tokenId)) do
            emblems = emblems + (v.prereq and v.seals or 0)
        end
        return emblems
    end
end

function ICT.QuestSort(player)
    return function(a, b)
        if ICT.db.options.orderLockLast then
            if a.locked and not b.locked then
                return false
            end
            if not a.locked and b.locked then
                return true
            end
        end
        if a.tokenId == b.tokenId then
            return a.name(player) < b.name(player)
        else
            return ICT.CurrencySort(a.tokenId, b.tokenId)
        end
    end
end