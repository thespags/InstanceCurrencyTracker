local addOnName, ICT = ...

ICT.LDBIcon = LibStub("LibDBIcon-1.0", true)
ICT.DDMenu = LibStub:GetLibrary("LibUIDropDownMenu-4.0", true)
ICT.LDBroker = LibStub("LibDataBroker-1.1")
ICT.LCInspector = LibStub("LibClassicInspector")
local Player = ICT.Player
local Instances = ICT.Instances
local Options = ICT.Options
local maxPlayers, instanceId

local function getOrCreateDb()
    local db = InstanceCurrencyDB or {}
    InstanceCurrencyDB = db
    ICT:putIfAbsent(db, "players", {})
    ICT:putIfAbsent(db, "options", {})
    ICT:putIfAbsent(db.options, "collapsible", {})
    db.reset = db.reset or { [1] = C_DateAndTime.GetSecondsUntilDailyReset() + GetServerTime(), [7] = C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime() }
    return db
end

-- local foo = CreateFrame("Frame", "asdf", UIParent, "BasicFrameTemplateWithInset")

-- foo:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 300, 400)
-- foo:SetSize(300, 400)
-- local tooltip = LibStub('LibQTip-2.0'):Acquire('MyFooBarTooltip', 2, "LEFT", "RIGHT")
-- tooltip:SmartAnchorTo(foo)
-- -- Add an header filling only the first two columns
-- tooltip:AddHeader('Anchor', 'Tooltip')
-- -- Add an new line, using all columns
-- tooltip:AddLine('Hello', 'World')
-- tooltip:Show()

local function flipFrame()
    if not ICT.frame:IsVisible() then
        -- Force display update if it's enabled.
        ICT:DisplayPlayer()
        ICT.frame:Show()
    else
        ICT.frame:Hide()
    end
end

local function updateDisplay()
    local player = Player:GetPlayer()
    player.time = GetServerTime();
    -- Defer updating the display if it's not currently viewed.
    if ICT.frame:IsVisible() then
        ICT:DisplayPlayer()
    else
        ICT.dprint("not updating frame")
    end
end

local function initMinimap()
    local miniButton = ICT.LDBroker:NewDataObject(addOnName, {
        type = "launcher",
        text = addOnName,
        -- Gold Coin
        icon = "237281",
        OnClick = function(self, button)
            flipFrame()
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(addOnName)
        end,
    })
    ICT.db.minimap = ICT.db.minimap or {}
    ICT.LDBIcon:Register(addOnName, miniButton, ICT.db.minimap)
    Options:FlipMinimapIcon()
end

local function initEvent(self, event, eventAddOn)
    -- After the LFG addon is loaded, attach our frame.
    if eventAddOn == "Blizzard_LookingForGroupUI" then
        ICT.db = getOrCreateDb()
        initMinimap()
        Player.OnLoad()
        for _, player in pairs(ICT.db.players) do
            -- Player may have already been created but we added new instances.
            Player:CreateInstances(player)
            -- In case the langauge changed, localize again.
            Player:LocalizeInstanceNames(player)
        end
        ICT:CreateFrame()
        print(string.format("[%s] Initialized...", addOnName))
        _, _, _, _, maxPlayers, _, _, instanceId = GetInstanceInfo()
        LFGParentFrame:HookScript("OnShow", function() if ICT.db.options.anchorLFG then ICT:DisplayPlayer() ICT.frame:Show() end end)
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
        updateDisplay()
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
-- Added for updating prerequisites and marking dailies done.
updateFrame:RegisterEvent("QUEST_COMPLETE")
updateFrame:SetScript("OnEvent", updateEvent)

local moneyFrame = CreateFrame("Frame")
moneyFrame:RegisterEvent("PLAYER_MONEY")
moneyFrame:SetScript("OnEvent", ICT:throttleFunction(2, Player.UpdateMoney, updateDisplay))

local skillFrame = CreateFrame("Frame")
skillFrame:RegisterEvent("CHAT_MSG_SKILL")
skillFrame:SetScript("OnEvent", ICT:throttleFunction(3, Player.UpdateSkills, updateDisplay))

local talentFrame = CreateFrame("Frame")
talentFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
talentFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
talentFrame:SetScript("OnEvent", ICT:throttleFunction(3, Player.UpdateTalents, updateDisplay))

local gearFrame = CreateFrame("Frame")
gearFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
gearFrame:SetScript("OnEvent", ICT:throttleFunction(3, Player.UpdateGear, updateDisplay))

local bagFrame = CreateFrame("Frame")
bagFrame:RegisterEvent("BAG_UPDATE")
bagFrame:SetScript("OnEvent", ICT:throttleFunction(1, Player.UpdateBags, updateDisplay))

-- Requires viewing the bank to update.
-- Executes immediately after closing instead of delaying.
local bankBagFrame = CreateFrame("Frame")
bankBagFrame:RegisterEvent("BANKFRAME_CLOSED")
-- Don't throttle but use the is db init check.
bankBagFrame:SetScript("OnEvent", ICT:throttleFunction(0, Player.UpdateBankBags, updateDisplay))

local guildFrame = CreateFrame("Frame")
guildFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
-- Don't throttle but use the is db init check.
guildFrame:SetScript("OnEvent", ICT:throttleFunction(0, Player.UpdateGuild, updateDisplay))

local xpFrame = CreateFrame("Frame")
xpFrame:RegisterEvent("PLAYER_XP_UPDATE")
xpFrame:SetScript("OnEvent", ICT:throttleFunction(2, Player.UpdateXP, updateDisplay))

local restFrame = CreateFrame("Frame")
restFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
restFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- Don't throttle but use the is db init check.
restFrame:SetScript("OnEvent", ICT:throttleFunction(0, Player.UpdateResting, updateDisplay))

-- If the player died, resurrected (e.g. rez sickness), or combat ended durability could have changed.
local durabilityFrame = CreateFrame("Frame")
durabilityFrame:RegisterEvent("PLAYER_DEAD")
durabilityFrame:RegisterEvent("PLAYER_UNGHOST")
durabilityFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
-- Don't throttle but use the is db init check.
durabilityFrame:SetScript("OnEvent", ICT:throttleFunction(0, Player.UpdateDurability, updateDisplay))

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
                local text = string.format("[%s] %s, collected %s of %s [%s]", addOnName, ICT:GetCurrencyWithIcon(tokenId), collected, max, total)
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
            Player:WipePlayer(Player.GetCurrentPlayer())
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