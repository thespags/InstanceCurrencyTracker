Emblems = {}
AddOnName = "Instance and Emblem Tracker"
local classIcons = {
    ["WARRIOR"] = 626008,
    ["PALADIN"] = 626003,
    ["HUNTER"] = 626000,
    ["ROGUE"] = 626005,
    ["PRIEST"] = 626004,
    ["DEATHKNIGHT"] = 135771,
    ["SHAMAN"] = 626006,
    ["MAGE"] = 626001,
    ["WARLOCK"] = 626007,
    ["DRUID"] = 625999
}

local availableColor = "FFFFFFFF"
local titleColor = "FFFFFF00"
local lockedColor = "FFFF00FF"
local nameColor = "FF00FF00"

local CELL_WIDTH = 160
local CELL_HEIGHT = 10
local NUM_CELLS = 1 -- cells per row
local player = Utils:GetFullName()

local f = CreateFrame("Frame", "InstanceCurrencyTracker", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(CELL_WIDTH * NUM_CELLS + 60, 600)
f:SetPoint("CENTER", 150, 0)
f:SetMovable(true)
f:SetScript("OnMouseDown" ,f.StartMoving)
f:SetScript("OnMouseUp", f.StopMovingOrSizing)
f:SetAlpha(.5)
f:SetToplevel(true)
local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetText(AddOnName)
title:SetPoint("TOP", -10, -6)

-- adding a scrollframe (includes basic scrollbar thumb/buttons and functionality)
f.scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
-- Set alpha to 1 for text.
f.scrollFrame:SetAlpha(1)
f.scrollFrame:SetIgnoreParentAlpha(true)

-- Points taken from example online that avoids writing into
f.scrollFrame:SetPoint("TOPLEFT", 12, -32)
f.scrollFrame:SetPoint("BOTTOMRIGHT", -34, 8)

-- creating a scrollChild to contain the content
f.scrollFrame.scrollChild = CreateFrame("Frame", nil, f.scrollFrame)
f.scrollFrame.scrollChild:SetSize(100, 100)
f.scrollFrame.scrollChild:SetPoint("TOPLEFT", 5, -5)
f.scrollFrame:SetScrollChild(f.scrollFrame.scrollChild)

-- adding content to the scrollChild
local content = f.scrollFrame.scrollChild
content.cells = {}

-- Gets the associated cell or create it if it doesn't exist yet.
local function getCell(x, y)
    local name = string.format("cell(%s, %s)", x, y)
    if not content.cells[name] then
        local button = CreateFrame("Button", nil, content)
        button:SetSize(CELL_WIDTH, CELL_HEIGHT)
        button:SetPoint("TOPLEFT", (x - 1) * CELL_WIDTH, -(y - 1) * CELL_HEIGHT)
        content.cells[name] = button
    end
    return content.cells[name]
end

-- Prints text in the associated cell.
local function printCell(x, y, color, text)
    local cell = getCell(x, y)
    -- Create the string if necessary.
    if not cell.value then
        cell.value = cell:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cell.value:SetPoint("LEFT")
    end
    -- TODO We could make font and size an option here.
    cell.value:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    cell.value:SetText(string.format("|c%s%s|r", color, text))
    return cell
end

-- Tooltip for instance information upon entering the cell.
local function instanceTooltipOnEnter(name, instance)
    return function(self, motion)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local color = instance.locked and lockedColor or nameColor
        GameTooltip:AddLine(name, Utils:hex2rgb(color))
        local encountersDone = instance.numEncounters - (instance.encounterProgress or 0)
        GameTooltip:AddLine(string.format("Encounters: %s/%s", encountersDone, instance.numEncounters), Utils:hex2rgb(availableColor))
        local staticInstance = StaticInstances[instance.id]
        for k, _ in Utils:spairs(staticInstance.tokenIds or {}, CurrencySort) do
            GameTooltip:AddLine(Utils:GetCurrencyName(k), Utils:hex2rgb(titleColor))
            local max = staticInstance.maxEmblems(instance)
            local available = instance.available[k] or max
            GameTooltip:AddLine(string.format("Currency: %s/%s", available, max), Utils:hex2rgb(availableColor))
        end
        GameTooltip:Show()
    end
end

local function hideTooltipOnLeave(self, motion)
    GameTooltip:Hide()
end

-- Prints all the instances with associated tooltips.
local function printInstances(title, instances, offset, i)
    offset = offset + 1
    printCell(i, offset, titleColor, title)
    for k, v in Utils:spairsByValue(instances, GetLocalizedInstanceName) do
        offset = offset + 1
        local color = v.locked and lockedColor or availableColor
        local cell = printCell(i, offset, color, k)
        cell:SetScript("OnEnter", instanceTooltipOnEnter(k, v))
        cell:SetScript("OnLeave", hideTooltipOnLeave)
    end
    return offset + 1
end

local function printInstancesForCurrency(title, instances, tokenId)
    -- Only print the title if there exists an instance for this token.
    local printTitle = true
    for k, v in Utils:spairsByValue(instances, GetLocalizedInstanceName) do
        if StaticInstances[v.id].tokenIds[tokenId] then
            if printTitle then
                printTitle = false
                GameTooltip:AddLine(title, Utils:hex2rgb(titleColor))
            end
            local color = v.locked and lockedColor or availableColor
            local max = StaticInstances[v.id].maxEmblems(v)
            local available = v.available[tokenId] or max
            GameTooltip:AddLine(string.format("%s: %s/%s", k, available, max), Utils:hex2rgb(color))
        end
    end
end

-- Tooltip for currency information upon entering the cell.
local function currencyTooltipOnEnter(player, tokenId)
    return function(self, motion)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(Utils:GetCurrencyName(tokenId), Utils:hex2rgb(titleColor))
        printInstancesForCurrency("Dungeons", player.dungeons, tokenId)
        printInstancesForCurrency("Raid", player.raids, tokenId)
        GameTooltip:Show()
    end
end

-- Prints currency with multi line information.
local function printCurrencyVerbose(player, tokenId, offset, i)
    offset = offset + 1
    local currency = Utils:GetCurrencyName(tokenId)
    local cell = printCell(i, offset, titleColor, currency)
    cell:SetScript("OnEnter", currencyTooltipOnEnter(player, tokenId))
    cell:SetScript("OnLeave", hideTooltipOnLeave)
    offset = offset + 1
    local available = (player.currency.weekly[tokenId] + player.currency.daily[tokenId])  or "n/a"
    cell = printCell(i, offset, availableColor, "Available  " .. available)
    cell:SetScript("OnEnter", currencyTooltipOnEnter(player, tokenId))
    cell:SetScript("OnLeave", hideTooltipOnLeave)
    offset = offset + 1
    local current = player.currency.wallet[tokenId] or "n/a"
    cell = printCell(i, offset, availableColor, "Current     " .. current)
    cell:SetScript("OnEnter", currencyTooltipOnEnter(player, tokenId))
    cell:SetScript("OnLeave", hideTooltipOnLeave)
    return offset + 1
end

-- Prints currency single line information.
-- TODO unused.
local function printCurrencyShort(player, tokenId, offset, i)
    offset = offset + 1
    local currency = Utils:GetCurrencyName(tokenId)
    local current = player.currency.wallet[tokenId] or "n/a"
    local available = (player.currency.weekly[tokenId] + player.currency.daily[tokenId]) or "n/a"
    local text = string.format("%s |c%s%s (%s)|r", currency, availableColor, current, available)
    local cell = printCell(i, offset, text)
    cell:SetScript("OnEnter", currencyTooltipOnEnter(player, tokenId))
    cell:SetScript("OnLeave", hideTooltipOnLeave)
    return offset + 1
end

-- Sets the dropdown width to the largest item string width.
local function maxWidth(db, dropdown)
    local string = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    string:SetPoint("TOPLEFT", 20, 10)
    local max = 0
    for _, v in pairs(db.players) do
        string:SetText(v.fullName)
        if max < string:GetStringWidth() then
            max = string:GetStringWidth()
        end
    end
    -- Remove the text now for sizing.
    string:SetText("")
    return max
end

local function createPlayerDropdown(db)
    local dropdown = CreateFrame("Frame", "PlayerSelection", f, 'UIDropDownMenuTemplate')
    dropdown:SetPoint("TOPLEFT", f);
    dropdown:SetAlpha(1)
    dropdown:SetIgnoreParentAlpha(true)

    UIDropDownMenu_SetWidth(dropdown, maxWidth(db, dropdown))
    local currentName = Utils:GetFullName()
    UIDropDownMenu_SetText(dropdown, currentName, currentName)

    UIDropDownMenu_Initialize(
        dropdown,
        function()
            local info = UIDropDownMenu_CreateInfo()
            for _, v in pairs(db.players) do
                info.text = v.fullName
                info.isNotRadio = true
                info.func = function(b)
                    UIDropDownMenu_SetText(dropdown, b.value, b.value)
                    player = b.value
                    Foobar(db)
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    )
end

-- TODO rename this
-- Prints out selected players with associated instances and currency infromation.
-- TODO do we want an option to display all users ignoring select field?
function Foobar(db)
    local v = db.players[player]
    local i = 1
    local offset = 1
    printCell(i, offset, nameColor, v.name)
    offset = printInstances("Dungeons", v.dungeons, offset, i)
    offset = printInstances("Raids", v.raids, offset, i)
    local printCurrency = true and printCurrencyVerbose or printCurrencyShort
    for tokenId, _ in Utils:spairs(Currency, CurrencySort) do
        offset = printCurrency(v, tokenId, offset, i)
    end
    createPlayerDropdown(db)
    f:Show()
end