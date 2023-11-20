local addOnName, ICT = ...

ICT.LDBIcon = LibStub("LibDBIcon-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local Players = ICT.Players

SLASH_InstanceCurrencyTracker1 = "/ict";
SlashCmdList.InstanceCurrencyTracker = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    -- Any leading non-whitespace is captured into command
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "wipe" then
        if rest == "" then
            ICT.WipePlayer(Players:getCurrentName())
        elseif rest == "all" then
            ICT.WipeAllPlayers()
        else
            command, rest = rest:match("^(%S*)%s*(.-)$")
            if command == "realm" then
                if rest == "" then
                    ICT.WipeRealm(GetRealmName())
                else
                    ICT.WipeRealm(rest)
                end
            elseif command == "player" then
                ICT.WipePlayer(rest)
            else
                ICT:print(L["Invalid command"])
            end
        end
        -- Refresh frame
        ICT:UpdateDisplay()
    elseif command == "font" then
        local fontSize = tonumber(rest)
        if fontSize and fontSize > 0 then
            ICT.db.options.fontSize = tonumber(rest)
        else
            ICT:print("Invalid size, must be a positive number.")
        end
        ICT:UpdateDisplay()
    elseif command == "message" then
        local name = rest
        ICT.Comms:transmitPlayerMetadata(name)
    elseif rest == "" then
        ICT.flipFrame()
    end
end

function ICT.WipePlayer(playerName)
    if ICT.db.players[playerName] then
        ICT.db.players[playerName] = nil
        ICT:print(L["Wiped character: %s"], playerName)
    else
        ICT:print(L["Unknown character: %s"], playerName)
    end
    Players:create()
end

function ICT.WipeRealm(realmName)
    local count = 0
    for name, _ in ICT:fpairsByValue(ICT.db.players, function(v) return v.realm == realmName end) do
        count = count + 1
        ICT.db.players[name] = nil
    end
    ICT:print(L["Wiped %s characters on realm: %s"], count, realmName)
    Players:create()
end

function ICT.WipeAllPlayers()
    local count = ICT:sum(ICT.db.players, ICT:returnX(1))
    ICT.db.players = {}
    ICT:print(L["Wiped %s characters"], count)
    Players:create()
end