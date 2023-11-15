local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local Tooltips = ICT.Tooltips
local UI = ICT.UI
local AdvOptions = {}
ICT.AdvOptions = AdvOptions

local function setBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = .5
    })
    frame:SetBackdropColor(0, 0, 0, .5)
    frame:SetBackdropBorderColor(.5, .5, .5)
end

local function createCommsList(parent)
    local frame = CreateFrame("Frame", "ICTAllowedComms", parent, "BackdropTemplate")
    frame:SetPoint("CENTER", parent, "LEFT", 75, 0)
    frame:SetHeight(100)
    frame:SetWidth(100)
    setBackdrop(frame)
    local scroll = UI:createScrollFrame(frame)
    local cells = ICT.Cells:new(scroll.content, 12, 100, 10)
    local tooltip = Tooltips:new(L["Link Accounts Tooltip Header"], L["Link Accounts Tooltip Body"])
    tooltip:attachFrame(frame)

    -- Title
    frame.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.name:SetText(string.format("|c%s%s|r", "FFFFFFFF", L["Link Accounts"]))
    frame.name:SetPoint("CENTER", frame, "TOP", 10, 10)

    return function()
        local numFriends = BNGetNumFriends()
        for i=1,numFriends do
            local friend = C_BattleNet.GetFriendAccountInfo(i)
            local cell = cells(1, i)
            local color = Colors:getSelectedColor(ICT.db.options.comms.players[friend.battleTag])
            cell:printLine(friend.accountName, color)
            cell:attachClick(
                function()
                    ICT.db.options.comms.players[friend.battleTag] = not ICT.db.options.comms.players[friend.battleTag]
                    color = Colors:getSelectedColor(ICT.db.options.comms.players[friend.battleTag])
                    cell:printLine(friend.accountName, color)
                end
            )
            tooltip:attach(cell)
        end
        scroll.content:SetSize(100, (numFriends + 1) * 10)
        scroll.vScrollBox:FullUpdate()
    end
end

local resetConfirm = UI:createDialogWindow("ICTResetOptionsDialog", "Confirm Reset Options", "Set all options to their default value?", "Confirm")
resetConfirm.button:SetScript("OnClick", function()
    ICT.Options:setDefaultOptions(true)
    resetConfirm:Hide()
end)

function AdvOptions:createFrame(name)
    local frame = CreateFrame("Frame", name, UIParent, "BasicFrameTemplateWithInset")
    frame:SetToplevel(true)
    frame:SetHeight(125)
    frame:SetHeight(200)
    frame:SetWidth(300)
    frame:SetMovable(true)
	frame:SetScript("OnMouseDown", frame.StartMoving)
	frame:SetScript("OnMouseUp",  frame.StopMovingOrSizing)
    frame:SetPoint("CENTER", UIParent, 0, 200)
    frame:SetFrameStrata("HIGH")
    table.insert(UISpecialFrames, name)

    frame.commsList = createCommsList(frame)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(L["Options"])
    title:SetPoint("TOP", -10, -6)

    -- frame.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- frame.name:SetText(string.format("|c%s%s|r", "FFFFFFFF", bodyText))
    -- frame.name:SetPoint("CENTER", 0, 10)

    frame.button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.button:SetSize(80 ,22)
    frame.button:SetText("Reset All")
    frame.button:SetPoint("RIGHT", frame, "RIGHT", -30, 0)
    frame.button:SetScript("OnClick", function()
        resetConfirm:Show()
    end)
    return frame
end

function AdvOptions:createButton()
    local button = CreateFrame("Button", "ICTResetOptions", ICT.frame, "UIPanelButtonTemplate")
    button:SetSize(24, 24)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetText("|TInterface\\Buttons\\UI-OptionsButton:12|t")
    button:SetPoint("TOPRIGHT", ICT.frame.options, "TOPLEFT", 18, -2)
    button:SetScript("OnClick", self:openResetOptionsFrame())
    local f = function(tooltip) 
        tooltip:printTitle("Reset Options")
        tooltip:printPlain("Opens a dialog to confirm to reset options to their default value.")
    end
    ICT.Tooltip:new(f)
    :attachFrame(button)
end

local options = AdvOptions:createFrame("ICTAdvancedOptions")
local showOptions = true
function AdvOptions:openResetOptionsFrame()
    return function()
        showOptions = not showOptions
        if showOptions then
            options:Hide()
            resetConfirm:Hide()
            return
        end
        options.commsList()
        options:Show()
    end
end