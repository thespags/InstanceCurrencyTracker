local addOn

local function onEvent(self, event, addOnName)
	if addOnName == "InstanceCurrencyTracker" then
        InstanceCurrencyDB = InstanceCurrencyDB or {}
        local db = InstanceCurrencyDB
        db.sessions = (db.sessions or 0) + 1
        db.options = (db.options or {})
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

NewButton = CreateFrame("Button", "NewButton", UIParent)
NewButton:SetWidth(40)
NewButton:SetHeight(40)
NewButton:SetPoint("CENTER",0,0)
NewButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
NewButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
NewButton:SetPushedTexture("Interface\\Icons\\INV_Misc_ArmorKit_17")
NewButton:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress","ADD")

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

-- Horizontal Scroll
---Do we want horizontal scroll to list all players?

-- TODO
-- test wipe commands
-- display quest stuff done, not done, prereq not met

-- Future ideas
-- display players on instance tooltips
-- hide/show instances
-- add wotlk as expansion?
-- print message on dungeon complete for advertisement like "[ICT] Collected x of y currency, etc etc"
-- TODO detach from LFG frame option?
-- TODO do we want an option to display all users ignoring select field?
-- multiple user showing option?
-- Announce quests to other users,i.e. have correct daily