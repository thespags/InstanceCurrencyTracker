local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
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
        frame.ticker = C_Timer.NewTimer(.5, update)
    end
end