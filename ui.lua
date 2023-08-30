local addOnName, ICT = ...

local Colors = ICT.Colors
local green = "FF00FF00"
local red = "FFFF0000"
ICT.tooltipTitleColor = green
ICT.availableColor = "FFFFFFFF"
ICT.queuedAvailableColor = "FF90C0FF"
ICT.sectionColor = "FFFFFF00"
ICT.subtitleColor = "FFFFCC00"
ICT.textColor = "FF9CD6DE"
ICT.lockedColor = "FFFF00FF"
ICT.lockedColor = "FF800080"
ICT.queuedLockedColor = "FFFFC0FF"
ICT.unavailableColor = red

local UI = {
    -- Individual cell size for each position in the frame.
    cellWidth = 200,
    cellHeight = 10,
    -- Default frame size.
    defaultWidth = 240,
    defaultHeight = 600,
    -- Default frame location.
    defaultX = 400,
    defaultY = 800,
    -- Tracks the last row and last column seen so we can hide those cells.
    displayX = 0,
    displayY = 0,
    -- Store tickers so we can turn them off on frame reloads.
    tickers = {}
}
ICT.UI = UI

ICT.Tooltips = {}
local Tooltips = ICT.Tooltips

function Tooltips:new(title)
    local o = { text = string.format("|c%s%s|r", ICT.tooltipTitleColor, title)}
    setmetatable(o, self)
    self.__index = self
    return o
end

local function tooltipEnter(parent, frame)
    return function(self, motion)
        frame:Show()
        -- local scale = frame:GetEffectiveScale()
        -- local x, y = GetCursorPosition()
        frame:SetPoint("LEFT", parent, "RIGHT")
    end
end

local function tooltipLeave(frame)
    return function(self, motion)
        frame:Hide()
    end
end

function Tooltips:attachFrame(frame)
    frame:HookScript("OnEnter", tooltipEnter(frame, self.frame))
    frame:HookScript("OnLeave", tooltipLeave(self.frame))
    return self
end

function Tooltips:attach(cell)
    return self:attachFrame(cell.frame)
end

function Tooltips:create(name)
    assert(name, "Name is required")
    self.frame = _G[name]
    if not self.frame then
        self.frame = CreateFrame("Frame", name, UIParent, "TooltipBorderedFrameTemplate")
        self.frame:SetBackdropColor(0,0,0,1);
        self.frame:SetFrameStrata("DIALOG")
        self.frame:Hide()
        self.frame.textField = self.frame:CreateFontString()
        self.frame.textField:SetPoint("CENTER")
        self.frame.textField:SetFont("Fonts\\FRIZQT__.TTF", 10)
        self.frame.textField:SetJustifyH("LEFT")
    end
    self.frame.textField:SetText(self.text)
    self.frame:SetWidth(self.frame.textField:GetStringWidth() + 18)
    self.frame:SetHeight(self.frame.textField:GetStringHeight() + 12)
    return self
end

function Tooltips:printLine(value, valueColor)
    valueColor = valueColor or ICT.textColor
    self.text = self.text .. string.format("\n|c%s%s|r", valueColor, value)
    return self
end

function Tooltips:printPlain(value)
    self.text = self.text .. string.format("\n|c%s%s|r", ICT.availableColor, value)
    return self
end

function Tooltips:printValue(label, value, labelColor, valueColor)
    if value then
        labelColor = labelColor or ICT.subtitleColor
        valueColor = valueColor or ICT.textColor
        local separator = string.len(value) > 0 and ":" or ""
        self.text = self.text .. string.format("\n|c%s%s%s|r |c%s%s|r", labelColor, label, separator, valueColor, value)
    end
    return self
end

function Tooltips:printTitle(title)
    if self.shouldPrintTitle then
        self.shouldPrintTitle = false
        self.text = self.text .. string.format("\n\n|c%s%s|r", ICT.sectionColor, title)
    end
    return self
end

local Cells = { indent = "" }
ICT.Cells = Cells

-- Gets the associated cell or create it if it doesn't exist yet.
function Cells:get(x, y)
    local name = string.format("ICTCell(%s, %s)", x, y)
    local cell = ICT.content.cells[name]

    if not cell then
        cell = { x = x, y = y }
        setmetatable(cell, self)
        self.__index = self
        cell.frame = CreateFrame("Button", name, ICT.content, "InsecureActionButtonTemplate")
        cell.frame:SetSize(UI.cellWidth, UI.cellHeight)
        cell.frame:SetPoint("TOPLEFT", (x - 1) * UI.cellWidth, -(y - 1) * UI.cellHeight)
        cell.buttons = {}
        ICT.content.cells[name] = cell

        -- Create the string if necessary.
        cell.left = cell.frame:CreateFontString()
        cell.left:SetPoint("LEFT")
        cell.left:SetJustifyH("LEFT")
        cell.left:SetFont("Fonts\\FRIZQT__.TTF", 10)

        cell.right = cell.frame:CreateFontString()
        cell.right:SetPoint("RIGHT")
        cell.right:SetJustifyH("RIGHT")
        cell.right:SetFont("Fonts\\FRIZQT__.TTF", 10)
    end
    -- Remove any cell action so we can reuse the cell.
    for _, button in pairs(cell.buttons) do
        button:Hide()
    end
    cell.frame:SetScript("OnEnter", nil)
    cell.frame:SetScript("OnLeave", nil)
    cell.frame:SetScript("OnClick", nil)
    return cell
end

function Cells:hide()
    for _, button in pairs(self.buttons) do
        button:Hide()
    end
    self.frame:Hide()
    return self.y + 1
end

local function countdown(expires, duration, startColor, endColor)
    if expires then
        local timeLeft = math.max(expires - GetServerTime(), 0)
        startColor = startColor or green
        endColor = endColor or red
        local color = duration and duration > 0 and Colors:gradient(startColor, endColor, timeLeft / duration) or endColor
        return timeLeft == 0 and "Ready" or ICT:DisplayTime(timeLeft), color
    end
    return "N/A"
end

function Cells:printTicker(title, expires, duration, colorOverride)
    local indent = Cells.indent
    local update = function()
        local time, color = countdown(expires, duration, red, green)
        Cells.indent = indent
        self:printValue(title, time, nil, colorOverride or color)
        Cells.indent = ""
    end
    UI.tickers[title] = { ticker = C_Timer.NewTicker(1, update) }
    local time, color = countdown(expires, duration, red, green)
    return self:printValue(title, time, nil, colorOverride or color)
end

-- Prints text in the associated cell.
function Cells:printLine(text, color)
    return self:printValue(text, nil, color, nil)
end

function Cells:printValue(leftText, rightText, leftColor, rightColor)
    self.frame:Show()
    self.leftText = leftText or ""
    self.leftColor = leftColor or ICT.subtitleColor
    -- Handle if we were rewriting the cell while hovering over it.
    local remap = self.hover and Colors:flipHex(self.leftColor) or self.leftColor
    leftText = string.format("%s|c%s%s|r", self.indent, remap, self.leftText)
    self.left:SetText(leftText)
    self.left:Show()
    self.rightText = rightText or ""
    self.rightColor = rightColor or ICT.textColor
    rightText = string.format("|c%s%s|r  ", self.rightColor, self.rightText)
    self.right:SetText(rightText)
    self.right:Show()
    return self.y + 1
end

function Cells:clickable(f)
    local indent = Cells.indent
    local leftColor = self.leftColor
    self.frame:SetScript("OnClick", f)
    self.frame:HookScript("OnEnter", function()
        Cells.indent = indent
        self.hover = true
        self:printValue(self.leftText, self.rightText, leftColor, self.rightColor)
        Cells.indent = ""
    end)
    self.frame:HookScript("OnLeave", function()
        Cells.indent = indent
        self.hover = false
        self:printValue(self.leftText, self.rightText, leftColor, self.rightColor)
        Cells.indent = ""
    end)
end

function Cells:printOptionalValue(option, leftText, rightText, leftColor, rightColor)
    return option and self:printValue(leftText, rightText, leftColor, rightColor) or self.y
end

local function getSectionTitle(title, key)
    local collapsed = ICT.db.options.collapsible[key or title]
    local icon = collapsed and "Interface\\Buttons\\UI-PlusButton-UP" or "Interface\\Buttons\\UI-MinusButton-UP"
    return string.format("|T%s:12|t%s", icon, title)
end

-- Key if you want different titles across columns. Currently only for character names to share the same collapse.
function Cells:printSectionTitle(title, key)
    local sectionTitle = getSectionTitle(title, key)
    self:printLine(sectionTitle, ICT.sectionColor)
    self:clickable(
        function()
            key = key or title
            ICT.db.options.collapsible[key] = not ICT.db.options.collapsible[key]
            ICT:PrintPlayers()
        end
    )
    return self.y + 1
end

function Cells:deletePlayerButton(player)
    local name = string.format("ICTDeletePlayer(%s, %s)", self.x, self.y)
    local button = self.buttons[name]
    if not button then
        button = CreateFrame("Button", name , self.frame, "UIPanelButtonTemplate")
        self.buttons[name] = button
        button:SetParent(self.frame)
        button:SetSize(12, 12)
        button:SetPoint("RIGHT", self.frame, "RIGHT")
        button:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
        Tooltips:new("Delete Player")
        :printPlain("Brings up a confirmation menu to delete the given player.")
        :create(name .. "Tooltip")
        :attachFrame(button)
    end
    button:SetScript("OnClick", UI:openDeleteFrame(player))
    button:Show()
end

function Cells:enqueueAllButton(f)
    local name = string.format("ICTEnqueueAll(%s, %s)", self.x, self.y)
    local button = self.buttons[name]
    if not button then
        button = CreateFrame("Button", name, self.frame, "UIPanelButtonTemplate")
        self.buttons[name] = button
        button:SetParent(self.frame)
        button:SetSize(12, 12)
        button:SetPoint("RIGHT", self.frame, "RIGHT")
        button:SetNormalTexture(134396)
        Tooltips:new("Enqueue Instances")
        :printPlain("Enqueues all non locked instances for the given category.")
        :printPlain("Dequeues if already queued.")
        :create(name .. "Tooltip")
        :attachFrame(button)
    end
    button:SetScript("OnClick", f)
    button:Show()
end

function UI:getQuestColor(player, quest)
    return (not player:isQuestAvailable(quest) and ICT.unavailableColor) or (player:isQuestCompleted(quest) and ICT.lockedColor or ICT.availableColor)
end

function UI:getSelectedColor(selected)
    return selected and ICT.lockedColor or ICT.availableColor
end

function UI:getSelectedQueueColor(selected)
    return selected and ICT.queuedLockedColor or ICT.queuedAvailableColor
end

function UI:hideTickers()
    for _, v in pairs(self.tickers) do
        v.ticker:Cancel()
        if v.frame then v.frame:Hide() end
    end
end

function UI:hideRows(x, startY, endY)
    for j=startY,endY do
        ICT.Cells:get(x, j):hide()
    end
    return startY < endY and endY or startY
end

function UI:hideColumns(startX, endX, endY)
    for i=startX,endX do
        for j=1,endY do
            ICT.Cells:get(i, j):hide()
        end
    end
end

function UI:drawFrame(x, y, width, height)
    ICT.db.X = x or self.defaultX
	ICT.db.Y = y or self.defaultY
    ICT.db.width = width or self.defaultWidth
    ICT.db.height = height or self.defaultHeight
    ICT.frame:ClearAllPoints()
    ICT.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ICT.db.X, ICT.db.Y)
    ICT.frame:SetSize(ICT.db.width, ICT.db.height)
end

function UI:resizeFrameButton()
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

function UI:resetFrameButton()
    local button = CreateFrame("Button", "ICTResetSizeAndPosition", ICT.frame)
    button:SetSize(32, 32)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetPoint("BOTTOMRIGHT", -5, 5)
    button:RegisterForClicks("AnyUp")
    button:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
    button:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
    button:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
    button:SetScript("OnClick", function()
        self:drawFrame(self.defaultX, self.defaultY, self.cellWidth * self.displayX + 40, math.max(self.defaultHeight, self.cellHeight * self.displayY))
    end)
    Tooltips:new("Reset size and position"):create("ICTResetFrameTooltip"):attachFrame(button)
end

function UI:updateFrameSizes(x, offset)
    local newHeight = offset * self.cellHeight
    -- Add 5 for delete button at the end so it isn't clipped.
    local newWidth = x * self.cellWidth + 5

    ICT.resize:Init(ICT.frame, self.cellWidth + 40, self.defaultHeight - 200, newWidth + 40, math.max(self.defaultHeight, newHeight))
    ICT.hScrollBox:SetHeight(newHeight)
    ICT.content:SetSize(newWidth, newHeight)
    ICT.hScrollBox:FullUpdate()
    ICT.vScrollBox:FullUpdate()
end

function UI:printMultiViewResetTicker(x, title, expires, duration)
    local frame = self.tickers[title] and self.tickers[title].frame
    if not frame then
        frame = CreateFrame("Button", "ICTReset" .. title, ICT.frame)
        frame:SetAlpha(1)
        frame:SetIgnoreParentAlpha(true)
        frame:SetSize(UI.cellWidth, UI.cellHeight)
        local textField = frame:CreateFontString()
        textField:SetPoint("CENTER")
        textField:SetFont("Fonts\\FRIZQT__.TTF", 8)
        textField:SetJustifyH("LEFT")
        frame.textField = textField
    end
    frame:SetPoint("TOP", x, -36)
    frame:Show()
    local update = function()
        local time, _ = countdown(expires, duration)
        frame.textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", ICT.subtitleColor, title, ICT.textColor, time))
    end
    self.tickers[title] = { ticker = C_Timer.NewTicker(1, update), frame = frame }
    local time, _ = countdown(expires, duration)
    frame.textField:SetText(string.format("|c%s   %s|r\n|c%s%s|r", ICT.subtitleColor, title, ICT.textColor, time))
    return x + 60, frame
end

local function createDialogWindow(name, titleText, bodyText, buttonText)
    local frame = CreateFrame("Frame", name, UIParent, "BasicFrameTemplateWithInset")
    frame:SetToplevel(true)
    frame:SetHeight(125)
    frame:SetWidth(250)
    frame:Show()
    frame:SetPoint("CENTER", UIParent, 0, 200)
    frame:SetFrameStrata("HIGH")
    table.insert(UISpecialFrames, name)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(titleText)
    title:SetPoint("TOP", -10, -6)

    frame.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.name:SetText(string.format("|c%s%s|r", "FFFFFFFF", bodyText))
    frame.name:SetPoint("CENTER", 0, 10)

    frame.button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.button:SetSize(80 ,22)
    frame.button:SetText(buttonText)
    frame.button:SetPoint("CENTER", 0, -30)
    return frame
end

local delete = createDialogWindow("ICTDeletePlayer", "Confirm Character Deletion", "", "Delete")
local lastPlayer;
function UI:openDeleteFrame(player)
    return function()
        -- Close the dialog if the X is clicked for the same player.
        if lastPlayer == player then
            delete:Hide()
            lastPlayer = nil
            return
        end
        lastPlayer = player;
        delete.name:SetText(string.format("|c%s%s|r", player:getClassColor(), player.fullName))
        delete:Show()
        delete.button:SetScript("OnClick", function ()
            ICT.WipePlayer(player.fullName)
            delete:Hide()
            ICT:PrintPlayers()
        end)
    end
end

local options = createDialogWindow("ICTResetOptionsDialog", "Confirm Reset Options", "Set all options to their default value?", "Confirm")
function UI:openResetOptionsFrame()
    return function()
        options:Show()
        options.button:SetScript("OnClick", function ()
            ICT.Options:setDefaultOptions(true)
            options:Hide()
        end)
    end
end

function UI:resetOptionsButton()
    local button = CreateFrame("Button", "ICTResetOptions", ICT.frame, "UIPanelButtonTemplate")
    button:SetSize(24, 24)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetNormalTexture("Interface/common/help-i")
    button:SetPoint("TOPRIGHT", ICT.frame.options, "TOPLEFT", 18, -2)
    button:SetScript("OnClick", UI:openResetOptionsFrame())
    Tooltips:new("Reset Options")
    :printPlain("Opens a dialog to confirm to reset options to their default value.")
    :create("ICTResetOptionsTooltip")
    :attachFrame(button)
end
