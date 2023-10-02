local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local UI = ICT.UI
local Cells = {}
ICT.Cells = Cells
local Cell = {}
Cell.__index = Cell

function Cells:new(frame)
    local t = { indent = "", cells = {}, frame = frame }
    setmetatable(t, self)
    self.__index = self
    return t
end

function Cells:_call(x, y)
    return self:get(x, y)
end

-- Gets the associated cell or create it if it doesn't exist yet.
function Cells:get(x, y)
    local name = string.format("ICTCell(%s, %s)", x, y)
    local cell = self.cells[name]

    if not cell then
        cell = { x = x, y = y, parent = self }
        setmetatable(cell, Cell)
        cell.frame = CreateFrame("Button", name, self.frame, "InsecureActionButtonTemplate")
        cell.frame:SetSize(UI.cellWidth, UI.cellHeight)
        cell.frame:SetPoint("TOPLEFT", (x - 1) * UI.cellWidth, -(y - 1) * UI.cellHeight)
        cell.buttons = {}
        self.cells[name] = cell

        -- Create the string if necessary.
        cell.left = cell.frame:CreateFontString()
        cell.left:SetPoint("LEFT")
        cell.left:SetJustifyH("LEFT")
        cell.left:SetFont(UI.font, 10)

        cell.right = cell.frame:CreateFontString()
        cell.right:SetPoint("RIGHT", 4, 0)
        cell.right:SetJustifyH("RIGHT")
        cell.right:SetFont(UI.font, 10)

        cell.frame:RegisterForClicks("AnyUp")
        cell.frame:HookScript("OnClick",
            function()
                if cell.hookOnShiftClick and IsShiftKeyDown() then
                    cell.hookOnShiftClick()
                elseif cell.hookOnClick then
                    cell.hookOnClick()
                end
            end
        )
    end
    _ = cell.ticker and cell.ticker:Cancel()
    -- Remove any cell action so we can reuse the cell.
    for _, button in pairs(cell.buttons) do
        button:Hide()
    end
    cell.hookOnClick = nil
    cell.hookOnShiftClick = nil
    cell.frame:SetScript("OnEnter", nil)
    cell.frame:SetScript("OnLeave", nil)
    cell.frame:SetAttribute("type", nil)
    cell.frame:SetAttribute("item", nil)
    cell.frame:GetNormalTexture()
    return cell
end

function Cells:hide()
    for _, cell in pairs(self.cells) do
        cell.frame:Hide()
        _ = cell.ticker and cell.ticker:Cancel()
    end
end

function Cells:hideRows(x, startY, endY)
    for j=startY,endY do
        self:get(x, j):hide()
    end
    return startY < endY and endY or startY
end

function Cell:hide()
    for _, button in pairs(self.buttons) do
        button:Hide()
    end
    self.frame:Hide()
    return self.y + 1
end

function Cell:printTicker(title, key, expires, duration, colorOverride)
    local indent = self.parent.indent
    local update = function(ticker)
        ICT:cancelTicker(ticker)
        local time, color = ICT:countdown(expires, duration, Colors.red, Colors.green)
        local old = self.parent.indent
        self.parent.indent = indent
        local offset = self:printValue(title, time, nil, colorOverride or color)
        self.parent.indent = old
        return offset
    end
    self.ticker = C_Timer.NewTicker(1, update)
    return update()
end

-- Prints text in the associated cell.
function Cell:printLine(text, color)
    return self:printValue(text, nil, color, nil)
end

function Cell:printValue(leftText, rightText, leftColor, rightColor)
    self.frame:Show()
    self.leftText = leftText or ""
    self.leftColor = leftColor or ICT.subtitleColor
    -- Handle if we were rewriting the cell while hovering over it.
    local remap = self.hover and Colors:flipHex(self.leftColor) or self.leftColor
    leftText = string.format("%s|c%s%s|r", self.parent.indent, remap, self.leftText)
    self.left:SetText(leftText)
    self.left:Show()
    self.rightText = rightText or ""
    self.rightColor = rightColor or ICT.textColor
    rightText = string.format("|c%s%s|r  ", self.rightColor, self.rightText)
    self.right:SetText(rightText)
    self.right:Show()
    return self.y + 1
end

function Cell:attachHyperLink(f)
    _ = f and self:attachClick(f)
    self.frame:SetHyperlinksEnabled(true)
    self.frame:SetScript("OnHyperlinkClick", function(self, link, text, button)
        -- Blizzard will only hyperlink items in chat if the color is correct...
        text = string.gsub(text, "|c%w+|", "|cffffd000|")
        if button == "LeftButton" and not IsShiftKeyDown() then
            _ = f and f()
        else
            SetItemRef(link, text, button, self)
        end
    end)
    self.frame:SetScript("OnHyperlinkEnter", function(_, link)
        GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
        _ = f and self.frame:SetNormalTexture("auctionhouse-nav-button-highlight")
    end)
    self.frame:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
        _ = f and self.frame:ClearNormalTexture()
    end)
end

function Cell:attachClickHover()
    local indent = self.parent.indent
    local leftColor = self.leftColor
    self.frame:HookScript("OnEnter", function()
        local old = self.parent.indent
        self.parent.indent = indent
        self.hover = true
        self:printValue(self.leftText, self.rightText, leftColor, self.rightColor)
        self.parent.indent = old
        self.frame:SetNormalTexture("auctionhouse-nav-button-highlight")
    end)
    self.frame:HookScript("OnLeave", function()
        local old = self.parent.indent
        self.parent.indent = indent
        self.hover = false
        self:printValue(self.leftText, self.rightText, leftColor, self.rightColor)
        self.parent.indent = old
        self.frame:ClearNormalTexture()
    end)
end

function Cell:attachSecureClick(itemName)
    self.frame:SetAttribute("type", "item")
    self.frame:SetAttribute("item", itemName)
    self:attachClickHover()
end

function Cell:attachClick(click, shiftClick)
    self.hookOnClick = click
    self:attachShiftClick(shiftClick)
    self:attachClickHover()
end

function Cell:printOptionalValue(option, leftText, rightText, leftColor, rightColor)
    return option and self:printValue(leftText, rightText, leftColor, rightColor) or self.y
end

function Cell:isSectionExpanded(key)
    key = self.parent.frame:GetName() .. key
    return not ICT.db.options.collapsible[key]
end

-- Key if you want different titles across columns. Currently only for character names to share the same collapse.
function Cell:printSectionTitle(title, key, color)
    return self:printSectionTitleValue(title, nil, key, color)
end

function Cell:printSectionTitleValue(title, value, key, color)
    key = self.parent.frame:GetName() .. (key or title)
    local expanded = ICT.db.options.collapsible[key]
    local icon = expanded and "Interface\\Buttons\\UI-PlusButton-UP" or "Interface\\Buttons\\UI-MinusButton-UP"
    title = string.format("|T%s:12|t%s", icon, title)
    self:printValue(title, value, color or ICT.sectionColor)
    self:attachClick(
        function()
            ICT.db.options.collapsible[key] = not ICT.db.options.collapsible[key]
            UI:PrintPlayers()
        end
    )
    return self.y + 1
end

function Cell:attachShiftClick(hookOnShiftClick)
    self.hookOnShiftClick = hookOnShiftClick
end

function Cell:printPlayerTitle(player)
    self:deletePlayerButton(player)
    return self:printLine(player:getNameWithIcon(), player:getClassColor())
end

function Cell:deletePlayerButton(player)
    local f = UI:openDeleteFrame(player)
    local tooltip = function(tooltip) tooltip:printTitle(L["Delete Player"]):printPlain(L["Delete Player Body"]) end
    local button = self:attachButton("ICTDeletePlayer", tooltip, f)
    button:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
    return button
end

function Cell:attachButton(key, tooltip, click, shiftClick)
    local name = string.format("%s(%s, %s)", key, self.x, self.y)
    local button = self.buttons[name]
    if not button then
        button = CreateFrame("Button", name, self.frame, "UIPanelButtonTemplate")
        self.buttons[name] = button
        button:SetParent(self.frame)
        button:SetSize(12, 12)
        button:SetPoint("RIGHT", self.frame, "RIGHT")
        button:SetNormalTexture(134396)
        ICT.Tooltip:new(name .. "Tooltip", tooltip):attachFrame(button)
    end
    button:SetScript("OnClick",
        function()
            if shiftClick and IsShiftKeyDown() then
                shiftClick()
            elseif click then
                click()
            end
        end)
    button:Show()
    return button
end