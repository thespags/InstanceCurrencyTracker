print("Hello World!")
local db
local function OnEvent(self, event, addOnName)
    print(addOnName)
	if addOnName == "InstanceCurrencyTracker" then -- name as used in the folder name and TOC file name
		InstanceCurrencyDB = InstanceCurrencyDB or {} -- initialize it to a table if this is the first time
		InstanceCurrencyDB.sessions = (InstanceCurrencyDB.sessions or 0) + 1
		print("You loaded this addon "..InstanceCurrencyDB.sessions.." times")
        db = InstanceCurrencyDB
	end
    -- After the LFG addon is loaded, attach our frame.
    if addOnName == "Blizzard_LookingForGroupUI" then
        local f = CreateAddOn(db)
        LFGParentFrame:HookScript("OnShow", function() f:Show() end)
        LFGParentFrame:HookScript("OnHide", function() f:Hide() end)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)

local options = {}

SLASH_InstanceCurrencyTracker1 = "/ict"; -- new slash command for showing framestack tool
SlashCmdList.InstanceCurrencyTracker = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    -- Any leading non-whitespace is captured into command
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "wipe" then
        if rest == "" then
            Player:WipePlayer(db, Utils:GetFullName())
        elseif rest == "all" then
            Player:WipeAllPlayers(db)
        else
            command, rest = msg:match("^(%S*)%s*(.-)$")
            if command == "realm" then
                Player:WipeRealm(db, rest)
            elseif command == "player" then
                Player:WipePlayer(db, rest)
            else
                print("Invalid command")
            end
        end
    else
        db.players = db.players or {}
        Player:Update(db)
        CreateAddOn(db)
    end
end

-- TODO add 
-- "ict wipe" current player
-- "ict wipe realm name"
-- "ict wipe player name"
-- "ict wipe all"

-- Horizontal Scroll
---Do we want horizontal scroll to list all players?
-- Icon
--- How to display them in text?