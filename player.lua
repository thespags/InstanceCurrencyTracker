local addOnName, ICT = ...

ICT.Player = {}
local Player = ICT.Player
local Instances = ICT.Instances
local Quests = ICT.Quests
local Currency = ICT.Currency

function Player:Create()
    local player = {}
    player.name = UnitName("Player")
    player.realm = GetRealmName()
    player.fullName = ICT:GetFullName()
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
    for _, v in pairs(ICT.InstanceInfo) do
        if v.expansion == ICT.Expansions[ICT.WOTLK] then
            if #v.maxPlayers > 1 then
                for _, size in pairs(v.maxPlayers) do
                    self:addInstance(player.raids, v, size)
                end
            else
                self:addInstance(player.dungeons, v)
            end
        elseif v.expansion < ICT.Expansions[ICT.WOTLK] then
            self:addInstance(player.oldRaids, v)
        end
    end
end

function Player:addInstance(t, info, size)
    local k = size and ICT:GetInstanceName(info.name, size) or info.name
    if not t[k] then
        local instance = { id = info.id, expansion = info.expansion, maxPlayers = size }
        ICT:LocalizeInstanceName(instance)
        Instances:Reset(instance)
        t[k] = instance
    end
end

function Player:LocalizeInstanceNames(player)
    for _, v in pairs(player.dungeons) do
        ICT:LocalizeInstanceName(v)
    end
    for _, v in pairs(player.raids) do
        ICT:LocalizeInstanceName(v)
    end
    for _, v in pairs(player.oldRaids) do
        ICT:LocalizeInstanceName(v)
    end
end

function Player:ResetInstances(player)
    local timestamp = GetServerTime()
    if not player.dailyReset or player.dailyReset < timestamp then
        self:DailyReset(player)
        print(string.format("[%s] Daily reset for player: %s", addOnName, player.fullName))
    end
    if not player.weeklyReset or player.weeklyReset < timestamp then
        self:WeeklyReset(player)
        print(string.format("[%s] Weekly reset for player: %s", addOnName, player.fullName))
    end
    Player:OldRaidReset(player)
end

function Player:DailyReset(player)
    Instances:ResetAll(player.dungeons)
    for k, _ in pairs(ICT.CurrencyInfo) do
        player.currency.daily[k] = player.currency.maxDaily[k] or 0
    end
    for k, _ in pairs(ICT.QuestInfo) do
        player.quests.completed[k] = false
    end
    player.dailyReset = C_DateAndTime.GetSecondsUntilDailyReset() + GetServerTime()
end

function Player:WeeklyReset(player)
    Instances:ResetAll(player.raids)
    for k, _ in pairs(ICT.CurrencyInfo) do
        player.currency.weekly[k] = Currency:CalculateMaxRaidEmblems(k)(player)
    end
    player.weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime()
end

function Player:OldRaidReset(player)
    Instances:ResetIfNecessary(player.oldRaids, GetServerTime())
end

function Player:CalculateCurrency(player)
    for k, _ in pairs(ICT.CurrencyInfo) do
        player.currency.wallet[k] = ICT:GetCurrencyAmount(k)
        -- There's no weekly raid quests so just add raid emblems.
        player.currency.weekly[k] = Currency:CalculateRaidEmblems(k)(player)
        player.currency.daily[k] = ICT:add(Currency:CalculateDungeonEmblems(k), Quests:CalculateAvailableDaily(k))(player)
        player.currency.maxDaily[k] = ICT:add(Currency:CalculateMaxDungeonEmblems(k), Quests:CalculateMaxDaily(k))(player)
    end
end

function Player:AvailableCurrency(player, tokenId)
    if not player.currency.weekly[tokenId] or not player.currency.daily[tokenId] then
        return "n/a"
    end
    return player.currency.weekly[tokenId] + player.currency.daily[tokenId]
end

function Player:CalculateQuest(player)
    for k, quest in pairs(ICT.QuestInfo) do
        player.quests.prereq[k] = quest.prereq(player)
        player.quests.completed[k] = Quests:IsDailyCompleted(quest)
    end
end

function Player:Update()
    for _, player in pairs(ICT.db.players) do
        Player:ResetInstances(player)
    end
    local player = self:GetPlayer()
    Instances:Update(player)
    self:CalculateCurrency(player)
    self:CalculateQuest(player)
end
-- Returns the provided player or current player if none provided.
function Player:GetPlayer(playerName)
    playerName = playerName or ICT:GetFullName()
    local exists = ICT.db.players[playerName] and true or false
    if not exists then
        print(string.format("[%s] Creating player: %s", addOnName, playerName))
    end
    local player = ICT.db.players[playerName] or Player:Create()
    ICT.db.players[playerName] = player
    return player
end

function Player:WipePlayer(playerName)
    if ICT.db.players[playerName] then
        ICT.db.players[playerName] = nil
        print(string.format("[%s] Wiped player: %s", addOnName, playerName))
    else
        print(string.format("[%s] Unknown player: %s", addOnName, playerName))
    end
    self:Update()
end

function Player:WipeRealm(realmName)
    local count = 0
    for name, _ in fpairsByValue(ICT.db.players, function(v) return v.realm == realmName end) do
        count = count + 1
        ICT.db.players[name] = nil
    end
    print(string.format("[%s] Wiped %s players on realm: %s", addOnName , count, realmName))
    self:Update()
end

function Player:WipeAllPlayers()
    local count = 0
    for _, _ in pairs(ICT.db.players) do
        count = count + 1
    end
    ICT.db.players = {}
    print(string.format("[%s] Wiped %s players", addOnName, count))
    self:Update()
end

-- Remenant from the WeakAura
function Player:EnablePlayer(playerName)
    if ICT.db.players[playerName] then ICT.db.players[playerName].isDisabled = false end
end

-- Remenant from the WeakAura
function Player:DisablePlayer(playerName)
    if ICT.db.players[playerName] then ICT.db.players[playerName].isDisabled = true end
end

-- Remenant from the WeakAura
function Player:ViewablePlayers(options)
    local currentName = ICT:GetFullName()
    local currentRealm = GetRealmName()
    local playerFilter = function(v) return
        -- Show all characters for the realm or specifically the current character.
        (options.showAllAlts or currentName == v.fullName)
        -- Show only max level characters if enabled.
        and (v.level == ICT.MaxLevel or not options.onlyMaxLevelCharacters)
        and (v.realm == currentRealm or options.showAllRealms)
        and not v.isDisabled
    end
    local players = {}
    for _, player in fpairsByValue(players, playerFilter) do
        players[player.fullName] = player
    end
    return players
end

function Player:GetName(player)
    return ICT.db.options.verboseName and player.fullName or player.name
end

function PlayerSort(a, b)
    return Player:GetName(a) < Player:GetName(b)
end