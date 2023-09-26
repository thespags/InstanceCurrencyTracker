local addOnName, ICT = ...

local Colors = ICT.Colors
local UI = ICT.UI
local Cells = {}
ICT.Cells = Cells
local Cell = {}
Cell.__index = Cell

function Cells:new(frame)
    local t = { indent = "", cells = {}, frame = frame}
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

        cell.frame:HookScript("OnClick", function() if cell.clickable then cell.hookOnClick() end end)
        cell.frame:RegisterForClicks("AnyUp")
    end
    -- Remove any cell action so we can reuse the cell.
    for _, button in pairs(cell.buttons) do
        button:Hide()
    end
    cell.clickable = false
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
    local update = function()
        local time, color = UI:countdown(expires, duration, Colors.red, Colors.green)
        self.parent.indent = indent
        self:printValue(title, time, nil, colorOverride or color)
        self.parent.indent = ""
    end
    ICT.UI.tickers[key] = { ticker = C_Timer.NewTicker(1, update) }
    local time, color = UI:countdown(expires, duration, Colors.red, Colors.green)
    return self:printValue(title, time, nil, colorOverride or color)
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
        self.parent.indent = indent
        self.hover = true
        self:printValue(self.leftText, self.rightText, leftColor, self.rightColor)
        self.parent.indent = ""
        self.frame:SetNormalTexture("auctionhouse-nav-button-highlight")
    end)
    self.frame:HookScript("OnLeave", function()
        self.parent.indent = indent
        self.hover = false
        self:printValue(self.leftText, self.rightText, leftColor, self.rightColor)
        self.parent.indent = ""
        self.frame:ClearNormalTexture()
    end)
end

function Cell:attachSecureClick(itemName)
    self.frame:SetAttribute("type", "item")
    self.frame:SetAttribute("item", itemName)
    self:attachClickHover()
end

function Cell:attachClick(f)
    self.clickable = true
    self.hookOnClick = f
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
function Cell:printSectionTitle(title, key)
    key = self.parent.frame:GetName() .. (key or title)
    local expanded = ICT.db.options.collapsible[key]
    local icon = expanded and "Interface\\Buttons\\UI-PlusButton-UP" or "Interface\\Buttons\\UI-MinusButton-UP"
    title = string.format("|T%s:12|t%s", icon, title)
    self:printLine(title, ICT.sectionColor)
    self:attachClick(
        function()
            ICT.db.options.collapsible[key] = not ICT.db.options.collapsible[key]
            UI:PrintPlayers()
        end
    )
    return self.y + 1
end

function Cell:printPlayerTitle(player)
    self:deletePlayerButton(player)
    return self:printLine(player:getNameWithIcon(), player:getClassColor())
end

function Cell:deletePlayerButton(player)
    local name = string.format("ICTDeletePlayer(%s, %s)", self.x, self.y)
    local button = self.buttons[name]
    if not button then
        button = CreateFrame("Button", name , self.frame, "UIPanelButtonTemplate")
        self.buttons[name] = button
        button:SetParent(self.frame)
        button:SetSize(12, 12)
        button:SetPoint("RIGHT", self.frame, "RIGHT")
        button:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
        ICT.Tooltips:new("Delete Player")
        :printPlain("Brings up a confirmation menu to delete the given player.")
        :create(name .. "Tooltip")
        :attachFrame(button)
    end
    button:SetScript("OnClick", UI:openDeleteFrame(player))
    button:Show()
end

function Cell:enqueueAllButton(f)
    local name = string.format("ICTEnqueueAll(%s, %s)", self.x, self.y)
    local button = self.buttons[name]
    if not button then
        button = CreateFrame("Button", name, self.frame, "UIPanelButtonTemplate")
        self.buttons[name] = button
        button:SetParent(self.frame)
        button:SetSize(12, 12)
        button:SetPoint("RIGHT", self.frame, "RIGHT")
        button:SetNormalTexture(134396)
        ICT.Tooltips:new("Enqueue Instances")
        :printPlain("Enqueues all non locked instances for the given category.")
        :printPlain("Dequeues if already queued.")
        :create(name .. "Tooltip")
        :attachFrame(button)
    end
    button:SetScript("OnClick", f)
    button:Show()
end