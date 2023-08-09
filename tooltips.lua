local addOnName, ICT = ...

ICT.tooltipTitleColor = "FF00FF00"
ICT.availableColor = "FFFFFFFF"
ICT.sectionColor = "FFFFFF00"
ICT.selectedSectionColor = "FF484800"
ICT.subtitleColor = "FFFFCC00"
ICT.textColor = "FF9CD6DE"
ICT.lockedColor = "FFFF00FF"
ICT.unavailableColor = "FFFF0000"

local UI = {}
ICT.UI = UI

function UI.getQuestColor(player, quest)
    return (not player.quests.prereq[quest.key] and ICT.unavailableColor) or (player.quests.completed[quest.key] and ICT.lockedColor or ICT.availableColor)
end

function UI.getSelectedColor(selected)
    return selected and ICT.lockedColor or ICT.availableColor
end

function UI.getClassColor(player)
    local classColorHex = select(4, GetClassColor(player.class))
    -- From NIT: Safeguard for weakauras/addons that like to overwrite and break the GetClassColor() function.
    if not classColorHex then
        classColorHex = player.class == "SHAMAN" and "ff0070dd" or "ffffffff"
    end
    return classColorHex
end

function UI.hideRows(x, startY, endY)
    for j=startY,endY do
        ICT.Cells:get(x, j):hide()
    end
    return startY < endY and endY or startY
end

function UI.hideColumns(startX, endX, endY)
    for i=startX,endX do
        for j=1,endY do
            ICT.Cells:get(i, j):hide()
        end
    end
end

ICT.Tooltips = {}
local Tooltips = ICT.Tooltips

function Tooltips:new(title)
    local o = { text = string.format("|c%s%s|r", ICT.tooltipTitleColor, title)}
    setmetatable(o, self)
    self.__index = self
    return o
end

local function tooltipEnter(frame)
    return function(self, motion)
        frame:Show()
        local scale = frame:GetEffectiveScale()
        local x, y = GetCursorPosition()
        frame:SetPoint("RIGHT", nil, "BOTTOMLEFT", (x / scale) - 2, y / scale)
    end
end

local function tooltipLeave(frame)
    return function(self, motion)
        frame:Hide()
    end
end

function Tooltips:attachFrame(frame)
    frame:SetScript("OnEnter", tooltipEnter(self.frame))
    frame:SetScript("OnLeave", tooltipLeave(self.frame))
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

function Tooltips:print(value, valueColor)
    valueColor = valueColor or ICT.textColor
    self.text = self.text .. string.format("\n|c%s%s|r", valueColor, value)
    return self
end

function Tooltips:printPlain(value)
    self.text = self.text .. string.format("\n|c%s%s|r", ICT.availableColor, value)
    return self
end

function Tooltips:printLine(label, value, labelColor, valueColor)
    if value then
        labelColor = labelColor or ICT.subtitleColor
        valueColor = valueColor or ICT.textColor
        self.text = self.text .. string.format("\n|c%s%s:|r |c%s%s|r", labelColor, label, valueColor, value)
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
    local name = string.format("ICTcell(%s, %s)", x, y)
    local cell = ICT.content.cells[name]

    if not cell then
        cell = { x = x, y = y }
        setmetatable(cell, self)
        self.__index = self
        cell.frame = CreateFrame("Button", name, ICT.content)
        cell.frame:SetSize(ICT.cellWidth, ICT.cellHeight)
        cell.frame:SetPoint("TOPLEFT", (x - 1) * ICT.cellWidth, -(y - 1) * ICT.cellHeight)
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
    cell.frame:SetScript("OnEnter", nil)
    cell.frame:SetScript("OnClick", nil)
    return cell
end


function Cells:hide()
    self.frame:Hide()
    return self.y + 1
end

-- Prints text in the associated cell.
function Cells:print(text, color)
    text = color and string.format("%s|c%s%s|r", self.indent, color, text) or text
    self.left:SetText(text)
    self.left:Show()
    -- Hide any right infor for this cell to cover up any previous information.
    self.right:Hide()
    self.frame:Show()
    return self.y + 1
end

function Cells:printValue(leftText, rightText, leftColor, rightColor)
    self.frame:Show()
    leftText = string.format("%s|c%s%s|r", self.indent, leftColor or ICT.subtitleColor, leftText)
    self.left:SetText(leftText)
    self.left:Show()
    rightText = string.format("|c%s%s|r  ", rightColor or ICT.textColor, rightText)
    self.right:SetText(rightText)
    self.right:Show()
    return self.y + 1
end

function Cells:printOptionalValue(option, leftText, rightText, leftColor, rightColor)
    if option and leftText and rightText then
        return self:printValue(leftText, rightText, leftColor, rightColor)
    end
    return self.y
end

local function getSectionTitle(title, key)
    local collapsed = ICT.db.options.collapsible[key or title]
    local icon = collapsed and "Interface\\Buttons\\UI-PlusButton-UP" or "Interface\\Buttons\\UI-MinusButton-UP"
    return string.format("|T%s:12|t%s", icon, title)
end

-- Key if you want different titles across columns. Currently only for character names to share the same collapse.
function Cells:printSectionTitle(title, key)
    local check = self
    self:print(getSectionTitle(title, key), ICT.sectionColor)
    self.frame:SetScript(
        "OnClick",
        function()
            key = key or title
            ICT.db.options.collapsible[key] = not ICT.db.options.collapsible[key]
            -- who is self here?
            check:print(getSectionTitle(title, key), ICT.sectionColor)
            ICT:DisplayPlayer()
        end
    )
    return self.y + 1
end