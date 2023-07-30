local addOnName, ICT = ...

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0", true)
local Player = ICT.Player
local Options = ICT.Options
local Instances = ICT.Instances
local availableColor = "FFFFFFFF"
local titleColor = "FFFFFF00"
local lockedColor = "FFFF00FF"
local unavailableColor = "FFFF0000"
local nameColor = "FF00FF00"
local cellWidth = 160
local cellHeight = 10
-- In the future we may want to display mutliple players at once.
local numCells = 1

local defaultWidth = cellWidth * numCells + 60
local defaultHeight = 600
local defaultX = 400
local defaultY = 800
local tickers = {}
local displayLength = 0

local function drawFrame(x, y, width, height)
    ICT.db.X = x or defaultX
	ICT.db.Y = y or defaultY
    ICT.db.width = width or defaultWidth
    ICT.db.height = height or defaultHeight
    ICT.frame:ClearAllPoints()
    ICT.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ICT.db.X, ICT.db.Y)
    ICT.frame:SetSize(ICT.db.width, ICT.db.height)
end

local function hideTooltipOnLeave(self, motion)
    GameTooltip:Hide()
end

local function enableMoving(frame, callback)
    frame:SetMovable(true)
    frame:SetResizable(true)
	frame:SetScript("OnMouseDown", frame.StartMoving)
	frame:SetScript("OnMouseUp", function(self)
        ICT.db.x = ICT.frame:GetLeft()
        ICT.db.y = ICT.frame:GetTop()
        frame:StopMovingOrSizing(self)
    end)
end

function ICT:CreateAddOn()
    local f = CreateFrame("Frame", "InstanceCurrencyTracker", UIParent, "BasicFrameTemplateWithInset")
    ICT.frame = f

    f:SetFrameStrata("HIGH")
    drawFrame(ICT.db.X, ICT.db.y, ICT.db.width, ICT.db.height)
    enableMoving(f)
    f:SetAlpha(.5)
    f:Hide()

    ICT:ResizeFrameButton()
    ICT:ResetFrameButton()
    ICT.selectedPlayer = ICT:GetFullName()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(addOnName)
    title:SetAlpha(1)
    title:SetIgnoreParentAlpha(true)
    title:SetPoint("TOP", -10, -6)

    -- adding a scrollframe (includes basic scrollbar thumb/buttons and functionality)
    local scrollFrame = CreateFrame("ScrollFrame", "ICTScroll", f, "UIPanelScrollFrameTemplate")
    f.scrollFrame = scrollFrame
    scrollFrame:SetAlpha(1)
    scrollFrame:SetIgnoreParentAlpha(true)
    -- Points taken from example online that avoids writing into the frame.
    scrollFrame:SetPoint("TOPLEFT", 12, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -34, 36)

    -- creating a scrollChild to contain the content
    local scrollChild = CreateFrame("Frame", "ICTContent", scrollFrame)
    scrollChild:SetSize(100, 100)
    scrollChild:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild.cells = {}

    ICT:CreatePlayerDropdown()
    Options:CreateOptionDropdown()
    ICT:DisplayPlayer()
end

local function getContent()
    return ICT.frame.scrollFrame:GetScrollChild()
end

-- Gets the associated cell or create it if it doesn't exist yet.
local function getCell(x, y)
    local content = getContent()
    local name = string.format("cell(%s, %s)", x, y)
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
        cell.value = cell:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cell.value:SetPoint("LEFT")
    end
    -- TODO We could make font and size an option here.
    cell.value:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    cell.value:SetText(string.format("|c%s%s|r", color, text))
    cell:Show()
    return cell
end

local function hideCell(x, y)
    getCell(x, y):Hide()
end

-- Tooltip for instance information upon entering the cell.
local function instanceTooltipOnEnter(key, instance)
    return function(self, motion)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local instanceColor = instance.locked and lockedColor or nameColor
        GameTooltip:AddLine(instance.name, ICT:hex2rgb(instanceColor))
        local info = ICT.InstanceInfo[instance.id]

        -- Display the available encounters for the instance.
        local encountersDone = info.numEncounters - (instance.encounterProgress or 0)
        GameTooltip:AddLine(string.format("Encounters: %s/%s", encountersDone, info.numEncounters), ICT:hex2rgb(availableColor))

        -- Display which players are locked or not for this instance.
        for _, player in ICT:spairsByValue(ICT.db.players, PlayerSort) do
            local playerInstance = Instances:GetInstanceByName(player, key) or { locked = false }
            local playerColor = playerInstance.locked and lockedColor or availableColor
            GameTooltip:AddLine(Player:GetName(player), ICT:hex2rgb(playerColor))
        end

        -- Display all available currency for the instance.
        for tokenId, _ in ICT:spairs(info.tokenIds or {}, ICT.CurrencySort) do
            -- Onyxia 40 is reused and has 0 emblems so skip currency.
            local max = info.maxEmblems(instance, tokenId)
            if ICT.db.options.currency[tokenId] and max ~= 0 then
                local available = instance.available[tokenId] or max
                local currency = ICT:GetCurrencyName(tokenId)
                local text = string.format("%s: |c%s%s/%s|r", currency, availableColor, available, max)
                GameTooltip:AddLine(text, ICT:hex2rgb(titleColor))
            end
        end
        GameTooltip:Show()
    end
end

local function updateSectionTitle(x, offset, title)
    local collapsed = ICT.db.options.collapsible[title]
    local icon = collapsed and "Interface\\Buttons\\UI-PlusButton-UP" or "Interface\\Buttons\\UI-MinusButton-UP:12"
    local titleText = string.format("|T%s:12|t%s", icon, title)
    return printCell(x, offset, titleText, titleColor)
end

local function printSectionTitle(x, offset, title, tooltip)
    offset = offset + 1
    local cell = updateSectionTitle(x, offset, title)
    cell:SetScript(
        "OnClick",
        function()
            ICT.db.options.collapsible[title] = not ICT.db.options.collapsible[title]
            updateSectionTitle(x, offset, title)
            ICT:DisplayPlayer()
        end
    )
    cell:SetScript("OnEnter", tooltip)
    cell:SetScript("OnLeave", hideTooltipOnLeave)
    return offset + 1
end

local function instanceSectionTooltip(self, motion)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Instance Color Codes")
    GameTooltip:AddLine("Available", ICT:hex2rgb(availableColor))
    GameTooltip:AddLine("Locked", ICT:hex2rgb(lockedColor))
    GameTooltip:Show()
end

-- Prints all the instances with associated tooltips.
local function printInstances(title, instances, x, offset)
    if not Options:showInstances(instances) then
        return offset
    end

    offset = printSectionTitle(x, offset, title, instanceSectionTooltip)

    -- If the section is collapsible then short circuit here.
    if not ICT.db.options.collapsible[title] then
        for key, instance in ICT:spairsByValue(instances, ICT.InstanceSort) do
            if Options.showInstance(instance) then
                local color = instance.locked and lockedColor or availableColor
                local cell = printCell(x, offset, instance.name, color)
                cell:SetScript("OnEnter", instanceTooltipOnEnter(key, instance))
                cell:SetScript("OnLeave", hideTooltipOnLeave)
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
    for _, instance in ICT:spairsByValue(instances, ICT.InstanceSort) do
        local info = ICT.InstanceInfo[instance.id]
        local max = info.maxEmblems(instance, tokenId)
        -- Onyxia 40 is reused and has 0 emblems so skip currency.
        if Options.showInstance(instance) and info.tokenIds[tokenId] and max ~= 0 then
            if printTitle then
                printTitle = false
                GameTooltip:AddLine(title, ICT:hex2rgb(titleColor))
            end
            -- Displays available currency out of the total currency for this instance.
            local color = instance.locked and lockedColor or availableColor
            local available = instance.available[tokenId] or max
            GameTooltip:AddLine(string.format("%s: %s/%s", instance.name, available, max), ICT:hex2rgb(color))
        end
    end
end

local function getQuestColor(player, quest)
    return (not player.quests.prereq[quest.key] and unavailableColor) or (player.quests.completed[quest.key] and lockedColor or availableColor)
end

local function printQuestsForCurrency(player, tokenId)
    local printTitle = true
    if ICT.db.options.showQuests then
        for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player)) do
            if quest.tokenId == tokenId and (player.quests.prereq[quest.key] or ICT.db.options.allQuests) then
                if printTitle then
                    printTitle = false
                    GameTooltip:AddLine("Quests", ICT:hex2rgb(titleColor))
                end
                local color = getQuestColor(player, quest)
                GameTooltip:AddLine(string.format("%s: %s", quest.name(player), quest.seals), ICT:hex2rgb(color))
            end
        end
    end
end

-- Tooltip for currency information upon entering the cell.
local function currencyTooltipOnEnter(selectedPlayer, tokenId)
    return function(self, motion)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(ICT:GetCurrencyName(tokenId), ICT:hex2rgb(titleColor))

        for _, player in ICT:spairsByValue(ICT.db.players, PlayerSort) do
            local available = Player:AvailableCurrency(player, tokenId)
            local text = string.format("%s %s (%s)", Player:GetName(player), player.currency.wallet[tokenId] or "n/a", available)
            GameTooltip:AddLine(text, ICT:hex2rgb(availableColor))

        end
        if ICT.db.options.verboseCurrencyTooltip then
            printInstancesForCurrency("Dungeons", selectedPlayer.dungeons, tokenId)
            printInstancesForCurrency("Raids", selectedPlayer.raids, tokenId)
            printQuestsForCurrency(selectedPlayer, tokenId)
        end
        GameTooltip:Show()
    end
end

-- Prints currency with multi line information.
local function printCurrencyVerbose(player, tokenId, x, offset)
    local currency = ICT:GetCurrencyName(tokenId)
    local cell = printCell(x, offset, currency, titleColor)
    cell:SetScript("OnEnter", currencyTooltipOnEnter(player, tokenId))
    cell:SetScript("OnLeave", hideTooltipOnLeave)
    offset = offset + 1
    local available = Player:AvailableCurrency(player, tokenId)
    cell = printCell(x, offset, "Available  " .. available, availableColor)
    cell:SetScript("OnEnter", currencyTooltipOnEnter(player, tokenId))
    cell:SetScript("OnLeave", hideTooltipOnLeave)
    offset = offset + 1
    local current = player.currency.wallet[tokenId] or "n/a"
    cell = printCell(x, offset, "Current     " .. current, availableColor)
    cell:SetScript("OnEnter", currencyTooltipOnEnter(player, tokenId))
    cell:SetScript("OnLeave", hideTooltipOnLeave)
    offset = offset + 1
    hideCell(x, offset)
    return offset
end

-- Prints currency single line information.
local function printCurrencyShort(player, tokenId, x, offset)
    local currency = ICT:GetCurrencyName(tokenId)
    local current = player.currency.wallet[tokenId] or "n/a"
    local available = Player:AvailableCurrency(player, tokenId)
    local text = string.format("%s |c%s%s (%s)|r", currency, availableColor, current, available)
    local cell = printCell(x, offset, text, titleColor)
    cell:SetScript("OnEnter", currencyTooltipOnEnter(player, tokenId))
    cell:SetScript("OnLeave", hideTooltipOnLeave)
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

local function questTooltipOnEnter(name, quest)
    return function(self, motion)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(name, ICT:hex2rgb(nameColor))
        local currency = ICT:GetCurrencyName(quest.tokenId)
        GameTooltip:AddLine(string.format("%s: %s", currency, quest.seals), ICT:hex2rgb(availableColor))

        for _, player in ICT:spairsByValue(ICT.db.players, PlayerSort) do
            local color = getQuestColor(player, quest)
            GameTooltip:AddLine(Player:GetName(player), ICT:hex2rgb(color))
        end
        GameTooltip:Show()
    end
end

local function isQuestAvailable(player)
    return function(quest)
        return ICT.db.options.currency[quest.tokenId] and (player.quests.prereq[quest.key] or ICT.db.options.allQuests)
    end
end

local function questSectionTooltip(self, motion)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Quest Color Codes")
    GameTooltip:AddLine("Available", ICT:hex2rgb(availableColor))
    GameTooltip:AddLine("Completed", ICT:hex2rgb(lockedColor))
    GameTooltip:AddLine("Missing Prerequesite", ICT:hex2rgb(unavailableColor))
    GameTooltip:Show()
end

local function printQuests(player, x, offset)
    if ICT.db.options.showQuests then
        if ICT:containsAnyValue(ICT.QuestInfo, isQuestAvailable(player)) then
            offset = printSectionTitle(x, offset, "Quests", questSectionTooltip)
        end
        if not ICT.db.options.collapsible["Quests"] then
            -- sort by token then name...
            for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player)) do
                if isQuestAvailable(player)(quest) then
                    local color = getQuestColor(player, quest)
                    local name = quest.name(player)
                    local cell = printCell(x, offset, name, color)
                    cell:SetScript("OnEnter", questTooltipOnEnter(name, quest))
                    cell:SetScript("OnLeave", hideTooltipOnLeave)
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

local function timerSectionTooltip(self, motion)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Reset Timer")
    local r, g, b = ICT:hex2rgb(availableColor)
    GameTooltip:AddLine("Countdown to the next reset respectively for 1, 3, 5 and 7 days.", r, g, b, true)
    GameTooltip:AddLine("\n")
    GameTooltip:AddLine("Note: 3 and 5 day resets need a known lockout to calculate from as Blizzard doesn't provide a way through their API.", r, g, b, true)
    GameTooltip:Show()
end

local function printTimer(x, offset, title, time)
    printCell(x, offset, title .. "  " .. time(), availableColor)
    cancelTicker(title)
    tickers[title] = C_Timer.NewTicker(1, function () printCell(x, offset, title .. "  " .. time(), availableColor) end)
    return offset + 1
end

local function cancelResetTimerTickers()
    for k, _ in ICT:spairs(ICT.db.reset) do
        cancelTicker(ICT.ResetInfo[k].name)
    end
end

local function printResetTimers(x, offset)
    cancelResetTimerTickers()
    if ICT:containsAnyValue(ICT.db.options.reset) then
        offset = printSectionTitle(x, offset, "Reset", timerSectionTooltip)

        if not ICT.db.options.collapsible["Reset"] then
            for k, v in ICT:spairs(ICT.db.reset) do
                if ICT.db.options.reset[k] then
                    local time = function() return v and ICT:DisplayTime(v - GetServerTime()) or "N/A" end
                    offset = printTimer(x, offset, ICT.ResetInfo[k].name, time)
                end
            end
        end
        hideCell(x, offset)
    end
    return offset
end

local function getSelectedOrDefault()
    if not ICT.db.players[ICT.selectedPlayer] then
        ICT.selectedPlayer = ICT:GetFullName()
    end
    return ICT.db.players[ICT.selectedPlayer]
end

-- Prints out selected players with associated instances and currency infromation.
function ICT:DisplayPlayer()
    local player = getSelectedOrDefault()
    local x = 1
    local offset = 1
    local name = string.format("|T%s:12|t%s", ICT.ClassIcons[player.class], Player:GetName(player))
    printCell(x, offset, name, nameColor)
    offset = printResetTimers(x, offset)
    offset = printInstances("Dungeons", player.dungeons, x, offset)
    offset = printInstances("Raids", player.raids, x, offset)
    offset = printInstances("Old Raids", player.oldRaids, x, offset)
    offset = printQuests(player, x, offset)
    offset = printCurrency(player, x, offset)
    for i=offset,displayLength do
        hideCell(x, i)
    end
    LibDD:UIDropDownMenu_SetText(ICT.frame.playerDropdown, Player:GetName(player))
    displayLength = offset
end

function ICT:CreatePlayerDropdown()
    local playerDropdown = LibDD:Create_UIDropDownMenu("PlayerSelection", ICT.frame)
    ICT.frame.playerDropdown = playerDropdown
    playerDropdown:SetPoint("TOP", ICT.frame, 0, -30);
    playerDropdown:SetAlpha(1)
    playerDropdown:SetIgnoreParentAlpha(true)

    -- Width set to slightly smaller than parent frame.
    LibDD:UIDropDownMenu_SetWidth(playerDropdown, 160)

    LibDD:UIDropDownMenu_Initialize(
        playerDropdown,
        function()
            local info = LibDD:UIDropDownMenu_CreateInfo()
            for _, player in ICT:spairsByValue(ICT.db.players, PlayerSort) do
                info.text = Player:GetName(player)
                info.value = player.fullName
                info.checked = ICT.selectedPlayer == player.fullName
                info.func = function(self)
                    ICT.selectedPlayer = self.value
                    LibDD:UIDropDownMenu_SetText(playerDropdown, Player:GetName(ICT.db.players[ICT.selectedPlayer]))
                    ICT:DisplayPlayer()
                end
                LibDD:UIDropDownMenu_AddButton(info)
            end
        end
    )
end

function ICT:ResetFrameButton()
    local button = CreateFrame("Button", "ResetSizeAndPosition", ICT.frame)
    button:SetSize(15, 15)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetPoint("TOPLEFT", 2, -4)
    button:RegisterForClicks("AnyUp")
    button:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
    button:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
    button:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
    button:SetScript("OnEnter", function(self, motion)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Reset size and position")
        GameTooltip:Show()
    end)
    button:SetScript("OnClick", function() drawFrame(defaultX, defaultY, defaultWidth, defaultHeight) end)
    button:SetScript("OnLeave", hideTooltipOnLeave)
end

function ICT:ResizeFrameButton()
    local button = CreateFrame("BUTTON", "some_cool_name", ICT.frame, "PanelResizeButtonTemplate")
    button:Init(ICT.frame, 200, defaultHeight - 200, defaultWidth + 200, defaultHeight + 200)
    button:SetSize(20, 20)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetPoint("BottomRight", 0, 0)
end