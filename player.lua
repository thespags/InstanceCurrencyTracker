Player = {}
local return0 = function(p) return 0 end
Currency = {
    [Utils.Triumph] = {
        daily = function(p) return  Quests:CalculateDailyHeroic() end,
        weekly = function(p) return Player:foo(p.raids, Utils.Triumph) end,
        maxDaily = Quests.DailyHeroicEmblems,
    },
    [Utils.SiderealEssence] = {
        daily = return0,
        weekly = function(p) return Instances:CalculateSiderealEssences(p.dungeons) end,
        -- 1 Sidereal Essence per dungeon
        maxDaily = Utils:sum(Instances.dungeons, function(_) return 1 end),
    },
    [Utils.ChampionsSeal] = {
        daily = function(p) return Quests:CalculateChampionsSeals() end,
        weekly = function(p) return Instances:CalculateChampionsSeals(p.dungeons) end,
    },
    [Utils.Conquest] = {
        daily = function(p) return Instances:CalculateDungeonEmblems(p.dungeons) + Quests:CalculateDailyNormal() end,
        weekly = function(p) return Player:foo(p.raids, Utils.Conquest) end,
        -- 1 Emblem per boss in dungeons + 2 for daily normal quest
        maxDaily = Utils:sum(Instances.dungeons, function(v) return v.numEncounters end) + Quests.DailyNormalEmblems,
    },
    [Utils.Valor] = {
        daily = return0,
        weekly = function(p) return Player:foo(p.raids, Utils.Valor) end,
    },
    -- Always 0 now in Phase 3 from instances and dailys.
    [Utils.Heroism] = {
        daily = return0,
        weekly = return0,
    },
}

function Player:CalculateCurrency(player)

    if not player.currency then
        player.currency = {
            wallet = {},
            weekly = {},
            daily = {},
        }
    end
    for k, v in pairs(Currency) do

        print(Utils:GetCurrencyName(k))
        player.currency.wallet[k] = Utils:GetCurrencyAmount(k)
        player.currency.weekly[k] = v.weekly(player)
        player.currency.daily[k] = v.daily(player)
        print(   player.currency.weekly[k] )
        print(   player.currency.daily[k] )
    end
end

function Player:foo(instances, tokenId)
    local emblems = 0
    for k, instance in pairs(instances) do
        if not instance.filter then
            print(k)
        end
        if instance.filter(tokenId) then
            emblems = emblems + instance.emblems(instance, tokenId)
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
        player.currency.daily[k] = v.maxWeekly or 0
    end
    player.weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime()
end

function Player:OldRaidReset(player)
    Instances:ResetIfNecessary(player.oldRaids, GetServerTime())
end