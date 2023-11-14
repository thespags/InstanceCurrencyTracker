local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Player = ICT.Player
local Players = {}
ICT.Players = Players

function Players:loadAll()
    for k, player in pairs(ICT.db.players) do
        ICT.db.players[k] = self:load(player)
        player.timestamp = player.timestamp or time()
    end
end

-- Sets the player with any new default information and sets meta tables.
-- Such as a new instance, and the index table.
-- This needs to be down on addOn load even if the player exists.
function Players:load(player)
    player = Player:new(player)
    player:createInstances()
    player:recreateCooldowns()
    player:recreatePets()
    return player
end

-- Returns the provided player or current player if none provided.
function Players:get(playerName)
    if not playerName then
        ICT.currentPlayer = ICT.currentPlayer or ICT.db.players[self:getCurrentName()]
        return ICT.currentPlayer
    end
    return ICT.db.players[playerName]
end

-- Adds "static" fields, 
-- Note: we may wnat to move this information to "onLoad",
-- as anything added won't get picked up by existing players.
function Players:create()
    local fullName = self:getCurrentName()
    if ICT.db.players[fullName] then
        return
    end
    ICT:print(L["Creating player: %s"], fullName)
    local player = Player:new()
    player.fullName = fullName
    player.name = UnitName("Player")
    player.realm = GetRealmName()
    player.class = select(2, UnitClass("Player"))
    player.faction = select(1, UnitFactionGroup("Player"))
    player.timestamp = time()
    player.quests = {
        prereq = {},
        completed = {}
    }
    player.currency = {
        wallet = {},
        weekly = {},
        daily = {},
        maxDaily = {},
        maxWeekly = {},
    }
    ICT.db.players[fullName] = player
    player:createInstances()
    -- Set transient information after copying main tables.
    player:dailyReset()
    player:weeklyReset()
    player:onLoad()

    return player
end

function Players:getCurrentName()
    return string.format("[%s] %s", GetRealmName(), UnitName("Player"))
end