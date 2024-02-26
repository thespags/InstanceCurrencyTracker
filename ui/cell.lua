local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Colors = ICT.Colors
local LFD = ICT.LFD
local UI = ICT.UI
local Cell = {}
ICT.Cell = Cell

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

-- Gradient goes from happy to sad.
function Cell:printBuffTicker(title, expires, duration)
    return self:printTicker(title, expires, duration, Colors.green, Colors.red)
end

-- Gradient goes from sad to happy.
function Cell:printTicker(title, expires, duration, startColor, endColor)
    local update = function(ticker)
        ICT:cancelTicker(ticker)
        startColor = startColor or Colors.red
        endColor = endColor or Colors.green
        local time, color = ICT:countdown(expires, duration, startColor, endColor)
        local y = self:printValue(title, time, nil, color)
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
    leftText = string.format("|c%s%s|r", remap, self.leftText)
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

-- Key if you want different titles across columns. Currently only for character names to share the same collapse.
function Cell:printSectionTitle(title, key, color)
    return self:printSectionTitleValue(title, nil, key, color)
end

function Cell:printSectionTitleValue(title, value, key, color)
    key = self.parent.frame:GetName() .. (key or title)
    local button = self:attachSectionButton(key)
    self.left:SetPoint("LEFT", button, "RIGHT")
    self:printValue(title, value, color or Colors.section)
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
    local button = self:attachRightButton("ICTDeletePlayer", f)
    ICT.Tooltip:new(tooltip):attachFrame(button)
    button:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
    return button
end

function Cell:attachLeftButton(key, click, shiftClick)
    local button = self:attachButton(key, click, shiftClick)
    button:SetPoint("LEFT", self.frame, "LEFT")
    return button
end

function Cell:attachRightButton(key, click, shiftClick)
    local button = self:attachButton(key, click, shiftClick)
    button:SetPoint("RIGHT", self.frame, "RIGHT")
    return button
end

function Cell:attachButton(key, click, shiftClick)
    local name = string.format("%s(%s, %s)", key, self.x, self.y)
    local button = self.buttons[name]
    if not button then
        button = CreateFrame("Button", name, self.frame, "UIPanelButtonTemplate")
        self.buttons[name] = button
        button:SetParent(self.frame)
        button:SetNormalTexture(134396)
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
    local font = self.parent:fontSize()
    button:SetSize(font, font)
    button:Show()
    return button
end

function Cell:attachSectionButton(key, tooltip)
    local button = self.buttons[key]
    if not button then
        button = CreateFrame("Button", key, self.frame)
        self.buttons[key] = button
        button:SetParent(self.frame)
        button:SetPoint("LEFT", self.parent.indent * 6, 0)
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
        ICT.UpdateDisplay()
    end)
    ICT.Tooltips:new(v.name, v.tooltip):attach(self)
end