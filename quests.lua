Quests = {}

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

function barf(hordeName, allianceName)
    return function(player)
        return player.faction == "Horde" and hordeName or player.faction == "Alliance" and allianceName or "Unknown"
    end
end

function foobar(nonDeathKnightAllianceID, deathKnightAllianceID, deathKnightHordeID, nonDeathKnightHordeID)
    return function(player)
        local questID
        if player.faction == "Horde" then
            questID = player.class == "DEATHKNIGHT" and deathKnightHordeID or nonDeathKnightHordeID
        elseif player.faction == "Alliance" then
            questID = player.class == "DEATHKNIGHT" and deathKnightAllianceID or nonDeathKnightAllianceID
        else
            return "Unknown"
        end
        return select(1, C_TaskQuest.GetQuestInfoByQuestID(questID))
    end
end

foobar(13682, 13788, 13809, 13812)
foobar(13861, 13864, 13862, 13863)
foobar(13790, 13793, 13811, 13814)
foobar(13789, 13791, 13810, 13813)

Quests = {
    [Utils.Triumph] = {
        -- Heroic Daily Dungeon
        -- This counts the quest and bag together, instead of separately.
        { ids = { 13245, 13246, 13247, 13248, 13249, 13250, 13251, 13252, 13253, 13254, 13255, 13256 }, seals = 5, prereq = ReturnX(true) }
    },
    [Utils.Conquest] = {
        -- Normal Daily Dungeon
        { ids = { 13240, 13241, 13243, 13244 }, seals = 2, prereq = ReturnX(true) }
    },
    -- List of the Horde or Alliance quest and class if necessary (e.g. DeathKnights have separate quests in some cases).
    [Utils.ChampionsSeal] = {
        -- Threat From Above
        { ids = { 13682, 13788, 13809, 13812 }, seals = 2, prereq = isTournamentChainCompleted },
        -- Battle Before The Citadel
        { ids = { 13861, 13862, 13863, 13864 }, seals = 1, prereq = isTournamentChainCompleted },
        -- Among the Champions
        { ids = { 13790, 13793, 13811, 13814 }, seals = 1, prereq = isTournamentChainCompleted },
        -- Taking Battle To The Enemy
        { ids = { 13789, 13791, 13810, 13813 }, seals = 1, prereq = isTournamentChainCompleted },
        {
            name = ReturnX("High Crusader Adelard"),
            ids = { 14101, 14102, 14104, 14105 },
            seals = 1,
            prereq = isExaltedTournamentFaction
        },
        {
            name = ReturnX("Crusader Silverdawn"),
            ids = { 14108, 14107}, 
            seals = 1,
            prereq = isExaltedTournamentFaction,
        },
        -- Breakfast Of Champions / Gormok Wants His Snobolds / What Do You Feed a Yeti, Anyway?
        {
            name = barf("Savinia Loresong", "Tylos Dawnrunner"),
            ids = { 14076, 14092, 14090, 14141, 14112, 14145 },
            seals = 1,
            prereq = isExaltedTournamentChampion,
        },
        -- You've Really Done It This Time, Kul / A Leg Up / Rescue at Sea / Stop The Aggressors / The Light's Mercy
        { 
            name = barf("Narasi Snowdawn", " Girana the Blooded"),
            ids = { 14096, 14142, 14074, 14143, 14136, 14152, 14080, 14140, 14077, 14144 },
            seals = 1,
            prereq = isExaltedTournamentChampion,
        }
    }
}

-- As far as I can tell, WOW groups daily quests, i.e. we could check a single quest of the group to check completed.
-- However, to be overly cautious check all quests in the groups looking for any true value.
function Quests:IsDailyCompleted(ids)
    for _, id in pairs(ids) do
        if C_QuestLog.IsQuestFlaggedCompleted(id) then
            return true
        end
    end
    return false
end

function Quests:CalculateAvailableDaily(tokenId)
    return function(player)
        local emblems = 0
        for _, v in pairs(Quests[tokenId] or {}) do
            emblems = emblems + (v.prereq and not self:IsDailyCompleted(v.ids) and v.seals or 0)
        end
        return emblems
    end
end

function Quests:CalculateMaxDaily(tokenId)
    return function(player)
        local emblems = 0
        for _, v in pairs(Quests[tokenId] or {}) do
            emblems = emblems + (v.prereq and v.seals or 0)
        end
        return emblems
    end
end