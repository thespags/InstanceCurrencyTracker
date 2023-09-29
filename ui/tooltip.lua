
local addOnName, ICT = ...

local UI = ICT.UI
local Tooltip = {}
ICT.Tooltip = Tooltip

function Tooltip:new(name, f)
    local frame = _G[name]
    if not frame then
        frame = CreateFrame("Frame", name, UIParent, "TooltipBorderedFrameTemplate")
        frame:SetBackdropColor(0,0,0,1);
        frame:SetFrameStrata("DIALOG")
        frame:Hide()
        frame.textField = frame:CreateFontString()
        frame.textField:SetPoint("CENTER")
        frame.textField:SetFont(UI.font, 10)
        frame.textField:SetJustifyH("LEFT")
    end
    local o = { frame = frame, f = f }
    setmetatable(o, self)
    self.__index = self
    return o
end

local function tooltipEnter(parent, tooltip)
    return function(self, motion)
        local frame = tooltip.frame
        if not tooltip.text then
            tooltip.text = {}
            tooltip.f(tooltip)
        end
        local text = table.concat(tooltip.text)
        frame.textField:SetText(text)
        frame:SetWidth(frame.textField:GetStringWidth() + 18)
        frame:SetHeight(frame.textField:GetStringHeight() + 12)
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

function Tooltip:attachFrame(frame)
    frame:HookScript("OnEnter", tooltipEnter(frame, self))
    frame:HookScript("OnLeave", tooltipLeave(self.frame))
    return self
end

function Tooltip:attach(cell)
    return self:attachFrame(cell.frame)
end

function Tooltip:printLine(value, valueColor)
    valueColor = valueColor or ICT.textColor
    tinsert(self.text, string.format("\n|c%s%s|r", valueColor, value))
    return self
end

function Tooltip:printPlain(value)
    tinsert(self.text, string.format("\n|c%s%s|r", ICT.availableColor, value))
    return self
end

function Tooltip:printValue(label, value, labelColor, valueColor)
    if value then
        labelColor = labelColor or ICT.subtitleColor
        valueColor = valueColor or ICT.textColor
        local separator = string.len(value) > 0 and ":" or ""
        tinsert(self.text, string.format("\n|c%s%s%s|r |c%s%s|r", labelColor, label, separator, valueColor, value))
    end
    return self
end

function Tooltip:printTitle(title)
    tinsert(self.text, string.format("|c%s%s|r", ICT.tooltipTitleColor, title))
    return self
end

function Tooltip:printSection(title)
    if self.shouldPrintTitle then
        self.shouldPrintTitle = false
        tinsert(self.text, string.format("\n\n|c%s%s|r", ICT.sectionColor, title))
    end
    return self
end