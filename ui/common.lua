local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Colors = ICT.Colors
local UI = ICT.UI

function UI:setBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = .5
    })
    frame:SetBackdropColor(0, 0, 0, .5)
    frame:SetBackdropBorderColor(.5, .5, .5)
end

function UI:printGearScore(tab, spec, tooltip, x, y)
    if TT_GS and tab:showGearScores() then
        local scoreColor = spec.gearScore and Colors:rgbPercentage2hex(TT_GS:GetQuality(spec.gearScore)) or nil
        local cell = tab.cells(x, y)
        y = cell:printValue(L["GearScore"], spec.gearScore, nil, scoreColor)
        tooltip:attach(cell)
        cell = tab.cells(x, y)
        y = cell:printValue(L["iLvl"], spec.ilvlScore, nil, scoreColor)
        tooltip:attach(cell)
    end
    return y
end

function UI:createDialogWindow(name, titleText, bodyText, buttonText)
    local frame = CreateFrame("Frame", name, UIParent, "BasicFrameTemplateWithInset")
    frame:SetToplevel(true)
    frame:SetHeight(125)
    frame:SetWidth(250)
    frame:SetPoint("CENTER", UIParent, 0, 200)
    frame:SetFrameStrata("HIGH")
    table.insert(UISpecialFrames, name)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(titleText)
    title:SetPoint("TOP", -10, -6)

    frame.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.name:SetText(string.format("|c%s%s|r", "FFFFFFFF", bodyText))
    frame.name:SetPoint("CENTER", 0, 10)

    frame.button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.button:SetSize(80 ,22)
    frame.button:SetText(buttonText)
    frame.button:SetPoint("CENTER", 0, -30)
    return frame
end

local delete = UI:createDialogWindow("ICTDeletePlayer", "Confirm Character Deletion", "", "Delete")
local lastPlayer
function UI:openDeleteFrame(player)
    return function()
        -- Close the dialog if the X is clicked for the same player.
        if lastPlayer == player then
            delete:Hide()
            lastPlayer = nil
            return
        end
        lastPlayer = player;
        delete.name:SetText(string.format("|c%s%s|r", player:getClassColor(), player.fullName))
        delete:Show()
        delete.button:SetScript("OnClick", function ()
            ICT.WipePlayer(player:getFullName())
            delete:Hide()
            UI:PrintPlayers()
        end)
    end
end

UI.DropdownFrame = CreateFrame("Frame", "ICTCellDropdown", UIParent, "InsetFrameTemplate")
function UI:cellDropdown(reference, f)
    return function()
        local frame = UI.DropdownFrame
        -- Double click hides the frame.
        if frame:IsVisible() then
            frame:Hide()
            return
        end
        frame:Show()
        frame:SetWidth(UI:getCellWidth() + 10)
        frame:ClearAllPoints()
        frame:SetPoint("TOP", reference.frame, "BOTTOM", 0, 0)
        frame:SetFrameStrata("DIALOG")

        local inset = CreateFrame("Frame", "ICTCellDropdownInset", frame)
        inset:SetAllPoints(frame)
        inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
        inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
        frame.cells = frame.cells or ICT.Cells:new(inset)
        frame.cells:hide()

        local rows = f(frame)
        frame:SetHeight(UI:getCellHeight() * rows  + 16)
        _ = frame.ticker and frame.ticker:Cancel()

        local update = function(self)
            if not(MouseIsOver(reference.frame) or MouseIsOver(frame)) then
                frame:Hide()
                self:Cancel()
            end
        end
        frame.ticker = C_Timer.NewTicker(.5, update)
    end
end

function UI:createEditBox(parent)
    local editBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
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
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return editBox
end

function UI:createDoubleScrollFrame(parent, name)
    local inset = CreateFrame("Frame", name, parent, "BackdropTemplate")
    inset:SetAllPoints(parent)
    inset:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -60)
    inset:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -35, 35)
    inset:SetAlpha(1)
    inset:SetIgnoreParentAlpha(true)
    UI:setBackdrop(inset)

    local vScrollBar = CreateFrame("EventFrame", name .. "VScrollBar", inset, "WowTrimScrollBar")
    vScrollBar:SetPoint("TOPLEFT", inset, "TOPRIGHT")
    vScrollBar:SetPoint("BOTTOMLEFT", inset, "BOTTOMRIGHT")

    local hScrollBar = CreateFrame("EventFrame", name .. "HScrollBar", inset, "WowTrimHorizontalScrollBar")
    hScrollBar:SetPoint("TOPLEFT", inset, "BOTTOMLEFT")
    hScrollBar:SetPoint("TOPRIGHT", inset, "BOTTOMRIGHT")

    local vScrollBox = CreateFrame("Frame", name .. "VScrollbox", inset, "WowScrollBox")
    inset.vScrollBox = vScrollBox
    vScrollBox:SetAllPoints(inset)

    local hScrollBox = CreateFrame("Frame", name .. "HScrollbox", vScrollBox, "WowScrollBox")
    inset.hScrollBox = hScrollBox
    hScrollBox:SetScript("OnMouseWheel", nil)
    hScrollBox.scrollable = true

    inset.content = CreateFrame("Frame", name .. "Content", hScrollBox, "ResizeLayoutFrame")
    inset.content.scrollable = true

    local hView = CreateScrollBoxLinearView()
    hView:SetPanExtent(50)
    hView:SetHorizontal(true)

    local vView = CreateScrollBoxLinearView()
    vView:SetPanExtent(50)

    ScrollUtil.InitScrollBoxWithScrollBar(hScrollBox, hScrollBar, hView)
    ScrollUtil.InitScrollBoxWithScrollBar(vScrollBox, vScrollBar, vView)
    return inset
end

function UI:createScrollFrame(inset)
    local name = inset:GetName()
    local vScrollBar = CreateFrame("EventFrame", name .. "VScrollBar", inset, "WowTrimScrollBar")
    vScrollBar:SetPoint("TOPLEFT", inset, "TOPRIGHT")
    vScrollBar:SetPoint("BOTTOMLEFT", inset, "BOTTOMRIGHT")

    local vScrollBox = CreateFrame("Frame", name .. "VScrollbox", inset, "WowScrollBox")
    inset.vScrollBox = vScrollBox
    vScrollBox:SetAllPoints(inset)

    inset.content = CreateFrame("Frame", name .. "Content", vScrollBox, "ResizeLayoutFrame")
    inset.content.scrollable = true

    local vView = CreateScrollBoxLinearView()
    vView:SetPanExtent(50)

    ScrollUtil.InitScrollBoxWithScrollBar(vScrollBox, vScrollBar, vView)
    return inset
end