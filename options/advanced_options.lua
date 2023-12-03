local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local Colors = ICT.Colors
local Players = ICT.Players
local Tooltips = ICT.Tooltips
local Tabs = ICT.Tabs
local UI = ICT.UI
local AdvOptions = {}
ICT.AdvOptions = AdvOptions

local width = 355
local height = 300
local fontSize = 12
local scrollWidth = 125
local scrollHeight = fontSize
-- Cells use fontSize plus 5.
local iconSize = fontSize + 5

local options = CreateFrame("Frame", "ICTAdvancedOptions", UIParent, "BasicFrameTemplateWithInset")
function AdvOptions:createFrame(frame)
    frame:SetToplevel(true)
    frame:SetSize(width, height)
    frame:SetMovable(true)
	frame:SetScript("OnMouseDown", frame.StartMoving)
	frame:SetScript("OnMouseUp",  frame.StopMovingOrSizing)
    frame:SetPoint("CENTER", UIParent, 0, 200)
    frame:SetFrameStrata("HIGH")
    table.insert(UISpecialFrames, frame:GetName())

    frame.update = function()
        ICT.MainOptions:prePrint()
    end
    Tabs:mixin(frame, ICT.db.options, "selectedTab")
    Tabs:add(frame, ICT.MainOptions, "Main")
    PanelTemplates_SetTab(frame, ICT.db.options.selectedTab or 1)
    frame.CloseButton:HookScript("OnClick", function()
        ICT.MainOptions.resetConfirm:Hide()
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(L["Options"])
    title:SetPoint("TOP", -10, -6)
end

local showOptions = true
local function openOptionsFrame()
    return function()
        showOptions = not showOptions
        if showOptions then
            options:Hide()
            ICT.MainOptions.resetConfirm:Hide()
            return
        end
        options:Show()
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
    button:SetScript("OnClick", openOptionsFrame())
    Tooltips:new(L["AdvancedOptionsTooltip"], L["AdvancedOptionsTooltipBody"]):attachFrame(button)
end

function AdvOptions:create()
    self:createButton()
    self:createFrame(options)
end