local addOnName, ICT = ...

ICT.LDBIcon = LibStub("LibDBIcon-1.0")
local LDBroker = LibStub("LibDataBroker-1.1")
local Player = ICT.Player
local Options = ICT.Options
local version = GetAddOnMetadata("InstanceCurrencyTracker", "Version")
local maxPlayers, instanceId

local function getOrCreateDb()
    local db = InstanceCurrencyDB or {}
    InstanceCurrencyDB = db
    ICT:putIfAbsent(db, "players", {})
    ICT:putIfAbsent(db, "options", {})
    ICT:putIfAbsent(db.options, "collapsible", {})
    -- ICT:putIfAbsent(db.options.collapsible, "Info", true)
    db.reset = db.reset or { [1] = C_DateAndTime.GetSecondsUntilDailyReset() + GetServerTime(), [7] = C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime() }
    return db
end

local function flipFrame()
    if not ICT.frame:IsVisible() then
        -- Force display update if it's enabled.
        ICT:PrintPlayers()
        ICT.frame:Show()
    else
        ICT.frame:Hide()
    end
end

function ICT.UpdateDisplay()
    local player = ICT.GetPlayer()
    player.time = GetServerTime();
    -- Defer updating the display if it's not currently viewed.
    if ICT.frame and ICT.frame:IsVisible() then
        ICT:PrintPlayers()
    else
        ICT.dprint("not updating frame")
    end
end

local function initMinimap()
    local miniButton = LDBroker:NewDataObject(addOnName, {
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
        if not(ICT.db.version) or ICT.semver(ICT.db.version) <= ICT.semver("v1.0.21") then
            print(string.format("[%s] Incompatible old version detected, wiping players. Please relog into each character, sorry.", addOnName))
            ICT:WipeAllPlayers()
        end
        ICT.db.version = version

        initMinimap()
        for k, player in pairs(ICT.db.players) do
            -- Recreate the player with any new functions.
            ICT.db.players[k] = Player:new(player)
            -- Player may have already been created but we added new instances.
            player:createInstances()
        end
        -- Check if we need to delay this part.
        ICT.CreateCurrentPlayer()
        ICT.init = true
        ICT.GetPlayer():onLoad()
        ICT:CreateFrame()
        print(string.format("[%s] Initialized %s...", addOnName, version))
        LFGParentFrame:HookScript("OnShow", function() if ICT.db.options.anchorLFG then ICT:PrintPlayers() ICT.frame:Show() end end)
        LFGParentFrame:HookScript("OnHide", function() if ICT.db.options.anchorLFG then ICT.frame:Hide() end end)
    end
end
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", initEvent)

local updateFrame = CreateFrame("Frame")
-- After the instance info is updated then trigger updates to our representation.
-- This fires every time we load LFG so it seems unnecessary.
-- updateFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
-- After an enounter update information for the instance.
updateFrame:RegisterEvent("ENCOUNTER_END")
-- After currency changes we need to update the wallet.
updateFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
-- Level 80 characters will appear.
updateFrame:RegisterEvent("PLAYER_LEVEL_UP")
-- Added for updating prerequisites and marking dailies done.
updateFrame:RegisterEvent("QUEST_COMPLETE")
updateFrame:SetScript("OnEvent", ICT:throttleFunction("Instance/Currency", 0, Player.update, ICT.UpdateDisplay))

local moneyFrame = CreateFrame("Frame")
moneyFrame:RegisterEvent("PLAYER_MONEY")
moneyFrame:SetScript("OnEvent", ICT:throttleFunction("Money", 2, Player.updateMoney, ICT.UpdateDisplay))

local skillFrame = CreateFrame("Frame")
-- Individual skill ups.
skillFrame:RegisterEvent("CHAT_MSG_SKILL")
-- Learning a new skill or raising a skill from Journeyman to Master. 
skillFrame:RegisterEvent("SKILL_LINES_CHANGED")
skillFrame:SetScript("OnEvent", ICT:throttleFunction("Skill", 3, Player.updateSkills, ICT.UpdateDisplay))

-- Links aren't shareable after the player logs out.
-- local skillShowFrame = CreateFrame("Frame")
-- skillShowFrame:RegisterEvent("TRADE_SKILL_SHOW")
-- skillShowFrame:SetScript("OnEvent", function()
--     -- Remove color so we can color it.
--     local link = GetTradeSkillListLink()
--     local spellId = tonumber(ICT.tradeLinkSplit(link)[2]) or 0
--     local player = ICT.GetPlayer()
--     player.professionLinks = player.professionLinks or {}
--     player.professionLinks[spellId] = link
-- end
-- )

local talentFrame = CreateFrame("Frame")
talentFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
talentFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
talentFrame:SetScript("OnEvent", ICT:throttleFunction("Talent", 3, Player.updateTalents, ICT.UpdateDisplay))

local glyphFrame = CreateFrame("Frame")
glyphFrame:RegisterEvent("ACTIVATE_GLYPH")
glyphFrame:SetScript("OnEvent", ICT:throttleFunction("Glyph", 1, Player.updateGlyphs, ICT.UpdateDisplay))

local gearFrame = CreateFrame("Frame")
gearFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
gearFrame:RegisterEvent("SOCKET_INFO_SUCCESS")
-- If something gets enchanted, although this is very potentially noisy as you can't filter it based on a specific skill.
gearFrame:RegisterEvent("TRADE_SKILL_UPDATE")
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
-- Don't throttle but use the is db init check.
durabilityFrame:SetScript("OnEvent", ICT:throttleFunction("Durability", 0, Player.updateDurability, ICT.UpdateDisplay))

local cooldownFrame = CreateFrame("Frame")
-- Trade skill update doesn't seem sufficient to determine an item was made (i.e. start a cooldown)
cooldownFrame:RegisterEvent("TRADE_SKILL_UPDATE")
cooldownFrame:RegisterEvent("CHAT_MSG_TRADESKILLS")
cooldownFrame:SetScript("OnEvent", ICT:throttleFunction("Cooldowns", 0, Player.updateCooldowns, ICT.UpdateDisplay))

-- message and add option
local function messageResults(player, instance)
    -- Only broadcast if we are locked and collected something...
    if instance and instance.locked then
        ICT.dprint("broadcast: announcing")
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
                local text = string.format("[%s] %s, collected %s of %s [%s]", addOnName, currency:getNameWithIcon(), collected, max, total)
                Options:PrintMessage(text)
            end
        end
    elseif instance then
        ICT.dprint("broadcast: no lock")
    else
        ICT.dprint("broadcast: no instance")
    end
end
local broadcastEvent = function()
    if maxPlayers and instanceId then
        local player = ICT.GetPlayer()
        local instance = player:getInstance(instanceId, maxPlayers)
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
                print("Invalid command")
            end
        end
        -- Refresh frame
        ICT:UpdateDisplay()
    elseif rest == "" then
        flipFrame()
    end
end

function ICT.WipePlayer(playerName)
    if ICT.db.players[playerName] then
        ICT.db.players[playerName] = nil
        print(string.format("[%s] Wiped player: %s", addOnName, playerName))
    else
        print(string.format("[%s] Unknown player: %s", addOnName, playerName))
    end
    ICT.CreateCurrentPlayer()
end

function ICT.WipeRealm(realmName)
    local count = 0
    for name, _ in ICT:fpairsByValue(ICT.db.players, function(v) return v.realm == realmName end) do
        count = count + 1
        ICT.db.players[name] = nil
    end
    print(string.format("[%s] Wiped %s players on realm: %s", addOnName , count, realmName))
    ICT.CreateCurrentPlayer()
end

function ICT.WipeAllPlayers()
    local count = ICT:sum(ICT.db.players, ICT:ReturnX(1))
    ICT.db.players = {}
    print(string.format("[%s] Wiped %s players", addOnName, count))
    ICT.CreateCurrentPlayer()
end