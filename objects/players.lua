local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
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

-- Uses the custom order define by the user, if a player does not have an order set,
-- defaults to natural order.
function Players.customSort(a, b)
    if a.order and b.order then
        return a.order < b.order
    elseif a.order then
        return true
    elseif b.order then
        return false
    else
        return a < b
    end
end

function Players.byShortName(a, b)
    return a:getName() < b.getName()
end

function Players.byClass(f)
    return function(a, b)
        if a.class == b.class then
            return f and f(a, b) or a < b
        else
            return a.class < b.class
        end
    end
end

function Players.currentFirst(f)
    return function(a, b)
        if a:isCurrentPlayer() then
            return true
        elseif b:isCurrentPlayer() then
            return false
        else
            return f(a, b)
        end
    end
end

function Players.getSort()
    local sort = function(a, b) return a < b end
    if ICT.db.options.sort.custom then
        sort = Players.customSort
    end
    -- elseif ICT.db.options.sort.shortName then
    --     sort = Players.byShortName
    -- end
    -- if ICT.db.options.sort.byClass then
    --     sort = Players.byClass(sort)
    -- end

    if ICT.db.options.sort.currentFirst then
        sort = Players.currentFirst(sort)
    end
    return sort
end