local addOnName, ICT = ...

ICT.Currency = {}
local Currency = ICT.Currency
-- Currency Id's with name helpers.
ICT.Heroism = 101
ICT.Valor = 102
ICT.Conquest = 221
ICT.Triumph = 301
ICT.SiderealEssence = 2589
ICT.ChampionsSeal = 241
ICT.Epicurean = 81
ICT.JewelcraftersToken = 61
ICT.StoneKeepersShards = 161
ICT.WintergraspMark = 126
-- Phase 3 dungeons grant conquest.
ICT.DungeonEmblem = ICT.Conquest

-- Creates a string with the icon and name of the provided currency.
function ICT:GetCurrencyWithIcon(id)
    local currency = C_CurrencyInfo.GetCurrencyInfo(id)
    return string.format("|T%s:12:12|t%s", currency["iconFileID"], currency["name"])
end

-- Creates a string with the icon and name of the provided currency.
function ICT:GetCurrencyWithIconTooltip(id)
    local currency = C_CurrencyInfo.GetCurrencyInfo(id)
    return string.format("|T%s:14:14|t%s", currency["iconFileID"], currency["name"])
end

-- Returns the amount of currency the player has for the currency provided.
function ICT:GetCurrencyAmount(id)
    return C_CurrencyInfo.GetCurrencyInfo(id)["quantity"]
end

-- Returns the localized name of the currency provided.
function ICT:GetCurrencyName(id)
    return C_CurrencyInfo.GetCurrencyInfo(id)["name"]
end

local function calculateEmblems(instances, tokenId)
    local emblems = 0

    for _, instance in pairs(instances) do
        if instance:hasTokenId(tokenId) then
            local available = instance.available or {}
            instance.available = available
            instance.available[tokenId] = instance:emblems(tokenId)
            emblems = emblems + instance.available[tokenId]
        end
    end
    return emblems
end

function Currency:CalculateDungeonEmblems(tokenId)
    return function(player)
        return calculateEmblems(player:getDungeons(), tokenId)
    end
end

function Currency:CalculateRaidEmblems(tokenId)
    return function(player)
        return calculateEmblems(player:getRaids(), tokenId)
    end
end

local MaxTokens = {}
local function calculateMaxEmblems(instances, tokenId)
    -- Lock the value once we calculated as it doesn't change.
    -- It probably doesn't matter for performance but let's do it.
    -- Resets on reload in case this value is updated on new version.
    if MaxTokens[tokenId] then
        return MaxTokens[tokenId]
    end
    local op = function(v) return v:maxEmblems(tokenId) end
    local filter = function(v) return v:hasTokenId(tokenId) end
    MaxTokens[tokenId] = ICT:sum(instances, op, filter)
    return MaxTokens[tokenId]
end

function Currency:CalculateMaxDungeonEmblems(tokenId)
    return function(player)
        return calculateMaxEmblems(player:getDungeons(), tokenId)
    end
end

function Currency:CalculateMaxRaidEmblems(tokenId)
    return function(player)
        return calculateMaxEmblems(player:getRaids(), tokenId)
    end
end

-- How to order currency, we sort from highest to lowest (reverse) so adding new currencies is easier.
ICT.CurrencyInfo = {
    [ICT.Triumph] = { order = 11 },
    [ICT.SiderealEssence] = { order = 10 },
    [ICT.ChampionsSeal] = { order = 9 },
    [ICT.Conquest] = { order = 8 },
    [ICT.Valor] = { order = 7 },
    [ICT.Heroism] = { order = 6 },
    [ICT.Epicurean] = { order = 5 },
    [ICT.JewelcraftersToken] = { order = 4 },
    [ICT.StoneKeepersShards] = { order = 3, unlimited = true},
    [ICT.WintergraspMark] = { order = 2, unlimited = true},
}

function ICT.CurrencySort(a, b)
    return ICT.CurrencyInfo[a].order > ICT.CurrencyInfo[b].order
end