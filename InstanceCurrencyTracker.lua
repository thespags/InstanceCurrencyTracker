local function OnEvent(self, event, addOnName)
	if addOnName == "InstanceCurrencyTracker" then -- name as used in the folder name and TOC file name
		InstanceCurrencyDB = InstanceCurrencyDB or {} -- initialize it to a table if this is the first time
		local db = InstanceCurrencyDB
        db.sessions = (db.sessions or 0) + 1
        db.options = (db.options or {})
        Player:Update(db)
		print("You loaded this addon "..InstanceCurrencyDB.sessions.." times")
	end
    -- After the LFG addon is loaded, attach our frame.
    if addOnName == "Blizzard_LookingForGroupUI" then
        local f = CreateAddOn(InstanceCurrencyDB)
        print(string.format("[%s] Initialized...", AddOnName))
        LFGParentFrame:HookScript("OnShow", function() f:Show() end)
        LFGParentFrame:HookScript("OnHide", function() f:Hide() end)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)

SLASH_InstanceCurrencyTracker1 = "/ict"; -- new slash command for showing framestack tool
SlashCmdList.InstanceCurrencyTracker = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    local db = InstanceCurrencyDB
    -- Any leading non-whitespace is captured into command
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "wipe" then
        if rest == "" then
            Player:WipePlayer(db, Utils:GetFullName())
        elseif rest == "all" then
            Player:WipeAllPlayers(db)
        else
            command, rest = rest:match("^(%S*)%s*(.-)$")
            if command == "realm" then
                if rest == "" then
                    print("No realm provided")
                else
                    Player:WipeRealm(db, rest)
                end
            elseif command == "player" then
                -- TODO require realm name? 
                Player:WipePlayer(db, rest)
            else
                print("Invalid command")
            end
        end
        -- Refresh frame
        DisplayPlayer(db)
    end
end

-- Horizontal Scroll
---Do we want horizontal scroll to list all players?

-- TODO
-- test wipe commands
-- test currency filters
-- see how db can be passed into file?!
---- see how addon name and whatever else ... does
-- see if removing instances/currency means we have to "Clear" cells
-- TODO make an optionunused.

-- Future ideas
-- short/long currency?
-- display players on instance tooltips
-- hide/show instances
-- add wotlk as expansion?
-- add encounters for other raids?
-- display quest stuff done, not done, prereq not met
-- print message on dungeon complete for advertisement like "[ICT] Collected x of y currency, etc etc"
-- TODO detach from LFG frame option?
-- TODO do we want an option to display all users ignoring select field?
-- multiple user showing option?
-- Announce quests to other users...