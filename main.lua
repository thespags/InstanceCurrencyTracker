Emblems = {}
WaName = "Instance and Emblem Tracker"
local classIcons = {
    ["WARRIOR"] = 626008,
    ["PALADIN"] = 626003,
    ["HUNTER"] = 626000,
    ["ROGUE"] = 626005,
    ["PRIEST"] = 626004,
    ["DEATHKNIGHT"] = 135771,
    ["SHAMAN"] = 626006,
    ["MAGE"] = 626001,
    ["WARLOCK"] = 626007,
    ["DRUID"] = 625999
}

function Emblems:Update(db)
    for _, player in pairs(db.players) do
        Player:ResetInstances(player)
    end
    local player = self:GetPlayer(db)
    Instances:Update(player)
    Player:CalculateCurrency(player)
end

-- Returns the provided player or current player if none provided.
function Emblems:GetPlayer(db, playerName)
    playerName = playerName or Utils:GetFullName()
    local player = db.players[playerName] or Player:Create()
    db.players[playerName] = player
    return player
end

function Emblems:WipePlayer(db, playerName)
    local realmData = self:GetRealmData(db)
    realmData[playerName] = Player:Create()
    print(WaName .. " - wiping player - " .. playerName)
end

function Emblems:WipeRealm(db, realmName)
    for name, _ in Utils.pairs(db.players, function(v) return v.realm == realmName end) do
        db.players[name] = {}
    end
    print(WaName .. " - wiping players on realm - " .. realmName)
end

function Emblems:WipeAllPlayers(db)
    db.players = {}
    print(WaName .. " - wiping all players")
end

function Emblems:EnablePlayer(db, playerName)
    local player = self:GetPlayer(db, playerName)
    player.isDisabled = false
end

function Emblems:DisablePlayer(db, playerName)
    local player = self:GetPlayer(db, playerName)
    player.isDisabled = true
end

function Emblems:ViewablePlayers(db, options)
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