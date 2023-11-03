local addOnName, ICT = ...

local Currency = {}
ICT.Currency = Currency

function Currency:new(id, unlimited)
    local currency = { id = id, unlimited = unlimited }
    setmetatable(currency, self)
    self.__index = self
    return currency
end

-- With Random LFD, currency is no longer limited.
function Currency:showLimit()
    return false
end

local function getNameWithIconTooltipSize(id, size)
    local currency = C_CurrencyInfo.GetCurrencyInfo(id)
    return string.format("|T%s:%s|t%s", currency["iconFileID"], size, currency["name"])
end

-- Creates a string with the icon and name of the provided currency.
function Currency:getNameWithIcon()
    self.nameWithIcon = self.nameWithIcon or getNameWithIconTooltipSize(self.id, ICT.UI.iconSize)
    return self.nameWithIcon
end

-- Returns the amount of currency the player has for the currency provided.
function Currency:getAmount()
    return C_CurrencyInfo.GetCurrencyInfo(self.id)["quantity"]
end

-- Returns the localized name of the currency provided.
function Currency:getName()
    return C_CurrencyInfo.GetCurrencyInfo(self.id)["name"]
end

function Currency:calculateAvailable(instances)
    local sum = 0
    for _, instance in pairs(instances) do
        if instance:hasCurrency(self) then
            instance.available = instance.available or {}
            instance.available[self.id] = instance:availableCurrency(self)
            sum = sum + instance.available[self.id]
        end
    end
    return sum
end

function Currency:calculateAvailableDungeon(player)
    return self:calculateAvailable(player:getDungeons())
end

function Currency:calculateAvailableRaid(player)
    return self:calculateAvailable(player:getRaids())
end

function Currency:calculateAvailableQuest(player, currency, f)
    local op = function(quest) return f(quest) and quest.prereq(player) and not quest:isCompleted() and quest.currencies[currency] or 0 end
    local filter = self:fromQuest()
    return ICT:sum(ICT.QuestInfo, op, filter)
end

function Currency:calculateAvailableDailyQuest(player, currency)
    return self:calculateAvailableQuest(player, currency, ICT.Quest.isDaily)
end

function Currency:calculateAvailableWeeklyQuest(player, currency)
    return self:calculateAvailableQuest(player, currency, ICT.Quest.isWeekly)
end

function Currency:calculateMax(instances)
    local op = function(v) return v:maxCurrency(self) end
    local filter = function(v) return v:hasCurrency(self) end
    return ICT:sum(instances, op, filter)
end

function Currency:calculateMaxDungeon(player)
    self.maxDungeon = self.maxDungeon or self:calculateMax(player:getDungeons())
    return self.maxDungeon
end

function Currency:calculateMaxRaid(player)
    self.maxRaid = self.maxRaid or self:calculateMax(player:getRaids())
    return self.maxRaid
end

function Currency:calculateMaxQuest(player, currency, f)
    local op = function(quest) return f(quest) and quest.prereq(player) and quest.currencies[currency] or 0 end
    local filter = self:fromQuest()
    return ICT:sum(ICT.QuestInfo, op, filter)
end

function Currency:calculateMaxDailyQuest(player, currency)
    return self:calculateMaxQuest(player, currency, ICT.Quest.isDaily)
end

function Currency:calculateMaxWeeklyQuest(player, currency)
    return self:calculateMaxQuest(player, currency, ICT.Quest.isWeekly)
end

function Currency:fromQuest()
    return function(quest) return quest.currencies[self] end
end

function Currency:isVisible()
    return ICT.db.options.currency[self.id]
end

function Currency:setVisible(v)
    ICT.db.options.currency[self.id] = v
end

function Currency:__eq(other)
    return self.order == other.order
end

function Currency:__lt(other)
    return self.order < other.order
end