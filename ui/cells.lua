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

function Cells:cellWidth()
    return rawget(self, "width") or UI:getCellWidth()
end

function Cells:cellHeight()
    return rawget(self, "height") or UI:getCellHeight()
end

function Cells:fontSize()
    return rawget(self, "font") or UI:getFontSize()
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
    local width = self:cellWidth()
    local height = self:cellHeight()
    local font = self:fontSize()
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
    cell.frame:ClearHighlightTexture()
    cell.frame:ClearNormalTexture()
    cell.frame:ClearPushedTexture()
    cell.frame:ClearDisabledTexture()
    return cell
end

-- Gets the cell without reseting the information. Must exist.
function Cells:get(x, y)
    local name = string.format("ICTCell(%s, %s)", x, y)
    return self.cells[name]
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

-- Deprecating. It can make some colors unpredictable.
function Cell:attachClickHover()
    local indent = self.parent.indent
    self.frame:HookScript("OnEnter", function()
        local old = self.parent.indent
        self.parent.indent = indent
        self.hover = true
        self:printValue(self.leftText, self.rightText, self.leftColor, self.rightColor)
        self.parent.indent = old
    end)
    self.frame:HookScript("OnLeave", function()
        local old = self.parent.indent
        self.parent.indent = indent
        self.hover = false
        self:printValue(self.leftText, self.rightText, self.leftColor, self.rightColor)
        self.parent.indent = old
    end)
end

function Cell:attachSecureClick(itemName)
    self.frame:SetAttribute("type", "item")
    self.frame:SetAttribute("item", itemName)
    self.frame:SetHighlightTexture("groupfinder-highlightbar-green")
    self.frame:SetNormalTexture("groupfinder-button-cover")
    self.frame:SetPushedTexture("groupfinder-button-cover-down")
    self.frame:SetDisabledTexture("")
end

function Cell:attachClick(click, shiftClick)
    self.hookOnClick = click
    self:attachShiftClick(shiftClick)
    self.frame:SetHighlightTexture("groupfinder-highlightbar-green")
    self.frame:SetNormalTexture("groupfinder-button-cover")
    self.frame:SetPushedTexture("groupfinder-button-cover-down")
    self.frame:SetDisabledTexture("")
end

function Cell:setClicked(clicked)
    local texture = clicked and "groupfinder-highlightbar-blue" or "groupfinder-button-cover"
    self.frame:SetNormalTexture(texture)
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
        button = CreateFrame("CheckButton", key, self.frame, "UICheckButtonTemplate")
        self.buttons[key] = button
        button:SetParent(self.frame)
        button:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
        -- _ = tooltip and ICT.Tooltip:new(tooltip):attachFrame(button)
    end
    local font = self.parent:fontSize()
    button:SetSize(font + 5, font + 5)
    button:Show()
    return button
end

function Cell:lockCheckButton(button)
    local font = self.parent:fontSize()
    -- This x adjustment doesn't scale with font size increase, so the lock moves left as the font increases.
    button:SetPoint("LEFT", self.frame, "LEFT", 5, 0)
    button:ClearHighlightTexture()
    button:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-LOCK")
    button:SetEnabled(false)
    button:SetSize(font, font)
end

-- These cells are created once, so I'm not preserving them for now.
function Cell:attachCheckOption(options, v)
    self:printLine("      " .. v.name, Colors.text)
    local button = self:attachCheckButton(self.frame:GetName() .. "Option")
    button:SetChecked(options[v.key])
    button:HookScript("OnClick", function(self)
        options[v.key] = not options[v.key]
        _ = v.func and v.func()
        ICT:UpdateDisplay()
    end)
    ICT.Tooltips:new(v.name, v.tooltip):attach(self)
end