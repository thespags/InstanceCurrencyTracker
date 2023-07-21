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
local NUM_CELLS = 1
local player = Utils:GetFullName()

local content

function CreateAddOn(db)
    local f = CreateFrame("Frame", "InstanceCurrencyTracker", LFGParentFrame, "BasicFrameTemplateWithInset")
    f:SetSize(CELL_WIDTH * NUM_CELLS + 60, 600)
    f:SetPoint("CENTER", 300, 0)
    f:SetMovable(true)
    f:SetScript("OnMouseDown", f.StartMoving)
    f:SetScript("OnMouseUp", f.StopMovingOrSizing)
    f:SetAlpha(.5)
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(AddOnName)
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
    f.scrollFrame:SetPoint("BOTTOMRIGHT", -34, 8)

    -- creating a scrollChild to contain the content
    f.scrollFrame.scrollChild = CreateFrame("Frame", "ICTContent", f.scrollFrame)
    f.scrollFrame.scrollChild:SetSize(100, 100)
    f.scrollFrame.scrollChild:SetPoint("TOPLEFT", 5, -5)
    f.scrollFrame:SetScrollChild(f.scrollFrame.scrollChild)

    content = f.scrollFrame.scrollChild
    content.cells = {}
    CreatePlayerDropdown(db, f)
    DisplayPlayer(db)
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
        local instanceInfo = InstanceInfo[instance.id]
        local encountersDone = instanceInfo.numEncounters - (instance.encounterProgress or 0)
        GameTooltip:AddLine(string.format("Encounters: %s/%s", encountersDone, instanceInfo.numEncounters), Utils:hex2rgb(availableColor))
        for k, _ in Utils:spairs(instanceInfo.tokenIds or {}, CurrencySort) do
            local max = instanceInfo.maxEmblems(instance, k)
            local available = instance.available[k] or max
            local currency = Utils:GetCurrencyName(k)
            local text = string.format("%s: |c%s%s/%s|r", currency, availableColor, available, max)
            GameTooltip:AddLine(text, Utils:hex2rgb(titleColor))
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
        if InstanceInfo[v.id].tokenIds[tokenId] then
            if printTitle then
                printTitle = false
                GameTooltip:AddLine(title, Utils:hex2rgb(titleColor))
            end
            local color = v.locked and lockedColor or availableColor
            local max = InstanceInfo[v.id].maxEmblems(v, tokenId)
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
-- TODO unused.
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
local function printCurrencyShort(player, tokenId, offset, i)
    offset = offset + 1
    local currency = Utils:GetCurrencyName(tokenId)
    local current = player.currency.wallet[tokenId] or "n/a"
    local available = (player.currency.weekly[tokenId] + player.currency.daily[tokenId]) or "n/a"
    local text = string.format("%s |c%s%s (%s)|r", currency, availableColor, current, available)
    local cell = printCell(i, offset, titleColor, text)
    cell:SetScript("OnEnter", currencyTooltipOnEnter(player, tokenId))
    cell:SetScript("OnLeave", hideTooltipOnLeave)
    return offset
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

function CreatePlayerDropdown(db, f)
    local dropdown = CreateFrame("Frame", "PlayerSelection", f, 'UIDropDownMenuTemplate')
    dropdown:SetPoint("TOP", f, 0, -30);
    dropdown:SetAlpha(1)
    dropdown:SetIgnoreParentAlpha(true)

    UIDropDownMenu_SetWidth(dropdown, maxWidth(db, dropdown) + 20)
    UIDropDownMenu_SetText(dropdown, player)

    UIDropDownMenu_Initialize(
        dropdown,
        function()
            local info = UIDropDownMenu_CreateInfo()
            for _, v in Utils:spairs(db.players) do
                info.text = v.fullName
                info.checked = player == v.fullName
                info.isNotRadio = true
                info.func = function(self)
                    player = self.value
                    UIDropDownMenu_SetText(dropdown, player)
                    DisplayPlayer(db)
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    )
end

-- Prints out selected players with associated instances and currency infromation.
-- TODO do we want an option to display all users ignoring select field?
function DisplayPlayer(db)
    local v = db.players[player]
    local i = 1
    local offset = 1
    printCell(i, offset, nameColor, string.format("|T%s:16|t%s", classIcons[v.class], v.name))
    offset = printInstances("Dungeons", v.dungeons, offset, i)
    offset = printInstances("Raids", v.raids, offset, i)
    local printCurrency = true and printCurrencyShort or printCurrencyVerbose
    for tokenId, _ in Utils:spairs(Currency, CurrencySort) do
        offset = printCurrency(v, tokenId, offset, i)
    end
end

--  -- Create the dropdown, and configure its appearance
--  -- Leaving this for additional option that shouldn't appear.
--  local dropDown = CreateFrame("FRAME", "WPDemoDropDown", UIParent, "UIDropDownMenuTemplate")
--  dropDown:SetPoint("CENTER")
--  dropDown:Hide()
--  UIDropDownMenu_SetWidth(dropDown, 200)
--  UIDropDownMenu_SetText(dropDown, "Old Instance Selection")
--  function continasAll(expansion)
--     for _, instance in pairs(expansion) do
--         if not oldInstances[instance.id] then
--             return false
--         end
--     end
--     return true
--  end

--  oldInstances = {}

--  -- Create and bind the initialization function to the dropdown menu
--  UIDropDownMenu_Initialize(dropDown, 
--     function(self, level, menuList)
--         local info = UIDropDownMenu_CreateInfo()
--         if (level or 1) == 1 then
--             for k, expansion in pairs(Instances.oldRaids) do
--                 info.text = k
--                 info.menuList = k
--                 info.hasArrow = true
--                 info.checked = continasAll(expansion)
--                 info.func = function(self)
--                     for _, instance in pairs(expansion) do
--                         oldInstances[instance.id] = not self.checked
--                     end
--                 end
--                 UIDropDownMenu_AddButton(info)
--             end
--         else
--             for k, v in Utils:spairs(Instances.oldRaids[menuList]) do
--                 info.text = k
--                 info.arg1 = v.id
--                 info.checked = oldInstances[v.id] or false
--                 info.func = function(self, id)
--                     oldInstances[id] = not self.checked
--                 end
--                 UIDropDownMenu_AddButton(info, level)
--                 -- Close the entire menu with this next call
--                 CloseDropDownMenus()
--             end
--         end
--     end
-- )