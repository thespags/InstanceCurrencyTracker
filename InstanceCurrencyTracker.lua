local addOnName, ICT = ...

local Player = ICT.Player
local addOn
local function getOrCreateDb()
    if not InstanceCurrencyDB then
        local db = {}
        db.players = db.players or {}
        db.options = db.options or {}
        db.options.collapsible = db.options.collapsible or {}
        InstanceCurrencyDB = db
    end
    return InstanceCurrencyDB
end

-- There's probably cleaner ways to organize this but wow events don't always behave as you would expect.
local function onEvent(self, event, eventAddOn)
	if eventAddOn == "InstanceCurrencyTracker" then
        local db = getOrCreateDb()
        for _, player in pairs(db.players) do
            -- Player may have already been created but we added new instances.
            Player:CreateInstances(player)
            -- In case the langauge changed, localize again.
            Player:LocalizeInstanceNames(player)
        end
	end
    -- After the LFG addon is loaded, attach our frame.
    if eventAddOn == "Blizzard_LookingForGroupUI" then
        addOn = addOn or ICT:CreateAddOn()
        print(string.format("[%s] Initialized...", addOnName))
        LFGParentFrame:HookScript("OnShow", function() addOn:Show() end)
        LFGParentFrame:HookScript("OnHide", function() addOn:Hide() end)
    end
    -- Events that change instance or currency information, refresh the player and frames.
    if event == "CURRENCY_DISPLAY_UPDATE" or event == "ENCOUNTER_END" or event == "PLAYER_LEVEL_UP" or event == "UPDATE_INSTANCE_INFO" then
        -- Don't update if the addon hasn't been initialized yet.
        if addOn and InstanceCurrencyDB then
            Player:Update(InstanceCurrencyDB, event)
            ICT:DisplayPlayer()
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
-- After the instance info is updated then trigger updates to our representation.
f:RegisterEvent("UPDATE_INSTANCE_INFO")
-- After an enounter update information for the instance.
f:RegisterEvent("ENCOUNTER_END")
-- After currency changes we need to update the wallet.
f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
-- Level 80 characters will appear.
f:RegisterEvent("PLAYER_LEVEL_UP")
-- Added for updating prerequisites.
f:RegisterEvent("QUEST_COMPLETE")
f:SetScript("OnEvent", onEvent)

SLASH_InstanceCurrencyTracker1 = "/ict"; -- new slash command for showing framestack tool
SlashCmdList.InstanceCurrencyTracker = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    local db = InstanceCurrencyDB
    -- Any leading non-whitespace is captured into command
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "wipe" then
        if rest == "" then
            Player:WipePlayer(db, ICT:GetFullName())
        elseif rest == "all" then
            Player:WipeAllPlayers(db)
        else
            command, rest = rest:match("^(%S*)%s*(.-)$")
            if command == "realm" then
                if rest == "" then
                    Player:WipeRealm(db, GetRealmName())
                else
                    Player:WipeRealm(db, rest)
                end
            elseif command == "player" then
                Player:WipePlayer(db, rest)
            else
                print("Invalid command")
            end
        end
        -- Refresh frame
        ICT:DisplayPlayer()
    end
end

-- message and add option
function messageResults(player, instance)
    local info = ICT.InstanceInfo[instance.id]
    for _, tokenId in pairs(info.tokenIds) do
        local available = instance.available[tokenId]
        local max = info.maxEmblems(instance, tokenId)
        local collected = max - available
        local total = player.currency.wallet[tokenId]
        local text = string.format("[%s] Collected %s of %s %s, total = %s", addOnName, collected, max, ICT:GetCurrencyName(tokenId), total)
        -- announce to raid>part>self?
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
--
-- TODO detach from LFG frame option?