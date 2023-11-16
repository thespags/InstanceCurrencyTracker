local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local Tooltips = ICT.Tooltips
local UI = ICT.UI
local AdvOptions = {}
ICT.AdvOptions = AdvOptions

local function createSectionTitle(frame, x, y, text)
    local title = frame:CreateFontString()
    title:SetFont(UI.font, 12)
    title:SetText(string.format("|c%s%s|r", ICT.sectionColor, text))
    title:SetPoint("CENTER", frame, "TOP", x, y)
end

local function createCommsList(parent)
    local frame = CreateFrame("Frame", "ICTAllowedComms", parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 25, -60)
    frame:SetSize(100, 100)
    UI:setBackdrop(frame)
    local scroll = UI:createScrollFrame(frame)
    local cells = ICT.Cells:new(scroll.content, 12, 100, 10)
    local tooltip = Tooltips:new(L["Link Accounts Tooltip Header"], L["Link Accounts Tooltip Body"])
    tooltip:attachFrame(frame)
    createSectionTitle(frame, 10, 10, L["Link Accounts"])

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

-- Pieces taken from NIT, creates a slider and edit box that work together to set the minimum level of characters to display.
local function createPlayerSlider(parent)
	local levelSlider = CreateFrame("Slider", "ICTCharacterLevel", parent, "OptionsSliderTemplate")
	levelSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", 25, -190)
    levelSlider.tooltipText = L["Character Level Toolip"];

    levelSlider:SetSize(120, 12)
    levelSlider:SetMinMaxValues(1, ICT.MaxLevel)
    levelSlider:SetObeyStepOnDrag(true);
    levelSlider:SetValueStep(1)
    levelSlider:SetStepsPerPage(1)
    levelSlider:SetValue(ICT.db.options.minimumLevel or ICT.MaxLevel)
    levelSlider.Low:SetText("1")
    levelSlider.High:SetText(ICT.MaxLevel)
    createSectionTitle(levelSlider, 0, 10, L["Character Level"])

    local function onEnterPressed(self)
        local value = self:GetText()
        value = tonumber(value)
        if value then
            value = math.max(math.min(ICT.MaxLevel, value), 1)
            ICT.db.options.minimumLevel = value
            levelSlider:SetValue(value)
            self:SetText(value)
            self:ClearFocus()
        else
            levelSlider.editBox:SetText(ICT.db.options.minimumLevel)
        end
    end

    local editBox = CreateFrame("EditBox", nil, levelSlider, "BackdropTemplate")
    editBox:SetText(ICT.db.options.minimumLevel or ICT.MaxLevel)
    editBox:SetAutoFocus(false);
    editBox:SetFontObject(GameFontHighlightSmall);
    editBox:SetPoint("TOP", levelSlider, "BOTTOM");
    editBox:SetSize(70, 14)
    editBox:SetJustifyH("CENTER");
    editBox:EnableMouse(true);
    UI:setBackdrop(editBox)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    editBox:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    editBox:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end);
    editBox:SetScript("OnEnterPressed", onEnterPressed)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end);

    levelSlider:HookScript("OnValueChanged", function(self, value)
        ICT.db.options.minimumLevel = value
        editBox:SetText(value)
        UI:PrintPlayers()
    end)
end

local function createResetButton(frame)
end

local options = CreateFrame("Frame", "ICTAdvancedOptions", UIParent, "BasicFrameTemplateWithInset")
function AdvOptions:createFrame(frame)
    frame:SetToplevel(true)
    frame:SetSize(300, 300)
    frame:SetMovable(true)
	frame:SetScript("OnMouseDown", frame.StartMoving)
	frame:SetScript("OnMouseUp",  frame.StopMovingOrSizing)
    frame:SetPoint("CENTER", UIParent, 0, 200)
    frame:SetFrameStrata("HIGH")
    table.insert(UISpecialFrames, frame:GetName())

    frame.commsList = createCommsList(frame)
    createPlayerSlider(frame)

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
end

local showOptions = true
local function openOptionsFrame()
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

function AdvOptions:createButton()
    local button = CreateFrame("Button", "ICTResetOptions", ICT.frame, "UIPanelButtonTemplate")
    button:SetSize(24, 24)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetText("|TInterface\\Buttons\\UI-OptionsButton:12|t")
    button:SetPoint("TOPRIGHT", ICT.frame.options, "TOPLEFT", 18, -2)
    button:SetScript("OnClick", openOptionsFrame())
    local f = function(tooltip)
        tooltip:printTitle("Reset Options")
        tooltip:printPlain("Opens a dialog to confirm to reset options to their default value.")
    end
    ICT.Tooltip:new(f)
    :attachFrame(button)
end

function AdvOptions:create()
    self:createButton()
    self:createFrame(options)

end