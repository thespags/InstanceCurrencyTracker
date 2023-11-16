local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local Colors = ICT.Colors
local LFD = ICT.LFD
local UI = ICT.UI
local Cells = {}
setmetatable(Cells, Cells)
ICT.Cells = Cells
local Cell = {}

function Cells:new(frame, font, width, height)
    local t = { indent = "", cells = {}, frame = frame, font = font, width = width, height = height}
    setmetatable(t, self)
    self.__index = self
    return t
end

function Cells:hide()
    for _, cell in pairs(self.cells) do
        cell.frame:Hide()
        _ = cell.ticker and cell.ticker:Cancel()
    end
end

function Cells:hideRows(x, startY, endY)
    for j=startY,endY do
        self(x, j):hide()
    end
    return startY < endY and endY or startY
end

-- Gets the associated cell or create it if it doesn't exist yet.
function Cells:__call(x, y)
    local name = string.format("ICTCell(%s, %s)", x, y)
    local cell = self.cells[name]

    if not cell then
        cell = Cell(self, x, y)
        cell.frame = CreateFrame("Button", name, self.frame, "InsecureActionButtonTemplate")
        cell.buttons = {}
        self.cells[name] = cell

        -- Create the string if necessary.
        cell.left = cell.frame:CreateFontString()
        cell.left:SetPoint("LEFT")
        cell.left:SetJustifyH("LEFT")

        cell.right = cell.frame:CreateFontString()
        cell.right:SetPoint("RIGHT", 4, 0)
        cell.right:SetJustifyH("RIGHT")

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
    -- I'm setting the table to the metatable, there's probably a better practice.
    -- Instead, I have to use rawget to avoid a loop.
    local width = rawget(self, "width") or UI:getCellWidth()
    local height = rawget(self, "height") or UI:getCellHeight()
    local font = rawget(self, "font") or UI:getFontSize()
    cell.frame:SetSize(width, height)
    cell.frame:SetPoint("TOPLEFT", 2 + (x - 1) * width, -2 - (y - 1) * height)
    cell.left:SetFont(UI.font, font)
    cell.right:SetFont(UI.font, font)

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
    cell.frame:ClearNormalTexture()
    return cell
end

function Cell:new(parent, x, y)
    local cell = { parent = parent, x = x, y = y }
    setmetatable(cell, self)
    self.__index = self
    return cell
end
setmetatable(Cell, { __call = function(...) return Cell.new(...) end })

function Cell:hide()
    for _, button in pairs(self.buttons) do
        button:Hide()
    end
    self.frame:Hide()
    return self.y + 1
end

function Cell:printTicker(title, expires, duration, colorOverride)
    local indent = self.parent.indent
    local update = function(ticker)
        ICT:cancelTicker(ticker)
        local time, color = ICT:countdown(expires, duration, Colors.red, Colors.green)
        local old = self.parent.indent
        self.parent.indent = indent
        local y = self:printValue(title, time, nil, colorOverride or color)
        self.parent.indent = old
        return y
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
    self.leftColor = leftColor or Colors.subtitle
    -- Handle if we were rewriting the cell while hovering over it.
    local remap = self.hover and Colors:flipHex(self.leftColor) or self.leftColor
    leftText = string.format("%s|c%s%s|r", self.parent.indent, remap, self.leftText)
    self.left:SetText(leftText)
    self.left:Show()
    self.rightText = rightText or ""
    self.rightColor = rightColor or Colors.text
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
        _ = f and self.frame:SetNormalTexture("groupfinder-highlightbar-green")
    end)
    self.frame:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
        _ = f and self.frame:SetNormalTexture("groupfinder-button-cover")
    end)
end

function Cell:attachClickHover()
    local indent = self.parent.indent
    -- local leftColor = self.leftColor
    self.frame:HookScript("OnEnter", function()
        local old = self.parent.indent
        self.parent.indent = indent
        self.hover = true
        self:printValue(self.leftText, self.rightText, self.leftColor, self.rightColor)
        self.parent.indent = old
        self.frame:SetNormalTexture("groupfinder-highlightbar-green")
    end)
    self.frame:HookScript("OnLeave", function()
        local old = self.parent.indent
        self.parent.indent = indent
        self.hover = false
        self:printValue(self.leftText, self.rightText, self.leftColor, self.rightColor)
        self.parent.indent = old
        self.frame:SetNormalTexture("groupfinder-button-cover")
    end)
    self.frame:SetNormalTexture("groupfinder-button-cover")
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
    title = string.format("    %s", title)
    self:printValue(title, value, color or Colors.section)
    self:attachSectionButton(key)
    return self.y + 1
end

function Cell:printLFDInstance(instance)
    local color = LFD:anySelected(instance) and Colors.queuedAvailable or Colors.available
    return self:printLine(instance:getName(), color)
end

function Cell:printLFDType(id, name)
    local _, queued = LFGDungeonList_EvaluateListState(LE_LFG_CATEGORY_LFD)
    local color = id == LFDQueueFrame.type and (queued and Colors.locked or Colors.queuedLocked) or Colors.available
    name = name or LFD:getName(id)
    name = name == "" and SPECIFIC_DUNGEONS or name
    local f = function(tooltip)
        tooltip:printTitle(L["LFD"])
        :printPlain(L["Type"])
        :printValue(L["Click"], L["LFD Click"])
        :printValue(L["Shift Click"], L["LFD Shift Click"])
        :printPlain(L["Instance"])
        :printValue(L["Click"], L["LFD Instance Click"])
        :printValue(L["Shift Click"], L["LFD Instance Shift Click"])
    end
    ICT.Tooltip:new(f):attach(self)
    return self:printLine(name, color)
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
        button:SetPoint("RIGHT", self.frame, "RIGHT")
        button:SetNormalTexture(134396)
        ICT.Tooltip:new(tooltip):attachFrame(button)
    end
    button:SetSize(UI:getFontSize(), UI:getFontSize())
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

function Cell:attachSectionButton(key, tooltip)
    local button = self.buttons[key]
    if not button then
        button = CreateFrame("Button", key, self.frame)
        self.buttons[key] = button
        button:SetParent(self.frame)
        local x = string.len(self.parent.indent)
        button:SetPoint("LEFT", self.frame, "LEFT", x * 3, 0)
        button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        _ = tooltip and ICT.Tooltip:new(tooltip):attachFrame(button)
    end
    button:SetSize(UI:getFontSize(), UI:getFontSize())
    local expanded = ICT.db.options.collapsible[key]
    local icon = expanded and "Interface\\Buttons\\UI-PlusButton-UP" or "Interface\\Buttons\\UI-MinusButton-UP"
    button:SetNormalTexture(icon)
    button:SetScript("OnClick",
        function()
            ICT.db.options.collapsible[key] = not ICT.db.options.collapsible[key]
            UI:PrintPlayers()
        end)
    button:Show()
    return button
end

function Cell:attachCheckButton(key)
    local button = self.buttons[key]
    if not button then
        button = CreateFrame("CheckButton", key, self.frame)
        self.buttons[key] = button
        button:SetParent(self.frame)
        button:SetSize(UI.getFontSize(), UI.getFontSize())
        button:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
        button:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        button:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        button:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        button:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
        -- _ = tooltip and ICT.Tooltip:new(tooltip):attachFrame(button)
    end
    button:Show()
    return button
end