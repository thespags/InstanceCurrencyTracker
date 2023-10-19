
local addOnName, ICT = ...

local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local Player = ICT.Player
local Tooltip = ICT.Tooltip

local Tooltips = {}
ICT.Tooltips= Tooltips

function Tooltips:goldTooltip(player, realmGold)
    local f = function(tooltip)
        tooltip:printTitle(L["Realm Gold"])
        :printValue(string.format("[%s]", player.realm), GetCoinTextureString(realmGold))
        for _, player in ICT:nspairsByValue(ICT.db.players, function(p) return player.realm == p.realm end) do
            tooltip:printValue(player:getName(), GetCoinTextureString(player.money or 0), player:getClassColor())
        end
    end
    return Tooltip:new("ICTGoldTip", f)
end

function Tooltips:bagTooltip(player)
    local f = function(tooltip)
        tooltip:printTitle(L["Bag Space"])
        :printValue(L["Bag"], L["Free / Total"])

        local printBags = function(bags, title)
            for _, v in ICT:spairs(bags) do
                tooltip:printSection(title)
                local name = string.format("|T%s:14|t%s", v.icon or "", v.name)
                tooltip:printValue(name, string.format("%s/%s", v.free, v.total))
            end
        end
        printBags(player.bags, L["Personal Bags"])
        tooltip.shouldPrintTitle = true
        if ICT.db.options.player.showBankBags then
            tooltip.shouldPrintTitle = true
            printBags(player.bankBags, L["Bank Bags"])
            tooltip:printPlain("\n" .. L["BagTooltipNote"])
        end
    end
    return Tooltip:new("ICTBagTooltip" .. player:getFullName(), f)
end

function Tooltips:specsSectionTooltip()
    local f = function(tooltip)
        tooltip:printTitle(L["Specs"])
        :printPlain("Displays specs, glyphs. If TacoTip is available, displays gearscore and iLvl as well.")
        :printPlain("\nNote: Gearscore and iLvl are the last equipped gear for a specific spec.")
        :printPlain("i.e. change spec before changing gear to have the most accurate data.")
    end
    return Tooltip:new("ICTSpecsSectionTooltip", f)
end

function Tooltips:specTooltip(player, spec)
    local f = function(tooltip)
        tooltip:printTitle(spec.name .. " " .. L["Gear"])
        tooltip:printLine("Item: iLvL Gems or ? if missing gem")
        tooltip:printLine("Glyph: Slot")
        tooltip:printLine("Item Slot: Enchant")

        tooltip.shouldPrintTitle = true
        for k, item in pairs(spec.items or {}) do
            tooltip:printSection(L["Items"])
            local text = item.level .. " " .. ICT:addGems(k, item)
            -- This may have to be relocalized, but that's true for some other info (e.g. bags), so just use the link.
            local color = Colors:getItemScoreHex(item.link)
            tooltip:printValue(string.format("|T%s:14|t%s", item.icon, item.link), text, nil, color)
        end

        local printGlyph = function(type, typeName)
            for index, glyph in ICT:fpairsByValue(spec.glyphs, function(v) return v.type == type and v.enabled end) do
                tooltip:printSection(typeName)
                local name = glyph.spellId and string.format("|T%s:14|t%s", glyph.icon, select(1, GetSpellInfo(glyph.spellId))) or L["Missing"]
                tooltip:printValue(name, index)
            end
        end

        tooltip.shouldPrintTitle = true
        printGlyph(1, L["Major"])
        tooltip.shouldPrintTitle = true
        printGlyph(2, L["Minor"])

        tooltip.shouldPrintTitle = true
        for _, item in ICT:fpairsByValue(spec.items, function(v) return v.shouldEnchant end) do
            tooltip:printSection(L["Enchants"])
            local enchant = item.enchantId and LibTradeSkillRecipes:GetEffect(item.enchantId) or L["Missing"]
            tooltip:printValue(_G[item.invType], enchant)
        end

        tooltip:printPlain("\nNote: Socket icons will appear if you are missing ")
        :printPlain("an item that can have an extra slot, such as your belt.")
        :printPlain("\nAlso, enchants aren't localized.")
    end
    return Tooltip:new("ICTGear" .. player:getFullName(), f)
end

-- Tooltip for instance information upon entering the cell.
function Tooltips:instanceTooltip(player, instance)
    local f = function(tooltip)
        tooltip:printTitle(instance.name)

        -- Display the available encounters for the instance.
        tooltip:printValue(L["Encounters"], string.format("%s/%s", instance:encountersLeft(), instance:numOfEncounters()))
        for k, v in pairs(instance:encounters()) do
            local encounterColor = Colors:getSelectedColor(instance:isEncounterKilled(k))
            tooltip:printLine(v, encounterColor)
        end

        -- Display which players are locked or not for this instance.
        -- You have to get at least one player to display a tooltip, so always print title.
        tooltip.shouldPrintTitle = true
        tooltip:printSection(L["Locks"])
        for _, player in ICT:nspairsByValue(ICT.db.players, Player.isEnabled) do
            local playerInstance = player:getInstance(instance.id, instance.size) or { locked = false }
            local playerColor = Colors:getSelectedColor(playerInstance.locked)
            tooltip:printLine(player:getNameWithIcon(), playerColor)
        end

        -- Display all available currency for the instance.
        tooltip.shouldPrintTitle = true
        for currency, _ in ICT:spairs(instance:currencies()) do
            -- Onyxia 40 is reused and has 0 emblems so skip currency.
            local max = instance:maxCurrency(currency)
            if currency:isVisible() and max ~= 0 then
                tooltip:printSection(L["Currency"])
                local available = instance:availableCurrency(currency)
                tooltip:printValue(currency:getNameWithIconTooltip(), string.format("%s/%s", available, max))
            end
        end
    end
    -- This player is the original player which owns the cell.
    return Tooltip:new("ICTInstanceTooltip" .. instance.id .. instance.size .. player:getFullName(), f)
end

function Tooltips:instanceSectionTooltip()
    local f = function(tooltip)
        tooltip:printTitle("Instance Format")
        :printLine(L["Available"], ICT.availableColor)
        :printLine(L["Queued Available"], ICT.queuedAvailableColor)
        :printLine(L["Locked"], ICT.lockedColor)
        :printLine(L["Queued Locked"], ICT.queuedLockedColor)
        :printValue("\n" .. L["Encounters"], L["Available / Total"])
        :printPlain(L["EncountersSection"])
        :printValue(L["Currency"], L["Available / Total"])
        :printValue(L["CurrencySection"])
    end
    return Tooltip:new("ICTInstanceTooltip", f)
end

function Tooltips:currencySectionTooltip()
    local f = function(tooltip)
        tooltip:printTitle("Currency Format")
        :printValue("Character", "Total (Available)")
        :printPlain("Shows the total currency per character,")
        :printPlain("and the available amount across all sources.")
        :printValue("\nCurrency", "Available / Total")
        :printPlain("Shows the available currency for the current lock out,")
        :printPlain("out of the total for any given lockout.")
        :printValue("\nQuests", "Total")
        :printPlain("Shows the currency reward for a given quest.")
    end
    return Tooltip:new("ICTCurrencyFormat", f)
end

local function printInstancesForCurrency(tooltip, title, instances, currency)
    -- Only print the title if there exists an instance for this token.
    tooltip.shouldPrintTitle = true
    for _, instance in pairs(instances) do
        local max = instance:maxCurrency(currency)
        -- Onyxia 40 is reused and has 0 currencies so skip.
        if instance:isVisible() and instance:hasCurrency(currency) and max ~= 0 then
            tooltip:printSection(title)
            -- Displays available currency out of the total currency for this instance.
            local color =  Colors:getSelectedColor(instance.locked)
            local available = instance.available[currency.id] or max
            tooltip:printValue(instance.name, string.format("%s/%s", available, max), color)
        end
    end
end

local function printQuestsForCurrency(tooltip, player, currency)
    if ICT.db.options.quests.show then
        tooltip.shouldPrintTitle = true
        for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player)) do
            if currency:fromQuest()(quest) and player:isQuestVisible(quest) then
                tooltip:printSection(L["Quests"])
                local color = Colors:getQuestColor(player, quest)
                tooltip:printValue(quest.name(player), quest.amount, color)
            end
        end
    end
end

-- Tooltip for currency information upon entering the cell.
function Tooltips:currencyTooltip(selectedPlayer, currency)
    local f = function(tooltip)
        tooltip:printTitle(currency:getNameWithIconTooltip())

        for _, player in ICT:nspairsByValue(ICT.db.players, Player.isEnabled) do
            local available = player:availableCurrency(currency)
            local total = player:totalCurrency(currency)
            local value = available and string.format("%s (%s)", total, available) or total
            tooltip:printValue(player:getNameWithIcon(), value, player:getClassColor())
        end

        if ICT.db.options.frame.verboseCurrencyTooltip then
            printInstancesForCurrency(tooltip, L["Dungeons"], selectedPlayer:getDungeons(), currency)
            printInstancesForCurrency(tooltip, L["Raids"], selectedPlayer:getRaids(), currency)
            printQuestsForCurrency(tooltip, selectedPlayer, currency)
        end
    end
    return Tooltip:new("ICTCurrencyTooltip" .. selectedPlayer:getFullName() .. currency.id, f)
end

function Tooltips:questTooltip(name, quest)
    local f = function(tooltip)
        tooltip:printTitle(name)
        :printValue(quest:getCurrencyName(), quest.amount or "")

        for _, player in ICT:nspairsByValue(ICT.db.players, Player.isEnabled) do
            if player:isQuestVisible(quest) then
                local color = Colors:getQuestColor(player, quest)
                tooltip:printLine(player:getNameWithIcon(), color)
            end
        end
    end
    return Tooltip:new("ICTQuestTooltip" .. name, f)
end

function Tooltips:questSectionTooltip()
    local f = function(tooltip)
        tooltip:printTitle("Quest Format")
        :printLine(L["Available"], ICT.availableColor)
        :printLine(L["Completed"], ICT.lockedColor)
        :printLine(L["Missing Prerequesite"], ICT.unavailableColor)
        :printValue("\n" .. L["Currency"], L["Total"])
        :printPlain(L["Shows the quest reward."])
    end
    return Tooltip:new("ICTQuestTooltip", f)
end

function Tooltips:timerSectionTooltip()
    local f = function(tooltip)
        tooltip:printTitle(L["Reset Timers"])
        :printPlain("Countdown to the next reset respectively for 1, 3, 5 and 7 days.")
        :printPlain("\nNote: 3 and 5 day resets need a known lockout to calculate from\nas Blizzard doesn't provide a way through their API.")
    end
   return Tooltip:new("ICTResetTimerTooltip", f)
end