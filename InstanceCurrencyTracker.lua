print("Hello World!")
local db
local function OnEvent(self, event, addOnName)
	if addOnName == "InstanceCurrencyTracker" then -- name as used in the folder name and TOC file name
		InstanceCurrencyDB = InstanceCurrencyDB or {} -- initialize it to a table if this is the first time
		InstanceCurrencyDB.sessions = (InstanceCurrencyDB.sessions or 0) + 1
		print("You loaded this addon "..InstanceCurrencyDB.sessions.." times")	
        db = InstanceCurrencyDB
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)

local options = {}

local CELL_WIDTH = 160
local CELL_HEIGHT = 10
local NUM_CELLS = 5 -- cells per row
-- creating a basic dialog frame (if you name this frame and define basic bits during the load (not after PLAYER_LOGIN), then
-- the client will restore the window position on login to wherever it was last moved by the user)
local f = CreateFrame("Frame", "SimpleScrollFrameTableDemo", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(CELL_WIDTH * NUM_CELLS + 40,300)
f:SetPoint("CENTER")
f:Hide()
f:SetMovable(true)
f:SetScript("OnMouseDown" ,f.StartMoving)
f:SetScript("OnMouseUp", f.StopMovingOrSizing)
 
-- adding a scrollframe (includes basic scrollbar thumb/buttons and functionality)
f.scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
-- Points taken from example online that avoids writing into
f.scrollFrame:SetPoint("TOPLEFT", 12, -32)
f.scrollFrame:SetPoint("BOTTOMRIGHT", -34, 8)
 
-- creating a scrollChild to contain the content
f.scrollFrame.scrollChild = CreateFrame("Frame", nil, f.scrollFrame)
f.scrollFrame.scrollChild:SetSize(100, 100)
f.scrollFrame.scrollChild:SetPoint("TOPLEFT", 5, -5)
f.scrollFrame:SetScrollChild(f.scrollFrame.scrollChild)
 
-- adding content to the scrollChild
local content = f.scrollFrame.scrollChild

content.rows = {} -- each row of data is one wide button stored here
content.columns = {}
GameTooltip:SetOwner(f, "ANCHOR_TOPRIGHT")
GameTooltip:SetText("TEST")
GameTooltip:Show()
content.cells = {}

local function getCell(x, y)
    local name = string.format("cell(%s, %s)", x, y)
    if not content.cells[name] then
        local button = CreateFrame("Button", nil, content)
        button:SetSize(CELL_WIDTH, CELL_HEIGHT)
        button:SetPoint("TOPLEFT", (x - 1) * CELL_WIDTH, -(y - 1) * CELL_HEIGHT)
        content.cells[name] = button
    end
    return content.cells[name]
end

local availableColor = "FFFFFFFF"
local titleColor = "FFFFFF00"
local lockedColor = "FFFF00FF"
local nameColor = "FF00FF00"


local function printCell(x, y, color, text)
    local cell = getCell(x, y)
    local value = cell:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    value:SetPoint("LEFT")
    value:SetText(string.format("|c%s%s|r", color, text))
    return cell
end

local function printInstances(title, instances, offset, i)
    local names = {}
    for _, v in pairs(instances) do
        names[Utils:GetLocalizedInstanceName(v)] = v
    end
    offset = offset + 1
    printCell(i, offset, titleColor, title)
    for _, v in Utils:spairs(names) do
        offset = offset + 1
        local color = v.locked and lockedColor or availableColor
        local cell = printCell(i, offset, color, Utils:GetLocalizedInstanceName(v))
        cell:SetScript("OnEnter", InstanceTooltipOnEnter(v))
        cell:SetScript("OnLeave", InstanceTooltipOnLeave)
    end
    return offset + 1
end

function InstanceTooltipOnEnter(v)
    return function(self, motion)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local color = v.locked and lockedColor or availableColor
        GameTooltip:AddLine(Utils:GetLocalizedInstanceName(v), Utils:hex2rgb(color))
        GameTooltip:AddLine((v.tokenId and Utils:GetCurrencyName(v.tokenId) or "n/a"), Utils:hex2rgb(availableColor))
        GameTooltip:AddLine(string.format("Currency Available: %s" , v.availableEmblems or 0), Utils:hex2rgb(availableColor))
        GameTooltip:AddLine(string.format("Encounters (%s/%s)", (v.encounterProgress or 0), v.numEncounters), Utils:hex2rgb(availableColor))
        GameTooltip:Show()
    end
end

function InstanceTooltipOnLeave(self, motion)
    GameTooltip:Hide()
end

local function printCurrencyVerbose(player, tokenId, offset, i)
    offset = offset + 1
    local currency = Utils:GetCurrencyName(tokenId)
    printCell(i, offset, titleColor, currency)
    offset = offset + 1
    print(tokenId)
    local available = (player.currency.weekly[tokenId] + player.currency.daily[tokenId])  or "n/a"
    printCell(i, offset, availableColor, "Available  " .. available)
    offset = offset + 1
    local current = player.currency.wallet[tokenId] or "n/a"
    printCell(i, offset, availableColor, "Current     " .. current)
    return offset + 1
end

local function printCurrencyShort(player, tokenId, offset, i)
    offset = offset + 1
    local currency = Utils:GetCurrencyName(tokenId)
    local current = player.currency.wallet[tokenId] or "n/a"
    local available = (player.currency.weekly[tokenId] + player.currency.daily[tokenId]) or "n/a"
    local text = string.format("%s |c%s%s (%s)|r", currency, availableColor, current, available)
    printCell(i, offset, text)
    return offset + 1
end

local function foobar()
    local i = 0
    for k, v in pairs(db.players) do
        i = i + 1
        local offset = 1
        printCell(offset, i, nameColor, v.name)
        offset = printInstances("Dungeons", v.dungeons, offset, i)
        offset = printInstances("Raids", v.raids, offset, i)
        local printCurrency = true and printCurrencyVerbose or printCurrencyShort
        for tokenId, _ in pairs(Currency) do
            offset = printCurrency(v, tokenId, offset, i)
        end
    end
end

SLASH_InstanceCurrencyTracker1 = "/ict"; -- new slash command for showing framestack tool
SlashCmdList.InstanceCurrencyTracker = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    -- Any leading non-whitespace is captured into command
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "wipe" and rest ~= "" then
        Emblems:WipeAllPlayers(db)
    else
        db.players = db.players or {}
        local p = Emblems:Update(db)

        for k, v in pairs(db.players) do
            print(k)
        end
        -- Emblems:Display(Emblems:GetPlayer(db), options)
        foobar()
        f:Show()
    end
end
