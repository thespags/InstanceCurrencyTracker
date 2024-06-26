local _, ICT = ...

local Quest = {}
ICT.Quest = Quest

-- Adds all the functions to the player.
function Quest:new(quest)
    setmetatable(quest, self)
    self.__index = self
    -- This a currency, not a number.
    quest.order = ICT:maxKey(quest.currencies)
    return quest
end

-- Grab the first id and try it.
function Quest:inExpansion()
    for _, id in pairs(self.ids) do
        if C_QuestLog.GetQuestInfo(id) ~= nil then
            return true
        end
    end
    return false
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
    return ICT:containsAnyKey(self.currencies, ICT.Currency.isVisible) or ICT.db.options.quests[self.key]
end

function Quest:isWeekly()
    return self.weekly or false
end

function Quest:isDaily()
    return not self.weekly
end

function ICT.QuestSort(player)
    return function(a, b)
        if ICT.db.options.sort.orderLockLast then
            if player:isQuestCompleted(a) and not player:isQuestCompleted(b) then
                return false
            end
            if not player:isQuestCompleted(a) and player:isQuestCompleted(b) then
                return true
            end
        end

        -- Orders by the highest currency for the quest.
        -- If matching, orders dailies before weeklies,
        -- then by name.
        if a.order == b.order then
            if a.weekly == b.weekly then
                return a.name(player) < b.name(player)
            end
            return b.weekly
        elseif a.order and b.order then
            return a.order < b.order
        else
            return a.order ~= nil
        end
    end
end