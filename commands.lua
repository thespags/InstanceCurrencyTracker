local addOnName, ICT = ...

ICT.LDBIcon = LibStub("LibDBIcon-1.0")
local LDBroker = LibStub("LibDataBroker-1.1")
local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Player = ICT.Player
local Options = ICT.Options
local version = GetAddOnMetadata("InstanceCurrencyTracker", "Version")
local maxPlayers, instanceId
local UI = ICT.UI

SLASH_InstanceCurrencyTracker1 = "/ict";
SlashCmdList.InstanceCurrencyTracker = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    -- Any leading non-whitespace is captured into command
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "wipe" then
        if rest == "" then
            ICT.WipePlayer(Player.GetCurrentPlayer())
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
        if rest == "small" then
            ICT.db.fontSize = 10
            ICT:print("Font change requires a reload")
        elseif rest == "medium" then
            ICT.db.fontSize = 12
            ICT:print("Font change requires a reload")
        elseif rest == "large" then
            ICT.db.fontSize = 14
            ICT:print("Font change requires a reload")
        else
            ICT:print("Invalid size (small/medium/large)")
        end
        ICT:UpdateDisplay()
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
    ICT.CreateCurrentPlayer()
end

function ICT.WipeRealm(realmName)
    local count = 0
    for name, _ in ICT:fpairsByValue(ICT.db.players, function(v) return v.realm == realmName end) do
        count = count + 1
        ICT.db.players[name] = nil
    end
    ICT:print(L["Wiped %s characters on realm: %s"], count, realmName)
    ICT.CreateCurrentPlayer()
end

function ICT.WipeAllPlayers()
    local count = ICT:sum(ICT.db.players, ICT:returnX(1))
    ICT.db.players = {}
    ICT:print(L["Wiped %s characters"], count)
    ICT.CreateCurrentPlayer()
end