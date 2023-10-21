local addOnName, ICT = ...

local Quest = {}
ICT.Quest = Quest

-- Adds all the functions to the player.
function Quest:new(quest)
    setmetatable(quest, self)
    self.__index = self
    quest.order = ICT:maxKey(quest.currencies)
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
    return ICT:containsAnyValue(self.currencies, ICT.Currency.isVisible) or ICT.db.options.quests[self.key]
end

function Quest:isWeekly()
    return self.weekly or false
end

function Quest:isDaily()
    return not self.weekly
end

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

        if a.order == b.order then
            return a.name(player) < b.name(player)
        elseif a.order and b.order then
            return a.order < b.order
        else
            return a.order ~= nil
        end
    end
end