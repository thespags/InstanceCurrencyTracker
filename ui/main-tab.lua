local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local Player = ICT.Player
local Reset = ICT.Reset
local Talents = ICT.Talents
local Tooltips = ICT.Tooltips
local UI = ICT.UI

local MainTab = {
    paddings = {},
    realmGold = {},
    tickers = {}
}
ICT.MainTab = MainTab

function MainTab:calculatePadding()
    local db = ICT.db
    local options = db.options
    self.paddings.info = ICT:sumNonNil({options.player.showLevel, options.player.showGuild, options.player.showGuildRank, options.player.showMoney, options.player.showDurability})
    -- If there is a viewable player under 80 then pad for XP info.
    self.paddings.rested = ICT:containsAnyValue(db.players, function(player) return player.level < ICT.MaxLevel and player:isEnabled() end)
        and ICT:sumNonNil({options.player.showXP, options.player.showRestedXP, options.player.showRestedState})
        or 0
    self.paddings.bags = options.player.showBags
        and ICT:max(db.players, function(player) return ICT:sum(player.bagsTotal, ICT:returnX(1), function(v) return v.total > 0 end) end, Player.isEnabled)
        or 0
    self.paddings.bags = self.paddings.bags + (options.player.showBags and options.player.showBankBags
        and ICT:max(db.players, function(player) return ICT:sum(player.bankBagsTotal, ICT:returnX(1), function(v) return v.total > 0 end) end, Player.isEnabled)
        or 0)
    self.paddings.professions = ICT:max(db.players, function(player) return ICT:size(player.professions) end, Player.isEnabled)
    self.paddings.cooldowns = options.player.showCooldowns
        and ICT:max(db.players, function(player) return ICT:sum(player.cooldowns, ICT:returnX(1), ICT.Cooldown.isVisible) end, Player.isEnabled)
        or 0
    self.paddings.specs = TT_GS and 6 or 2
    self.paddings.quests = ICT:max(db.players, function(player) return ICT:sum(ICT.QuestInfo, ICT:returnX(1), player:isQuestVisible()) end, Player.isEnabled)
end

function MainTab:getPadding(offset, name)
    return offset + (true and self.paddings[name] or 0)
end

function MainTab:calculateGold()
    for _, player in pairs(ICT.db.players) do
        self.realmGold[player.realm] = (self.realmGold[player.realm] or 0) + (player.money or 0)
    end
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
    Tooltips:goldTooltip(player, self.realmGold[player.realm]):attach(cell)
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
        local tooltip = Tooltips:bagTooltip(player)
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
        Tooltips:specsSectionTooltip():attach(cell)

        if cell:isSectionExpanded("Specs") then
            padding = self:getPadding(offset, "specs")
            for _, spec in pairs(player:getSpecs()) do
                if Talents:isValidSpec(spec) then
                    local specColor = Colors:getSelectedColor(spec.id == player.activeSpec)
                    local tooltip = Tooltips:specTooltip(player, spec)
                    cell = self.cells:get(x, offset)
                    local icon = spec.icon and CreateSimpleTextureMarkup(spec.icon, 14, 14) or ""
                    local name = icon .. (spec.name or "")
                    offset = cell:printValue(name, string.format("%s/%s/%s    ", spec.tab1, spec.tab2, spec.tab3), specColor)
                    tooltip:attach(cell)
                    local buttonTooltip = function(tooltip)
                        tooltip:printTitle(L["Spec"])
                        :printValue(L["Click"], L["Spec Click"])
                        :printValue(L["Shift Click"], L["Spec Shift Click"])
                    end
                    cell:attachButton("ICTSetSpec", buttonTooltip, Talents:activateSpec(spec.id), Talents:viewSpec(spec.id))
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
            for _, v in ICT:nspairsByValue(player.cooldowns, ICT.Cooldown.isVisible) do
                cell = self.cells:get(x, offset)
                local key = player:getFullName() .. v:getName()
                offset = cell:printTicker(v:getNameWithIcon(), key, v.expires, v.duration)
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
    Tooltips:instanceSectionTooltip():attach(cell)
    local canQueue = not IsInGroup() or UnitIsGroupLeader("player")
    local cantQueue = function() ICT:print(L["Cannot queue, not currently the group leader."]) end
    if player:isCurrentPlayer() then
        local f = canQueue and enqueueAll(title, subTitle, instances) or cantQueue
        local tooltip = function(tooltip) tooltip:printTitle(L["Enqueue Instances"]):printPlain(L["Enqueue Instances Body"]) end
        cell:attachButton("ICTEnqueueAll", tooltip, f)
    end

    -- If the section is collapsible then short circuit here.
    if cell:isSectionExpanded(key) then
        for _, instance in ICT:nspairsByValue(instances) do
            if instance:isVisible() then
                local color = player:isCurrentPlayer() and instance:queued() and Colors:getSelectedQueueColor(instance.locked) or Colors:getSelectedColor(instance.locked)
                cell = self.cells:get(x, offset)
                offset = cell:printLine(instance:getName(), color)
                Tooltips:instanceTooltip(player, instance):attach(cell)
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
            sizes[k] = ICT:size(v.instances(player, expansion), ICT.Instance.isVisible)
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

-- Prints currency with multi line information.
function MainTab:printCurrencyVerbose(player, currency, x, offset)
    local cell = self.cells:get(x, offset)
    offset = cell:printValue(currency:getNameWithIcon(), nil, ICT.subtitleColor)
    local tooltip = Tooltips:currencyTooltip(player, currency)
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
    Tooltips:currencyTooltip(player, currency):attach(cell)
    return offset
end

function MainTab:printCurrency(player, x, offset)
    if ICT:containsAnyValue(ICT.db.options.currency) then
        local cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Currency"])
        Tooltips:currencySectionTooltip():attach(cell)
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

function MainTab:printQuests(player, x, offset)
    if ICT.db.options.quests.show then
        local cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Quests"])
       Tooltips: questSectionTooltip():attach(cell)
        if cell:isSectionExpanded(L["Quests"]) then
            local padding = self:getPadding(offset, "quests")
            for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player), player:isQuestVisible()) do
                local color = Colors:getQuestColor(player, quest)
                local name = quest.name(player)
                cell = self.cells:get(x, offset)
                offset = cell:printLine(name, color)
                Tooltips:questTooltip(name, quest):attach(cell)
            end
            offset = self.cells:hideRows(x, offset, padding)
        end
        offset = self.cells:get(x, offset):hide()
    end
    return offset
end

function MainTab:printResetTimers(x, offset)
    if not ICT.db.options.multiPlayerView then
        local cell = self.cells:get(x, offset)
        offset = cell:printSectionTitle(L["Reset"])
        Tooltips:timerSectionTooltip():attach(cell)

        if cell:isSectionExpanded(L["Reset"]) then
            for _, v in ICT:nspairsByValue(ICT.Resets, Reset.isVisible) do
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
    if ICT:sumNonNil(ICT.db.options.player) > 0 then
        offset = self:printCharacterInfo(player, x, offset)
    end
    offset = self:printResetTimers(x, offset)
    offset = self:printAllInstances(player, x, offset)
    offset = self:printQuests(player, x, offset)
    offset = self:printCurrency(player, x, offset)
    return offset
end

function MainTab:prePrint()
    self:hideTickers()
    self:calculatePadding()
    self:calculateGold()
end

function MainTab:postPrint()
    local selected = ICT.db.selectedTab == self.button:GetID()
    if selected and ICT.db.options.multiPlayerView then
        local count = ICT:sum(ICT.db.options.reset, function(v) return v and 1 or 0 end)
        local tooltip = Tooltips:timerSectionTooltip()
        -- local start = 32 + -60 * count / 2
        local start = 28 + -55 * count / 2
        local frame = nil
        for _, v in ICT:nspairsByValue(ICT.Resets, Reset.isVisible) do
            start, frame = self:printMultiViewResetTicker(start, v:getName(), v:expires(), v:duration())
            tooltip:attachFrame(frame)
        end
    end
end

function MainTab:printMultiViewResetTicker(x, title, expires, duration)
    local frame = self.tickers[title] and self.tickers[title].frame
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
    local update = function(self)
        ICT:cancelTicker(self)
        local time, _ = ICT:countdown(expires, duration)
        frame.textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", ICT.subtitleColor, title, ICT.textColor, time))
    end
    self.tickers[title] = { ticker = C_Timer.NewTicker(1, update), frame = frame }
    update()
    return x + 55, frame
end

function MainTab:show()
    MainTab:postPrint()
    self.frame:Show()
end

function MainTab:hide()
    self:hideTickers()
    self.frame:Hide()
end

function MainTab:hideTickers()
    for _, v in pairs(self.tickers or {}) do
        v.ticker:Cancel()
        if v.frame then v.frame:Hide() end
    end
end

function MainTab:showGearScores()
    return ICT.db.options.player.showGearScores
end