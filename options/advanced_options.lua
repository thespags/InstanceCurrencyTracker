local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local Colors = ICT.Colors
local Players = ICT.Players
local Tooltips = ICT.Tooltips
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

local function createSectionTitle(frame, x, y, text)
    local title = frame:CreateFontString()
    title:SetFont(UI.font, 12)
    title:SetText(string.format("|c%s%s|r", Colors.section, text))
    title:SetPoint("CENTER", frame, "TOP", x, y)
end

local function createLinkList(parent)
    local frame = CreateFrame("Frame", "ICTOptionsLink", parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -50)
    frame:SetSize(scrollWidth, 100)
    UI:setBackdrop(frame)
    local scroll = UI:createScrollFrame(frame)
    local cells = ICT.Cells:new(scroll.content, fontSize, scrollWidth, scrollHeight)
    Tooltips:info(frame, L["LinkAccountsTooltip"], L["LinkAccountsTooltipBody"])
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
            Tooltips:new(friend.battleTag):attach(cell)
        end
        cells(1, numFriends + 1):printLine("") -- Adds a dummy line for view, because the following line doesn't seem to work as I thought.
        scroll.content:SetSize(scrollWidth, (numFriends + 1) * scrollHeight)
        scroll.vScrollBox:FullUpdate()
    end
end

local function createUpArrow(frame)
    local moveUp = CreateFrame("Button", nil, frame)
    moveUp:SetSize(iconSize, iconSize)
    moveUp:SetPoint("BOTTOMRIGHT", frame, "LEFT", 0, 0)
    moveUp:SetNormalAtlas("hud-MainMenuBar-arrowup-up")
    moveUp:SetPushedAtlas("hud-MainMenuBar-arrowup-down")
    moveUp:SetDisabledAtlas("hud-MainMenuBar-arrowup-disabled")
    moveUp:SetHighlightAtlas("hud-MainMenuBar-arrowup-highlight")
    moveUp:SetEnabled(false)
    return moveUp
end

local function createDownArrow(frame)
    local moveDown = CreateFrame("Button", nil, frame)
    moveDown:SetSize(iconSize, iconSize)
    moveDown:SetPoint("TOPRIGHT", frame, "LEFT", 0, 0)
    moveDown:SetNormalAtlas("hud-MainMenuBar-arrowdown-up")
    moveDown:SetPushedAtlas("hud-MainMenuBar-arrowdown-down")
    moveDown:SetDisabledAtlas("hud-MainMenuBar-arrowdown-disabled")
    moveDown:SetHighlightAtlas("hud-MainMenuBar-arrowdown-highlight")
    moveDown:SetEnabled(false)
    return moveDown
end

local function createSortList(parent)
    local frame = CreateFrame("Frame", "ICTOptionsSort", parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 190, -50)
    frame:SetSize(scrollWidth, 100)
    UI:setBackdrop(frame)
    local scroll = UI:createScrollFrame(frame)
    local cells = ICT.Cells:new(scroll.content, fontSize, scrollWidth, scrollHeight)
    Tooltips:info(frame, L["Custom Order"], L["CustomOrderHelpTooltip"])
    createSectionTitle(frame, 10, 10, L["Custom Order"])

    local selectedPlayer
    local moveUp = createUpArrow(frame)
    local moveDown = createDownArrow(frame)
    local ordered = {}
    local setArrowsEnabled = function(max)
        moveUp:SetEnabled(ICT.db.options.sort.custom and selectedPlayer and selectedPlayer.order > 1)
        moveDown:SetEnabled(ICT.db.options.sort.custom and selectedPlayer and selectedPlayer.order < max)
    end
    local update = function()
        local i = 0
        for _, player in ICT:spairsByValue(ICT.db.players, Players.customSort) do
            i = i + 1
            ordered[i] = player
            -- Sets the player order to ensure it is non nil and compact if any were deleted.
            player.order = i
            local cell = cells(1, i)
            cell:printLine(player:getShortName(), player:getClassColor())
            cell:attachClick(function()
                for j=1,i do
                    cells:get(1, j):setClicked(false)
                end
                if selectedPlayer ~= player then
                    -- Unselect if already selected.
                    cell:setClicked(true)
                    selectedPlayer = player
                else
                    selectedPlayer = nil
                end
                setArrowsEnabled(i)
            end)
            -- If the cell is reenable then we perserve the selected player.
            cell.frame:SetEnabled(ICT.db.options.sort.custom)
            cell:setClicked(selectedPlayer == player)
            Tooltips:new(player.realm):attach(cell)
        end
        cells(1, i + 1):printLine("") -- Adds a dummy line for view, because the following line doesn't seem to work as I thought.
        scroll.content:SetSize(scrollWidth, (i + 1) * scrollHeight)
        scroll.vScrollBox:FullUpdate()
        -- Check that the player wasn't deleted.
        selectedPlayer = selectedPlayer and ICT.db.players[selectedPlayer:getFullName()]
    end

    moveDown:SetScript("OnClick", function()
        if #ordered == ICT:size(ICT.db.players) then
            local prev = selectedPlayer.order
            selectedPlayer.order = selectedPlayer.order + 1
            ordered[selectedPlayer.order].order = prev
            setArrowsEnabled(#ordered)
            ICT:UpdateDisplay()
        end
        update()
    end)
    moveUp:SetScript("OnClick", function()
        if #ordered == ICT:size(ICT.db.players) then
            local prev = selectedPlayer.order
            selectedPlayer.order = selectedPlayer.order - 1
            ordered[selectedPlayer.order].order = prev
            setArrowsEnabled(#ordered)
            ICT:UpdateDisplay()
        end
        update()
    end)
    local button = CreateFrame("CheckButton", "ICTOptionsSortEnabled", parent, "UICheckButtonTemplate")
    button:SetSize(iconSize, iconSize)
    button:SetPoint("BOTTOMLEFT", frame, "TOPLEFT")
    button:SetChecked(ICT.db.options.sort.custom)
    button:HookScript("OnClick", function(self)
        ICT.db.options.sort.custom = not ICT.db.options.sort.custom
        update()
        setArrowsEnabled(#ordered)
        ICT:UpdateDisplay()
    end)
    Tooltips:new(L["Custom Order"], L["CustomOrderTooltip"]):attachFrame(button)
    return update
end

local resetConfirm = UI:createDialogWindow("ICTResetOptionsDialog", L["ResetOptionsDialog"], L["ResetOptionsDialogBody"], L["Confirm"])
resetConfirm.button:SetScript("OnClick", function()
    ICT.Options:setDefaultOptions(true)
    resetConfirm:Hide()
end)

local function createEditBox(parent, onEnterPressed)
    local editBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetPoint("TOP", parent, "BOTTOM")
    editBox:SetNumeric(true)
    editBox:SetSize(70, 14)
    editBox:SetJustifyH("CENTER")
    editBox:EnableMouse(true)
    UI:setBackdrop(editBox)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    editBox:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    editBox:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end)
    editBox:SetScript("OnEnterPressed", onEnterPressed)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return editBox
end

-- Pieces taken from NIT, creates a slider and edit box that work together to set the minimum level of characters to display.
local function createSlider(parent, name, x, y, key, min, max)
	local frame = CreateFrame("Slider", "ICTSlider" .. key, parent, "OptionsSliderTemplate")
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(120, 12)
    frame:SetMinMaxValues(min, max)
    frame:SetObeyStepOnDrag(true)
    frame:SetValueStep(1)
    frame:SetStepsPerPage(1)
    frame:SetValue(ICT.db.options[key] or max)
    frame.Low:SetText(min)
    frame.High:SetText(max)
    createSectionTitle(frame, 0, 10, name)

    local function onEnterPressed(self)
        local value = self:GetText()
        value = tonumber(value)
        if value then
            value = math.max(math.min(max, value), min)
            ICT.db.options[key] = value
            frame:SetValue(value)
            self:SetText(value)
            self:ClearFocus()
        else
            frame.editBox:SetText(min)
        end
    end
    local editBox = createEditBox(frame, onEnterPressed)
    editBox:SetText(ICT.db.options[key] or max)

    frame:HookScript("OnValueChanged", function(self, value)
        ICT.db.options[key] = value
        editBox:SetText(value)
        ICT:UpdateDisplay()
    end)
    return frame
end

local function createResetButton(frame)
    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    local length = string.len(L["Reset All"]) * 10
    button:SetSize(length, 22)
    button:SetText(L["Reset All"])
    button:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    button:SetScript("OnClick", function()
        resetConfirm:Show()
    end)
    Tooltips:new(L["ResetOptionsTooltip"], L["ResetOptionsTooltipBody"]):attachFrame(button)
end

local function checkedOptions(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(scrollWidth, 100)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 190, -175)
    local cells = ICT.Cells:new(frame, fontSize, scrollWidth, scrollHeight)
    local i = 0
    for _, v in pairs(ICT.Options.sort) do
        if not v.skipped then
            i = i + 1
            cells(1, i):attachCheckOption(ICT.db.options.sort, v)
        end
    end
    for _, v in pairs(ICT.Options.frame) do
        if not v.skipped then
            i = i + 1
            cells(1, i):attachCheckOption(ICT.db.options.frame, v)
        end
    end
end

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

    frame.linkList = createLinkList(frame)
    frame.sortList = createSortList(frame)
    local playerSlider = createSlider(frame, L["Character Level"], 25, -180, "minimumLevel", 1, ICT.MaxLevel)
    Tooltips:new(L["Character Level"], L["CharacterLevelToolip"]):attachFrame(playerSlider)
    local fontSlider = createSlider(frame, L["Font Size"], 25, -230, "fontSize", 6, 100)
    Tooltips:new(L["Font Size"], L["FontSizeTooltip"]):attachFrame(fontSlider)

    createResetButton(frame)
    checkedOptions(frame)

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
            resetConfirm:Hide()
            return
        end
        options.linkList()
        options.sortList()
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
    Tooltips:new(L["AdvancedOptionsTooltip"], L["AdvancedOptionsTooltipBody"]):attachFrame(button)
end

function AdvOptions:create()
    self:createButton()
    self:createFrame(options)
end