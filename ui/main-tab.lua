local addOnName, ICT = ...

local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local Instances = ICT.Instances
local Player = ICT.Player
local Reset = ICT.Reset
local Tooltips = ICT.Tooltips
local UI = ICT.UI

local MainTab = {
    paddings = {},
    realmGold = {},
}
ICT.MainTab = MainTab

function MainTab:calculatePadding()
    local db = ICT.db
    local options = db.options
    self.paddings.info = ICT:sumNonNil(options.player.showLevel, options.player.showGuild, options.player.showGuildRank, options.player.showMoney, options.player.showDurability)
    -- If there is a viewable player under 80 then pad for XP info.
    self.paddings.rested = ICT:containsAnyValue(db.players, function(player) return player.level < ICT.MaxLevel and player:isEnabled() end)
        and ICT:sumNonNil(options.player.showXP, options.player.showRestedXP, options.player.showRestedState)
        or 0
    self.paddings.bags = options.player.showBags
        and ICT:max(db.players, function(player) return ICT:sum(player.bagsTotal or {}, ICT:ReturnX(1), function(v) return v.total > 0 end) end, Player.isEnabled)
        or 0
    self.paddings.bags = self.paddings.bags + (options.player.showBags and options.player.showBankBags
        and ICT:max(db.players, function(player) return ICT:sum(player.bankBagsTotal or {}, ICT:ReturnX(1), function(v) return v.total > 0 end) end, Player.isEnabled)
        or 0)
    self.paddings.professions = ICT:max(db.players, function(player) return ICT:size(player.professions) end, Player.isEnabled)
    self.paddings.cooldowns = options.player.showCooldowns
        and ICT:max(db.players, function(player) return ICT:sum(player.cooldowns or {}, ICT:ReturnX(1), ICT.Cooldown.isVisible) end, Player.isEnabled)
        or 0
    self.paddings.specs = TT_GS and 6 or 2
    self.paddings.quests = ICT:max(db.players, function(player) return ICT:sum(ICT.QuestInfo, ICT:ReturnX(1), player:isQuestVisible()) end, Player.isEnabled)
end

function MainTab:getPadding(offset, name)
    return offset + (true and self.paddings[name] or 0)
end

function MainTab:calculateGold()
    for _, player in pairs(ICT.db.players) do
        self.realmGold[player.realm] = (self.realmGold[player.realm] or 0) + (player.money or 0)
    end
end

function MainTab:goldTooltip(player)
    local tooltip = Tooltips:new(L["Realm Gold"])
    tooltip:printValue(string.format("[%s]", player.realm), GetCoinTextureString(self.realmGold[player.realm]))

    for _, player in ICT:nspairsByValue(ICT.db.players, function(p) return player.realm == p.realm end) do
        tooltip:printValue(player:getName(), GetCoinTextureString(player.money or 0), player:getClassColor())
    end
    return tooltip:create("ICTGoldTip" .. player.fullName)
end

function MainTab:bagTooltip(player)
    local tooltip = Tooltips:new(L["Bag Space"])
    tooltip:printValue(L["Bag"], L["Free / Total"])

    local printBags = function(bags, title)
        for _, v in ICT:spairs(bags or {}) do
            tooltip:printTitle(title)
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
    return tooltip:create("ICTBagTooltip" .. player.fullName)
end

function MainTab:specTooltip(player, spec)
    local tooltip = Tooltips:new(spec.name .. " " .. L["Gear"])
    tooltip:printLine("Item: iLvL Gems or ? if missing gem")
    tooltip:printLine("Glyph: Slot")
    tooltip:printLine("Item Slot: Enchant")

    tooltip.shouldPrintTitle = true
    for k, item in pairs(spec.items or {}) do
        tooltip:printTitle(L["Items"])
        local text = item.level .. " " .. ICT:addGems(k, item)
        -- This may have to be relocalized, but that's true for some other info (e.g. bags), so just use the link.
        local color = Colors:getItemScoreHex(item.link)
        tooltip:printValue(string.format("|T%s:14|t%s", item.icon, item.link), text, nil, color)
    end

    local printGlyph = function(type, typeName)
        for index, glyph in ICT:fpairsByValue(spec.glyphs or {}, function(v) return v.type == type and v.enabled end) do
            tooltip:printTitle(typeName)
            local name = glyph.spellId and string.format("|T%s:14|t%s", glyph.icon, select(1, GetSpellInfo(glyph.spellId))) or L["Missing"]
            tooltip:printValue(name, index)
        end
    end

    tooltip.shouldPrintTitle = true
    printGlyph(1, L["Major"])
    tooltip.shouldPrintTitle = true
    printGlyph(2, L["Minor"])

    tooltip.shouldPrintTitle = true
    for _, item in ICT:fpairsByValue(spec.items or {}, function(v) return v.shouldEnchant end) do
        tooltip:printTitle(L["Enchants"])
        local enchant = item.enchantId and LibTradeSkillRecipes:GetEffect(item.enchantId) or L["Missing"]
        tooltip:printValue(_G[item.invType], enchant)
    end

    tooltip:printPlain("\nNote: Socket icons will appear if you are missing ")
    :printPlain("an item that can have an extra slot, such as your belt.")
    :printPlain("\nAlso, enchants aren't localized.")
    return tooltip:create("ICTSpec" .. spec.id .. player.fullName)
end

function MainTab:printCharacterInfo(player, x, offset)
    local cell = self.cells:get(x, offset)
    offset = cell:printSectionTitle(L["Info"])
    local options = ICT.db.options
    if not cell:isSectionExpanded(L["Info"]) then
        return self.cells:get(x, offset):hide()
    end
    self.cells.indent = "  "
    local padding = self:getPadding(offset, "info")
    offset = self.cells:get(x, offset):printOptionalValue(options.player.showLevel, L["Level"], player.level)
    offset = self.cells:get(x, offset):printOptionalValue(options.player.showGuild, L["Guild"], player.guild)
    offset = self.cells:get(x, offset):printOptionalValue(options.player.showGuildRank, L["Guild Rank"], player.guildRank)
    cell = self.cells:get(x, offset)
    offset = cell:printOptionalValue(options.player.showMoney, L["Gold"], GetCoinTextureString(player.money or 0))
    self:goldTooltip(player):attach(cell)
    if not options.player.showSpecs then
        local spec = player:getSpec()
        local tooltip = self:specTooltip(player, spec)
        offset = UI:printGearScore(self, spec, tooltip, x, offset)
    end
    local durabilityColor = player.durability and Colors:gradient("FF00FF00", "FFFF0000", player.durability / 100) or "FF00FF00"
    offset = self.cells:get(x, offset):printOptionalValue(options.player.showDurability, L["Durability"], player.durability and string.format("%.0f%%", player.durability), nil, durabilityColor)
    offset = self.cells:hideRows(x, offset, padding)

    padding = self:getPadding(offset, "rested")
    if player.level < ICT.MaxLevel then
        local currentXP = player.currentXP or 0
        local maxXP = player.maxXP or 1
        local xpPercentage = currentXP / maxXP * 100 
        offset = self.cells:get(x, offset):printOptionalValue(options.player.showXP, L["XP"], string.format("%s/%s (%.0f%%)", currentXP, maxXP, xpPercentage))
        local restedPercentage = player:getRestedXP()
        local bubbles = restedPercentage * 20
        offset = self.cells:get(x, offset):printOptionalValue(options.player.showRestedXP, L["Rested XP"], string.format("%.1f %s (%.0f%%)", bubbles, L["Bubbles"], restedPercentage * 100))
        local resting = player.resting and L["Resting"] or L["Not Resting"]
        offset = self.cells:get(x, offset):printOptionalValue(options.player.showRestedState, L["Resting State"], resting)
    end
    offset = self.cells:hideRows(x, offset, padding)

    local bags = player.bagsTotal or {}
    if options.player.showBags then
        offset = self.cells:get(x, offset):hide()
        local tooltip = self:bagTooltip(player)
        cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Bags"])
        tooltip:attach(cell)

        if cell:isSectionExpanded(L["Bags"]) then
            padding = self:getPadding(offset, "bags")
            for k, bag in ICT:nspairs(bags, function(k) return bags[k].total > 0 end) do
                cell = self.cells:get(x, offset)
                offset = cell:printValue(string.format("|T%s:12|t%s", ICT.BagFamily[k].icon, ICT.BagFamily[k].name), string.format("%s/%s", bag.free, bag.total))
                tooltip:attach(cell)
            end

            local bankBags = player.bankBagsTotal or {}
            if options.player.showBankBags and ICT:sum(bankBags, function(v) return v.total end) > 0 then
                for k, bag in ICT:nspairs(bankBags, function(k) return bags[k].total > 0 end) do
                    cell = self.cells:get(x, offset)
                    offset = cell:printValue(string.format("|T%s:12|t[Bank] %s", ICT.BagFamily[k].icon, ICT.BagFamily[k].name), string.format("%s/%s", bag.free, bag.total))
                    tooltip:attach(cell)
                end
            end
            offset = self.cells:hideRows(x, offset, padding)
        end
    end

    if options.player.showSpecs then
        offset = self.cells:get(x, offset):hide()
        cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Specs"])
        UI:specsSectionTooltip():attach(cell)

        if cell:isSectionExpanded("Specs") then
            padding = self:getPadding(offset, "specs")
            for _, spec in pairs(player:getSpecs()) do
                if not(spec.tab1 == 0 and spec.tab2 == 0 and spec.tab3 == 0) then
                    local specColor = Colors:getSelectedColor(spec.id == player.activeSpec)
                    local tooltip = self:specTooltip(player, spec)
                    cell = self.cells:get(x, offset)
                    offset = cell:printValue(spec.name or "", string.format("%s/%s/%s", spec.tab1, spec.tab2, spec.tab3), specColor)
                    tooltip:attach(cell)
                    offset = UI:printGearScore(self, spec, tooltip, x, offset)
                end
            end
            offset = self.cells:hideRows(x, offset, padding)
        end
    end

    -- This should be already indexed primary over secondary professions.
    if options.player.showProfessions then
        offset = self.cells:get(x, offset):hide()
        cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Professions"])

        if cell:isSectionExpanded(L["Professions"]) then
            padding = self:getPadding(offset, "professions")
            for _, v in pairs(player.professions or {}) do
                -- We should have already filtered out those without icons but safety check here.
                local nameWithIcon = v.icon and string.format("|T%s:14|t%s", v.icon, v.name) or v.name
                cell = self.cells:get(x, offset)
                offset = cell:printValue(nameWithIcon, string.format("%s/%s", v.rank, v.max))
                if v.spellId and player:isCurrentPlayer() then
                    cell:attachClick(function() CastSpellByID(v.spellId) end)
                end
            end
            offset = self.cells:hideRows(x, offset, padding)
        end
    end

    if ICT.db.options.player.showCooldowns and ICT:containsAnyValue(ICT.db.options.displayCooldowns) then
        offset = self.cells:get(x, offset):hide()
        cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Cooldowns"])

        if cell:isSectionExpanded(L["Cooldowns"]) then
            padding = self:getPadding(offset, "cooldowns")
            for _, v in ICT:nspairsByValue(player.cooldowns or {}, ICT.Cooldown.isVisible) do
                cell = self.cells:get(x, offset)
                local name = v:getNameWithIcon()
                local key = player.fullName .. name
                offset = cell:printTicker(name, key, v.expires, v.duration)
                if player:isCurrentPlayer() then
                    if v:getSpell() then
                        cell:attachClick(function() v:cast(player) end)
                    elseif v:getItem() then
                        cell:attachSecureClick(v:getItem())
                    end
                end
            end
            offset = self.cells:hideRows(x, offset, padding)
        end
    end
    offset = self.cells:get(x, offset):hide()
    self.cells.indent = ""
    return offset
end

-- Tooltip for instance information upon entering the cell.
local function instanceTooltip(player, instance)
    local tooltip = Tooltips:new(instance.name)

    -- Display the available encounters for the instance.
    tooltip:printValue(L["Encounters"], string.format("%s/%s", instance:encountersLeft(), instance:numOfEncounters()))
    for k, v in pairs(instance:encounters()) do
        local encounterColor = Colors:getSelectedColor(instance:isEncounterKilled(k))
        tooltip:printLine(v, encounterColor)
    end

    -- Display which players are locked or not for this instance.
    -- You have to get at least one player to display a tooltip, so always print title.
    tooltip.shouldPrintTitle = true
    tooltip:printTitle(L["Locks"])
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
            tooltip:printTitle(L["Currency"])
            local available = instance:availableCurrency(currency)
            tooltip:printValue(currency:getNameWithIconTooltip(), string.format("%s/%s", available, max))
        end
    end
    -- This player is the original player which owns the cell.
    return tooltip:create("ICTInstanceTooltip" .. instance.id .. instance.size .. player.fullName)
end

local function instanceSectionTooltip()
    return Tooltips:new("Instance Format")
    :printLine(L["Available"], ICT.availableColor)
    :printLine(L["Queued Available"], ICT.queuedAvailableColor)
    :printLine(L["Locked"], ICT.lockedColor)
    :printLine(L["Queued Locked"], ICT.queuedLockedColor)
    :printValue("\n" .. L["Encounters"], L["Available / Total"])
    :printPlain(L["EncountersSection"])
    :printValue("\n" .. L["Currency"], L["Available / Total"])
    :printValue(L["CurrencySection"])
    :create("ICTInstanceTooltip")
end

local function enqueueAll(title, subTitle, instances)
    return function()
        local info = C_LFGList.GetActiveEntryInfo()
        if info == nil then
            local queuedIds = {}
            for _, instance in pairs(instances) do
                instance:enqueue(queuedIds, false, false)
            end
            C_LFGList.CreateListing(queuedIds)
            if #queuedIds > 41 then
                ICT:print(L["Enqueued too many instances: {0}"], #queuedIds)
            else
                ICT:oprint(L["Enqueued all non lock %s %s."], "lfg", ICT.Expansions[title], subTitle)
            end
        else
            C_LFGList.RemoveListing()
            ICT:oprint(L["Listing removed."], "lfg")
        end
    end
end

local function enqueue(instance)
    return function()
        local info = C_LFGList.GetActiveEntryInfo()
        local queuedIds = info and info.activityIDs or {}
        instance:enqueue(queuedIds, true, true)

        if #queuedIds == 0 then
            ICT:oprint(L["No more instances queued, delisting."], "lfg")
            C_LFGList.RemoveListing()
            UI:PrintPlayers()
            return
        end
        if #queuedIds > 41 then
            ICT:print(L["Enqueued too many instances: %s"], #queuedIds)
        end
        local f = queuedIds == {} and C_LFGList.RemoveListing or info == nil and C_LFGList.CreateListing or C_LFGList.UpdateListing
        f(queuedIds)
    end
end

-- Prints all the instances with associated tooltips.
function MainTab:printInstances(player, title, subTitle, size, instances, x, offset)
    if size == 0 then
        return offset
    end

    local cell = self.cells:get(x, offset)
    local key = title .. subTitle
    offset = cell:printSectionTitle(subTitle, key)
    instanceSectionTooltip():attach(cell)
    local canQueue = not IsInGroup() or UnitIsGroupLeader("player")
    local cantQueue = function() ICT:print(L["Cannot queue, not currently the group leader."]) end
    if player:isCurrentPlayer() then
        if canQueue then
            cell:enqueueAllButton(enqueueAll(title, subTitle, instances))
        else
            cell:enqueueAllButton(cantQueue)
        end
    end

    -- If the section is collapsible then short circuit here.
    if cell:isSectionExpanded(key) then
        for _, instance in ICT:nspairsByValue(instances) do
            if instance:isVisible() then
                local color = player:isCurrentPlayer() and instance:queued() and Colors:getSelectedQueueColor(instance.locked) or Colors:getSelectedColor(instance.locked)
                cell = self.cells:get(x, offset)
                offset = cell:printLine(instance:getName(), color)
                instanceTooltip(player, instance):attach(cell)
                if player:isCurrentPlayer() then
                    if canQueue then
                        cell:attachClick(enqueue(instance))
                    else
                        cell:attachClick(cantQueue)
                    end
                end
            end
        end
    end
    return self.cells:get(x, offset):hide()
end

function MainTab:printAllInstances(player, x, offset)
    local subSections =  { { name = L["Dungeons"], instances = Player.getDungeons }, { name = L["Raids"], instances = Player.getRaids },  }
    for expansion, name in ICT:spairs(ICT.Expansions, ICT.reverseSort) do
        local sizes = {}
        for k, v in ipairs(subSections) do
            sizes[k] = ICT:size(v.instances(player, expansion), Instances.isVisible)
        end
        if ICT:sum(sizes) > 0 then
            local cell = self.cells:get(x, offset)
            offset = cell:printSectionTitle(name)

            if cell:isSectionExpanded(name) then
                self.cells.indent = "  "
                for k, v in ipairs(subSections) do
                    offset = self:printInstances(player, expansion, v.name, sizes[k], v.instances(player, expansion), x, offset)
                end
                self.cells.indent = ""
            else
                offset = self.cells:get(x, offset):hide()
            end
        end
    end
    return offset
end

local function printInstancesForCurrency(tooltip, title, instances, currency)
    -- Only print the title if there exists an instance for this token.
    tooltip.shouldPrintTitle = true
    for _, instance in pairs(instances) do
        local max = instance:maxCurrency(currency)
        -- Onyxia 40 is reused and has 0 currencies so skip.
        if instance:isVisible() and instance:hasCurrency(currency) and max ~= 0 then
            tooltip:printTitle(title)
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
                tooltip:printTitle(L["Quests"])
                local color = Colors:getQuestColor(player, quest)
                tooltip:printValue(quest.name(player), quest.amount, color)
            end
        end
    end
end

local function currencySectionTooltip()
    return Tooltips:new("Currency Format")
    :printValue("Character", "Total (Available)")
    :printPlain("Shows the total currency per character,")
    :printPlain("and the available amount across all sources.")
    :printValue("\nCurrency", "Available / Total")
    :printPlain("Shows the available currency for the current lock out,")
    :printPlain("out of the total for any given lockout.")
    :printValue("\nQuests", "Total")
    :printPlain("Shows the currency reward for a given quest.")
    :create("ICTCurrencyFormat")
end

-- Tooltip for currency information upon entering the cell.
local function currencyTooltip(selectedPlayer, currency)
    local tooltip = Tooltips:new(currency:getNameWithIconTooltip())

    for _, player in ICT:nspairsByValue(ICT.db.players, Player.isEnabled) do
        local available = player:availableCurrency(currency)
        local total = player:totalCurrency(currency)
        tooltip:printValue(player:getNameWithIcon(), string.format("%s (%s)", total, available), player:getClassColor())
    end

    if ICT.db.options.frame.verboseCurrencyTooltip then
        printInstancesForCurrency(tooltip, L["Dungeons"], selectedPlayer:getDungeons(), currency)
        printInstancesForCurrency(tooltip, L["Raids"], selectedPlayer:getRaids(), currency)
        printQuestsForCurrency(tooltip, selectedPlayer, currency)
    end
    return tooltip:create("ICTCurrencyTooltip" .. selectedPlayer.fullName .. currency.id)
end

-- Prints currency with multi line information.
function MainTab:printCurrencyVerbose(player, currency, x, offset)
    local cell = self.cells:get(x, offset)
    offset = cell:printValue(currency:getNameWithIcon(), nil, ICT.subtitleColor)
    local tooltip = currencyTooltip(player, currency)
    tooltip:attach(cell)
    local available = player:availableCurrency(currency)
    cell = self.cells:get(x, offset)
    offset = cell:printValue(L["Available"], available, ICT.textColor)
    tooltip:attach(cell)
    local current = player:totalCurrency(currency)
    cell = self.cells:get(x, offset)
    offset = cell:printValue(L["Current"], current, ICT.textColor)
    tooltip:attach(cell)
    return self.cells:get(x, offset):hide()
end

-- Prints currency single line information.
function MainTab:printCurrencyShort(player, currency, x, offset)
    local current = player:totalCurrency(currency)
    local available = player:availableCurrency(currency)
    local value = string.format("%s (%s)", current, available)
    local cell = self.cells:get(x, offset)
    offset = cell:printValue(currency:getNameWithIcon(), value)
    currencyTooltip(player, currency):attach(cell)
    return offset
end

function MainTab:printCurrency(player, x, offset)
    if ICT:containsAnyValue(ICT.db.options.currency) then
        local cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Currency"])
        currencySectionTooltip():attach(cell)
        if cell:isSectionExpanded(L["Currency"]) then
            local printCurrency = ICT.db.options.frame.verboseCurrency and self.printCurrencyVerbose or self.printCurrencyShort
            for _, currency in ipairs(ICT.Currencies) do
                if currency:isVisible() then
                    offset = printCurrency(self, player, currency, x, offset)
                end
            end
        end
    end
    return self.cells:get(x, offset):hide()
end

local function questTooltip(name, quest)
    local tooltip = Tooltips:new(name)
    tooltip:printValue(quest.currency:getNameWithIconTooltip(), quest.amount)

    for _, player in ICT:nspairsByValue(ICT.db.players, Player.isEnabled) do
        if player:isQuestVisible(quest) then
            local color = Colors:getQuestColor(player, quest)
            tooltip:printLine(player:getNameWithIcon(), color)
        end
    end
    return tooltip:create("ICTQuestTooltip" .. name)
end

local function questSectionTooltip()
    return Tooltips:new("Quest Format")
    :printLine(L["Available"], ICT.availableColor)
    :printLine(L["Completed"], ICT.lockedColor)
    :printLine(L["Missing Prerequesite"], ICT.unavailableColor)
    :printValue("\n" .. L["Currency"], L["Total"])
    :printPlain(L["Shows the quest reward."])
    :create("ICTQuestTooltip")
end

function MainTab:printQuests(player, x, offset)
    if ICT.db.options.quests.show then
        local cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Quests"])
        questSectionTooltip():attach(cell)
        if cell:isSectionExpanded(L["Quests"]) then
            local padding = self:getPadding(offset, "quests")
            for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player), player:isQuestVisible()) do
                local color = Colors:getQuestColor(player, quest)
                local name = quest.name(player)
                cell = self.cells:get(x, offset)
                offset = cell:printLine(name, color)
                questTooltip(name, quest):attach(cell)
            end
            offset = self.cells:hideRows(x, offset, padding)
        end
        offset = self.cells:get(x, offset):hide()
    end
    return offset
end

local function timerSectionTooltip()
    return Tooltips:new(L["Reset Timers"])
    :printPlain("Countdown to the next reset respectively for 1, 3, 5 and 7 days.")
    :printPlain("\nNote: 3 and 5 day resets need a known lockout to calculate from\nas Blizzard doesn't provide a way through their API.")
    :create("ICTResetTimerTooltip")
end

function MainTab:printResetTimers(x, offset)
    if not ICT.db.options.multiPlayerView and 1 > 0 then
        local cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Reset"])
        timerSectionTooltip():attach(cell)

        if cell:isSectionExpanded(L["Reset"]) then
            for _, v in ICT:nspairsByValue(ICT.ResetInfo, Reset.isVisible) do
                offset = self.cells:get(x, offset):printTicker(v:getName(), v:getName(), v:expires(), v:duration())
            end
        end
        offset = self.cells:get(x, offset):hide()
    end
    return offset
end

function MainTab:printPlayer(player, x)
    local offset = 1
    offset = self.cells:get(x, offset):printPlayerTitle(player)
    if ICT:sumNonNilTable(ICT.db.options.player) > 0 then
        offset = self:printCharacterInfo(player, x, offset)
    end
    offset = self:printResetTimers(x, offset)
    offset = self:printAllInstances(player, x, offset)
    offset = self:printQuests(player, x, offset)
    offset = self:printCurrency(player, x, offset)
    -- self.cells:hideRows(x, offset, self.frame.displayY or 0)
    return offset
end

function MainTab:prePrint()
    self:calculatePadding()
    self:calculateGold()
end

function MainTab:postPrint()
    local selected = ICT.db.selectedTab == self.button:GetID()
    if selected and ICT.db.options.multiPlayerView then
        local count = ICT:sum(ICT.db.options.reset, function(v) return v and 1 or 0 end)
        local tooltip = timerSectionTooltip()
        -- local start = 32 + -60 * count / 2
        local start = 28 + -55 * count / 2
        local frame = nil
        for _, v in ICT:nspairsByValue(ICT.ResetInfo, Reset.isVisible) do
            start, frame = self:printMultiViewResetTicker(start, v:getName(), v:expires(), v:duration())
            tooltip:attachFrame(frame)
        end
    end
end

function MainTab:printMultiViewResetTicker(x, title, expires, duration)
    local frame = UI.tickers[title] and UI.tickers[title].frame
    if not frame then
        frame = CreateFrame("Button", "ICTReset" .. title, ICT.frame)
        frame:SetAlpha(1)
        frame:SetIgnoreParentAlpha(true)
        frame:SetSize(UI.cellWidth, UI.cellHeight)
        local textField = frame:CreateFontString()
        textField:SetPoint("CENTER")
        textField:SetFont(UI.font, 10)
        textField:SetJustifyH("LEFT")
        frame.textField = textField
    end
    frame:SetPoint("TOP", x, -36)
    frame:Show()
    local update = function()
        local time, _ = UI:countdown(expires, duration)
        frame.textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", ICT.subtitleColor, title, ICT.textColor, time))
    end
    UI.tickers[title] = { ticker = C_Timer.NewTicker(1, update), frame = frame }
    local time, _ = UI:countdown(expires, duration)
    frame.textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", ICT.subtitleColor, title, ICT.textColor, time))
    return x + 55, frame
end

function MainTab:show()
    MainTab:postPrint()
    self.frame:Show()
end

function MainTab:hide()
    UI:hideTickers()
    self.frame:Hide()
end

function MainTab:showGearScores()
    return ICT.db.options.player.showGearScores
end