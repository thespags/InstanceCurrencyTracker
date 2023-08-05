local addOnName, ICT = ...

local Player = ICT.Player
local Options = ICT.Options
local Instances = ICT.Instances
local availableColor = "FFFFFFFF"
local sectionColor = "FFFFFF00"
local selectedSectionColor = "FF484800"
local tooltipTitleColor = "FF00FF00"
local subtitleColor = "FFFFCC00"
local textColor = "FF9CD6DE"
local lockedColor = "FFFF00FF"
local unavailableColor = "FFFF0000"
local cellWidth = 200
local cellHeight = 10
local defaultWidth = cellWidth + 40
local defaultHeight = 600
local defaultX = 400
local defaultY = 800
local tickers = {}
local displayX = 0
local displayY = 0

local function drawFrame(x, y, width, height)
    ICT.db.X = x or defaultX
	ICT.db.Y = y or defaultY
    ICT.db.width = width or defaultWidth
    ICT.db.height = height or defaultHeight
    ICT.frame:ClearAllPoints()
    ICT.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ICT.db.X, ICT.db.Y)
    ICT.frame:SetSize(ICT.db.width, ICT.db.height)
end

local function tooltipEnter(frame)
    return frame and function(self, motion)
        frame:Show()
        local scale = frame:GetEffectiveScale()
        local x, y = GetCursorPosition()
        frame:SetPoint("RIGHT", nil, "BOTTOMLEFT", (x / scale) - 2, y / scale)
    end
end

local function tooltipLeave(frame)
    return frame and function(self, motion)
        frame:Hide()
    end
end

local function addTooltip(frame, tooltip)
    frame:SetScript("OnEnter", tooltipEnter(tooltip))
    frame:SetScript("OnLeave", tooltipLeave(tooltip))
end

local function createTooltip(name, text)
    local tooltip = _G[name]
    local textField = tooltip and tooltip.textField
    if not tooltip then
        tooltip = CreateFrame("Frame", name, UIParent, "TooltipBorderedFrameTemplate")
        tooltip:SetFrameStrata("DIALOG")
        tooltip:Hide()
        textField = tooltip:CreateFontString()
        textField:SetPoint("CENTER")
        textField:SetFont("Fonts\\FRIZQT__.TTF", 10)
        textField:SetJustifyH("LEFT")
        tooltip.textField = textField
    end
    textField:SetText(text)
    tooltip:SetWidth(textField:GetStringWidth() + 18)
    tooltip:SetHeight(textField:GetStringHeight() + 12)
    return tooltip
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

function ICT:CreateAddOn()
    local frame = CreateFrame("Frame", "ICTFrame", UIParent, "BasicFrameTemplateWithInset")
    ICT.frame = frame

    frame:SetFrameStrata("HIGH")
    drawFrame(ICT.db.X, ICT.db.Y, ICT.db.width, ICT.db.height)
    enableMoving(frame)
    frame:SetAlpha(.5)
    frame:Hide()

    ICT:ResizeFrameButton()
    ICT:ResetFrameButton()
    ICT.selectedPlayer = ICT:GetFullName()

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
    ICT:DisplayPlayer()
end

local function getContent()
    return ICT.content
end

-- Gets the associated cell or create it if it doesn't exist yet.
local function getCell(x, y)
    local content = getContent()
    local name = string.format("ICTcell(%s, %s)", x, y)
    if not content.cells[name] then
        local button = CreateFrame("Button", name, content)
        button:SetSize(cellWidth, cellHeight)
        button:SetPoint("TOPLEFT", (x - 1) * cellWidth, -(y - 1) * cellHeight)
        content.cells[name] = button
    end
    local cell = content.cells[name]
    -- Remove any cell action so we can reuse the cell.
    cell:SetScript("OnEnter", nil)
    cell:SetScript("OnClick", nil)

    return cell
end

-- Prints text in the associated cell.
local function printCell(x, y, text, color)
    local cell = getCell(x, y)
    -- Create the string if necessary.
    if not cell.value then
        cell.value = cell:CreateFontString()
        cell.value:SetPoint("LEFT")
    end
    -- TODO We could make font and size an option here.
    cell.value:SetFont("Fonts\\FRIZQT__.TTF", 10)
    text = color and string.format("|c%s%s|r", color, text) or text
    cell.value:SetText(text)
    cell:Show()
    return cell
end

local function hideCell(x, y)
    getCell(x, y):Hide()
end

local function getClassColor(player)
    local classColorHex = select(4, GetClassColor(player.class))
    -- From NIT: Safeguard for weakauras/addons that like to overwrite and break the GetClassColor() function.
    if not classColorHex then
        classColorHex = player.class == "SHAMAN" and "ff0070dd" or "ffffffff"
    end
    return classColorHex
end

-- Prints a {label}: {value} with label and value appropriately colored.
local function printCellInfo(label, value, labelColor, valueColor)
    labelColor = labelColor or subtitleColor
    valueColor = valueColor or textColor
    return string.format("|c%s%s:|r |c%s%s|r", labelColor, label, valueColor, value)
end

-- Instead of cleaning this up to align newline and no newline this one stays the same name.
local function printInfo(label, value, labelColor, valueColor)
    labelColor = labelColor or subtitleColor
    valueColor = valueColor or textColor
    return "\n" .. printCellInfo(label, value, labelColor, valueColor)
end

local function playerTooltip(player)
    local text = string.format("|T%s:14|t|c%s%s|r", ICT.ClassIcons[player.class], getClassColor(player), Player.GetName(player))
    local printTitle = true
    for k, spec in pairs(player.specs or {}) do
        if printTitle then
            printTitle = false
            text = text .. string.format("\n|c%sSpecs|r", sectionColor)
        end
        local color = k == player.activeSpec and lockedColor or availableColor
        text = text .. printInfo(spec.name, string.format("%s/%s/%s", spec.tab1, spec.tab2, spec.tab3), color)
        -- for _, glyph in pairs(spec.glyphs or {}) do
        --     if glyph then
        --         text = text .. string.format("|T%s:14|t", glyph.icon)
        --     end
        -- end
        if TT_GS and spec.gearScore then
            local scoreColor = ICT:rgb2hex(TT_GS:GetQuality(spec.gearScore))
            text = text .. printInfo("GearScore", spec.gearScore, subtitleColor, scoreColor)
            .. printInfo("iLvl", spec.ilvlScore, subtitleColor, scoreColor)
        end
    end

    -- This should be already indexed primary over secondary professions.
    printTitle = true
    for _, v in pairs(player.professions or {}) do
        if printTitle then
            printTitle = false
            text = text .. string.format("\n\n|c%sProfessions|r", sectionColor)
        end
        -- We should have already filtered out those without icons but safety check here.
        local name = v.icon and string.format("|T%s:14|t%s", v.icon, v.name) or v.name
        text = text .. printInfo(name, string.format("%s/%s", v.rank, v.max))
    end
    return createTooltip("ICT" .. player.fullName, text)
end

-- Tooltip for instance information upon entering the cell.
local function instanceTooltip(key, instance)
    local text = string.format("|c%s%s", tooltipTitleColor, instance.name)

    local info = ICT.InstanceInfo[instance.id]
    -- Display the available encounters for the instance.
    local encountersDone = info.numEncounters - (instance.encounterProgress or 0)
    text = text .. printInfo("Encounters", string.format("%s/%s", encountersDone, info.numEncounters))

    -- Display which players are locked or not for this instance.
    text = text .. string.format("\n\n|c%sLocks|r", sectionColor)
    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.PlayerEnabled) do
        local playerInstance = Instances:GetInstanceByName(player, key) or { locked = false }
        local playerColor = playerInstance.locked and lockedColor or availableColor
        text = text .. string.format("\n|c%s%s|r", playerColor, Player.GetName(player))
    end

    -- Display all available currency for the instance.
    local printTitle = true
    for tokenId, _ in ICT:spairs(info.tokenIds or {}, ICT.CurrencySort) do
        -- Onyxia 40 is reused and has 0 emblems so skip currency.
        local max = info.maxEmblems(instance, tokenId)
        if ICT.db.options.currency[tokenId] and max ~= 0 then
            if printTitle then
                text = text .. string.format("\n\n|c%sCurrency|r", sectionColor)
                printTitle = false
            end
            local available = instance.available[tokenId] or max
            text = text .. printInfo(ICT:GetCurrencyWithIconTooltip(tokenId), string.format("%s/%s", available, max))
        end
    end
    return createTooltip("ICTInstanceTooltip" .. key, text)
end

local function updateSectionTitle(x, offset, title, color)
    local collapsed = ICT.db.options.collapsible[title]
    local icon = collapsed and "Interface\\Buttons\\UI-PlusButton-UP" or "Interface\\Buttons\\UI-MinusButton-UP"
    local titleText = string.format("|T%s:12|t%s", icon, title)
    local cell = printCell(x, offset, titleText, color)
    return cell;
end

local function printSectionTitle(x, offset, title, tooltip)
    offset = offset + 1
    local cell = updateSectionTitle(x, offset, title, sectionColor)
    cell:SetScript(
        "OnClick",
        function()
            ICT.db.options.collapsible[title] = not ICT.db.options.collapsible[title]
            updateSectionTitle(x, offset, title, sectionColor)
            ICT:DisplayPlayer()
        end
    )
    addTooltip(cell, tooltip)
    return offset + 1
end

local function instanceSectionTooltip()
    local text = string.format("|c%sInstance Color Codes|r", tooltipTitleColor)
    .. string.format("\n|c%sAvailable|r", availableColor)
    .. string.format("\n|c%sLocked|r", lockedColor)
    return createTooltip("ICTInstanceTooltip", text)
end

-- Prints all the instances with associated tooltips.
local function printInstances(title, instances, x, offset)
    if not Options:showInstances(instances) then
        return offset
    end

    offset = printSectionTitle(x, offset, title, instanceSectionTooltip())

    -- If the section is collapsible then short circuit here.
    if not ICT.db.options.collapsible[title] then
        for key, instance in ICT:spairsByValue(instances, ICT.InstanceSort) do
            if Options.showInstance(instance) then
                local color = instance.locked and lockedColor or availableColor
                local cell = printCell(x, offset, instance.name, color)
                addTooltip(cell, instanceTooltip(key, instance))
                offset = offset + 1
            end
        end
    end
    hideCell(x, offset)
    return offset
end

local function printInstancesForCurrency(title, instances, tokenId)
    -- Only print the title if there exists an instance for this token.
    local printTitle = true
    local text = ""
    for _, instance in ICT:spairsByValue(instances, ICT.InstanceSort) do
        local info = ICT.InstanceInfo[instance.id]
        local max = info.maxEmblems(instance, tokenId)
        -- Onyxia 40 is reused and has 0 emblems so skip currency.
        if Options.showInstance(instance) and info.tokenIds[tokenId] and max ~= 0 then
            if printTitle then
                printTitle = false
                text = text .. string.format("\n\n|c%s%s|r", sectionColor, title)
            end
            -- Displays available currency out of the total currency for this instance.
            local color = instance.locked and lockedColor or availableColor
            local available = instance.available[tokenId] or max
            text = text .. printInfo(instance.name, string.format("%s/%s", available, max), color)
        end
    end
    return text
end

local function getQuestColor(player, quest)
    return (not player.quests.prereq[quest.key] and unavailableColor) or (player.quests.completed[quest.key] and lockedColor or availableColor)
end

local function printQuestsForCurrency(player, tokenId)
    local printTitle = true
    local text = ""
    if ICT.db.options.showQuests then
        for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player)) do
            if quest.tokenId == tokenId and (player.quests.prereq[quest.key] or ICT.db.options.allQuests) then
                if printTitle then
                    printTitle = false
                    text = text .. string.format("\n\n|c%sQuests|r", sectionColor)
                end
                local color = getQuestColor(player, quest)
                text = text .. printInfo(quest.name(player), quest.seals, color)
            end
        end
    end
    return text
end

-- Tooltip for currency information upon entering the cell.
local function currencyTooltip(selectedPlayer, tokenId)
    local text = string.format("|c%s%s|r", tooltipTitleColor, ICT:GetCurrencyWithIconTooltip(tokenId))

    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.PlayerEnabled) do
        local available = Player:AvailableCurrency(player, tokenId)
        local total = player.currency.wallet[tokenId] or 0
        text = text .. printInfo(Player.GetName(player), string.format("%s (%s)", total, available), getClassColor(player))
    end

    if ICT.db.options.verboseCurrencyTooltip then
        text = text .. printInstancesForCurrency("Dungeons", selectedPlayer.dungeons, tokenId)
        text = text .. printInstancesForCurrency("Raids", selectedPlayer.raids, tokenId)
        text = text .. printQuestsForCurrency(selectedPlayer, tokenId)
    end
    return createTooltip("ICTCurrencyTooltip" .. selectedPlayer.fullName .. tokenId, text)
end

-- Prints currency with multi line information.
local function printCurrencyVerbose(player, tokenId, x, offset)
    local cell = printCell(x, offset, ICT:GetCurrencyWithIcon(tokenId), sectionColor)
    local tooltip = currencyTooltip(player, tokenId)
    addTooltip(cell, tooltip)
    offset = offset + 1
    local available = Player:AvailableCurrency(player, tokenId)
    cell = printCell(x, offset, "Available  " .. available, textColor)
    addTooltip(cell, tooltip)
    offset = offset + 1
    local current = player.currency.wallet[tokenId] or 0
    cell = printCell(x, offset, "Current     " .. current, textColor)
    addTooltip(cell, tooltip)
    offset = offset + 1
    hideCell(x, offset)
    return offset
end

-- Prints currency single line information.
local function printCurrencyShort(player, tokenId, x, offset)
    local current = player.currency.wallet[tokenId] or 0
    local available = Player:AvailableCurrency(player, tokenId)
    local text = printCellInfo(ICT:GetCurrencyWithIcon(tokenId), string.format("%s (%s)", current, available), subtitleColor, textColor)
    local cell = printCell(x, offset, text)
    local tooltip = currencyTooltip(player, tokenId)
    addTooltip(cell, tooltip)
    return offset + 1
end

local function printCurrency(player, x, offset)
    if ICT:containsAnyValue(ICT.db.options.currency) then
        offset = printSectionTitle(x, offset, "Currency")
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
    local text = string.format("|c%s%s|r", tooltipTitleColor, name)
    .. printInfo(ICT:GetCurrencyWithIconTooltip(quest.tokenId), quest.seals)

    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.PlayerEnabled) do
        local color = getQuestColor(player, quest)
        text = text .. string.format("\n|c%s%s|r", color, Player.GetName(player))
    end
    return createTooltip("ICTQuestTooltip" .. name, text)
end

local function isQuestAvailable(player)
    return function(quest)
        return ICT.db.options.currency[quest.tokenId] and (player.quests.prereq[quest.key] or ICT.db.options.allQuests)
    end
end

local function questSectionTooltip()
    local text = string.format("|c%sQuest Color Codes|r", tooltipTitleColor)
    .. string.format("\n|c%sAvailable|r", availableColor)
    .. string.format("\n|c%sCompleted|r", lockedColor)
    .. string.format("\n|c%sMissing Prerequesite|r", unavailableColor)
    return createTooltip("ICTQuestTooltip", text)
end

local function printQuests(player, x, offset)
    if ICT.db.options.showQuests then
        if ICT:containsAnyValue(ICT.QuestInfo, isQuestAvailable(player)) then
            offset = printSectionTitle(x, offset, "Quests", questSectionTooltip())
        end
        if not ICT.db.options.collapsible["Quests"] then
            -- sort by token then name...
            for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player)) do
                if isQuestAvailable(player)(quest) then
                    local color = getQuestColor(player, quest)
                    local name = quest.name(player)
                    local cell = printCell(x, offset, name, color)
                    local tooltip = questTooltip(name, quest)
                    addTooltip(cell, tooltip)
                    offset = offset + 1
                end
            end
        end
    end
    hideCell(x, offset)
    return offset
end

local function cancelTicker(k)
    if tickers[k] then
        tickers[k]:Cancel()
    end
end

local function timerSectionTooltip()
    local text = string.format("|c%sReset Timer|r", tooltipTitleColor)
    .. string.format("\n|c%sCountdown to the next reset respectively for 1, 3, 5 and 7 days.|r", availableColor)
    .. string.format("\n\n|c%sNote: 3 and 5 day resets need a known lockout to calculate from\nas Blizzard doesn't provide a way through their API.|r", availableColor)
    return createTooltip("ICTResetTimerTooltip", text)
end

local function printTimerSingleView(x, offset, title, time)
    printCell(x, offset, printCellInfo(title, time(), subtitleColor, textColor))
    tickers[title] = C_Timer.NewTicker(1, function () printCell(x, offset, printCellInfo(title, time(), subtitleColor, textColor)) end)
    return offset + 1
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
        addTooltip(timer, timerSectionTooltip())
    end
    timer:SetPoint("TOP", x, -36)
    timer:Show()
    textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", subtitleColor, title, textColor, time()))
    tickers[title] = C_Timer.NewTicker(1, function() textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", subtitleColor, title, textColor, time())) end)
    return x + 60
end

local function createTooltip(name, text)
    local tooltip = _G[name]
    local textField = tooltip and tooltip.textField
    if not tooltip then
        tooltip = CreateFrame("Frame", name, UIParent, "TooltipBorderedFrameTemplate")
        tooltip:SetFrameStrata("DIALOG")
        tooltip:Hide()
        textField = tooltip:CreateFontString()
        textField:SetPoint("CENTER", 0, 0)
        textField:SetFont("Fonts\\FRIZQT__.TTF", 10)
        textField:SetJustifyH("LEFT")
        tooltip.textField = textField
    end
    textField:SetText(text)
    tooltip:SetWidth(textField:GetStringWidth() + 18)
    tooltip:SetHeight(textField:GetStringHeight() + 12)
    return tooltip
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
            local start = 30 + -60 * count / 2
            for k, v in ICT:spairs(ICT.db.reset) do
                if ICT.db.options.reset[k] then
                    local time = function() return v and ICT:DisplayTime(v - GetServerTime()) or "N/A" end
                    start = printTimerMultiView(start, ICT.ResetInfo[k].name, time)
                end
            end
        else
            offset = printSectionTitle(x, offset, "Reset", timerSectionTooltip())

            if not ICT.db.options.collapsible["Reset"] then
                for k, v in ICT:spairs(ICT.db.reset) do
                    if ICT.db.options.reset[k] then
                        local time = function() return v and ICT:DisplayTime(v - GetServerTime()) or "N/A" end
                        offset = printTimerSingleView(x, offset, ICT.ResetInfo[k].name, time)
                    end
                end
            end
            hideCell(x, offset)
        end
    end
    return offset
end

local function getSelectedOrDefault()
    if not ICT.db.players[ICT.selectedPlayer] then
        ICT.selectedPlayer = ICT:GetFullName()
    end
    return ICT.db.players[ICT.selectedPlayer]
end

local function display(player, x)
    local offset = 1
    local name = string.format("|T%s:12|t%s", ICT.ClassIcons[player.class], Player.GetName(player))
    local cell = printCell(x, offset, name, getClassColor(player))
    addTooltip(cell, playerTooltip(player))
    offset = printResetTimers(x, offset)
    offset = printInstances("Dungeons", player.dungeons, x, offset)
    offset = printInstances("Raids", player.raids, x, offset)
    offset = printInstances("Old Raids", player.oldRaids, x, offset)
    offset = printQuests(player, x, offset)
    offset = printCurrency(player, x, offset)
    -- Hide any old frames.
    for i=offset,displayY do
        hideCell(x, i)
    end
    return offset
end

-- Prints out selected players with associated instances and currency infromation.
function ICT:DisplayPlayer()
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

    -- Hide any old frames.
    for i=x+1,displayX do
        for j=1,displayY do
            hideCell(i, j)
        end
    end
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
                info.text = Player.GetName(player)
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
    local tooltip = createTooltip("ICTResetFrame", "Reset size and position")
    addTooltip(button, tooltip)
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

-- Possible idea for headings on multi view
-- local button = CreateFrame("Button", nil, ICT.frame)
-- button:SetSize(cellWidth+ 100, cellHeight+100)
-- button:SetPoint("TOPLEFT", x * cellWidth + 10, 10)
-- local cell = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
-- cell:SetPoint("LEFT")
-- cell:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
-- cell:SetText(string.format("|c%s%s|r", getClassColor(player), Player.GetName(player)))