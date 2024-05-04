local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Expansion = ICT.Expansion
local Players = ICT.Players
local Tabs = ICT.Tabs
local UI = {
    -- Default frame location.
    defaultX = 400,
    defaultY = 800,
    maxX = 0,
    maxY = 0,
    --font = "Fonts\\FRIZQT__.TTF"
    font = "Fonts\\ARIALN.ttf",
    fontSize = 14,
    iconSize = 12,
}
ICT.UI = UI

local function enableMoving(frame)
    frame:SetMovable(true)
    frame:SetResizable(true)
	frame:SetScript("OnMouseDown", frame.StartMoving)
	frame:SetScript("OnMouseUp", function(self)
        ICT.db.X = frame:GetLeft()
        ICT.db.Y = frame:GetTop()
        frame:StopMovingOrSizing(self)
    end)
end

function UI:getFontSize()
    ICT.db.options.fontSize = ICT.db.options.fontSize or UI.fontSize
    return ICT.db.options.fontSize
end

function UI:getCellWidth(fontSize)
    return (fontSize or self:getFontSize()) * 20
end

function UI:getCellHeight(fontSize)
    return (fontSize or self:getFontSize())
end

function UI:getMinWidth()
    return math.max(UI:getCellWidth() + 5, 290)
end

function UI:getMinHeight()
    return 600
end

function UI:calculateWidth(x)
    return math.max(self:getMinWidth(), x * self:getCellWidth())
end

function UI:calculateHeight(y)
    return math.max(self:getMinHeight(), y * self:getCellHeight())
end

function UI:CreateFrame()
    local frame = CreateFrame("Frame", "ICTFrame", UIParent, "BasicFrameTemplateWithInset")
    ICT.frame = frame

    frame:SetFrameStrata("HIGH")
    self:drawFrame(ICT.db.X, ICT.db.Y, ICT.db.width, ICT.db.height)
    enableMoving(frame)
    frame:SetAlpha(.5)
    frame:Hide()
    frame.CloseButton:SetAlpha(1)
    frame.CloseButton:SetIgnoreParentAlpha(true)

    local resizeButton = self:resizeFrameButton()
    local resetSizeButton = self:resetFrameButton()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(L["AddOnName"])
    title:SetAlpha(1)
    title:SetIgnoreParentAlpha(true)
    title:SetPoint("TOP", -10, -6)

    -- For whatever reason, new users with Questie can't seem to load the first panel.
    -- If we call this this creates a dummy panel that takes the failure.
    UI:createDoubleScrollFrame(frame, "ICTDummy"):Hide()
    Tabs:mixin(frame, ICT.db, "selectedTab")
    frame.update = function() return self:PrintPlayers() end
    Tabs:addPanel(frame, ICT.MainTab, L["Main"])
    Tabs:addPanel(frame, ICT.GearTab, L["Gear"])
    Tabs:addPanel(frame, ICT.ProfessionsTab, L["Professions"])
    _ = Expansion.max(ICT.WOTLK) and Tabs:addPanel(frame, ICT.SkillsTab, L["Skills"])
    Tabs:addPanel(frame, ICT.ReputationTab, L["Reputation"])
    -- self:addTab(frame, ICT.InventoryTab, L["Inventory"])
    PanelTemplates_SetTab(frame, frame:getSelectedTab())

    ICT.DropdownOptions:createPlayer()
    ICT.AdvOptions:create()

    local minimizeButton = CreateFrame("Button", "ICTMinButton", frame, "MaximizeMinimizeButtonFrameTemplate")
    minimizeButton:SetPoint("RIGHT", frame.CloseButton, "LEFT", 10, 0)
    minimizeButton:SetAlpha(1)
    minimizeButton:SetIgnoreParentAlpha(true)
    minimizeButton:SetOnMaximizedCallback(function()
        resizeButton:Show()
        resetSizeButton:Show()
        for i=1,frame.numTabs do
            frame.tabs[i].button:Show()
        end
        frame.tabs[frame:getSelectedTab()]:show()
        PanelTemplates_SetTab(frame, frame:getSelectedTab())
        self:drawFrame(ICT.db.X, ICT.db.Y, ICT.db.width, ICT.db.height)
        ICT.frame.minimized = false
    end)
    minimizeButton:SetOnMinimizedCallback(function()
        resizeButton:Hide()
        resetSizeButton:Hide()
        for i=1,frame.numTabs do
            frame.tabs[i].button:Hide()
            frame.tabs[i]:hide()
        end
        self:minFrame()
        ICT.frame.minimized = true
    end)
end

function UI:minFrame()
    ICT.frame:ClearAllPoints()
    ICT.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ICT.db.X, ICT.db.Y)
    -- Enables the frame to be minimized as we enforce a min height greater than 50.
    ICT.resize:Init(ICT.frame, 0, 0, 9999, 9999)
    ICT.frame:SetSize(ICT.db.width, 50)
end

function UI:drawFrame(x, y, width, height)
    ICT.db.X = x or self.defaultX
    ICT.db.Y = y or self.defaultY
    ICT.frame:ClearAllPoints()
    ICT.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ICT.db.X, ICT.db.Y)
    -- Don't set width and height if the frame was minimized
    if ICT.frame.minimized then
        ICT.frame:SetSize(width, height)
    else
        ICT.db.width = width or self:getMinWidth()
        ICT.db.height = height or self:getMinHeight()
        ICT.frame:SetSize(ICT.db.width, ICT.db.height)
    end
end

function UI:resizeFrameButton()
    local button = CreateFrame("Button", "ICTResizeButton", ICT.frame, "PanelResizeButtonTemplate")
    ICT.resize = button
    button:SetSize(20, 20)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetPoint("BOTTOMRIGHT", 0, 0)
	button:HookScript("OnMouseUp", function(self)
        ICT.db.width = ICT.frame:GetWidth()
        ICT.db.height = ICT.frame:GetHeight()
    end)
    -- Enables the frame to be redrawn correctly if it was minimized after a reload.
    -- I'm not sure why it's necessary if a reload is recreating this, but it is.
    button:Init(ICT.frame, self:getMinWidth() + 40, self:getMinHeight(), 9999, 9999)
    return button
end

function UI:resetFrameButton()
    local button = CreateFrame("Button", "ICTResetSizeAndPosition", ICT.frame)
    button:SetSize(32, 32)
    button:SetAlpha(1)
    button:SetIgnoreParentAlpha(true)
    button:SetPoint("BOTTOMRIGHT", -5, 5)
    button:RegisterForClicks("AnyUp")
    button:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
    button:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
    button:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
    button:SetScript("OnClick", function()
        -- Prevents us from making the window go off the screen.
        local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
        local screenHeight = GetScreenHeight() * UIParent:GetEffectiveScale()
        local maxWidth = math.min(self:calculateWidth(self.maxX) + 50, screenWidth)
        local maxHeight = math.min(self:calculateHeight(self.maxY), screenHeight)
        local x = self.defaultX
        -- Adjust so we maximize space if the window is drawn that large.
        -- The x formula seems slightly off but it's fine for now.
        if self.defaultX + maxWidth > screenWidth then
            x = (GetScreenWidth() - screenWidth) / 2
        end
        local y = self.defaultY
        if self.defaultY + maxHeight > screenHeight then
            y = GetScreenHeight() - (GetScreenHeight() - screenHeight) / 2
        end
        self:drawFrame(x, y, maxWidth, maxHeight)
    end)
    ICT.Tooltips:new("Reset size and position"):attachFrame(button)
    return button
end

function UI:updateFrameSizes(frame, x, y)
    local newHeight = self:calculateHeight(y)
    -- Add 5 for delete button at the end so it isn't clipped.
    local newWidth = self:calculateWidth(x) + 5
    frame.hScrollBox:SetHeight(newHeight)
    frame.content:SetSize(newWidth, newHeight)
    frame.headerScrollBox:SetHeight( self:getCellHeight())
    frame.header:SetSize(newWidth, self:getCellHeight())
    frame.headerScrollBox:FullUpdate()
    frame.hScrollBox:FullUpdate()
    frame.vScrollBox:FullUpdate()
    return newWidth, newHeight
end

function UI:getSelectedOrDefault()
    if not ICT.db.players[ICT.selectedPlayer] then
        ICT.selectedPlayer = ICT.Players:getCurrentName()
    end
    return ICT.db.players[ICT.selectedPlayer]
end


function UI:PrintPlayers()
    local maxX, maxY = 0, 0
    for _, tab in pairs(ICT.frame.tabs) do
        tab.frame.top:SetPoint("BOTTOMRIGHT", tab.frame, "TOPRIGHT", 0, -self:getCellHeight() - 5)
        tab.frame.bottom:SetPoint("TOPLEFT", tab.frame, "TOPLEFT", 1, -self:getCellHeight() - 5)

        -- Only update the viewed Tab.
        if ICT.frame:getSelectedTab() == tab.button:GetID() then
            local x = 0
            local y = 0
            tab.cells:hide()
            _ = tab.prePrint and tab:prePrint()
            if ICT.db.options.frame.multiPlayerView then
                for _, player in ICT:spairsByValue(ICT.db.players, Players.getSort(), ICT.Player.isEnabled) do
                    x = x + 1
                    tab.header(x, 1):printPlayerTitle(player)
                    y = math.max(tab:printPlayer(player, x), y)
                end
            else
                local player = self:getSelectedOrDefault()
                x = x + 1
                y = tab:printPlayer(player, x)
                ICT.DropdownOptions:setPlayer(player)
            end
            _ = tab.postPrint and tab:postPrint()
            self:updateFrameSizes(tab.frame, x, y)
            tab.X = x
            tab.Y = y
        end
        -- Preserve width/height from other tabs.
        maxX = math.max(maxX, tab.X or 0)
        maxY = math.max(maxY, tab.Y or 0)
    end
    self.maxX = maxX
    self.maxY = maxY
    ICT.resize:Init(ICT.frame, self:getMinWidth() + 40, self:getMinHeight(), self:calculateWidth(maxX) + 50, self:calculateHeight(maxY))
end