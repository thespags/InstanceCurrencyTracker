local addOnName, ICT = ...

local Currency = {}
-- Adds all the functions to the player.
function Currency:new(id, unlimited)
    local currency = { id = id, unlimited = unlimited }
    setmetatable(currency, self)
    self.__index = self
    return currency
end

-- Creates a string with the icon and name of the provided currency.
function Currency:getNameWithIcon()
    local currency = C_CurrencyInfo.GetCurrencyInfo(self.id)
    return string.format("|T%s:12:12|t%s", currency["iconFileID"], currency["name"])
end

-- Creates a string with the icon and name of the provided currency.
function Currency:getNameWithIconTooltip()
    local currency = C_CurrencyInfo.GetCurrencyInfo(self.id)
    return string.format("|T%s:14:14|t%s", currency["iconFileID"], currency["name"])
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

function Currency:calculateAvailableQuest(player)
    local emblems = 0
    for _, quest in ICT:fpairsByValue(ICT.QuestInfo, self.fromQuest) do
        emblems = emblems + (quest.prereq(player) and not quest:isDailyCompleted() and quest.amount or 0)
    end
    return emblems
end

local maxTokens = {}
function Currency:calculateMax(instances)
    -- Lock the value once we calculated as it doesn't change.
    -- It probably doesn't matter for performance but let's do it.
    -- Resets on reload in case this value is updated on new version.
    if maxTokens[self.id] then
        return maxTokens[self.id]
    end
    local op = function(v) return v:maxCurrency(self) end
    local filter = function(v) return v:hasCurrency(self) end
    maxTokens[self.id] = ICT:sum(instances, op, filter)
    return maxTokens[self.id]
end

function Currency:calculateMaxDungeon(player)
    return self:calculateMax(player:getDungeons())
end

function Currency:calculateMaxRaid(player)
    return self:calculateMax(player:getRaids())
end

function Currency:calculateMaxQuest(player)
    local emblems = 0
    for _, quest in ICT:fpairsByValue(ICT.QuestInfo, self.fromQuest) do
        emblems = emblems + (quest.prereq(player) and quest.amount or 0)
    end
    return emblems
end

function Currency:fromQuest()
    return function(quest) return quest.currency == self end
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

ICT.Triumph = Currency:new(301)
ICT.SiderealEssence = Currency:new(2589)
ICT.ChampionsSeal = Currency:new(241)
ICT.Conquest = Currency:new(221)
ICT.Valor = Currency:new(102)
ICT.Heroism = Currency:new(101)
ICT.Epicurean = Currency:new(81)
ICT.JewelcraftersToken = Currency:new(61)
ICT.StoneKeepersShards = Currency:new(161)
ICT.WintergraspMark = Currency:new(126)
-- Phase 3 dungeons grant conquest.
ICT.DungeonEmblem = ICT.Conquest

ICT.Currencies = {
    ICT.Triumph,
    ICT.SiderealEssence,
    ICT.ChampionsSeal,
    ICT.Conquest,
    ICT.Valor,
    ICT.Heroism,
    ICT.Epicurean,
    ICT.JewelcraftersToken,
    ICT.StoneKeepersShard,
    ICT.WintergraspMark,
}

for k, v in ipairs(ICT.Currencies) do
    v.order = k
end