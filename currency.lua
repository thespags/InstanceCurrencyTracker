local function foo(instances, tokenId)
    local emblems = 0
    for _, instance in pairs(instances) do
        local staticInstance = StaticInstances[instance.id]
        if staticInstance.tokenIds[tokenId] then
            local available = instance.available or {}
            instance.available = available
            instance.available[tokenId] = staticInstance.emblems(instance, tokenId)
            emblems = emblems + instance.available[tokenId]
        end
    end
    return emblems
end

-- Currency helpers and how to calculate information
-- index - how we sort the currency, from latest released to earliest (i.e. most relevant)
-- daily - the available amount left to collect in the day
-- weekly - the available amoutn left to collect in the week
-- maxDaily - the maximum amount possible to collect in a day, used for resets on out of date players
-- maxWeekly - the maximum amount possible to collect in a week, used for resets on out of date players
--
-- Note: Some max values are generated on the number of dungeons which will change in phase 4.
-- Otherwise for simplicity we hard code the value. 
-- However champion's seals have a pre-req so the max is snapshot to a specific player
Currency = {
    [Utils.Triumph] = {
        index = 1,
        daily = function(p) return Quests:CalculateDailyHeroic() end,
        weekly = function(p) return foo(p.raids, Utils.Triumph) end,
        maxDaily = Quests.DailyHeroicEmblems,
        -- ToGC(10) + TOGC(10) + Onyxia(10) + Onyxia(25) + VoA
        maxWeekly = 20 + 25 + 4 + 5 + 2,
    },
    [Utils.SiderealEssence] = {
        index = 2,
        daily = function(p) return Instances:CalculateSiderealEssences(p.dungeons) end,
        weekly = Utils:returnX(0),
        -- 1 Sidereal Essence per dungeon
        maxDaily = Utils:sum(Instances.dungeons, function() return 1 end),
    },
    [Utils.ChampionsSeal] = {
        index = 3,
        daily = function(p) return foo(p.dungeons, Utils.ChampionsSeal) + Quests:CalculateChampionsSeals() end,
        weekly = Utils:returnX(0),
        -- TODO snapshot this per player
    },
    [Utils.Conquest] = {
        index = 4,
        daily = function(p) return foo(p.dungeons, Utils.Conquest) + Quests:CalculateDailyNormal() end,
        weekly = function(p) return foo(p.raids, Utils.Conquest) end,
        -- 1 Emblem per boss in dungeons + 2 for daily normal quest
        maxDaily = Utils:sum(Instances.dungeons, function(v) return v.numEncounters end) + Quests.DailyNormalEmblems,
        -- (Ulduar) * 2 (10/25) + VoA
        maxWeekly = Instances.MaxUlduarEmblems * 2 + 2,
    },
    [Utils.Valor] = {
        index = 5,
        daily = Utils:returnX(0),
        weekly = function(p) return foo(p.raids, Utils.Valor) end,
        -- (Naxx + EoE + OS) * 2 (10/25) + VoA
        maxWeekly = (16 + 5 + 2) * 2 + 2
    },
    -- Always 0 now in Phase 3.
    [Utils.Heroism] = {
        index = 6,
        daily = Utils:returnX(0),
        weekly = Utils:returnX(0),
    },
}

function CurrencySort(a, b)
    return Currency[a].index <= Currency[b].index
end