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

SLASH_InstanceCurrencyTracker1 = "/ict"; -- new slash command for showing framestack tool
SlashCmdList.InstanceCurrencyTracker = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    -- Any leading non-whitespace is captured into command
    -- the rest (minus leading whitespace) is captured into rest.
    if command == "wipe" then
        if rest == "" then
            Player:WipePlayer(db, Utils:GetFullName())
        elseif rest == "all" then
            Player:WipeAllPlayers(db)
        else
            command, rest = msg:match("^(%S*)%s*(.-)$")
            if command == "realm" then
                Player:WipeRealm(db, rest)
            elseif command == "player" then
                Player:WipePlayer(db, rest)
            else
                print("Invalid command")
            end
        end
    else
        db.players = db.players or {}
        Player:Update(db)
        print("Hello World")
        Foobar(db)
    end
end

local function createPlayerDropdown()
    local dropdown = CreateFrame("Frame", "test", f, 'UIDropDownMenuTemplate')
    dropdown:SetPoint("TOPLEFT", f);

    UIDropDownMenu_SetWidth(dropdown, 200)
    -- current player
    UIDropDownMenu_SetText(dropdown, default_val)
    local info = UIDropDownMenu_CreateInfo()
    for k, v in pairs(db.players) do
        info.text = v.name
        UIDropDownMenu_AddButton(info)
    end
end

-- TODO add 
-- "ict wipe" current player
-- "ict wipe realm name"
-- "ict wipe player name"
-- "ict wipe all"
-- TODO add options
-- TODO add tabs

-- --- Opts:
-- ---     name (string): Name of the dropdown (lowercase)
-- ---     parent (Frame): Parent frame of the dropdown.
-- ---     items (Table): String table of the dropdown options.
-- ---     defaultVal (String): String value for the dropdown to default to (empty otherwise).
-- ---     changeFunc (Function): A custom function to be called, after selecting a dropdown option.
local function createDropdown(opts)
    local dropdown_name = '$parent_' .. opts['name'] .. '_dropdown'
    local menu_items = opts['items'] or {}
    local title_text = opts['title'] or ''
    local dropdown_width = 0
    local default_val = opts['defaultVal'] or ''
    local change_func = opts['changeFunc'] or function (dropdown_val) end

    local dropdown = CreateFrame("Frame", dropdown_name, opts['parent'], 'UIDropDownMenuTemplate')

    local dd_title = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dd_title:SetPoint("TOPLEFT", 20, 10)

    for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
        dd_title:SetText(item)
        local text_width = dd_title:GetStringWidth() + 20
        if text_width > dropdown_width then
            dropdown_width = text_width
        end
    end

    UIDropDownMenu_SetWidth(dropdown, dropdown_width)
    UIDropDownMenu_SetText(dropdown, default_val)
    dd_title:SetText(title_text)

    UIDropDownMenu_Initialize(dropdown, function(self, level, _)
        local info = UIDropDownMenu_CreateInfo()
        for key, val in pairs(menu_items) do
            info.checked = false
            info.menuList= key
            info.hasArrow = false
            info.func = function(b)
                UIDropDownMenu_SetSelectedValue(dropdown, b.value, b.value)
                UIDropDownMenu_SetText(dropdown, b.value)
                b.checked = true
                change_func(dropdown, b.value)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    return dropdown
end

-- local raid_opts = {
--     ['name']='raid',
--     ['parent']=f,
--     ['title']='Raid',
--     ['items']= {'Molten Core', 'Blackwing Lair', 'Onyxia\'s' },
--     ['defaultVal']='', 
--     ['changeFunc']=function(dropdown_frame, dropdown_val)
--         print(dropdown_val) -- Custom logic goes here, when you change your dropdown option.
--     end
-- }
-- raidDD = createDropdown(raid_opts)-- Don't forget to set your dropdown's points, we don't do this in the creation method for simplicities sake.
-- raidDD:SetPoint("TOPLEFT", f);
