local function calculateEmblems(instances, tokenId)
    local emblems = 0
    for _, instance in pairs(instances) do
        local staticInstance = InstanceInfo[instance.id]
        if staticInstance.tokenIds[tokenId] then
            local available = instance.available or {}
            instance.available = available
            instance.available[tokenId] = staticInstance.emblems(instance, tokenId)
            emblems = emblems + instance.available[tokenId]
        end
    end
    return emblems
end

function CalculateDungeonEmblems(tokenId)
    return function(player)
        return calculateEmblems(player.dungeons, tokenId)
    end
end

function CalculateRaidEmblems(tokenId)
    return function(player)
        return calculateEmblems(player.raids, tokenId)
    end
end

-- Calculate max emblems per player until static information is able to provide results for 10 vs 25 values.
local MaxTokens = {}
local function caculateMaxEmblems(instances, tokenId)
    -- Lock the value once we calculated as it doesn't change.
    -- It probably doesn't matter for performance but let's do it.
    -- Resets on reload in case this value is updated on new version.
    if MaxTokens[tokenId] then
        return MaxTokens[tokenId]
    end
    local op = function(v) return InstanceInfo[v.id] and InstanceInfo[v.id].maxEmblems(v, tokenId) or 0 end
    local filter = function(v) return InstanceInfo[v.id].tokenIds[tokenId] end
    MaxTokens[tokenId] = Utils:sum(instances, op, filter)
    return MaxTokens[tokenId]
end

function CalculateMaxDungeonEmblems(tokenId)
    return function(player)
        return caculateMaxEmblems(player.dungeons, tokenId)
    end
end

function CalculateMaxRaidEmblems(tokenId)
    return function(player)
        return caculateMaxEmblems(player.raids, tokenId)
    end
end

-- How to order currency, we sort from highest to lowest (reverse) so adding new currencies is easier.
Currency = {
    [Utils.Triumph] = 6,
    [Utils.SiderealEssence] = 5,
    [Utils.ChampionsSeal] = 4,
    [Utils.Conquest] = 3,
    [Utils.Valor] = 2,
    [Utils.Heroism] = 1,
}
function CurrencySort(a, b)
    return Currency[a] > Currency[b]
end