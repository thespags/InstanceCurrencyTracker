local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");

local UI = {
    -- Default frame location.
    defaultX = 400,
    defaultY = 800,
    maxX = 0,
    maxY = 0,
    --font = "Fonts\\FRIZQT__.TTF"
    font = "Fonts\\ARIALN.ttf",
    fontSize = 10,
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
    return ICT.db.fontSize or UI.fontSize
end

function UI:getCellWidth()
    return self:getFontSize() * 20
end

function UI:getCellHeight()
    return self:getFontSize()
end

function UI:getMinWidth()
    return UI:getCellWidth() + 5
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

    self:resizeFrameButton()
    self:resetFrameButton()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(addOnName)
    title:SetAlpha(1)
    title:SetIgnoreParentAlpha(true)
    title:SetPoint("TOP", -10, -6)

    self:addTab(frame, ICT.MainTab, L["Main"])
    self:addTab(frame, ICT.GearTab, L["Gear"])
    self:addTab(frame, ICT.ProfessionsTab, L["Professions"])
    PanelTemplates_SetTab(frame, ICT.db.selectedTab or 1)

    ICT.Options:CreatePlayerDropdown()
    ICT.Options:CreateOptionDropdown()
    ICT.AdvOptions:create()
end

function UI:drawFrame(x, y, width, height)
    ICT.db.X = x or self.defaultX
    ICT.db.Y = y or self.defaultY
    ICT.db.width = width or self:getMinWidth()
    ICT.db.height = height or self:getMinHeight()
    ICT.frame:ClearAllPoints()
    ICT.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ICT.db.X, ICT.db.Y)
    ICT.frame:SetSize(ICT.db.width, ICT.db.height)
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
        self:drawFrame(self.defaultX, self.defaultY, self:calculateWidth(self.maxX) + 50, self:calculateHeight(self.maxY))
    end)
    ICT.Tooltips:new("Reset size and position"):attachFrame(button)
end

function UI:updateFrameSizes(fame, x, y)
    local newHeight = self:calculateHeight(y)
    -- Add 5 for delete button at the end so it isn't clipped.
    local newWidth = self:calculateWidth(x) + 5
    fame.hScrollBox:SetHeight(newHeight)
    fame.content:SetSize(newWidth, newHeight)
    fame.hScrollBox:FullUpdate()
    fame.vScrollBox:FullUpdate()
    return newWidth, newHeight
end

function UI:getSelectedOrDefault()
    if not ICT.db.players[ICT.selectedPlayer] then
        ICT.selectedPlayer = ICT.Players:getCurrentName()
    end
    return ICT.db.players[ICT.selectedPlayer]
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

function UI:selectTab(tab)
    return function()
        local parent = tab.frame:GetParent()
        PanelTemplates_SetTab(parent, tab.button:GetID())
        for i=1,parent.numTabs do
            parent.tabs[i]:hide()
        end
        ICT.db.selectedTab = tab.button:GetID()
        self:PrintPlayers()
        tab:show()
        if tab.OnSelect then
            tab.OnSelect(tab)
        end
    end
end

function UI:addTab(frame, tab, name)
    local tabFrame = UI:createDoubleScrollFrame(frame, "ICT" .. name)
    tab.frame = tabFrame
    tab.cells = ICT.Cells:new(tabFrame.content)

	local frameName = frame:GetName()
	frame.numTabs = frame.numTabs and frame.numTabs + 1 or 1
    frame.tabs = frame.tabs or {}
	local tabButton = CreateFrame("Button", frameName.."Tab"..frame.numTabs, frame, "CharacterFrameTabButtonTemplate")
    tabButton:SetAlpha(1)
    tabButton:SetIgnoreParentAlpha(true)
    frame.tabs[frame.numTabs] = tab
	tabButton:SetID(frame.numTabs)
	tabButton:SetText(name)
	tabButton:SetScript("OnClick", self:selectTab(tab))
	tab.button = tabButton
    -- Hide then show to ensure scroll bars load.
	tabFrame:Hide()
    if ICT.db.selectedTab == frame.numTabs then
        tabFrame:Show()
    end

	if frame.numTabs == 1 then
		tabButton:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 4, 3)
	else
		tabButton:SetPoint("TOPLEFT", frame.tabs[frame.numTabs-1].button, "TOPRIGHT", -14, 0)
	end
	return frame.numTabs
end

function UI:PrintPlayers()
    local maxX, maxY = 0, 0
    for _, tab in pairs(ICT.frame.tabs) do
        -- Only update the viewed Tab.
        if ICT.db.selectedTab == tab.button:GetID() then
            local x = 0
            local y = 0
            tab.cells:hide()
            _ = tab.prePrint and tab:prePrint()
            if ICT.db.options.multiPlayerView then
                for _, player in ICT:nspairsByValue(ICT.db.players, ICT.Player.isEnabled) do
                    x = x + 1
                    y = math.max(tab:printPlayer(player, x), y)
                end
            else
                local player = self:getSelectedOrDefault()
                x = x + 1
                y = tab:printPlayer(player, x)
                ICT.Options:SetPlayerDropDown(player)
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