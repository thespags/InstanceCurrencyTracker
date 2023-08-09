local addOnName, ICT = ...

local Player = ICT.Player
local Options = ICT.Options
local Instances = ICT.Instances
local Tooltips = ICT.Tooltips
local Quests = ICT.Quests
local Cells = ICT.Cells
local UI = ICT.UI
local cellWidth = 200
ICT.cellWidth = 200
local cellHeight = 10
ICT.cellHeight = 10
local defaultWidth = cellWidth + 40
local defaultHeight = 600
local defaultX = 400
local defaultY = 800

-- Values that change
local tickers = {}
local displayX = 0
local displayY = 0
local paddings = {}

local function drawFrame(x, y, width, height)
    ICT.db.X = x or defaultX
	ICT.db.Y = y or defaultY
    ICT.db.width = width or defaultWidth
    ICT.db.height = height or defaultHeight
    ICT.frame:ClearAllPoints()
    ICT.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ICT.db.X, ICT.db.Y)
    ICT.frame:SetSize(ICT.db.width, ICT.db.height)
end

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
    drawFrame(ICT.db.X, ICT.db.Y, ICT.db.width, ICT.db.height)
    enableMoving(frame)
    frame:SetAlpha(.5)
    frame:Hide()

    ICT:ResizeFrameButton()
    ICT:ResetFrameButton()
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

    ICT:CreatePlayerDropdown()
    Options:CreateOptionDropdown()
    ICT:CreatePlayerSlider()
end

local function calculatePadding()
    local db = ICT.db
    local options = db.options
    paddings.info = ICT:sumNonNil(options.player.showLevel, options.player.showGuild, options.player.showGuildRank, options.player.showMoney, options.player.showDurability)
    paddings.rested = ICT:containsAnyValue(db.players, function(player) return player.level < ICT.MaxLevel end, Player.PlayerEnabled)
        and ICT:sumNonNil(options.player.showXP, options.player.showRestedXP, options.player.showRestState) or 0
    paddings.bags = ICT:max(db.players, function(player) return ICT:sum(player.bagsTotal or {}, ICT:ReturnX(1), function(v) return v.total > 0 end) end, Player.PlayerEnabled)
    paddings.bankBags = ICT:max(db.players, function(player) return ICT:sum(player.bankBagsTotal or {}, ICT:ReturnX(1), function(v) return v.total > 0 end) end, Player.PlayerEnabled)
    paddings.professions = ICT:max(db.players, function(player) return #player.professions end, Player.PlayerEnabled)
    paddings.specs = TT_GS and 6 or 2
    paddings.quests = ICT:max(db.players, function(player) return ICT:sum(ICT.QuestInfo, ICT:ReturnX(1), Quests.IsQuestAvailable(player)) end, Player.PlayerEnabled)
end

local function getPadding(offset, padding)
    return offset + (true and padding or 0)
end

local function printCharacterInfo(player, x, offset)
    local playerTitle = string.format("|c%s%s|r", UI.getClassColor(player), Player.GetNameWithIcon(player))
    offset = Cells:get(x, offset):printSectionTitle(playerTitle, "Info")
    local options = ICT.db.options
    Cells.indent = "  "
    if ICT.db.options.collapsible["Info"] then
        Cells:get(x, offset)
        Cells.indent = ""
        return offset
    end
    local padding = getPadding(offset, paddings.info)
    offset = Cells:get(x, offset):printOptionalValue(options.player.showLevel, "Level", player.level)
    offset = Cells:get(x, offset):printOptionalValue(options.player.showGuild, "Guild", player.guild)
    offset = Cells:get(x, offset):printOptionalValue(options.player.showGuildRank, "Guild Rank", player.guildRank)
    offset = Cells:get(x, offset):printOptionalValue(options.player.showMoney, "Gold", player.money and GetCoinTextureString(player.money))
    local durabilityColor = player.durability and ICT:gradient("FF00FF00", "FFFF0000", player.durability / 100) or "FF00FF00"
    offset = Cells:get(x, offset):printOptionalValue(options.player.showDurability, "Durability", player.durability and string.format("%.0f%%", player.durability), nil, durabilityColor)
    offset = UI.hideRows(x, offset, padding)

    padding = getPadding(offset, paddings.rested)
    if player.level < ICT.MaxLevel then
        local currentXP = player.currentXP or 0
        local maxXP = player.maxXP or 1
        local xpPercentage = currentXP / maxXP * 100 
        offset = Cells:get(x, offset):printOptionalValue(options.player.showXP, "XP", string.format("%s/%s (%.0f%%)", currentXP, maxXP, xpPercentage))
        local restedPercentage = Player.GetRestedXP(player)
        local bubbles = restedPercentage * 20
        offset = Cells:get(x, offset):printOptionalValue(options.player.showRestedXP, "Rested XP", string.format("%s bubbles (%.0f%%)", bubbles, restedPercentage * 100))
        local resting = string.format("|A:%s:14|a", player.resting and "common-icon-checkmark" or "common-icon-redx")
        offset = Cells:get(x, offset):printOptionalValue(options.player.showRestedState, "Resting", resting)
    end
    offset = UI.hideRows(x, offset, padding)

    local bags = player.bagsTotal or {}
    if options.player.showBags then
        offset = Cells:get(x, offset):hide()
        offset = Cells:get(x, offset):printSectionTitle("Bags")

        if not ICT.db.options.collapsible["Bags"] then
            padding = getPadding(offset, paddings.bags)
            for k, bag in ICT:spairs(bags, ICT.NaturalSort, function(k) return bags[k].total > 0 end) do
                offset = Cells:get(x, offset):printValue(string.format("|T%s:14|t%s", ICT.BagFamily[k].icon, ICT.BagFamily[k].name), string.format("%s/%s", bag.free, bag.total))
            end
            offset = UI.hideRows(x, offset, padding)

            local bankBags = player.bankBagsTotal or {}
            padding = getPadding(offset, paddings.bankBags)
            if options.player.showBankBags and ICT:sum(bankBags, function(v) return v.total end) > 0 then
                for k, bag in ICT:spairs(bankBags, ICT.NaturalSort, function(k) return bankBags[k].total > 0 end) do
                    offset = Cells:get(x, offset):printValue(string.format("|T%s:14|t[Bank]%s", ICT.BagFamily[k].icon, ICT.BagFamily[k].name), string.format("%s/%s", bag.free, bag.total))
                end
            end
            offset = UI.hideRows(x, offset, padding)
        end
    end

    local specs = player.specs or {}
    if options.player.showSpecs then
        offset = Cells:get(x, offset):hide()
        offset = Cells:get(x, offset):printSectionTitle("Specs")

        if not ICT.db.options.collapsible["Specs"] then
            padding = getPadding(offset, paddings.specs)
            for k, spec in pairs(specs) do
                local specColor = UI.getSelectedColor(k == player.activeSpec)

                offset = Cells:get(x, offset):printValue(spec.name or "", string.format("%s/%s/%s", spec.tab1, spec.tab2, spec.tab3), specColor)
                local text = ""
                for _, glyph in pairs(spec.glyphs or {}) do
                    if glyph and glyph ~= 0 then
                        print(player.fullName)
                        local name, _, _, _, _, _, _, icon = GetSpellInfo(glyph)
                        print(GetSpellInfo(glyph))
                        print(glyph)
                        print(icon)
                        text = text .. string.format("|T%s:14|t", glyph)
                    end
                end
               offset = Cells:get(x, offset):printValue("Glyphs", text)
                if TT_GS and options.showGearScore then
                    local scoreColor = spec.gearScore and ICT:rgbPercentage2hex(TT_GS:GetQuality(spec.gearScore)) or nil
                    offset = Cells:get(x, offset):printOptionalValue("GearScore", spec.gearScore, nil, scoreColor)
                    offset = Cells:get(x, offset):printOptionalValue("iLvl", spec.ilvlScore, nil, scoreColor)
                end
            end
            offset = UI.hideRows(x, offset, padding)
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
                local name = v.icon and string.format("|T%s:14|t%s", v.icon, v.name) or v.name
                offset = Cells:get(x, offset):printValue(name, string.format("%s/%s", v.rank, v.max))
            end
            offset = UI.hideRows(x, offset, padding)
        end
    end
    offset = Cells:get(x, offset):hide()
    Cells.indent = ""
    return offset
end

-- Tooltip for instance information upon entering the cell.
local function instanceTooltip(player, key, instance)
    local tooltip = Tooltips:new(instance.name)

    local info = ICT.InstanceInfo[instance.id]
    -- Display the available encounters for the instance.
    local encountersDone = info.numEncounters - (instance.encounterProgress or 0)
    tooltip:printLine("Encounters", string.format("%s/%s", encountersDone, info.numEncounters))

    -- Display which players are locked or not for this instance.
    -- You have to get at least one player to display a tooltip, so always print title.
    tooltip.shouldPrintTitle = true
    tooltip:printTitle("Locks")
    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.PlayerEnabled) do
        local playerInstance = Instances:GetInstanceByName(player, key) or { locked = false }
        local playerColor = UI.getSelectedColor(playerInstance.locked)
        tooltip:print(Player.GetNameWithIcon(player), playerColor)
    end

    -- Display all available currency for the instance.
    tooltip.shouldPrintTitle = true
    for tokenId, _ in ICT:spairs(info.tokenIds or {}, ICT.CurrencySort) do
        -- Onyxia 40 is reused and has 0 emblems so skip currency.
        local max = info.maxEmblems(instance, tokenId)
        if ICT.db.options.currency[tokenId] and max ~= 0 then
            tooltip:printTitle("Currency")

            local available = instance.available[tokenId] or max
            tooltip:printLine(ICT:GetCurrencyWithIconTooltip(tokenId), string.format("%s/%s", available, max))
        end
    end
    -- This player is the original player which owns the cell.
    return tooltip:create("ICTInstanceTooltip" .. key .. player.name)
end

local function instanceSectionTooltip()
    return Tooltips:new("Instance Color Codes")
    :print("Available", ICT.availableColor)
    :print("Locked", ICT.lockedColor)
    :create("ICTInstanceTooltip")
end

-- Prints all the instances with associated tooltips.
local function printInstances(player, title, instances, x, offset)
    if not Options:showInstances(instances) then
        return offset
    end

    local cell = Cells:get(x, offset)
    offset = cell:printSectionTitle(title)
    instanceSectionTooltip():attach(cell)

    -- If the section is collapsible then short circuit here.
    if not ICT.db.options.collapsible[title] then
        for key, instance in ICT:spairsByValue(instances, ICT.InstanceSort) do
            if Options.showInstance(instance) then
                local color = UI.getSelectedColor(instance.locked)
                cell = Cells:get(x, offset)
                offset = cell:print(instance.name, color)
                instanceTooltip(player, key, instance):attach(cell)
            end
        end
    end
    return Cells:get(x, offset):hide()
end

local function printInstancesForCurrency(tooltip, title, instances, tokenId)
    -- Only print the title if there exists an instance for this token.
    tooltip.shouldPrintTitle = true
    for _, instance in ICT:spairsByValue(instances, ICT.InstanceSort) do
        local info = ICT.InstanceInfo[instance.id]
        local max = info.maxEmblems(instance, tokenId)
        -- Onyxia 40 is reused and has 0 emblems so skip currency.
        if Options.showInstance(instance) and info.tokenIds[tokenId] and max ~= 0 then
            tooltip:printTitle(title)
            -- Displays available currency out of the total currency for this instance.
            local color =  UI.getSelectedColor(instance.locked)
            local available = instance.available[tokenId] or max
            tooltip:printLine(instance.name, string.format("%s/%s", available, max), color)
        end
    end
end

local function printQuestsForCurrency(tooltip, player, tokenId)
    tooltip.shouldPrintTitle = true
    if ICT.db.options.showQuests then
        for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player)) do
            if quest.tokenId == tokenId and (player.quests.prereq[quest.key] or ICT.db.options.allQuests) then
                tooltip:printTitle("Quests")
                local color = UI.getQuestColor(player, quest)
                tooltip:printLine(quest.name(player), quest.seals, color)
            end
        end
    end
end

local function currencySectionTooltip()
    return Tooltips:new("Currency Format")
    :printLine("Character", "Total (Available)")
    :printPlain("Shows the total currency per character,")
    :printPlain("and the available amount across all sources.")
    :printLine("\nInstances", "Available / Total")
    :printPlain("Shows the available for the current lock out,")
    :printPlain("out of the total for any given lockout.")
    :printLine("\nQuests", "Total")
    :printPlain("Shows the currency reward for a given quest.")
    :create("ICTCurrencyFormat")
end

-- Tooltip for currency information upon entering the cell.
local function currencyTooltip(selectedPlayer, tokenId)
    local tooltip = Tooltips:new(ICT:GetCurrencyWithIconTooltip(tokenId))

    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.PlayerEnabled) do
        local available = Player:AvailableCurrency(player, tokenId)
        local total = player.currency.wallet[tokenId] or 0
        tooltip:printLine(Player.GetNameWithIcon(player), string.format("%s (%s)", total, available), UI.getClassColor(player))
    end

    if ICT.db.options.verboseCurrencyTooltip then
        printInstancesForCurrency(tooltip, "Dungeons", selectedPlayer.dungeons, tokenId)
        printInstancesForCurrency(tooltip, "Raids", selectedPlayer.raids, tokenId)
        printQuestsForCurrency(tooltip, selectedPlayer, tokenId)
    end
    return tooltip:create("ICTCurrencyTooltip" .. selectedPlayer.fullName .. tokenId)
end

-- Prints currency with multi line information.
local function printCurrencyVerbose(player, tokenId, x, offset)
    local cell = Cells:get(x, offset)
    offset = cell:printValue(ICT:GetCurrencyWithIcon(tokenId), ICT.subtitleColor)
    local tooltip = currencyTooltip(player, tokenId)
    tooltip:attach(cell)
    local available = Player:AvailableCurrency(player, tokenId)
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
    local available = Player:AvailableCurrency(player, tokenId)
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
    tooltip:printLine(ICT:GetCurrencyWithIconTooltip(quest.tokenId), quest.seals)

    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.PlayerEnabled) do
        local color = UI.getQuestColor(player, quest)
        tooltip:print(Player.GetNameWithIcon(player), color)
    end
    return tooltip:create("ICTQuestTooltip" .. name)
end

local function questSectionTooltip()
    return Tooltips:new("Quest Color Codes")
    :print("Available", ICT.availableColor)
    :print("Completed", ICT.lockedColor)
    :print("Missing Prerequesite", ICT.unavailableColor)
    :create("ICTQuestTooltip")
end

local function printQuests(player, x, offset)
    if ICT.db.options.showQuests then
        local cell = Cells:get(x, offset)
        offset = cell:printSectionTitle("Quests")
        questSectionTooltip():attach(cell)
        if not ICT.db.options.collapsible["Quests"] then
            local padding = getPadding(offset, paddings.quests)
            -- sort by token then name...
            for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player)) do
                if Quests.IsQuestAvailable(player)(quest) then
                    local color = UI.getQuestColor(player, quest)
                    local name = quest.name(player)
                    cell = Cells:get(x, offset)
                    offset = cell:print(name, color)
                    questTooltip(name, quest):attach(cell)
                end
            end
            offset = UI.hideRows(x, offset, padding)
        end
        offset = Cells:get(x, offset):hide()
    end
    return offset
end

local function cancelTicker(k)
    if tickers[k] then
        tickers[k]:Cancel()
    end
end

local function timerSectionTooltip()
    return Tooltips:new("Reset Timer")
    :printPlain("Countdown to the next reset respectively for 1, 3, 5 and 7 days.")
    :printPlain("\nNote: 3 and 5 day resets need a known lockout to calculate from\nas Blizzard doesn't provide a way through their API.")
    :create("ICTResetTimerTooltip")
end

local function printTimerSingleView(x, offset, title, time)
    offset = Cells:get(x, offset):printValue(title, time())
    tickers[title] = C_Timer.NewTicker(1, function () Cells:get(x, offset):printValue(title, time()) end)
    return offset
end

local function printTimerMultiView(x, title, time)
    local name = "ICTReset" .. title
    local timer = _G[name]
    local textField = timer and timer.textField
    if not timer then
        timer = CreateFrame("Button", name, ICT.frame)
        timer:SetAlpha(1)
        timer:SetIgnoreParentAlpha(true)
        timer:SetSize(cellWidth, cellHeight)
        textField = timer:CreateFontString()
        textField:SetPoint("CENTER")
        textField:SetFont("Fonts\\FRIZQT__.TTF", 8)
        textField:SetJustifyH("LEFT")
        timer.textField = textField
        timerSectionTooltip():attachFrame(timer)
    end
    timer:SetPoint("TOP", x, -36)
    timer:Show()
    textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", ICT.subtitleColor, title, ICT.textColor, time()))
    tickers[title] = C_Timer.NewTicker(1, function() textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", ICT.subtitleColor, title, ICT.textColor, time())) end)
    return x + 60
end

local function hideMultiView(title)
    local name = "ICTReset" .. title
    local timer = _G[name]
    if timer then
        timer:Hide()
    end
end

local function cancelResetTimerTickers()
    for k, _ in ICT:spairs(ICT.db.reset) do
        local name = ICT.ResetInfo[k].name
        cancelTicker(name)
        hideMultiView(name)
    end
end

local function printResetTimers(x, offset)
    cancelResetTimerTickers()
    local count = ICT:sum(ICT.db.options.reset, function(v) return v and 1 or 0 end)
    if count > 0 then
        if ICT.db.options.multiPlayerView then
            local start = 32 + -60 * count / 2
            for k, v in ICT:spairs(ICT.db.reset) do
                if ICT.db.options.reset[k] then
                    local time = function() return v and ICT:DisplayTime(v - GetServerTime()) or "N/A" end
                    start = printTimerMultiView(start, ICT.ResetInfo[k].name, time)
                end
            end
        else
            local cell = Cells:get(x, offset)
            offset = cell:printSectionTitle("Reset")
            timerSectionTooltip():attach(cell)

            if not ICT.db.options.collapsible["Reset"] then
                for k, v in ICT:spairs(ICT.db.reset) do
                    if ICT.db.options.reset[k] then
                        local time = function() return v and ICT:DisplayTime(v - GetServerTime()) or "N/A" end
                        offset = printTimerSingleView(x, offset, ICT.ResetInfo[k].name, time)
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

local function display(player, x)
    local offset = 1
    offset = printCharacterInfo(player, x, offset)
    offset = printResetTimers(x, offset)
    offset = printInstances(player, "Dungeons", player.dungeons, x, offset)
    offset = printInstances(player, "Raids", player.raids, x, offset)
    offset = printInstances(player, "Old Raids", player.oldRaids, x, offset)
    offset = printQuests(player, x, offset)
    offset = printCurrency(player, x, offset)
    UI.hideRows(x, offset, displayY)
    return offset
end

-- Prints out selected players with associated instances and currency infromation.
function ICT:DisplayPlayer()
    calculatePadding()
    local offset = 0
    local x = 0
    if ICT.db.options.multiPlayerView then
        for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.PlayerEnabled) do
            x = x + 1
            offset = math.max(display(player, x), offset)
        end
    else
        local player = getSelectedOrDefault()
        x = x + 1
        offset = display(player, x)
        ICT.DDMenu:UIDropDownMenu_SetText(ICT.frame.playerDropdown, Player.GetName(player))
    end

    UI.hideColumns(x + 1, displayX, displayY)
    ICT:UpdateFrameSizes(x, offset)
    displayY = offset
    displayX = x
end

function ICT:CreatePlayerDropdown()
    local playerDropdown = ICT.DDMenu:Create_UIDropDownMenu("PlayerSelection", ICT.frame)
    ICT.frame.playerDropdown = playerDropdown
    playerDropdown:SetPoint("TOP", ICT.frame, 0, -30)
    playerDropdown:SetAlpha(1)
    playerDropdown:SetIgnoreParentAlpha(true)
    -- Width set to slightly smaller than parent frame.
    ICT.DDMenu:UIDropDownMenu_SetWidth(playerDropdown, 160)

    ICT.DDMenu:UIDropDownMenu_Initialize(
        playerDropdown,
        function()
            local info = ICT.DDMenu:UIDropDownMenu_CreateInfo()
            for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.PlayerEnabled) do
                info.text = Player.GetNameWithIcon(player)
                info.value = player.fullName
                info.checked = ICT.selectedPlayer == player.fullName
                info.func = function(self)
                    ICT.selectedPlayer = self.value
                    ICT.DDMenu:UIDropDownMenu_SetText(playerDropdown, Player.GetName(ICT.db.players[ICT.selectedPlayer]))
                    ICT:DisplayPlayer()
                end
                ICT.DDMenu:UIDropDownMenu_AddButton(info)
            end
        end
    )
    Options:FlipOptionsMenu()
end

function ICT:CreatePlayerSlider()
	local levelSlider = CreateFrame("Slider", "ICTCharacterLevel", ICT.frame, "OptionsSliderTemplate")
	levelSlider:SetPoint("TOP", ICTOptions, "BOTTOM")
	ICTCharacterLevelText:SetText("Min Level")
    --.tooltipText = "Minimum level alts to show?";
    --NIT.charsMinLevelSlider:SetFrameStrata("HIGH");
    levelSlider:SetWidth(120)
    levelSlider:SetHeight(12)
    levelSlider:SetMinMaxValues(1, ICT.MaxLevel)
    levelSlider:SetObeyStepOnDrag(true);
    levelSlider:SetValueStep(1)
    levelSlider:SetStepsPerPage(1)
    levelSlider:SetValue(ICT.db.options.minCharacterLevel or ICT.MaxLevel)
    ICTCharacterLevelLow:SetText("1")
    ICTCharacterLevelHigh:SetText(ICT.MaxLevel)
    levelSlider:HookScript("OnValueChanged", function(self, value)
        ICT.db.options.minCharacterLevel = value
        --editBox:SetText(value);
        --NIT:recalcAltsLineFrames();
    end
    )

    local ManualBackdrop = {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true, edgeSize = 1, tileSize = 5,
    };
    local editBox = CreateFrame("EditBox", nil, levelSlider, "BackdropTemplate");
    levelSlider.editBox = editBox
    editBox:SetAutoFocus(false);
    editBox:SetFontObject(GameFontHighlightSmall);
    editBox:SetPoint("TOP", levelSlider, "BOTTOM");
    editBox:SetHeight(14);
    editBox:SetWidth(70);
    editBox:SetJustifyH("CENTER");
    editBox:EnableMouse(true);
    editBox:SetBackdrop(ManualBackdrop);
    editBox:SetBackdropColor(0, 0, 0, 0.5);
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80);
    editBox:SetScript("OnEnter", EditBox_OnEnter);
    editBox:SetScript("OnLeave", EditBox_OnLeave);
    editBox:SetScript("OnEnterPressed", EditBox_OnEnterPressed);
    editBox:SetScript("OnEscapePressed", EditBox_OnEscapePressed);
end

function ICT:ResizeFrameButton()
    local button = CreateFrame("Button", "ICTResizeButton", ICT.frame, "PanelResizeButtonTemplate")
    ICT.resize = button
    button:SetSize(20, 20)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetPoint("BOTTOMRIGHT", 0, 0)
	button:HookScript("OnMouseUp", function(self)
        ICT.db.width = ICT.frame:GetWidth()
        ICT.db.height = ICT.frame:GetHeight()
    end)
end

function ICT:ResetFrameButton()
    local button = CreateFrame("Button", "ICTResetSizeAndPosition", ICT.frame)
    button:SetSize(32, 32)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetPoint("BOTTOMRIGHT", -5, 5)
    button:RegisterForClicks("AnyUp")
    button:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
    button:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
    button:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
    button:SetScript("OnClick", function() drawFrame(defaultX, defaultY, cellWidth * displayX + 40, math.max(defaultHeight, cellHeight * displayY)) end)
    Tooltips:new("Reset size and position"):create("ICTResetFrame"):attachFrame(button)
end

function ICT:UpdateFrameSizes(x, offset)
    local newHeight = offset * cellHeight
    local newWidth = x * cellWidth

    ICT.resize:Init(ICT.frame, cellWidth + 40, defaultHeight - 200, newWidth + 40, math.max(defaultHeight, newHeight))
    ICT.hScrollBox:SetHeight(newHeight)
    ICT.content:SetSize(newWidth, newHeight)
    ICT.hScrollBox:FullUpdate()
    ICT.vScrollBox:FullUpdate()
end

-- local f1 = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
-- f1:SetSize(100,100)
-- f1:SetPoint("CENTER")
-- local t1 = f1:CreateTexture(nil,"BACKGROUND",nil,-8)
-- t1:SetAllPoints(f1)
-- t1:SetTexture("interface/icons/inv_mushroom_11")
-- local t2 = f1:CreateTexture(nil,"BACKGROUND",nil,-7)
-- local t3 = f1:CreateTexture(nil,"BACKGROUND",nil,-6)
-- local t4 = f1:CreateTexture(nil,"BACKGROUND",nil,-5)

-- local f = CreateFrame("Frame", nil, UIParent)
-- f:SetPoint("CENTER")
-- f:SetSize(64, 64)

-- local tex = f:CreateTexture(nil,"BACKGROUND",nil,2)
-- tex:SetAllPoints(f)
-- tex:SetTexture("interface/icons/inv_mushroom_11")

-- local tex = f:CreateTexture(nil,"BACKGROUND",nil,3)
-- tex:SetAllPoints(f)
-- print(GetSpellTexture(64261))
-- tex:SetTexture(237633)