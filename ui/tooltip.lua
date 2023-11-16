
local addOnName, ICT = ...

local Colors = ICT.Colors
local UI = ICT.UI
local Tooltip = {}
ICT.Tooltip = Tooltip

local frame = CreateFrame("Frame", "ICTTooltip", UIParent, "TooltipBorderedFrameTemplate")
frame:SetBackdropColor(0, 0, 0, 1)
frame:SetFrameStrata("DIALOG")
frame:Hide()

local createTextField = function()
    local textField = frame:CreateFontString()
    textField:SetPoint("CENTER")
    textField:SetJustifyH("LEFT")
    return textField
end

function Tooltip:new(f)
    local o = { f = f }
    setmetatable(o, self)
    self.__index = self
    return o
end

local function tooltipEnter(reference, tooltip)
    return function(self, motion)
        if not tooltip.text then
            tooltip.text = {}
            tooltip.f(tooltip)
            tooltip.cachedText = table.concat(tooltip.text)
        end
        frame.textField = frame.textField or createTextField()
        frame.textField:SetFont(UI.font, UI:getFontSize())
        frame.textField:SetText(tooltip.cachedText)
        frame:SetWidth(frame.textField:GetStringWidth() + 18)
        frame:SetHeight(frame.textField:GetStringHeight() + 12)
        frame:Show()
        -- local scale = frame:GetEffectiveScale()
        -- local x, y = GetCursorPosition()
        frame:SetPoint("LEFT", reference, "RIGHT")
    end
end

local function tooltipLeave()
    return function(self, motion)
        frame:Hide()
    end
end

function Tooltip:attachFrame(reference)
    reference:HookScript("OnEnter", tooltipEnter(reference, self))
    reference:HookScript("OnLeave", tooltipLeave())
    return self
end

function Tooltip:attach(cell)
    return self:attachFrame(cell.frame)
end

function Tooltip:printLine(value, valueColor)
    valueColor = valueColor or Colors.text
    tinsert(self.text, string.format("\n|c%s%s|r", valueColor, value))
    return self
end

function Tooltip:printPlain(value)
    tinsert(self.text, string.format("\n|c%s%s|r", Colors.available, value))
    return self
end

function Tooltip:printValue(label, value, labelColor, valueColor)
    if value then
        labelColor = labelColor or Colors.subtitle
        valueColor = valueColor or Colors.text
        local separator = string.len(value) > 0 and ":" or ""
        tinsert(self.text, string.format("\n|c%s%s%s|r |c%s%s|r", labelColor, label, separator, valueColor, value))
    end
    return self
end

function Tooltip:printTitle(title)
    tinsert(self.text, string.format("|c%s%s|r", Colors.tooltipTitle, title))
    return self
end

function Tooltip:printSection(title)
    if self.shouldPrintTitle then
        self.shouldPrintTitle = false
        tinsert(self.text, string.format("\n\n|c%s%s|r", Colors.section, title))
    end
    return self
end