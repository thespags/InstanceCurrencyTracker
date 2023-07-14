print("Hello World!")
local db
local function OnEvent(self, event, addOnName)
	if addOnName == "InstanceEmblemTracker" then -- name as used in the folder name and TOC file name
		InstanceEmblemDB = InstanceEmblemDB or {} -- initialize it to a table if this is the first time
		InstanceEmblemDB.sessions = (InstanceEmblemDB.sessions or 0) + 1
		print("You loaded this addon "..InstanceEmblemDB.sessions.." times")	
        db = InstanceEmblemDB
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)

local options = {}

-- we'll use an ordered table of arbitrary data: {{fruit,number,alphabet},{fruit,number,alphabet},etc}
local fruits = {"apple","banana","orange","pear","tomato","pineapple"}
local numbers = {"one","two","three","four","five","six"}
local alphabet = {"abc","def","ghij","klmn","op","qrstuv","wx","yz"}
local data = {}


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
-- f:SetScript("OnMouseDown" ,f.StartMoving)
-- f:SetScript("OnMouseUp", f.StopMovingOrSizing)
 
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

local function getRow(i)
    if not content.rows[i] then
        local button = CreateFrame("Button", nil, content)
        button:SetSize(CELL_WIDTH, CELL_HEIGHT)
        button:SetPoint("TOPLEFT", 0, -(i-1) * CELL_HEIGHT)
        button.columns = {}
        content.rows[i] = button
        content.rows[i]:Show()
    end
    return content.rows[i]
end

local function printSection(text, offset, i)
    for j=1, #text do
        --print((j + offset).. " " .. text[j])
        local button = getRow(j + offset)
        button.columns[i] = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        button.columns[i]:SetPoint("LEFT", CELL_WIDTH * (i - 1), 0)
        button.columns[i]:SetText(text[j])
    end
    return offset + #text + 1
end

local nameColor = "|cFF00FF00"
local function foobar()
    local i = 0
    content:SetScript("OnEnter", BagBuddy_Button_OnEnter)
    content:SetScript("OnLeave", BagBuddy_Button_OnLeave)
    for k, v in pairs(InstanceEmblemDB.players) do
        i = i + 1

        local availableEmblemsOfConquest = v.availableEmblemsOfConquest + (v.availableDungeonEmblems or 0)
        local availableEmblemsOfTriumph = v.availableEmblemsOfTriumph + (v.availableHeroicDungeonEmblems or 0)
        local printCurrency = true and Player.PrintCurrencyVerbose or Player.PrintCurrencyShort
        local text = { ""}
        local offset = printSection({ nameColor .. v.name .. "|r" }, 0, i)
        text = Player:PrintInstances("Dungeons", v.dungeons, true, true)
        offset = printSection(text, offset, i)
        text = Player:PrintInstances("Raids", v.raids, true, true)
        offset = printSection(text, offset, i)
        text = printCurrency("Emblem of Triumph", v.currentEmblemsOfTriumph, availableEmblemsOfTriumph, true)
        offset = printSection(text, offset, i)
        text = printCurrency("Sidereal Essence", v.currentSiderealEssences, v.availableSiderealEssences, true)
        offset = printSection(text, offset, i)
        text = printCurrency("Champion's Seal", v.currentChampionsSeals, v.availableChampionsSeals, true)
        offset = printSection(text, offset, i)
        text = printCurrency("Emblem of Conquest", v.currentEmblemsOfConquest, availableEmblemsOfConquest, true)
        offset = printSection(text, offset, i)
        text = printCurrency("Emblem of Valor", v.currentEmblemsOfValor, v.availableEmblemsOfValor, true)
        offset = printSection(text, offset, i)
        text = printCurrency("Emblem of Heroism", v.currentEmblemsOfHeroism, v.availableEmblemsOfHeroism, true)
        offset = printSection(text, offset, i)

        for j=1, #text do
            local row = getRow(j)
            local column = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            row.columns[i] = column
            row.columns[i]:SetPoint("LEFT", CELL_WIDTH * (i - 1), 0)
            row.columns[i]:SetText(text[j])
        end
    end
end

function BagBuddy_Button_OnEnter(self, motion)
    print("Test entered", self:GetName())
end

function BagBuddy_Button_OnLeave(self, motion)
    print("test left", self:GetName())
end

SLASH_InstanceEmblemTracker1 = "/ict"; -- new slash command for showing framestack tool
SlashCmdList.InstanceEmblemTracker = function()
    db.players = db.players or {}
    local p = Emblems:Update(db)

    for k, v in pairs(db.players) do
        print(k)
    end
    -- Emblems:Display(Emblems:GetPlayer(db), options)
    foobar()
    f:Show()
end
-- From the guide ---
