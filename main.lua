local addOnName, ICT = ...

local Instances = ICT.Instances
local Player = ICT.Player
local Options = ICT.Options
local Tooltips = ICT.Tooltips
local Cells = ICT.Cells
local UI = ICT.UI

-- Values that change
local paddings = {}

local function enableMoving(frame, callback)
    frame:SetMovable(true)
    frame:SetResizable(true)
	frame:SetScript("OnMouseDown", frame.StartMoving)
	frame:SetScript("OnMouseUp", function(self)
        ICT.db.X = ICT.frame:GetLeft()
        ICT.db.Y = ICT.frame:GetTop()
        frame:StopMovingOrSizing(self)
    end)
end

function ICT:CreateFrame()
    local frame = CreateFrame("Frame", "ICTFrame", UIParent, "BasicFrameTemplateWithInset")
    ICT.frame = frame

    frame:SetFrameStrata("HIGH")
    UI:drawFrame(ICT.db.X, ICT.db.Y, ICT.db.width, ICT.db.height)
    enableMoving(frame)
    frame:SetAlpha(.5)
    frame:Hide()
    ICT.frame.CloseButton:SetAlpha(1)
    ICT.frame.CloseButton:SetIgnoreParentAlpha(true)

    UI:resizeFrameButton()
    UI:resetFrameButton()
    ICT.selectedPlayer = Player.GetCurrentPlayer()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(addOnName)
    title:SetAlpha(1)
    title:SetIgnoreParentAlpha(true)
    title:SetPoint("TOP", -10, -6)

    local inset = CreateFrame("Frame", "ICTInset", frame)
    inset:SetAllPoints(frame)
    inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -60)
    inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 35)
    inset:SetAlpha(1)
    inset:SetIgnoreParentAlpha(true)

    local vScrollBar = CreateFrame("EventFrame", nil, inset, "WowTrimScrollBar")
    vScrollBar:SetPoint("TOPLEFT", inset, "TOPRIGHT")
    vScrollBar:SetPoint("BOTTOMLEFT", inset, "BOTTOMRIGHT")

    local hScrollBar = CreateFrame("EventFrame", nil, inset, "WowTrimHorizontalScrollBar")
    hScrollBar:SetPoint("TOPLEFT", inset, "BOTTOMLEFT")
    hScrollBar:SetPoint("TOPRIGHT", inset, "BOTTOMRIGHT")

    local vScrollBox = CreateFrame("Frame", nil, inset, "WowScrollBox")
    ICT.vScrollBox = vScrollBox
    vScrollBox:SetAllPoints(inset)

    local hScrollBox = CreateFrame("Frame", nil, vScrollBox, "WowScrollBox")
    ICT.hScrollBox = hScrollBox
    hScrollBox:SetScript("OnMouseWheel", nil)
    hScrollBox.scrollable = true

    ICT.content = CreateFrame("Frame", nil, hScrollBox, "ResizeLayoutFrame")
    ICT.content.scrollable = true
    ICT.content.cells = {}

    local hView = CreateScrollBoxLinearView()
    hView:SetPanExtent(50)
    hView:SetHorizontal(true)

    local vView = CreateScrollBoxLinearView()
    vView:SetPanExtent(50)

    ScrollUtil.InitScrollBoxWithScrollBar(hScrollBox, hScrollBar, hView)
    ScrollUtil.InitScrollBoxWithScrollBar(vScrollBox, vScrollBar, vView)

    Options.CreatePlayerDropdown()
    Options.CreateOptionDropdown()
    ICT:CreatePlayerSlider()
end

local function calculatePadding()
    local db = ICT.db
    local options = db.options
    paddings.info = ICT:sumNonNil(options.player.showLevel, options.player.showGuild, options.player.showGuildRank, options.player.showMoney, options.player.showDurability)
    -- If there is a viewable player under 80 then pad for XP info.
    paddings.rested = ICT:containsAnyValue(db.players, function(player) return player.level < ICT.MaxLevel and player:isEnabled() end)
        and ICT:sumNonNil(options.player.showXP, options.player.showRestedXP, options.player.showRestState)
        or 0
    paddings.bags = options.player.showBags
        and ICT:max(db.players, function(player) return ICT:sum(player.bagsTotal or {}, ICT:ReturnX(1), function(v) return v.total > 0 end) end, Player.isEnabled)
        or 0
    paddings.bankBags = options.player.showBags and options.player.showBankBags
        and ICT:max(db.players, function(player) return ICT:sum(player.bankBagsTotal or {}, ICT:ReturnX(1), function(v) return v.total > 0 end) end, Player.isEnabled)
        or 0
    paddings.professions = ICT:max(db.players, function(player) return ICT:size(player.professions) end, Player.isEnabled)
    paddings.cooldowns = ICT:max(db.players, function(player) return ICT:sum(player.cooldowns or {}, ICT:ReturnX(1), Options.showCooldown) end, Player.isEnabled)
    paddings.specs = TT_GS and 6 or 2
    paddings.quests = ICT:max(db.players, function(player) return ICT:sum(ICT.QuestInfo, ICT:ReturnX(1), player:isQuestAvailable()) end, Player.isEnabled)
end

local function getPadding(offset, padding)
    return offset + (true and padding or 0)
end

local realmGold = {}
local function calculateGold()
    realmGold = {}
    for _, player in pairs(ICT.db.players) do
        realmGold[player.realm] = (realmGold[player.realm] or 0) + (player.money or 0)
    end
end

local function goldTooltip(player)
    local tooltip = Tooltips:new("Realm Gold")
    tooltip:printValue(string.format("[%s]", player.realm), GetCoinTextureString(realmGold[player.realm]))

    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, function(p) return player.realm == p.realm end) do
        tooltip:printValue(player:getName(), GetCoinTextureString(player.money or 0), player:getClassColor())
    end
    return tooltip:create("ICTGoldTip" .. player.fullName)
end

local function bagTooltip(player)
    local tooltip = Tooltips:new("Bag Space")
    tooltip:printValue("Bag", "Free / Total")

    local printBags = function(bags, title)
        for _, v in ICT:spairs(bags or {}) do
            tooltip:printTitle(title)
            local name = string.format("|T%s:14|t%s", v.icon or "", v.name)
            tooltip:printValue(name, string.format("%s/%s", v.free, v.total))
        end
    end

    printBags(player.bags, "Personal Bags")

    tooltip.shouldPrintTitle = true
    if ICT.db.options.player.showBankBags then
        tooltip.shouldPrintTitle = true
        printBags(player.bankBags, "Bank Bags")

        tooltip:printPlain("\nNote: Bank bags require opening and closing the bank for each character.")
    end
    return tooltip:create("ICTBagTooltip" .. player.fullName)
end

local deleteButtons = {}
local function deletePlayerButton(player, cell)
    local button = deleteButtons[player.fullName] or CreateFrame("Button", "ICTDelete" .. player.fullName, cell.frame, "UIPanelButtonTemplate")
    deleteButtons[player.fullName] = button
    button:SetParent(cell.frame)
    button:SetSize(12, 12)
    button:SetPoint("RIGHT", cell.frame, "RIGHT")
    button:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
    button:SetScript("OnClick", UI:openDeleteFrame(player))
    button:Show()
end

local function specsSectionTooltip()
    return Tooltips:new("Specs")
    :printPlain("Displays specs, glyphs. If TacoTip is available, displays gearscore and iLvl as well.")
    :printPlain("\nNote: Gearscore and iLvl are the last equipped gear for a specific spec.")
    :printPlain("i.e. change spec before changing gear to have the most accurate data.")
    :create("ICTSpecsSectionTooltip")
end

local function addGems(k, item)
    local gemTotal = 0
    local text = ""
    for _, gem in pairs(item.gems) do
        text = text .. string.format("|T%s:14|t", gem)
        gemTotal = gemTotal + 1
    end
    -- Add '?' if you are missing ids.
    for _=gemTotal + 1,item.socketTotals do
        text = text .. "|T134400:14|t"
    end
    if gemTotal < item.socketTotals and item.extraSocket then
        text = text .. string.format("|T%s:14|t", ICT.CheckSlotSocket[k].icon)
    end
    return text
end

local function specTooltip(player, specId, spec)
    local tooltip = Tooltips:new(spec.name .. " Gear")
    tooltip:printLine("Item: iLvL Gems or ? if missing gem")
    tooltip:printLine("Glyph: Slot")
    tooltip:printLine("Item Slot: Enchant")

    tooltip.shouldPrintTitle = true
    for k, item in pairs(spec.items or {}) do
        tooltip:printTitle("Items")
        local text = item.level .. " " .. addGems(k, item)
        -- This may have to be relocalized, but that's true for some other info (e.g. bags), so just use the link.
        local color = ICT:getItemScoreHex(item.link)
        tooltip:printValue(string.format("|T%s:14|t%s", item.icon, item.link), text, nil, color)
    end

    local printGlyph = function(type, typeName)
        for index, glyph in ICT:fpairsByValue(spec.glyphs or {}, function(v) return v.type == type end) do
            if glyph.enabled then
                tooltip:printTitle(typeName)
                local name = glyph.spellId and string.format("|T%s:14|t%s", glyph.icon, select(1, GetSpellInfo(glyph.spellId))) or "Missing"
                tooltip:printValue(name, index)
            end
        end
    end

    tooltip.shouldPrintTitle = true
    printGlyph(1, "Major")
    tooltip.shouldPrintTitle = true
    printGlyph(2, "Minor")

    tooltip.shouldPrintTitle = true
    for _, item in ICT:fpairsByValue(spec.items or {}, function(v) return v.shouldEnchant end) do
        tooltip:printTitle("Enchants")
        local enchant = item.enchantId and ICT.Enchants[item.enchantId] or "Missing"
        tooltip:printValue(_G[item.invType], enchant)
    end

    tooltip:printPlain("\nNote: Socket icons will appear if you are missing ")
    :printPlain("an item that can have an extra slot, such as your belt.")
    :printPlain("\nAlso, enchants aren't localized.")
    return tooltip:create("ICTSpec" .. specId .. player.fullName)
end

local function printGearScore(spec, tooltip, x, offset)
    if TT_GS and ICT.db.options.player.showGearScores then
        local scoreColor = spec.gearScore and ICT:rgbPercentage2hex(TT_GS:GetQuality(spec.gearScore)) or nil
        local cell = Cells:get(x, offset)
        offset = cell:get(x, offset):printValue("GearScore", spec.gearScore, nil, scoreColor)
        tooltip:attach(cell)
        cell = Cells:get(x, offset)
        offset = cell:printValue("iLvl", spec.ilvlScore, nil, scoreColor)
        tooltip:attach(cell)
    end
    return offset
end

local function printCharacterInfo(player, x, offset)
    local specs = player.specs or {}
    local playerTitle = string.format("|c%s%s|r", player:getClassColor(), player:getNameWithIcon())
    local cell = Cells:get(x, offset)
    deletePlayerButton(player, cell)
    offset = cell:printSectionTitle(playerTitle, "Info")
    local options = ICT.db.options
    Cells.indent = "  "
    if ICT.db.options.collapsible["Info"] then
        Cells.indent = ""
        return Cells:get(x, offset):hide()
    end
    local padding = getPadding(offset, paddings.info)
    offset = Cells:get(x, offset):printOptionalValue(options.player.showLevel, "Level", player.level)
    offset = Cells:get(x, offset):printOptionalValue(options.player.showGuild, "Guild", player.guild)
    offset = Cells:get(x, offset):printOptionalValue(options.player.showGuildRank, "Guild Rank", player.guildRank)
    cell = Cells:get(x, offset)
    offset = cell:printOptionalValue(options.player.showMoney, "Gold", GetCoinTextureString(player.money or 0))
    goldTooltip(player):attach(cell)
    if not options.player.showSpecs then
        local spec = specs[player.activeSpec]
        if spec then
            local tooltip = specTooltip(player, player.activeSpec, spec)
            offset = printGearScore(spec, tooltip, x, offset)
        end
    end
    local durabilityColor = player.durability and ICT:gradient("FF00FF00", "FFFF0000", player.durability / 100) or "FF00FF00"
    offset = Cells:get(x, offset):printOptionalValue(options.player.showDurability, "Durability", player.durability and string.format("%.0f%%", player.durability), nil, durabilityColor)
    offset = UI:hideRows(x, offset, padding)

    padding = getPadding(offset, paddings.rested)
    if player.level < ICT.MaxLevel then
        local currentXP = player.currentXP or 0
        local maxXP = player.maxXP or 1
        local xpPercentage = currentXP / maxXP * 100 
        offset = Cells:get(x, offset):printOptionalValue(options.player.showXP, "XP", string.format("%s/%s (%.0f%%)", currentXP, maxXP, xpPercentage))
        local restedPercentage = player:getRestedXP()
        local bubbles = restedPercentage * 20
        offset = Cells:get(x, offset):printOptionalValue(options.player.showRestedXP, "Rested XP", string.format("%s bubbles (%.0f%%)", bubbles, restedPercentage * 100))
        local resting = player.resting and "Resting" or "Not Resting"
        offset = Cells:get(x, offset):printOptionalValue(options.player.showRestedState, "Resting State", resting)
    end
    offset = UI:hideRows(x, offset, padding)

    local bags = player.bagsTotal or {}
    if options.player.showBags then
        offset = Cells:get(x, offset):hide()
        local tooltip = bagTooltip(player)
        cell = Cells:get(x, offset)
        offset = cell:printSectionTitle("Bags")
        tooltip:attach(cell)

        if not ICT.db.options.collapsible["Bags"] then
            padding = getPadding(offset, paddings.bags)
            for k, bag in ICT:spairs(bags, ICT.NaturalSort, function(k) return bags[k].total > 0 end) do
                cell = Cells:get(x, offset)
                offset = cell:printValue(string.format("|T%s:12|t%s", ICT.BagFamily[k].icon, ICT.BagFamily[k].name), string.format("%s/%s", bag.free, bag.total))
                tooltip:attach(cell)
            end
            offset = UI:hideRows(x, offset, padding)

            local bankBags = player.bankBagsTotal or {}
            padding = getPadding(offset, paddings.bankBags)
            if options.player.showBankBags and ICT:sum(bankBags, function(v) return v.total end) > 0 then
                for k, bag in ICT:spairs(bankBags, ICT.NaturalSort, function(k) return bankBags[k].total > 0 end) do
                    cell = Cells:get(x, offset)
                    offset = cell:printValue(string.format("|T%s:12|t[Bank] %s", ICT.BagFamily[k].icon, ICT.BagFamily[k].name), string.format("%s/%s", bag.free, bag.total))
                    tooltip:attach(cell)
                end
            end
            offset = UI:hideRows(x, offset, padding)
        end
    end

    if options.player.showSpecs then
        offset = Cells:get(x, offset):hide()
        cell = Cells:get(x, offset)
        offset = cell:printSectionTitle("Specs")
        specsSectionTooltip():attach(cell)

        if not ICT.db.options.collapsible["Specs"] then
            padding = getPadding(offset, paddings.specs)
            for k, spec in pairs(specs) do
                if not(spec.tab1 == 0 and spec.tab2 == 0 and spec.tab3 == 0) then
                    local specColor = UI:getSelectedColor(k == player.activeSpec)
                    local tooltip = specTooltip(player, k, spec)
                    cell = Cells:get(x, offset)
                    offset = cell:printValue(spec.name or "", string.format("%s/%s/%s", spec.tab1, spec.tab2, spec.tab3), specColor)
                    tooltip:attach(cell)

                    offset = printGearScore(spec, tooltip, x, offset)
                end
            end
            offset = UI:hideRows(x, offset, padding)
        end
    end

    -- This should be already indexed primary over secondary professions.
    if options.player.showProfessions then
        offset = Cells:get(x, offset):hide()
        offset = Cells:get(x, offset):printSectionTitle("Professions")

        if not ICT.db.options.collapsible["Professions"] then
            padding = getPadding(offset, paddings.professions)
            for _, v in pairs(player.professions or {}) do
                -- We should have already filtered out those without icons but safety check here.
                local nameWithIcon = v.icon and string.format("|T%s:14|t%s", v.icon, v.name) or v.name
                cell = Cells:get(x, offset)
                offset = cell:printValue(nameWithIcon, string.format("%s/%s", v.rank, v.max))
                if v.spellId and player:isCurrentPlayer() then
                    cell:clickable(function() CastSpellByID(v.spellId) end)
                end
            end
            offset = UI:hideRows(x, offset, padding)
        end
    end

    if ICT:containsAnyValue(ICT.db.options.displayCooldowns) then
        offset = Cells:get(x, offset):hide()
        offset = Cells:get(x, offset):printSectionTitle("Cooldowns")

        if not ICT.db.options.collapsible["Cooldowns"] then
            padding = getPadding(offset, paddings.cooldowns)
            for _, v in ICT:spairsByValue(player.cooldowns or {}, ICT.CooldownSort, Options.showCooldown) do
                cell = Cells:get(x, offset)
                local name = string.format("|T%s:14|t%s", v.icon, v.name)
                offset = cell:printTicker(name, v.expires, v.duration)
                if player:isCurrentPlayer() then
                    cell:clickable(function() v:cast(player) end)
                end
            end
            offset = UI:hideRows(x, offset, padding)
        end
    end
    offset = Cells:get(x, offset):hide()
    Cells.indent = ""
    return offset
end

-- Tooltip for instance information upon entering the cell.
local function instanceTooltip(player, instance)
    local tooltip = Tooltips:new(instance.name)

    -- Display the available encounters for the instance.
    tooltip:printValue("Encounters", string.format("%s/%s", instance:encountersLeft(), instance:numOfEncounters()))
    for k, v in pairs(instance:encounters()) do
        local encounterColor = UI:getSelectedColor(instance:isEncounterKilled(k))
        tooltip:printLine(v, encounterColor)
    end

    -- Display which players are locked or not for this instance.
    -- You have to get at least one player to display a tooltip, so always print title.
    tooltip.shouldPrintTitle = true
    tooltip:printTitle("Locks")
    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.isEnabled) do
        local playerInstance = player:getInstance(instance.id, instance.size) or { locked = false }
        local playerColor = UI:getSelectedColor(playerInstance.locked)
        tooltip:printLine(player:getNameWithIcon(), playerColor)
    end

    -- Display all available currency for the instance.
    tooltip.shouldPrintTitle = true
    for tokenId, _ in ICT:spairs(instance:tokenIds(), ICT.CurrencySort) do
        -- Onyxia 40 is reused and has 0 emblems so skip currency.
        local max = instance:maxEmblems(tokenId)
        if ICT.db.options.currency[tokenId] and max ~= 0 then
            tooltip:printTitle("Currency")
            local available = instance.available[tokenId] or max
            tooltip:printValue(ICT:GetCurrencyWithIconTooltip(tokenId), string.format("%s/%s", available, max))
        end
    end
    -- This player is the original player which owns the cell.
    return tooltip:create("ICTInstanceTooltip" .. instance.id .. instance.size .. player.fullName)
end

local function instanceSectionTooltip()
    return Tooltips:new("Instance Format")
    :printLine("Available", ICT.availableColor)
    :printLine("Locked", ICT.lockedColor)
    :printValue("\nEncounters", "Available / Total")
    :printPlain("Shows the available boss fights for the current lock out,")
    :printPlain("out of the total for any given lockout.")
    :printValue("\nCurrency", "Available / Total")
    :printPlain("Shows the available currency for the current lock out,")
    :printPlain("out of the total for any given lockout.")
    :create("ICTInstanceTooltip")
end

-- Prints all the instances with associated tooltips.
local function printInstances(player, title, size, instances, x, offset)
    if size == 0 then
        return offset
    end

    local cell = Cells:get(x, offset)
    offset = cell:printSectionTitle(title)
    instanceSectionTooltip():attach(cell)

    -- If the section is collapsible then short circuit here.
    if not ICT.db.options.collapsible[title] then
        for _, instance in instances do
            if instance:isVisible() then
                local color = UI:getSelectedColor(instance.locked)
                cell = Cells:get(x, offset)
                offset = cell:printLine(instance.name, color)
                instanceTooltip(player, instance):attach(cell)
            end
        end
    end
    return Cells:get(x, offset):hide()
end

local function printAllInstances(player, x, offset)
    local foo = {
        { name = ICT.WOTLK, subs = { {name = "Dungeons", filter = Instances.isDungeon }, {name = "Raids", filter = Instances.isRaid },  }, } ,
        { name = ICT.TBC, subs = { {name = "Dungeons", filter = Instances.isDungeon }, {name = "Raids", filter = Instances.isRaid },  },  },
        { name = ICT.VANILLA, subs = { {name = "Dungeons", filter = Instances.isDungeon }, {name = "Raids", filter = Instances.isRaid, },  }, },
    }
    for _, v in ipairs(foo) do
        local expansion = ICT.Expansions[v.name]
        local sizes = {}
        for k, sub in ipairs(v.subs) do
            sizes[k] = ICT:iSize(ICT:spairsByValue(player.instances, ICT.InstanceSort, sub.filter, expansion), Instances.isVisible)
        end
        local sum = ICT:sum(sizes)
        if sum > 0 then
            offset = Cells:get(x, offset):printSectionTitle(v.name)

            if not ICT.db.options.collapsible[v.name] then
                Cells.indent = "  "
                for k, sub in ipairs(v.subs) do
                    local iterator = ICT:spairsByValue(player.instances, ICT.InstanceSort, sub.filter, expansion)
                    offset = printInstances(player, sub.name, sizes[k], iterator, x, offset)
                end
                Cells.indent = ""
            else
                offset = Cells:get(x, offset):hide()
            end
        end
    end
    return offset
end

local function printInstancesForCurrency(tooltip, title, instances, tokenId)
    -- Only print the title if there exists an instance for this token.
    tooltip.shouldPrintTitle = true
    for _, instance in pairs(instances) do
        local max = instance:maxEmblems(tokenId)
        -- Onyxia 40 is reused and has 0 emblems so skip currency.
        if instance:isVisible() and instance:hasTokenId(tokenId) and max ~= 0 then
            tooltip:printTitle(title)
            -- Displays available currency out of the total currency for this instance.
            local color =  UI:getSelectedColor(instance.locked)
            local available = instance.available[tokenId] or max
            tooltip:printValue(instance.name, string.format("%s/%s", available, max), color)
        end
    end
end

local function printQuestsForCurrency(tooltip, player, tokenId)
    tooltip.shouldPrintTitle = true
    if ICT.db.options.showQuests then
        for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player)) do
            if quest.tokenId == tokenId and (player.quests.prereq[quest.key] or ICT.db.options.allQuests) then
                tooltip:printTitle("Quests")
                local color = UI:getQuestColor(player, quest)
                tooltip:printValue(quest.name(player), quest.seals, color)
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
local function currencyTooltip(selectedPlayer, tokenId)
    local tooltip = Tooltips:new(ICT:GetCurrencyWithIconTooltip(tokenId))

    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.isEnabled) do
        local available = player:availableCurrency(tokenId)
        local total = player.currency.wallet[tokenId] or 0
        tooltip:printValue(player:getNameWithIcon(), string.format("%s (%s)", total, available), player:getClassColor())
    end

    if ICT.db.options.verboseCurrencyTooltip then
        printInstancesForCurrency(tooltip, "Dungeons", selectedPlayer:getDungeons(), tokenId)
        printInstancesForCurrency(tooltip, "Raids", selectedPlayer:getRaids(), tokenId)
        printQuestsForCurrency(tooltip, selectedPlayer, tokenId)
    end
    return tooltip:create("ICTCurrencyTooltip" .. selectedPlayer.fullName .. tokenId)
end

-- Prints currency with multi line information.
local function printCurrencyVerbose(player, tokenId, x, offset)
    local cell = Cells:get(x, offset)
    offset = cell:printValue(ICT:GetCurrencyWithIcon(tokenId), nil, ICT.subtitleColor)
    local tooltip = currencyTooltip(player, tokenId)
    tooltip:attach(cell)
    local available = player:availableCurrency(tokenId)
    cell = Cells:get(x, offset)
    offset = cell:printValue("Available", available, ICT.textColor)
    tooltip:attach(cell)
    local current = player.currency.wallet[tokenId] or 0
    cell = Cells:get(x, offset)
    offset = cell:printValue("Current", current, ICT.textColor)
    tooltip:attach(cell)
    return Cells:get(x, offset):hide()
end

-- Prints currency single line information.
local function printCurrencyShort(player, tokenId, x, offset)
    local current = player.currency.wallet[tokenId] or 0
    local available = player:availableCurrency(tokenId)
    local value = string.format("%s (%s)", current, available)
    local cell = Cells:get(x, offset)
    offset = cell:printValue(ICT:GetCurrencyWithIcon(tokenId), value)
    currencyTooltip(player, tokenId):attach(cell)
    return offset
end

local function printCurrency(player, x, offset)
    if ICT:containsAnyValue(ICT.db.options.currency) then
        local cell = Cells:get(x, offset)
        offset = cell:printSectionTitle("Currency")
        currencySectionTooltip():attach(cell)
    end
    if not ICT.db.options.collapsible["Currency"] then
        local printCurrency = ICT.db.options.verboseCurrency and printCurrencyVerbose or printCurrencyShort
        for tokenId, _ in ICT:spairs(ICT.CurrencyInfo, ICT.CurrencySort) do
            if ICT.db.options.currency[tokenId] then
                offset = printCurrency(player, tokenId, x, offset)
            end
        end
    end
    return offset
end

local function questTooltip(name, quest)
    local tooltip = Tooltips:new(name)
    tooltip:printValue(ICT:GetCurrencyWithIconTooltip(quest.tokenId), quest.seals)

    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.isEnabled) do
        if ICT.db.options.allQuests or player.quests.prereq[quest.key] then
            local color = UI:getQuestColor(player, quest)
            tooltip:printLine(player:getNameWithIcon(), color)
        end
    end
    return tooltip:create("ICTQuestTooltip" .. name)
end

local function questSectionTooltip()
    return Tooltips:new("Quest Format")
    :printLine("Available", ICT.availableColor)
    :printLine("Completed", ICT.lockedColor)
    :printLine("Missing Prerequesite", ICT.unavailableColor)
    :printValue("\nCurrency", "Total")
    :printPlain("Shows the quest reward.")
    :create("ICTQuestTooltip")
end

local function printQuests(player, x, offset)
    if ICT.db.options.showQuests then
        local cell = Cells:get(x, offset)
        offset = cell:printSectionTitle("Quests")
        questSectionTooltip():attach(cell)
        if not ICT.db.options.collapsible["Quests"] then
            local padding = getPadding(offset, paddings.quests)
            for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player), player:isQuestAvailable()) do
                local color = UI:getQuestColor(player, quest)
                local name = quest.name(player)
                cell = Cells:get(x, offset)
                offset = cell:printLine(name, color)
                questTooltip(name, quest):attach(cell)
            end
            offset = UI:hideRows(x, offset, padding)
        end
        offset = Cells:get(x, offset):hide()
    end
    return offset
end

local function timerSectionTooltip()
    return Tooltips:new("Reset Timer")
    :printPlain("Countdown to the next reset respectively for 1, 3, 5 and 7 days.")
    :printPlain("\nNote: 3 and 5 day resets need a known lockout to calculate from\nas Blizzard doesn't provide a way through their API.")
    :create("ICTResetTimerTooltip")
end

local function printResetTimers(x, offset)
    local count = ICT:sum(ICT.db.options.reset, function(v) return v and 1 or 0 end)
    local tooltip = timerSectionTooltip()
    if count > 0 then
        if ICT.db.options.multiPlayerView then
            local start = 32 + -60 * count / 2
            local frame = nil
            for k, v in ICT:spairs(ICT.db.reset) do
                if ICT.db.options.reset[k] then
                    start, frame = UI:printMultiViewResetTicker(start, ICT.ResetInfo[k].name, v, k * ICT.OneDay)
                    tooltip:attachFrame(frame)
                end
            end
        else
            local cell = Cells:get(x, offset)
            offset = cell:printSectionTitle("Reset")
            tooltip:attach(cell)

            if not ICT.db.options.collapsible["Reset"] then
                for k, v in ICT:spairs(ICT.db.reset) do
                    if ICT.db.options.reset[k] then
                        offset = Cells:get(x, offset):printTicker(ICT.ResetInfo[k].name, v, k * ICT.OneDay, ICT.textColor)
                    end
                end
            end
            offset = Cells:get(x, offset):hide()
        end
    end
    return offset
end

local function getSelectedOrDefault()
    if not ICT.db.players[ICT.selectedPlayer] then
        ICT.selectedPlayer = Player.GetCurrentPlayer()
    end
    return ICT.db.players[ICT.selectedPlayer]
end

local function printPlayer(player, x)
    local offset = 1
    offset = printCharacterInfo(player, x, offset)
    offset = printResetTimers(x, offset)
    offset = printAllInstances(player, x, offset)
    offset = printQuests(player, x, offset)
    offset = printCurrency(player, x, offset)
    UI:hideRows(x, offset, UI.displayY)
    return offset
end

-- Prints out selected players with associated instances and currency infromation.
function ICT:DisplayPlayer()
    calculatePadding()
    calculateGold()
    UI:hideTickers()
    Options:FlipSlider()
    for _, v in pairs(deleteButtons) do
        v:Hide()
    end
    local offset = 0
    local x = 0
    if ICT.db.options.multiPlayerView then
        for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.isEnabled) do
            x = x + 1
            offset = math.max(printPlayer(player, x), offset)
        end
    else
        local player = getSelectedOrDefault()
        x = x + 1
        offset = printPlayer(player, x)
        ICT.DDMenu:UIDropDownMenu_SetText(ICT.frame.playerDropdown, player:getName())
    end

    UI:hideColumns(x + 1, UI.displayX, UI.displayY)
    UI:updateFrameSizes(x, offset)
    UI.displayY = offset
    UI.displayX = x
end

-- Taken from NIT
function ICT:CreatePlayerSlider()
    local name = "ICTCharacterLevel"
	local levelSlider = CreateFrame("Slider", name, ICT.frame, "OptionsSliderTemplate")
    ICT.frame.levelSlider = levelSlider
    levelSlider:SetAlpha(1)
    levelSlider:SetIgnoreParentAlpha(true)
	levelSlider:SetPoint("TOP", ICT.frame.options, "BOTTOM")
    levelSlider.tooltipText = "Minimum level alts to show?";
    levelSlider:SetWidth(120)
    levelSlider:SetHeight(12)
    levelSlider:SetMinMaxValues(1, ICT.MaxLevel)
    levelSlider:SetObeyStepOnDrag(true);
    levelSlider:SetValueStep(1)
    levelSlider:SetStepsPerPage(1)
    levelSlider:SetValue(ICT.db.options.minimumLevel or ICT.MaxLevel)
    _G[name .. "Low"]:SetText("1")
    _G[name .. "High"]:SetText(ICT.MaxLevel)
    levelSlider:HookScript("OnValueChanged", function(self, value)
        ICT.db.options.minimumLevel = value
        levelSlider.editBox:SetText(value);
        ICT:DisplayPlayer()
    end)
    levelSlider:Hide()

    local function EditBox_OnEnterPressed(frame)
        local value = frame:GetText();
        value = tonumber(value);
        if value then
            ICT.db.options.minimumLevel = value
            levelSlider.editBox:SetText(value)
            frame:ClearFocus()
        else
            levelSlider.editBox:SetText(ICT.db.options.minimumLevel)
        end
    end
    local ManualBackdrop = {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true, edgeSize = 1, tileSize = 5,
    };
    local editBox = CreateFrame("EditBox", nil, levelSlider, "BackdropTemplate");
    editBox:SetText(ICT.MaxLevel);
    levelSlider.editBox = editBox
    editBox:SetText(ICT.db.options.minimumLevel or ICT.MaxLevel)
    editBox:SetAutoFocus(false);
    editBox:SetFontObject(GameFontHighlightSmall);
    editBox:SetPoint("TOP", levelSlider, "BOTTOM");
    editBox:SetHeight(14);
    editBox:SetWidth(70);
    editBox:SetJustifyH("CENTER");
    editBox:EnableMouse(true);
    editBox:SetBackdrop(ManualBackdrop);
    editBox:SetBackdropColor(0, 0, 0, 0.5);
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8);
    editBox:SetScript("OnEnter", function(frame)
        frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1);
    end);
    editBox:SetScript("OnLeave", function(frame)
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8);
    end);
    editBox:SetScript("OnEnterPressed",EditBox_OnEnterPressed );
    editBox:SetScript("OnEscapePressed", function(frame)
        frame:ClearFocus();
    end);
end