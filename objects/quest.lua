local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Quest = {}
ICT.Quest = Quest

-- Adds all the functions to the player.
function Quest:new(quest)
    setmetatable(quest, self)
    self.__index = self
    return quest
end

-- As far as I can tell, WOW groups daily quests, i.e. we could check a single quest of the group to check completed.
-- However, to be overly cautious check all quests in the groups looking for any true value.
function Quest:isCompleted()
    for _, id in pairs(self.ids) do
        if C_QuestLog.IsQuestFlaggedCompleted(id) then
            return true
        end
    end
    return false
end

function Quest:isVisible()
    return self.currency and self.currency:isVisible() or ICT.db.options.quests[self.key]
end

function Quest:getCurrencyName()
    return self.currency and self.currency:getNameWithIconTooltip() or L["No Currency"]
end

function Quest:isWeekly()
    return self.weekly or false
end

function Quest:isDaily()
    return not self.weekly
end

-- This would be nicer if it wasn't player dependent.
-- In general, I believe quests are the same name across factions but may have different quest givers.
-- However, I don't always have a common name for "some group of quests".
-- If we had enough users we could share the specific quest id, but that isn't the same across realms (and probably not factions).
function ICT.QuestSort(player)
    return function(a, b)
        if ICT.db.options.frame.orderLockLast then
            if player:isQuestCompleted(a) and not player:isQuestCompleted(b) then
                return false
            end
            if not player:isQuestCompleted(a) and player:isQuestCompleted(b) then
                return true
            end
        end
        if a.currency == b.currency then
            return a.name(player) < b.name(player)
        elseif a.currency and b.currency then
            return a.currency < b.currency
        else
            return a.currency ~= nil
        end
    end
end