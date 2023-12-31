local addOnName, ICT = ...

ICT.LDBIcon = LibStub("LibDBIcon-1.0")
local LDBroker = LibStub("LibDataBroker-1.1")
local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local Expansion = ICT.Expansion
local log = ICT.log
local Player = ICT.Player
local Players = ICT.Players
local Options = ICT.Options
local version = GetAddOnMetadata(addOnName, "Version")
local maxPlayers, instanceId
local UI = ICT.UI

local function getOrCreateDb()
    local db = InstanceCurrencyDB or {}
    InstanceCurrencyDB = db
    ICT.putIfAbsent(db, "players", {})
    ICT.putIfAbsent(db, "options", {})
    ICT.putIfAbsent(db.options, "collapsible", {})
    db.reset = db.reset or { [1] = C_DateAndTime.GetSecondsUntilDailyReset() + GetServerTime(), [7] = C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime() }
    return db
end

function ICT.flipFrame()
    if ICT.frame then
        if not ICT.frame:IsVisible() then
            ICT.frame:Show()
            ICT.UpdateDisplay()
        else
            ICT.frame:Hide()
        end
    end
end

function ICT.UpdateDisplay()
    -- Update the active players timestamp of "last updated".
    Players:get().timestamp = time()
    -- Defer updating the display if it's not currently viewed or minimized.
    if ICT.frame and ICT.frame:IsVisible() and not ICT.frame.minimized then
        UI:PrintPlayers()
    end
end

local function initMinimap()
    local miniButton = LDBroker:NewDataObject(addOnName, {
        type = "launcher",
        text = addOnName,
        -- Gold Coin
        icon = "237281",
        OnClick = function(self, button)
            ICT.flipFrame()
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
    if eventAddOn == "InstanceCurrencyTracker" then
        ICT.db = getOrCreateDb()
        ICT.Options:setDefaultOptions()
        -- Preserve this option if necessary, remove in future versions.
        if ICT.db.options.frame.orderLockLast then
            ICT.db.options.sort.orderLockLast = ICT.db.options.frame.orderLockLast
            ICT.db.options.frame.orderLockLast = nil
        end
        if ICT.db.fontSize then
            ICT.db.options.fontSize = ICT.db.fontSize
            ICT.db.fontSize = nil
        end

        local semVer = ICT.semver(ICT.db.version or "0.0.0")
        if semVer <= ICT.semver("v1.1.29") then
            ICT:print("Updating currencies and instances...")
            ICT.db.options.currency[ICT.Frost.id] = true
            ICT.db.options.currency[ICT.DefilersScourgeStone.id] = true
            ICT.db.options.displayInstances[2][632] = true
            ICT.db.options.displayInstances[2][658] = true
            ICT.db.options.displayInstances[2][668] = true
            ICT.db.options.displayInstances[2][631] = true
        end
        if semVer <= ICT.semver("v1.1.3") then
            ICT:print("Old version detected, reseting options to default...")
            ICT.Options:setDefaultOptions(true)
        end
        if semVer <= ICT.semver("v1.0.21") then
            ICT:print("Old version detected, wiping players. Please relog into each character.")
            ICT:WipeAllPlayers()
        end
        ICT.db.version = version

        initMinimap()
        Players:loadAll()
        -- If necessary, create the current player. Handled by the function.
        Players:create()
        ICT.init = true
        Players:get():onLoad()
        ICT.UI:CreateFrame()
        ICT.selectedPlayer = Players:getCurrentName()
        ICT:print(L["Initialized Instance Currency Tracker: %s..."], version)
        ICT:print(L["Blizzard often changes emblem amounts if you notice a boss off please report to discord: %s"], "https://discord.gg/yY6Q6EgNRu")
        if GroupFinderFrame then
            GroupFinderFrame:HookScript("OnShow", function() if ICT.db.options.frame.anchorLFG then UI:PrintPlayers() ICT.frame:Show() end end)
            GroupFinderFrame:HookScript("OnHide", function() if ICT.db.options.frame.anchorLFG then ICT.frame:Hide() end end)
        end
        ICT.Comms:Init()
    end
end
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", initEvent)

local updateFrame = CreateFrame("Frame")
-- After the instance info is updated then trigger updates to our representation.
-- This forces encounters to be updated, there seems to be some delay after encounter_end...
updateFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
-- After an enounter update information for the instance.
updateFrame:RegisterEvent("ENCOUNTER_END")
-- After currency changes we need to update the wallet.
updateFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
-- Level 80 characters will appear.
updateFrame:RegisterEvent("PLAYER_LEVEL_UP")
-- Added for updating prerequisites and marking dailies done.
updateFrame:RegisterEvent("QUEST_FINISHED")
updateFrame:SetScript("OnEvent", ICT:throttleFunction("Instance/Currency", 0, Player.update, ICT.UpdateDisplay))

local moneyFrame = CreateFrame("Frame")
moneyFrame:RegisterEvent("PLAYER_MONEY")
moneyFrame:SetScript("OnEvent", ICT:throttleFunction("Money", 2, Player.updateMoney, ICT.UpdateDisplay))

local skillFrame = CreateFrame("Frame")
-- Individual skill ups.
skillFrame:RegisterEvent("CHAT_MSG_SKILL")
-- Learning a new skill or raising a skill from Journeyman to Master. 
skillFrame:RegisterEvent("SKILL_LINES_CHANGED")
skillFrame:SetScript("OnEvent", ICT:throttleFunction("Professions", 3, Player.updateProfessions, ICT.UpdateDisplay))

local skillShowFrame = CreateFrame("Frame")
skillShowFrame:RegisterEvent("TRADE_SKILL_SHOW")
skillShowFrame:SetScript("OnEvent", ICT:throttleFunction("Skills", 0.5, Player.updateSkills, ICT.UpdateDisplay))

-- Delay update for new level, or using points until player is finished.
local talentFrame = CreateFrame("Frame")
talentFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
-- talentFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
talentFrame:SetScript("OnEvent", ICT:throttleFunction("Talent", 3, Player.updateTalents, ICT.UpdateDisplay))

-- Update immediately after spec change.
talentFrame = CreateFrame("Frame")
talentFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
talentFrame:SetScript("OnEvent", ICT:throttleFunction("Talent", 0, Player.updateTalents, ICT.UpdateDisplay))

local petFrame = CreateFrame("Frame")
-- Bunch of different things to try to get a pet loaded.
petFrame:RegisterEvent("UNIT_PET")
petFrame:RegisterEvent("UNIT_PET_TRAINING_POINTS")
petFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
petFrame:RegisterEvent("PET_TALENT_UPDATE")
petFrame:RegisterEvent("PET_BAR_UPDATE")
petFrame:RegisterEvent("LOCALPLAYER_PET_RENAMED")
petFrame:SetScript("OnEvent", ICT:throttleFunction("Talent", 3, Player.updatePets, ICT.UpdateDisplay))

local glyphFrame = CreateFrame("Frame")
glyphFrame:RegisterEvent("ACTIVATE_GLYPH")
glyphFrame:SetScript("OnEvent", ICT:throttleFunction("Glyph", 1, Player.updateGlyphs, ICT.UpdateDisplay))

local gearFrame = CreateFrame("Frame")
gearFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
gearFrame:RegisterEvent("SOCKET_INFO_SUCCESS")
gearFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
gearFrame:SetScript("OnEvent", ICT:throttleFunction("Gear", 3, Player.updateGear, ICT.UpdateDisplay))

local bagFrame = CreateFrame("Frame")
bagFrame:RegisterEvent("BAG_UPDATE")
bagFrame:SetScript("OnEvent", ICT:throttleFunction("Bag", 1, Player.updateBags, ICT.UpdateDisplay))

-- Requires viewing the bank to update.
-- Executes immediately after closing instead of delaying.
local bankBagFrame = CreateFrame("Frame")
bankBagFrame:RegisterEvent("BANKFRAME_CLOSED")
bankBagFrame:RegisterEvent("BANKFRAME_OPENED")
-- Don't throttle but use the is db init check.
bankBagFrame:SetScript("OnEvent", ICT:throttleFunction("BankBag", 0, Player.updateBankBags, ICT.UpdateDisplay))

local guildFrame = CreateFrame("Frame")
guildFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
-- Don't throttle but use the is db init check.
guildFrame:SetScript("OnEvent", ICT:throttleFunction("Guild", 0, Player.updateGuild, ICT.UpdateDisplay))

local xpFrame = CreateFrame("Frame")
xpFrame:RegisterEvent("PLAYER_XP_UPDATE")
xpFrame:SetScript("OnEvent", ICT:throttleFunction("XP", 2, Player.updateXP, ICT.UpdateDisplay))

local restFrame = CreateFrame("Frame")
restFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
restFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- Don't throttle but use the is db init check.
restFrame:SetScript("OnEvent", ICT:throttleFunction("Rest", 0, Player.updateResting, ICT.UpdateDisplay))

-- If durability changed or equipment was swapped update the equipped durability.
local durabilityFrame = CreateFrame("Frame")
durabilityFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
durabilityFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
durabilityFrame:SetScript("OnEvent", ICT:throttleFunction("Durability", .5, Player.updateDurability, ICT.UpdateDisplay))

local cooldownFrame = CreateFrame("Frame")
cooldownFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
cooldownFrame:SetScript("OnEvent", ICT:throttleFunction("Cooldowns", 0, Player.updateCooldowns, ICT.UpdateDisplay))

-- We can't update the color of instances until we know we've been queued or dequeued.
-- So this simply updates the page performing no function.
local queueFrame = CreateFrame("Frame")
queueFrame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
queueFrame:SetScript("OnEvent", ICT:throttleFunction("Cooldowns", 0, function() end, ICT.UpdateDisplay))

if Expansion.isVanilla() then
    local buffFrame = CreateFrame("Frame")
    buffFrame:RegisterEvent("UNIT_AURA")
    buffFrame:SetScript("OnEvent", function(self, event, unit, info)
        -- The info parameter isn't available in era. So we have to full scan aura's every time.
        if unit == "player" then
            ICT:throttleFunction("WorldBuffs", 5, Player.updateWorldBuffs, ICT.UpdateDisplay)()
        end
    end)

    local consumeFrame = CreateFrame("Frame")
    consumeFrame:RegisterEvent("BAG_UPDATE")
    consumeFrame:SetScript("OnEvent", ICT:throttleFunction("Consumes", 5, Player.updateConsumes, ICT.UpdateDisplay))
end

-- message and add option
local function messageResults(player, instance)
    -- Only broadcast if we are locked and collected something...
    if instance and instance.locked then
        log.debug("broadcast: announcing")
        -- Double check amounts before messaging.
        -- It seems WOW may process oddly.
        player:update()
        ICT:UpdateDisplay()
        for currency, _ in ICT:spairs(instance:currencies()) do

            -- Onyxia 40 is reused and has 0 emblems so skip currency.
            local max = instance:maxCurrency(currency)
            if currency:isVisible() and max ~= 0 then
                local available = instance:availableCurrency(currency)
                local collected = max - available
                local total = player:totalCurrency(currency)
                -- I don't know or I can't put an icon into chat.
                local text = string.format("[%s] %s, collected %s of %s [%s]", addOnName, currency:getName(), collected, max, total)
                Options:PrintMessage(text)
            end
        end
    elseif instance then
        log.debug("broadcast: no lock")
    else
        log.debug("broadcast: no instance")
    end
end
local broadcastEvent = function()
    if maxPlayers and instanceId then
        local player = Players:get()
        local instance = player:getInstance(instanceId, maxPlayers)
        messageResults(player, instance)
    end
    _, _, _, _, maxPlayers, _, _, instanceId = GetInstanceInfo()
end
local broadcastFrame = CreateFrame("Frame")
broadcastFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
broadcastFrame:SetScript("OnEvent", broadcastEvent)
-- On reload set the instance.
C_Timer.After(0.5, broadcastEvent)