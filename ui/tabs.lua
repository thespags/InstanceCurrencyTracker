local addOnName, ICT = ...

local Tabs = {}
ICT.Tabs = Tabs

-- Creates get/set tab functions for the key on the provided table. Used to create a Mixin.
function Tabs:mixin(frame, table, key)
    Mixin(frame, {
        getSelectedTab = function()
            return table[key]
        end,
        setSelectedTab = function(value)
            table[key] = value
        end
    })
end

-- Selects the provided tab storing the info on the parent frame via setSelectedTab.
function Tabs:select(tab)
    return function()
        local parent = tab.parent
        PanelTemplates_SetTab(parent, tab.button:GetID())
        for i=1,parent.numTabs do
            parent.tabs[i]:hide()
        end
        parent.setSelectedTab(tab.button:GetID())
        _ = parent.update and parent.update()
        tab:show()
        if tab.OnSelect then
            tab.OnSelect(tab)
        end
    end
end

-- Adds a tab with a double scroll frame.
function Tabs:addPanel(parent, tab, name)
    local tabFrame = ICT.UI:createDoubleScrollFrame(parent, "ICT" .. name)
    tab.frame = tabFrame
    tab.cells = ICT.Cells:new(tabFrame.content)
    return self:add(parent, tab, name)
end

-- Adds a tab with 
function Tabs:add(parent, tab, name)
    tab.parent = parent
    _ = tab.init and tab:init(parent)
	local frameName = parent:GetName()
	parent.numTabs = parent.numTabs and parent.numTabs + 1 or 1
    parent.tabs = parent.tabs or {}
	local tabButton = CreateFrame("Button", frameName.."Tab"..parent.numTabs, parent, "CharacterFrameTabButtonTemplate")
    tabButton:SetAlpha(1)
    tabButton:SetIgnoreParentAlpha(true)
    parent.tabs[parent.numTabs] = tab
	tabButton:SetID(parent.numTabs)
	tabButton:SetText(name)
	tabButton:SetScript("OnClick", self:select(tab))
	tab.button = tabButton
    -- Hide then show to ensure scroll bars load.
	tab:hide()
    if parent:getSelectedTab() == parent.numTabs then
        tab:show()
    end

	if parent.numTabs == 1 then
		tabButton:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 4, 3)
	else
		tabButton:SetPoint("TOPLEFT", parent.tabs[parent.numTabs-1].button, "TOPRIGHT", -14, 0)
	end
	return parent.numTabs
end