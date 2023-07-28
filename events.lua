local addOnName, ICT = ...

local Player = ICT.Player
local Instances = ICT.Instances
local Options = ICT.Options
local maxPlayers, instanceId

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

local function initEvent(self, event, eventAddOn)
    -- After the LFG addon is loaded, attach our frame.
    if eventAddOn == "Blizzard_LookingForGroupUI" then
        ICT.db = getOrCreateDb()
        Player:Update()
        for _, player in pairs(ICT.db.players) do
            -- Player may have already been created but we added new instances.
            Player:CreateInstances(player)
            -- In case the langauge changed, localize again.
            Player:LocalizeInstanceNames(player)
        end
        ICT:CreateAddOn()
        print(string.format("[%s] Initialized...", addOnName))
        LFGParentFrame:HookScript("OnShow", function() ICT.frame:Show() end)
        LFGParentFrame:HookScript("OnHide", function() ICT.frame:Hide() end)
    end
end
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", initEvent)

local function updateEvent(self, event)
    -- Don't update if the addon hasn't been initialized yet.
    if ICT.frame and ICT.db then
        Player:Update()
        ICT:DisplayPlayer()
    end
end
local updateFrame = CreateFrame("Frame")
-- After the instance info is updated then trigger updates to our representation.
updateFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
-- After an enounter update information for the instance.
updateFrame:RegisterEvent("ENCOUNTER_END")
-- After currency changes we need to update the wallet.
updateFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
-- Level 80 characters will appear.
updateFrame:RegisterEvent("PLAYER_LEVEL_UP")
-- Added for updating prerequisites.
updateFrame:RegisterEvent("QUEST_COMPLETE")
updateFrame:SetScript("OnEvent", updateEvent)

-- message and add option
local function messageResults(player, instance)
    if instance then
        local info = ICT.InstanceInfo[instance.id]
        for tokenId, _ in ICT:spairs(info.tokenIds or {}, ICT.CurrencySort) do
            if ICT.db.options.currency[tokenId] then
                local available = instance.available[tokenId]
                local max = info.maxEmblems(instance, tokenId)
                local collected = max - available
                local total = player.currency.wallet[tokenId]
                local text = string.format("[%s] Collected %s of %s [%s] %s", addOnName, collected, max, total, ICT:GetCurrencyName(tokenId))
                Options:PrintMessage(text)
            end
        end
    end
end
local broadcastEvent =  function()
    local db = getOrCreateDb()
    if maxPlayers and instanceId then
        local player = Player:GetPlayer()
        local instance = Instances:GetInstanceById(player, instanceId, maxPlayers)
        messageResults(player, instance)
    end
    _, _, _, _, maxPlayers, _, _, instanceId = GetInstanceInfo()
end
local broadcastFrame = CreateFrame("Frame")
broadcastFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
broadcastFrame:SetScript("OnEvent", broadcastEvent)

SLASH_InstanceCurrencyTracker1 = "/ict";
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