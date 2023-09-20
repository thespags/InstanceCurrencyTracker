
local addOnName, ICT = ...

local UI = ICT.UI
local Tooltips = {}
ICT.Tooltips = Tooltips

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
        self.frame.textField:SetFont(UI.font, 10)
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