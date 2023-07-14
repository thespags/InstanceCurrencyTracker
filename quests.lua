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

-- List of the Horde or Alliance quest and class if necessary (e.g. DeathKnights have separate quests in some cases).
local dailyChampionsSeals = {
    -- Threat From Above
    { ids = { 13682, 13788, 13809, 13812 }, seals = 2, prereq = isTournamentChainCompleted },
    -- Battle Before The Citadel
    { ids = { 13861, 13862, 13863, 13864 }, seals = 1, prereq = isTournamentChainCompleted },
    -- Among the Champions
    { ids = { 13790, 13793, 13811, 13814 }, seals = 1, prereq = isTournamentChainCompleted },
    -- Taking Battle To The Enemy
    { ids = { 13789, 13791, 13810, 13813 }, seals = 1, prereq = isTournamentChainCompleted },
    -- High Crusader Adelard 
    { ids = { 14101, 14102, 14104, 14105 }, seals = 1, prereq = isExaltedTournamentFaction },
    -- Crusader Silverdawn 
    { ids = { 14108, 14107}, seals = 1, prereq = isExaltedTournamentFaction },
    -- Tylos Dawnrunner / Savinia Loresong 
    -- Breakfast Of Champions / Gormok Wants His Snobolds / What Do You Feed a Yeti, Anyway?
    { ids = { 14076, 14092, 14090, 14141, 14112, 14145 }, seals = 1, prereq = isExaltedTournamentChampion},
    -- Girana the Blooded / Narasi Snowdawn
    -- You've Really Done It This Time, Kul / A Leg Up / Rescue at Sea / Stop The Aggressors / The Light's Mercy
    { ids = { 14096, 14142, 14074, 14143, 14136, 14152, 14080, 14140, 14077, 14144 }, seals = 1, prereq = isExaltedTournamentChampion}
}

local dailyHeroic = { 13245, 13246, 13247, 13248, 13249, 13250, 13251, 13252, 13253, 13254, 13255, 13256 }
local dailyNormal = { 13240, 13241, 13243, 13244 }

Quests.DailyNormalEmblems = 2
Quests.DailyHeroicEmblems = 5

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

-- Return the available champions seals based on quests, reputation, and achievements for the current player.
function Quests:CalculateChampionsSeals()
    -- Count available champion's seal total if the prereq is met.
    local countChampionsSeals = function(v) 
        return v.prereq() and not self:IsDailyCompleted(v.ids) and v.seals or 0
    end
    return Utils:sum(dailyChampionsSeals, countChampionsSeals)
end

-- Returns the available daily heroic emblems, i.e. the daily herioc quest (2) plus last boss bag (3).
-- This counts the quest and bag together, instead of separately.
-- I'm not aware of how to determine the daily instance through the WOW API.
function Quests:CalculateDailyHeroic()
    return self:IsDailyCompleted(dailyHeroic) and 0 or self.DailyHeroicEmblems
end

-- Returns the available daily normal emblems, i.e. the dailly normal quest (2).
function Quests:CalculateDailyNormal()
    return self:IsDailyCompleted(dailyNormal) and 0 or self.DailyNormalEmblems
end