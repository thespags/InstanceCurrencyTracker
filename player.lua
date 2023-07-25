Player = {}

function Player:Create()
    local player = {}
    player.name = UnitName("Player")
    player.realm = GetRealmName()
    player.fullName = Utils:GetFullName()
    player.class = select(2, UnitClass("Player"))
    player.faction = select(1, UnitFactionGroup("Player"))
    player.level = UnitLevel("Player")
    player.quests = {
        prereq = {},
        completed = {}
    }
    player.currency = {
        wallet = {},
        weekly = {},
        daily = {},
        maxDaily = {},
        -- There's no prereq for weekly currencies so no player based max weekly.
    }
    self:CreateInstances(player)
    -- Set transient information after copying main tables.
    self:DailyReset(player)
    self:WeeklyReset(player)
    return player
end

-- Creates instances in the transient tables if necessary.
-- The key is the English name with raid size if multiple sizes.
function Player:CreateInstances(player)
    player.dungeons = player.dungeons or {}
    player.raids = player.raids or {}
    player.oldRaids = player.oldRaids or {}
    for _, v in pairs(InstanceInfo) do
        if v.expansion == Expansions[WOTLK] then
            if #v.maxPlayers > 1 then
                for _, size in pairs(v.maxPlayers) do
                    self:addInstance(player.raids, v, size)
                end
            else
                self:addInstance(player.dungeons, v)
            end
        elseif v.expansion < Expansions[WOTLK] then
            self:addInstance(player.oldRaids, v)
        end
    end
end

function Player:addInstance(t, info, size)
    local k = size and Utils:GetInstanceName(info.name, size) or info.name
    if not t[k] then
        local instance = { id = info.id, expansion = info.expansion, maxPlayers = size }
        Utils:LocalizeInstanceName(instance)
        Instances:Reset(instance)
        t[k] = instance
    end
end

-- We probably want to merge these three tables so we don't need this funny business.
-- But then we have to filter the table for each type on certain views.
function Player:GetInstance(player, name)
    if player.dungeons[name] then
        return player.dungeons[name]
    end
    if player.raids[name] then
        return player.raids[name]
    end
    if player.oldRaids[name] then
        return player.oldRaids[name]
    end
    print("Unknown instance: " .. name .. " " .. player.fullName)
    return { locked = false }
end

function Player:LocalizeInstanceNames(player)
    for _, v in pairs(player.dungeons) do
        Utils:LocalizeInstanceName(v)
    end
    for _, v in pairs(player.raids) do
        Utils:LocalizeInstanceName(v)
    end
    for _, v in pairs(player.oldRaids) do
        Utils:LocalizeInstanceName(v)
    end
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
    for k, _ in pairs(QuestInfo) do
        player.quests.completed[k] = false
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

function Player:CalculateQuest(player)
    for k, quest in pairs(QuestInfo) do
        player.quests.prereq[k] = quest.prereq(player)
        player.quests.completed[k] = Quests:IsDailyCompleted(quest)
    end
end

function Player:Update(db)
    for _, player in pairs(db.players) do
        Player:ResetInstances(player)
    end
    local player = self:GetPlayer(db)
    Instances:Update(player)
    self:CalculateCurrency(player)
    self:CalculateQuest(player)
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
        db.players[playerName] = nil
        print(string.format("[%s] Wiped player: %s", AddOnName, playerName))
    else
        print(string.format("[%s] Unknown player: %s", AddOnName, playerName))
    end
    self:Update(db)
end

function Player:WipeRealm(db, realmName)
    local count = 0
    for name, _ in fpairsByValue(db.players, function(v) return v.realm == realmName end) do
        count = count + 1
        db.players[name] = nil
    end
    print(string.format("[%s] Wiped %s players on realm: %s", AddOnName , count, realmName))
    self:Update(db)
end

function Player:WipeAllPlayers(db)
    local count = 0
    for _, _ in pairs(db.players) do
        count = count + 1
    end
    db.players = {}
    print(string.format("[%s] Wiped %s players", AddOnName, count))
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
    for _, player in fpairsByValue(db.players, playerFilter) do
        players[player.fullName] = player
    end
    return players
end

function Player:GetName(player)
    return InstanceCurrencyDB.options.verboseName and player.fullName or player.name
end

function PlayerSort(a, b)
    return Player:GetName(a) < Player:GetName(b)
end