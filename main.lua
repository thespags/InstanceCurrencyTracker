local addOnName, ICT = ...

local Player = ICT.Player
local Options = ICT.Options
local availableColor = "FFFFFFFF"
local titleColor = "FFFFFF00"
local lockedColor = "FFFF00FF"
local unavailableColor = "FFFF0000"
local nameColor = "FF00FF00"

local CELL_WIDTH = 160
local CELL_HEIGHT = 10
local NUM_CELLS = 1
local db

-- Currently selected player plus the length.
local selectedPlayer = ICT:GetFullName()
local content
local playerDropdown
local tickers = {}
local displayLength = 0

function ICT:CreateAddOn()
    db = InstanceCurrencyDB
    local f = CreateFrame("Frame", "InstanceCurrencyTracker", LFGParentFrame, "BasicFrameTemplateWithInset")
    f:SetSize(CELL_WIDTH * NUM_CELLS + 60, 600)
    f:SetPoint("CENTER", 300, 0)
    f:SetMovable(true)
    f:SetScript("OnMouseDown", f.StartMoving)
    f:SetScript("OnMouseUp", f.StopMovingOrSizing)
    f:SetAlpha(.5)
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(addOnName)
    title:SetAlpha(1)
    title:SetIgnoreParentAlpha(true)
    title:SetPoint("TOP", -10, -6)

    -- adding a scrollframe (includes basic scrollbar thumb/buttons and functionality)
    f.scrollFrame = CreateFrame("ScrollFrame", "ICTScroll", f, "UIPanelScrollFrameTemplate")
    -- Set alpha to 1 for text.
    f.scrollFrame:SetAlpha(1)
    f.scrollFrame:SetIgnoreParentAlpha(true)

    -- Points taken from example online that avoids writing into the frame.
    f.scrollFrame:SetPoint("TOPLEFT", 12, -60)
    f.scrollFrame:SetPoint("BOTTOMRIGHT", -34, 32)

    -- creating a scrollChild to contain the content
    f.scrollFrame.scrollChild = CreateFrame("Frame", "ICTContent", f.scrollFrame)
    f.scrollFrame.scrollChild:SetSize(100, 100)
    f.scrollFrame.scrollChild:SetPoint("TOPLEFT", 5, -5)
    f.scrollFrame:SetScrollChild(f.scrollFrame.scrollChild)

    content = f.scrollFrame.scrollChild
    content.cells = {}
    ICT:CreatePlayerDropdown(f)
    Options:CreateOptionDropdown(f)
    ICT:DisplayPlayer()
    return f
end

-- Gets the associated cell or create it if it doesn't exist yet.
local function getCell(x, y)
    local name = string.format("cell(%s, %s)", x, y)
    if not content.cells[name] then
        local button = CreateFrame("Button", name, content)
        button:SetSize(CELL_WIDTH, CELL_HEIGHT)
        button:SetPoint("TOPLEFT", (x - 1) * CELL_WIDTH, -(y - 1) * CELL_HEIGHT)
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
        local instanceInfo = ICT.InstanceInfo[instance.id]

        -- Display the available encounters for the instance.
        local encountersDone = instanceInfo.numEncounters - (instance.encounterProgress or 0)
        GameTooltip:AddLine(string.format("Encounters: %s/%s", encountersDone, instanceInfo.numEncounters), ICT:hex2rgb(availableColor))

        -- Display which players are locked or not for this instance.
        for _, player in ICT:spairsByValue(db.players, PlayerSort) do
            local playerInstance = Player:GetInstance(player, key)
            local playerColor = playerInstance.locked and lockedColor or availableColor
            GameTooltip:AddLine(Player:GetName(player), ICT:hex2rgb(playerColor))
        end

        -- Display all available currency for the instance.
        for tokenId, _ in ICT:spairs(instanceInfo.tokenIds or {}, ICT.CurrencySort) do
            if db.options.currency[tokenId] then
                local max = instanceInfo.maxEmblems(instance, tokenId)
                local available = instance.available[tokenId] or max
                local currency = ICT:GetCurrencyName(tokenId)
                local text = string.format("%s: |c%s%s/%s|r", currency, availableColor, available, max)
                GameTooltip:AddLine(text, ICT:hex2rgb(titleColor))
            end
        end
        GameTooltip:Show()
    end
end

local function hideTooltipOnLeave(self, motion)
    GameTooltip:Hide()
end

local function updateSectionTitle(x, offset, title)
    local collapsed = db.options.collapsible[title]
    local icon = collapsed and "Interface\\Buttons\\UI-PlusButton-UP" or "Interface\\Buttons\\UI-MinusButton-UP:12"
    local titleText = string.format("|T%s:12|t%s", icon, title)
    return printCell(x, offset, titleText, titleColor)
end

local function printSectionTitle(x, offset, title, f)
    offset = offset + 1
    updateSectionTitle(x, offset, title):SetScript(
        "OnClick",
        function()
            db.options.collapsible[title] = not db.options.collapsible[title]
            updateSectionTitle(x, offset, title)
            ICT:DisplayPlayer()
        end
    )
    return offset + 1
end

-- Prints all the instances with associated tooltips.
local function printInstances(title, instances, x, offset)
    if not Options:showInstances(instances) then
        return offset
    end

    offset = printSectionTitle(x, offset, title)

    -- If the section is collapsible then short circuit here.
    if not db.options.collapsible[title] then
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
        if Options.showInstance(instance) and ICT.InstanceInfo[instance.id].tokenIds[tokenId] then
            if printTitle then
                printTitle = false
                GameTooltip:AddLine(title, ICT:hex2rgb(titleColor))
            end
            -- Displays available currency out of the total currency for this instance.
            local color = instance.locked and lockedColor or availableColor
            local max = ICT.InstanceInfo[instance.id].maxEmblems(instance, tokenId)
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
    for _, quest in ICT:spairsByValue(ICT.QuestInfo, ICT.QuestSort(player)) do
        if quest.tokenId == tokenId and (player.quests.prereq[quest.key] or db.options.allQuests) then
            if printTitle then
                printTitle = false
                GameTooltip:AddLine("Quests", ICT:hex2rgb(titleColor))
            end
            local color = getQuestColor(player, quest)
            GameTooltip:AddLine(string.format("%s: %s", quest.name(player), quest.seals), ICT:hex2rgb(color))
        end
    end
end

-- Tooltip for currency information upon entering the cell.
local function currencyTooltipOnEnter(selectedPlayer, tokenId)
    return function(self, motion)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(ICT:GetCurrencyName(tokenId), ICT:hex2rgb(titleColor))

        for _, player in ICT:spairsByValue(db.players, PlayerSort) do
            local available = Player:AvailableCurrency(player, tokenId)
            local text = string.format("%s %s (%s)", Player:GetName(player), player.currency.wallet[tokenId] or "n/a", available)
            GameTooltip:AddLine(text, ICT:hex2rgb(availableColor))

        end
        if not db.options.simpleCurrencyTooltip then
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
    if ICT:containsAnyValue(db.options.currency) then
        offset = printSectionTitle(x, offset, "Currency")
    end
    if not db.options.collapsible["Currency"] then
        local printCurrency = db.options.verboseCurrency and printCurrencyVerbose or printCurrencyShort
        for tokenId, _ in ICT:spairs(ICT.CurrencyInfo, ICT.CurrencySort) do
            if db.options.currency[tokenId] then
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

        for _, player in ICT:spairsByValue(db.players, PlayerSort) do
            local color = getQuestColor(player, quest)
            GameTooltip:AddLine(Player:GetName(player), ICT:hex2rgb(color))
        end
        GameTooltip:Show()
    end
end

local function isQuestAvailable(player)
    return function(quest)
        return db.options.currency[quest.tokenId] and (player.quests.prereq[quest.key] or db.options.allQuests)
    end
end

local function printQuests(player, x, offset)
    if not db.options.hideQuests then
        if ICT:containsAnyValue(ICT.QuestInfo, isQuestAvailable(player)) then
            offset = printSectionTitle(x, offset, "Quests")
        end
        if not db.options.collapsible["Quests"] then
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

local function printTimer(x, offset, title, f)
    printCell(x, offset, title .. "  " .. f(), availableColor)
    cancelTicker(title)
    tickers[title] = C_Timer.NewTicker(1, function () printCell(x, offset, title .. "  " .. f(), availableColor) end)
    return offset + 1
end

local function getDailyResetTime()
    return ICT:DisplayTime(C_DateAndTime.GetSecondsUntilDailyReset())
end

local function getWeeklyResetTime()
    return ICT:DisplayTime(C_DateAndTime.GetSecondsUntilWeeklyReset())
end

local function printResetTimers(x, offset)
    if not db.options.hideResetTimers then
        offset = printSectionTitle(x, offset, "Reset")

        if db.options.collapsible["Reset"] then
            cancelTicker("Daily")
            cancelTicker("Weekly")
        else
            offset = printTimer(x, offset, "Daily", getDailyResetTime)
            offset = printTimer(x, offset, "Weekly", getWeeklyResetTime)
        end
        hideCell(x, offset)
    else
        cancelTicker("Daily")
        cancelTicker("Weekly")
    end
    return offset
end

-- Prints out selected players with associated instances and currency infromation.
function ICT:DisplayPlayer()
    local player = (db or InstanceCurrencyDB).players[selectedPlayer]
    if not player then
        return
    end
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
    UIDropDownMenu_SetText(playerDropdown, Player:GetName(player))
    displayLength = offset
end

function ICT:CreatePlayerDropdown(f)
    playerDropdown = CreateFrame("Frame", "PlayerSelection", f, 'UIDropDownMenuTemplate')
    playerDropdown:SetPoint("TOP", f, 0, -30);
    playerDropdown:SetAlpha(1)
    playerDropdown:SetIgnoreParentAlpha(true)

    -- Width set to slightly smaller than parent frame.
    UIDropDownMenu_SetWidth(playerDropdown, 180)

    UIDropDownMenu_Initialize(
        playerDropdown,
        function()
            local info = UIDropDownMenu_CreateInfo()
            for _, player in ICT:spairsByValue(db.players, PlayerSort) do
                info.text = Player:GetName(player)
                info.value = player.fullName
                info.checked = selectedPlayer == player.fullName
                info.isNotRadio = true
                info.func = function(self)
                    selectedPlayer = self.value
                    UIDropDownMenu_SetText(playerDropdown, Player:GetName(db.players[selectedPlayer]))
                    ICT:DisplayPlayer()
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    )
end