local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local Tooltips = ICT.Tooltips
local Tabs = ICT.Tabs
local AdvOptions = {}
ICT.AdvOptions = AdvOptions

local width = 355
local height = 300

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

    Tabs:mixin(frame, ICT.db.options, "selectedTab")
    frame.update = function()
        ICT.MainOptions:prePrint()
    end
    Tabs:add(frame, ICT.MainOptions, L["Main"])
    PanelTemplates_SetTab(frame, frame:getSelectedTab())
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
        -- Refresh any information
        options.update()
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