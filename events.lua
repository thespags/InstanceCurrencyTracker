local addOnName, ICT = ...

local icon = LibStub("LibDBIcon-1.0", true)
local Player = ICT.Player
local Instances = ICT.Instances
local Options = ICT.Options
local maxPlayers, instanceId

local function getOrCreateDb()
    local db = InstanceCurrencyDB or {}
    InstanceCurrencyDB = db
    ICT:putIfAbsent(db.options, "players", {})
    ICT:putIfAbsent(db.options, "options", {})
    ICT:putIfAbsent(db.options, "collapsible", {})
    db.resetTimers = db.resetTimers or { [1] = C_DateAndTime.GetSecondsUntilDailyReset() + GetServerTime(), [7] = C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime() }
    return db
end

local function flipFrame()
    if not ICT.frame:IsVisible() then
        ICT.frame:Show()
    else
        ICT.frame:Hide()
    end
end

local function initMinimap()
    local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject(addOnName, {
        type = "data source",
        text = addOnName,
        -- Gold Coin
        icon = "237281",
        OnClick = function(self, btn)
            flipFrame()
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(addOnName)
        end,
    })
    icon:Register(addOnName, miniButton, ICT.db.minimap)
    Options:FlipMinimapIcon()
end

local function initEvent(self, event, eventAddOn)
    -- After the LFG addon is loaded, attach our frame.
    if eventAddOn == "Blizzard_LookingForGroupUI" then
        ICT.db = getOrCreateDb()
        initMinimap()
        Player:Update()
        for _, player in pairs(ICT.db.players) do
            -- Player may have already been created but we added new instances.
            Player:CreateInstances(player)
            -- In case the langauge changed, localize again.
            Player:LocalizeInstanceNames(player)
        end
        ICT:CreateAddOn()
        print(string.format("[%s] Initialized...", addOnName))
        _, _, _, _, maxPlayers, _, _, instanceId = GetInstanceInfo()
        LFGParentFrame:HookScript("OnShow", function() if ICT.db.options.anchorLFG then ICT.frame:Show() end end)
        LFGParentFrame:HookScript("OnHide", function() if ICT.db.options.anchorLFG then ICT.frame:Hide() end end)
    end
end
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", initEvent)

local function updateEvent(self, event)
    -- Don't update if the addon hasn't been initialized yet.
    if ICT.frame and ICT.db then
        ICT.dprint("updating: " .. event)
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
    -- Only broadcast if we are locked and collected something...
    if instance and instance.locked then
        ICT.dprint("broadcast: announcing")
        local info = ICT.InstanceInfo[instance.id]
        -- Double check amounts before messaging.
        -- It seems WOW may process oddly.
        Player:Update()
        ICT:DisplayPlayer()
        for tokenId, _ in ICT:spairs(info.tokenIds or {}, ICT.CurrencySort) do
            -- Onyxia 40 is reused and has 0 emblems so skip currency.
            local max = info.maxEmblems(instance, tokenId)
            if ICT.db.options.currency[tokenId] and max ~= 0 then
                local available = instance.available[tokenId]
                local collected = max - available
                local total = player.currency.wallet[tokenId]
                local text = string.format("[%s] Collected %s of %s [%s] %s", addOnName, collected, max, total, ICT:GetCurrencyName(tokenId))
                Options:PrintMessage(text)
            end
        end
    elseif instance then
        ICT.dprint("broadcast: no lock")
    else
        ICT.dprint("broadcast: no instance")
    end
end
local broadcastEvent =  function()
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
            Player:WipePlayer(ICT:GetFullName())
        elseif rest == "all" then
            Player:WipeAllPlayers()
        else
            command, rest = rest:match("^(%S*)%s*(.-)$")
            if command == "realm" then
                if rest == "" then
                    Player:WipeRealm(GetRealmName())
                else
                    Player:WipeRealm(rest)
                end
            elseif command == "player" then
                Player:WipePlayer(rest)
            else
                print("Invalid command")
            end
        end
        -- Refresh frame
        ICT:DisplayPlayer()
    elseif rest == "" then
        flipFrame()
    end
end