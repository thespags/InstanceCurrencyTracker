local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Colors = ICT.Colors
local Expansion = ICT.Expansion
local LFD = ICT.LFD
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
    self.paddings.rested = ICT:containsAnyValue(db.players, function(player) return not player:isMaxLevel() and player:isEnabled() end)
        and ICT:sumNonNil({options.player.showXP, options.player.showRestedXP, options.player.showRestedState})
        or 0
    local bagCount = function(player)
        return ICT:sum(player.bagsTotal, ICT:returnX(1), function(v) return v.total > 0 end)
            + (options.player.showBankBags and ICT:sum(player.bankBagsTotal, ICT:returnX(1), function(v) return v.total > 0 end) or 0)
    end
    self.paddings.bags = options.player.showBags and ICT:max(db.players,  bagCount, Player.isEnabled) or 0
    self.paddings.professions = ICT:max(db.players, function(player) return ICT:size(player.professions) end, Player.isEnabled)
    self.paddings.cooldowns = options.player.showCooldowns
        and ICT:max(db.players, function(player) return ICT:sum(player.cooldowns, ICT:returnX(1), ICT.Cooldown.isVisible) end, Player.isEnabled)
        or 0
    self.paddings.specs = ICT.WOTLK <= Expansion.value and 2 or 1
    self.paddings.quests = ICT:max(db.players, function(player) return ICT:sum(ICT.Quests, ICT:returnX(1), player:isQuestVisible()) end, Player.isEnabled)
    self.paddings.worldBuffs = ICT:max(db.players, function(player) return ICT:size(player.worldBuffs) + ICT:size(player.consumes) end, Player.isEnabled)
end

function MainTab:getPadding(y, name)
    return y + (true and self.paddings[name] or 0)
end

function MainTab:calculateGold()
    self.realmGold = {}
    for _, player in pairs(ICT.db.players) do
        self.realmGold[player.realm] = (self.realmGold[player.realm] or 0) + (player.money or 0)
    end
end

-- Same as canQueue for now, but may be different if I support retail ever or if a season adds specs.
local function canSpecSwap(player)
    return player:isCurrentPlayer() and Expansion.isWOTLK()
end

function MainTab:printCharacterInfo(player, x, y)
    local cell = self.cells(x, y)
    y = cell:printSectionTitle(L["Info"])
    local options = ICT.db.options
    if not self.cells:isSectionExpanded(L["Info"]) then
        return y
    end
    self.cells:startSection(1)
    local padding = self:getPadding(y, "info")
    y = self.cells(x, y):printOptionalValue(options.player.showLevel, L["Level"], player.level)
    y = self.cells(x, y):printOptionalValue(options.player.showGuild, L["Guild"], player.guild)
    y = self.cells(x, y):printOptionalValue(options.player.showGuildRank, L["Guild Rank"], player.guildRank)
    cell = self.cells(x, y)
    y = cell:printOptionalValue(options.player.showMoney, L["Gold"], GetCoinTextureString(player.money or 0))
    Tooltips:goldTooltip(player, self.realmGold[player.realm]):attach(cell)
    local durabilityColor = player.durability and Colors:gradient("FF00FF00", "FFFF0000", player.durability / 100) or "FF00FF00"
    y = self.cells(x, y):printOptionalValue(options.player.showDurability, L["Durability"], player.durability and string.format("%.0f%%", player.durability), nil, durabilityColor)
    y = self.cells:hideRows(x, y, padding)
    local spec = player:getSpec()
    local tooltip = Tooltips:specTooltip(spec)
    y = UI:printGearScore(self, spec, tooltip, x, y)

    padding = self:getPadding(y, "rested")
    if not player:isMaxLevel() then
        local currentXP = player.currentXP or 0
        local maxXP = player.maxXP or 1
        local xpPercentage = currentXP / maxXP * 100
        y = self.cells(x, y):printOptionalValue(options.player.showXP, L["XP"], string.format("%s/%s (%.0f%%)", currentXP, maxXP, xpPercentage))
        local restedPercentage = player:getRestedXP()
        local bubbles = restedPercentage * 20
        y = self.cells(x, y):printOptionalValue(options.player.showRestedXP, L["Rested XP"], string.format("%.1f %s (%.0f%%)", bubbles, L["Bubbles"], restedPercentage * 100))
        local resting = player.resting and L["Resting"] or L["Not Resting"]
        y = self.cells(x, y):printOptionalValue(options.player.showRestedState, L["Resting State"], resting)
    end
    y = self.cells:hideRows(x, y, padding)

    if options.player.showWorldBuffs then
        y = self.cells(x, y):hide()
        cell = self.cells(x, y)
        y = cell:printSectionTitle(L["World Buffs"])
        if self.cells:isSectionExpanded(L["World Buffs"]) then
            padding = self:getPadding(y, "worldBuffs")
            self.cells:startSection(2)
            for id, buff in ICT:nspairs(player.worldBuffs or {}) do
                cell = self.cells(x, y)
                local name, _, icon = GetSpellInfo(id)
                local title = buff.booned
                    and string.format("|T%s:12|t|T%s:12|t%s", 133881, icon, name)
                    or string.format("|T%s:12|t%s", icon, name)
                y = (not player:isCurrentPlayer() or buff.booned)
                    and cell:printValue(title, ICT:displayTime(buff.duration))
                    or cell:printBuffTicker(title, buff.expires, buff.duration)
            end

            for id, _ in ICT:nspairs(player.consumes or {}) do
                -- I think I have to lock this variable so it doesn't change when on item load is called.
                local cell = self.cells(x, y)
                local item = Item:CreateFromItemID(id)
                y = y + 1
                item:ContinueOnItemLoad(function()
                    local title = string.format("|T%s:12|t%s", item:GetItemIcon(), item:GetItemName())
                    cell:printValue(title)
                end)
            end
            y = self.cells:endSection(x, y, padding)
        end
    end

    if options.player.showBags then
        y = self.cells(x, y):hide()
        tooltip = Tooltips:bagTooltip(player)
        cell = self.cells(x, y)
        y = cell:printSectionTitle(L["Bags"])
        tooltip:attach(cell)

        if self.cells:isSectionExpanded(L["Bags"]) then
            padding = self:getPadding(y, "bags")
            self.cells:startSection(2)
            local bags = player.bagsTotal or {}
            for k, bag in ICT:nspairs(bags, function(k, v) return v.total > 0 end) do
                cell = self.cells(x, y)
                y = cell:printValue(string.format("|T%s:12|t%s", ICT.BagFamily[k].icon, ICT.BagFamily[k].name), string.format("%s/%s", bag.free, bag.total))
                tooltip:attach(cell)
            end

            local bankBags = player.bankBagsTotal or {}
            if options.player.showBankBags and ICT:sum(bankBags, function(v) return v.total end) > 0 then
                for k, bag in ICT:nspairs(bankBags, function(k, v) return v.total > 0 end) do
                    cell = self.cells(x, y)
                    y = cell:printValue(string.format("|T%s:12|t[Bank] %s", ICT.BagFamily[k].icon, ICT.BagFamily[k].name), string.format("%s/%s", bag.free, bag.total))
                    tooltip:attach(cell)
                end
            end
            y = self.cells:endSection(x, y, padding)
        end
    end

    if options.player.showSpecs then
        y = self.cells(x, y):hide()
        cell = self.cells(x, y)
        y = cell:printSectionTitle(L["Specs"])

        if self.cells:isSectionExpanded("Specs") then
            padding = self:getPadding(y, "specs")
            self.cells:startSection(2)
            for _, spec in pairs(player:getSpecs()) do
                if Talents:isValidSpec(spec) then
                    local specColor = Colors:getSelectedColor(spec.id == player.activeSpec)
                    cell = self.cells(x, y)
                    local icon = spec.icon and CreateSimpleTextureMarkup(spec.icon, UI.iconSize, UI.iconSize) or ""
                    local name = icon .. (spec.name or "")
                    y = cell:printValue(name, string.format("%s/%s/%s", spec.tab1 or 0, spec.tab2 or 0, spec.tab3 or 0), specColor)
                    local f = function(tooltip)
                        tooltip:printTitle(L["Spec"])
                        :printValue(L["Click"], L["Spec Click"])
                        :printValue(L["Shift Click"], L["Spec Shift Click"])
                    end
                    ICT.Tooltip:new(f):attach(cell)
                    if canSpecSwap(player) then
                        cell:attachClick(Talents:activateSpec(spec.id), Talents:viewSpec(spec.id))
                    end
                end
            end
            y = self.cells:endSection(x, y, padding)
        end
    end

    -- This should be already indexed primary over secondary professions.
    if options.player.showProfessions then
        y = self.cells(x, y):hide()
        cell = self.cells(x, y)
        y = cell:printSectionTitle(L["Professions"])

        if self.cells:isSectionExpanded(L["Professions"]) then
            padding = self:getPadding(y, "professions")
            self.cells:startSection(2)
            for _, v in pairs(player.professions or {}) do
                -- We should have already filtered out those without icons but safety check here.
                local nameWithIcon = v.icon and string.format("|T%s:%s|t%s", v.icon, UI.iconSize, v.name) or v.name
                cell = self.cells(x, y)
                y = cell:printValue(nameWithIcon, string.format("%s/%s", v.rank, v.max))
                if v.spellId and player:isCurrentPlayer() then
                    cell:attachClick(function() CastSpellByID(v.spellId) end)
                end
            end
            y = self.cells:endSection(x, y, padding)
        end
    end

    if ICT.db.options.player.showCooldowns
    and ICT:containsAnyValue(ICT.db.options.displayCooldowns)
    and self.paddings.cooldowns > 0 then
        y = self.cells(x, y):hide()
        cell = self.cells(x, y)
        y = cell:printSectionTitle(L["Cooldowns"])

        if self.cells:isSectionExpanded(L["Cooldowns"]) then
            padding = self:getPadding(y, "cooldowns")
            self.cells:startSection(2)
            for _, v in ICT:nspairsByValue(player.cooldowns, ICT.Cooldown.isVisible) do
                cell = self.cells(x, y)
                y = cell:printTicker(v:getNameWithIcon(), v.expires, v.duration)
                if player:isCurrentPlayer() then
                    if v:getSpell() then
                        cell:attachClick(function() v:cast(player) end)
                    elseif v:getItem() then
                        cell:attachSecureClick(v:getItem())
                    end
                end
            end
            y = self.cells:endSection(x, y, padding)
        end
    end
    return self.cells:endSection(x, y)
end

local function canQueue(player)
    return player:isCurrentPlayer() and Expansion.isWOTLK()
end

-- Prints all the instances with associated tooltips.
function MainTab:printInstances(player, title, subTitle, size, instances, x, y)
    if size == 0 then
        return y
    end

    local cell = self.cells(x, y)
    local key = title .. subTitle
    y = cell:printSectionTitle(subTitle, key)
    Tooltips:instanceSectionTooltip():attach(cell)

    -- If the section is collapsible then short circuit here.
    self.cells:startSection(2)
    if self.cells:isSectionExpanded(key) then
        for _, instance in ICT:nspairsByValue(instances) do
            if instance:isVisible() then
                local color = Colors:getSelectedColor(instance.locked)
                cell = self.cells(x, y)
                y = cell:printLine(instance:getName(), color)
                Tooltips:instanceTooltip(instance):attach(cell)
                -- Only enable LFD for not locked dungeons on the current player.
                if canQueue(player) and not instance.locked and instance:isDungeon() then
                    cell:printLFDInstance(instance)
                    cell:attachClick(LFD:selectInstance(cell, instance), LFD:specificDropdown(cell, instance))
                end
            end
        end
    end
    return self.cells:endSection(x, y, y + 1)
end

function MainTab:printAllInstances(player, x, y)
    local subSections =  { { name = L["Dungeons"], instances = Player.getDungeons }, { name = L["Raids"], instances = Player.getRaids },  }

    if canQueue(player) then
        local cell = self.cells(x, y)
        y = cell:printLFDType(LFDQueueFrame.type)
        cell:attachClick(LFD:queue(cell), LFD:randomDropdown(cell))
    else
        y = self.cells(x, y):hide()
    end

    for expansion, name in ICT:rspairs(ICT.Expansions) do
        local sizes = {}
        for k, v in ipairs(subSections) do
            sizes[k] = ICT:size(v.instances(player, expansion), ICT.Instance.isVisible)
        end
        if ICT:sum(sizes) > 0 then
            local cell = self.cells(x, y)
            y = cell:printSectionTitle(name)

            if self.cells:isSectionExpanded(name) then
                self.cells:startSection(1)
                for k, v in ipairs(subSections) do
                    y = self:printInstances(player, expansion, v.name, sizes[k], v.instances(player, expansion), x, y)
                end
                -- No need to pad here as loop takes care of it.
                y = self.cells:endSection(x, y)
            else
                y = self.cells(x, y):hide()
            end
        end
    end
    return y
end

-- Prints currency single line information.
function MainTab:printCurrencyShort(player, currency, x, y)
    local current = player:totalCurrency(currency)
    local available = player:availableCurrency(currency)
    local value = available and string.format("%s (%s)", current, available) or current
    local cell = self.cells(x, y)
    y = cell:printValue(currency:getNameWithIcon(), value)
    Tooltips:currencyTooltip(player, currency):attach(cell)
    return y
end

function MainTab:printCurrency(player, x, y)
    if ICT:containsAnyValue(ICT.db.options.currency) then
        local cell = self.cells(x, y)
        y = cell:printSectionTitle(L["Currency"])
        Tooltips:currencySectionTooltip():attach(cell)
        if self.cells:isSectionExpanded(L["Currency"]) then
            self.cells:startSection(1)
            for _, currency in ipairs(ICT.Currencies) do
                if currency:isVisible() then
                    y = self:printCurrencyShort(player, currency, x, y)
                end
            end
            y = self.cells:endSection(x, y)
        end
    end
    return self.cells(x, y):hide()
end

function MainTab:printQuests(player, x, y)
    if ICT.db.options.quests.show and ICT:size(ICT.Quests, player:isQuestVisible()) > 0 then
        local cell = self.cells(x, y)
        y = cell:printSectionTitle(L["Quests"])
        Tooltips:questSectionTooltip():attach(cell)
        if self.cells:isSectionExpanded(L["Quests"]) then
            self.cells:startSection(1)
            local padding = self:getPadding(y, "quests")
            for _, quest in ICT:spairsByValue(ICT.Quests, ICT.QuestSort(player), player:isQuestVisible()) do
                local color = Colors:getQuestColor(player, quest)
                local name = quest.name(player)
                cell = self.cells(x, y)
                y = cell:printLine(name, color)
                Tooltips:questTooltip(name, quest):attach(cell)
            end
            y = self.cells:endSection(x, y, padding)
        end
        y = self.cells(x, y):hide()
    end
    return y
end

function MainTab:printResetTimers(x, y)
    if not ICT.db.options.multiPlayerView then
        local cell = self.cells(x, y)
        y = cell:printSectionTitle(L["Reset"])
        Tooltips:timerSectionTooltip(ICT.Resets):attach(cell)
        self.cells:startSection(1)
        if self.cells:isSectionExpanded(L["Reset"]) then
            for _, v in ICT:nspairsByValue(ICT.Resets, Reset.isVisibleAndActive) do
                y = self.cells(x, y):printTicker(v:getName(), v:expires(), v:duration())
            end
        end
        y = self.cells:endSection(x, y, y + 1)
    end
    return y
end

function MainTab:printPlayer(player, x)
    local y = 1
    y = self.cells(x, y):printPlayerTitle(player)
    if ICT:sumNonNil(ICT.db.options.player) > 0 then
        y = self:printCharacterInfo(player, x, y)
    end
    y = self:printResetTimers(x, y)
    y = self:printAllInstances(player, x, y)
    y = self:printQuests(player, x, y)
    y = self:printCurrency(player, x, y)
    return y
end

function MainTab:prePrint()
    self:hideTickers()
    self:calculatePadding()
    self:calculateGold()
end

local tickerSpacing = function(fontSize)
    -- Adjust spacing to fit enough apart but within the minimum size.
    -- This could probably be derived from the cell width (i.e. minimum), but it works
    return 55 + (fontSize - 10) * 5
end

function MainTab:postPrint()
    local selected = ICT.frame:getSelectedTab() == self.button:GetID()
    if selected and ICT.db.options.multiPlayerView then
        local count = ICT:sum(ICT.Resets, function(v) return v:isVisibleAndActive() and 1 or 0 end)
        local tooltip = Tooltips:timerSectionTooltip(ICT.Resets)
        local fontSize = math.min(16, UI:getFontSize())

        local start = -tickerSpacing(fontSize) * (count - 1) / 2
        local frame = nil
        for _, v in ICT:nspairsByValue(ICT.Resets, Reset.isVisibleAndActive) do
            start, frame = self:printMultiViewResetTicker(start, fontSize, v:getName(), v:expires(), v:duration())
            tooltip:attachFrame(frame)
        end
    end
end

function MainTab:printMultiViewResetTicker(x, fontSize, title, expires, duration)
    local frame = self.tickers[title] and self.tickers[title].frame
    if not frame then
        frame = CreateFrame("Button", "ICTReset" .. title, ICT.frame)
        frame:SetAlpha(1)
        frame:SetIgnoreParentAlpha(true)
        frame.textField = frame:CreateFontString()
        frame.textField:SetPoint("CENTER")
        frame.textField:SetJustifyH("LEFT")
    end
    frame:SetSize(UI:getCellWidth(fontSize), UI:getCellHeight(fontSize))
    frame.textField:SetFont(UI.font, fontSize)
    frame:SetPoint("TOP", x, -36)
    frame:Show()
    local update = function(self)
        ICT:cancelTicker(self)
        local time, _ = ICT:countdown(expires, duration)
        frame.textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", Colors.subtitle, title, Colors.text, time))
    end
    self.tickers[title] = { ticker = C_Timer.NewTicker(1, update), frame = frame }
    update()
    return x + tickerSpacing(fontSize), frame
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