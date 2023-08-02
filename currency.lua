local addOnName, ICT = ...

ICT.Currency = {}
local Currency = ICT.Currency

-- Creates a string with the icon and name of the provided currency.
function ICT:GetCurrencyWithIcon(id)
    local currency = C_CurrencyInfo.GetCurrencyInfo(id)
    return string.format("|T%s:12:12:0:0|t%s", currency["iconFileID"], currency["name"])
end

-- Creates a string with the icon and name of the provided currency.
function ICT:GetCurrencyWithIconTooltip(id)
    local currency = C_CurrencyInfo.GetCurrencyInfo(id)
    return string.format("|T%s:14:14:0:0|t%s", currency["iconFileID"], currency["name"])
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
        local info = ICT.InstanceInfo[instance.id]
        if info.tokenIds[tokenId] then
            local available = instance.available or {}
            instance.available = available
            instance.available[tokenId] = info.emblems(instance, tokenId)
            emblems = emblems + instance.available[tokenId]
        end
    end
    return emblems
end

function Currency:CalculateDungeonEmblems(tokenId)
    return function(player)
        return calculateEmblems(player.dungeons, tokenId)
    end
end

function Currency:CalculateRaidEmblems(tokenId)
    return function(player)
        return calculateEmblems(player.raids, tokenId)
    end
end

local MaxTokens = {}
local function caculateMaxEmblems(instances, tokenId)
    -- Lock the value once we calculated as it doesn't change.
    -- It probably doesn't matter for performance but let's do it.
    -- Resets on reload in case this value is updated on new version.
    if MaxTokens[tokenId] then
        return MaxTokens[tokenId]
    end
    local op = function(v) return ICT.InstanceInfo[v.id] and ICT.InstanceInfo[v.id].maxEmblems(v, tokenId) or 0 end
    local filter = function(v) return ICT.InstanceInfo[v.id].tokenIds[tokenId] end
    MaxTokens[tokenId] = ICT:sum(instances, op, filter)
    return MaxTokens[tokenId]
end

function Currency:CalculateMaxDungeonEmblems(tokenId)
    return function(player)
        return caculateMaxEmblems(player.dungeons, tokenId)
    end
end

function Currency:CalculateMaxRaidEmblems(tokenId)
    return function(player)
        return caculateMaxEmblems(player.raids, tokenId)
    end
end

-- How to order currency, we sort from highest to lowest (reverse) so adding new currencies is easier.
ICT.CurrencyInfo = {
    [ICT.Triumph] = 11,
    [ICT.SiderealEssence] = 10,
    [ICT.ChampionsSeal] = 9,
    [ICT.Conquest] = 8,
    [ICT.Valor] = 7,
    [ICT.Heroism] = 6,
    [ICT.Epicurean] = 5,
    [ICT.JewelcraftersToken] = 4,
    [ICT.StoneKeepersShards] = 3,
    [ICT.WintergraspMark] = 2,
    [ICT.Justice] = 1,
}

function ICT.CurrencySort(a, b)
    return ICT.CurrencyInfo[a] > ICT.CurrencyInfo[b]
end