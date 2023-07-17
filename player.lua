Player = {}
Currency = {
    [Utils.Triumph] = {
        daily = function(p) return  Quests:CalculateDailyHeroic() end,
        weekly = function(p) return Player:foo(p.raids, Utils.Triumph) end,
        maxDaily = Quests.DailyHeroicEmblems,
    },
    [Utils.SiderealEssence] = {
        daily = function(p) return Instances:CalculateSiderealEssences(p.dungeons) end,
        weekly = Utils:returnX(0),
        -- 1 Sidereal Essence per dungeon
        maxDaily = Utils:sum(Instances.dungeons, function(_) return 1 end),
    },
    [Utils.ChampionsSeal] = {
        daily = function(p) return Quests:CalculateChampionsSeals() + Instances:CalculateChampionsSeals(p.dungeons) end,
        weekly = Utils:returnX(0),
    },
    [Utils.Conquest] = {
        daily = function(p) return Instances:CalculateDungeonEmblems(p.dungeons) + Quests:CalculateDailyNormal() end,
        weekly = function(p) return Player:foo(p.raids, Utils.Conquest) end,
        -- 1 Emblem per boss in dungeons + 2 for daily normal quest
        maxDaily = Utils:sum(Instances.dungeons, function(v) return v.numEncounters end) + Quests.DailyNormalEmblems,
    },
    [Utils.Valor] = {
        daily = Utils:returnX(0),
        weekly = function(p) return Player:foo(p.raids, Utils.Valor) end,
    },
    -- Always 0 now in Phase 3.
    [Utils.Heroism] = {
        daily = Utils:returnX(0),
        weekly = Utils:returnX(0),
    },
}

function Player:CalculateCurrency(player)
    for k, v in pairs(Currency) do
        player.currency.wallet[k] = Utils:GetCurrencyAmount(k)
        player.currency.weekly[k] = v.weekly(player)
        player.currency.daily[k] = v.daily(player)
    end
end

function Player:foo(instances, tokenId)
    local emblems = 0
    for _, instance in pairs(instances) do
        local staticInstance = StaticInstances[instance.id]
        if staticInstance.tokenIds[tokenId] then
            instance.availableEmblems = staticInstance.emblems(instance, tokenId)
            emblems = emblems + instance.availableEmblems
        end
    end
    return emblems
end

function Player:Create()
    local player = {}
    player.name = UnitName("Player")
    player.realm = GetRealmName()
    player.fullName = Utils:GetFullName()
    player.class = select(2, UnitClass("Player"))
    player.level = UnitLevel("Player")
    player.dungeons = CopyTable(Instances.dungeons)
    player.raids = CopyTable(Instances.raids)
    player.oldRaids = CopyTable(Instances.oldRaids)
    player.currency = {
        wallet = {},
        weekly = {},
        daily = {},
    }
    -- Set transient information after copying main tables.
    self:DailyReset(player)
    self:WeeklyReset(player)
    Instances:ResetAll(player.oldRaids)
    return player
end

function Player:ResetInstances(player)
    local timestamp = GetServerTime()
    if not player.dailyReset or player.dailyReset < timestamp then
        self:DailyReset(player)
        print(WaName .. " - daily reset - wiping " .. player.fullName)
    end
    if not player.weeklyReset or player.weeklyReset < timestamp then
        self:WeeklyReset(player)
        print(WaName .. " - weekly reset - wiping " .. player.fullName)
    end
    Player:OldRaidReset(player)
end

function Player:DailyReset(player)
    Instances:ResetAll(player.dungeons)
    for k, v in pairs(Currency) do
        player.currency.daily[k] = v.maxDaily or 0
    end
    player.dailyReset = C_DateAndTime.GetSecondsUntilDailyReset() + GetServerTime()
end

function Player:WeeklyReset(player)
    Instances:ResetAll(player.raids)
    for k, v in pairs(Currency) do
        player.currency.weekly[k] = v.maxWeekly or 0
    end
    player.weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime()
end

function Player:OldRaidReset(player)
    Instances:ResetIfNecessary(player.oldRaids, GetServerTime())
end