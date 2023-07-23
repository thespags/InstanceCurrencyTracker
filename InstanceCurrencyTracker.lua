local addOn

local function onEvent(self, event, addOnName)
	if addOnName == "InstanceCurrencyTracker" then
        InstanceCurrencyDB = InstanceCurrencyDB or {}
        local db = InstanceCurrencyDB
        db.sessions = (db.sessions or 0) + 1
        db.options = (db.options or {})
        db.options.collasible = (db.options.collasible or {})
        Player:Update(db)
	end
    -- After the LFG addon is loaded, attach our frame.
    if addOnName == "Blizzard_LookingForGroupUI" then
        addOn = addOn or CreateAddOn()
        print(string.format("[%s] Initialized...", AddOnName))
        LFGParentFrame:HookScript("OnShow", function() addOn:Show() end)
        LFGParentFrame:HookScript("OnHide", function() addOn:Hide() end)
    end
    -- Events that change instance or currency information, refresh the player and frames.
    if event == "CURRENCY_DISPLAY_UPDATE" or event == "ENCOUNTER_END" or event == "PLAYER_LEVEL_UP" then
        -- Don't update if the addon hasn't been initialized yet.
        if addOn and InstanceCurrencyDB then
            Player:Update(InstanceCurrencyDB)
            DisplayPlayer()
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
f:SetScript("OnEvent", onEvent)

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
        DisplayPlayer()
    end
end

-- TODO
--
-- Do we want a multi player display?
--- does that require a horizontal scroll?
--- adds option for players to display/ignore
--
-- Share daily quests to addon users
--
-- Add WOTLK as expansion with instances to filter?
--
-- print message on dungeon complete for advertisement like "[ICT] Collected x of y currency, etc etc"
--
-- TODO detach from LFG frame option?