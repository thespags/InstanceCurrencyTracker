Player = {}

function Player:Create()
    local player = {}
    player.name = UnitName("Player")
    player.realm = GetRealmName()
    player.fullName = Utils:GetFullName()
    player.class = select(2, UnitClass("Player"))
    player.faction = select(1, UnitFactionGroup("Player"))
    player.level = UnitLevel("Player")
    player.dungeons = CopyTable(Instances.dungeons)
    player.raids = CopyTable(Instances.raids)
    player.oldRaids = CopyTable(Instances.oldRaids)
    player.currency = {
        wallet = {},
        weekly = {},
        daily = {},
        maxDaily = {},
        -- There's no prereq for weekly currencies so no player based max weekly.
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
        print(string.format("[%s] Daily reset for player: %s", AddOnName, player.fullName))
    end
    if not player.weeklyReset or player.weeklyReset < timestamp then
        self:WeeklyReset(player)
        print(string.format("[%s] Weekly reset for player: %s", AddOnName, player.fullName))
    end
    Player:OldRaidReset(player)
end

function Player:DailyReset(player)
    Instances:ResetAll(player.dungeons)
    for k, _ in pairs(Currency) do
        player.currency.daily[k] = player.currency.maxDaily[k] or 0
    end
    player.dailyReset = C_DateAndTime.GetSecondsUntilDailyReset() + GetServerTime()
end

function Player:WeeklyReset(player)
    Instances:ResetAll(player.raids)
    for k, _ in pairs(Currency) do
        player.currency.weekly[k] = CalculateMaxRaidEmblems(k)(player)
    end
    player.weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime()
end

function Player:OldRaidReset(player)
    Instances:ResetIfNecessary(player.oldRaids, GetServerTime())
end

function Player:CalculateCurrency(player)
    for k, _ in pairs(Currency) do
        player.currency.wallet[k] = Utils:GetCurrencyAmount(k)
        -- There's no weekly raid quests so just add raid emblems.
        player.currency.weekly[k] = CalculateRaidEmblems(k)(player)
        player.currency.daily[k] = Utils:add(CalculateDungeonEmblems(k), Quests:CalculateAvailableDaily(k))(player)
        player.currency.maxDaily[k] = Utils:add(CalculateMaxDungeonEmblems(k), Quests:CalculateMaxDaily(k))(player)
    end
end

function Player:Update(db)
    db.players = db.players or {}
    for _, player in pairs(db.players) do
        Player:ResetInstances(player)
    end
    local player = self:GetPlayer(db)
    Instances:Update(player)
    Player:CalculateCurrency(player)
end

-- Returns the provided player or current player if none provided.
function Player:GetPlayer(db, playerName)
    playerName = playerName or Utils:GetFullName()
    local player = db.players[playerName] or Player:Create()
    db.players[playerName] = player
    return player
end

function Player:WipePlayer(db, playerName)
    if db.players[playerName] then
        db.players[playerName] = {}
        print(string.format("[%s] Wiped player: %s", AddOnName, playerName))
    else   
        print(string.format("[%s] Unknown player: %s", AddOnName, playerName))
    end
    self:Update(db)
end

function Player:WipeRealm(db, realmName)
    local count = 0
    for name, _ in Utils.fpairs(db.players, function(v) return v.realm == realmName end) do
        count = count + 1
        db.players[name] = {}
    end
    print(string.format("[%s] Wiped % players on realm: %s", AddOnName , count, realmName))
    self:Update(db)
end

function Player:WipeAllPlayers(db)
    local count = 0
    for _, _ in pairs(db.players) do
        count = count + 1
    end
    db.players = {}
    print(string.format("[%s] Wiped % players", AddOnName, count))
    self:Update(db)
end

-- Remenant from the WeakAura
function Player:EnablePlayer(db, playerName)
    if db.players[playerName] then db.players[playerName].isDisabled = false end
end

-- Remenant from the WeakAura
function Player:DisablePlayer(db, playerName)
    if db.players[playerName] then db.players[playerName].isDisabled = true end
end

-- Remenant from the WeakAura
function Player:ViewablePlayers(db, options)
    local currentName = Utils:GetFullName()
    local currentRealm = GetRealmName()
    local playerFilter = function(v) return
        -- Show all characters for the realm or specifically the current character.
        (options.showAllAlts or currentName == v.fullName)
        -- Show only max level characters if enabled.
        and (v.level == 80 or not options.onlyMaxLevelCharacters)
        and (v.realm == currentRealm or options.showAllRealms)
        and not v.isDisabled
    end
    local players = {}
    for _, player in Utils.fpairs(db.players, playerFilter) do
        players[player.fullName] = player
    end
    return players
end