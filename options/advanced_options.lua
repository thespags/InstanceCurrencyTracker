local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Tooltips = ICT.Tooltips
local Tabs = ICT.Tabs
local AdvOptions = {
    frame = CreateFrame("Frame", "ICTAdvancedOptions", UIParent, "BasicFrameTemplateWithInset")
}
ICT.AdvOptions = AdvOptions

local width = 360
local height = 300

function AdvOptions:createFrame()
    self.frame:SetToplevel(true)
    self.frame:SetSize(width, height)
    self.frame:SetMovable(true)
	self.frame:SetScript("OnMouseDown", self.frame.StartMoving)
	self.frame:SetScript("OnMouseUp",  self.frame.StopMovingOrSizing)
    self.frame:SetPoint("CENTER", UIParent, 0, 200)
    self.frame:SetFrameStrata("HIGH")
    table.insert(UISpecialFrames, self.frame:GetName())

    Tabs:mixin(self.frame, ICT.db.options, "selectedTab")
    self.frame.update = function()
        ICT.MainOptions:prePrint()
    end
    Tabs:add(self.frame, ICT.MainOptions, L["Main"])
    Tabs:add(self.frame, ICT.DisplayOptions, L["Display"])
    PanelTemplates_SetTab(self.frame, self.frame:getSelectedTab())
    self.frame.CloseButton:HookScript("OnClick", function()
        ICT.MainOptions.resetConfirm:Hide()
    end)

    local title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(L["Options"])
    title:SetPoint("TOP", -10, -6)
end

local showOptions = true
function AdvOptions:openOptionsFrame()
    return function()
        showOptions = not showOptions
        if showOptions then
            self.frame:Hide()
            ICT.MainOptions.resetConfirm:Hide()
            return
        end
        self.frame:Show()
        -- Refresh any information
        self.frame.update()
    end
end

function AdvOptions:createButton()
    local button = CreateFrame("Button", "ICTAdvancedOptions", ICT.frame, "UIPanelButtonTemplate")
    button:SetToplevel(true)
    button:SetSize(22, 22)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetText("|TInterface\\Buttons\\UI-OptionsButton:12|t")
    button:SetPoint("TOPLEFT", ICT.frame, "TOPLEFT", 1, -1)
    button:SetScript("OnClick", self:openOptionsFrame())
    Tooltips:new(L["AdvancedOptionsTooltip"], L["AdvancedOptionsTooltipBody"]):attachFrame(button)
end

function AdvOptions:create()
    self:createButton()
    self:createFrame()
    self.frame:Hide()
end