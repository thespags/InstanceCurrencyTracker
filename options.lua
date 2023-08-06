local addOnName, ICT = ...

ICT.Options = {}
local Options = ICT.Options
local Player = ICT.Player
local frameLabel = "      Frame"

-- Helper to set all the currencies as enabled.
local function getOrCreateCurrencyOptions()
    if not ICT.db.options.currency then
        ICT.db.options.currency = {}
        for k, _ in pairs(ICT.CurrencyInfo) do
            -- Display heroism and up (i.e. recent currency) by default.
            ICT.db.options.currency[k] = ICT.CurrencyInfo[k].order >= ICT.CurrencyInfo[ICT.Heroism].order
        end
    end
    return ICT.db.options.currency
end

-- Defaults WOTLK instances as shown and old content as off.
local function getOrCreateDisplayInstances()
    if not ICT.db.options.displayInstances then
        ICT.db.options.displayInstances = {}
        for k, v in pairs(ICT.InstanceInfo) do
            ICT.db.options.displayInstances[k] = v.expansion == ICT.Expansions[ICT.WOTLK]
        end
    end
    return ICT.db.options.displayInstances
end

local function getOrCreateDisplayLegacyInstances(expansion)
    ICT:putIfAbsent(ICT.db.options, "displayLegacyInstances", {})
    local t = ICT.db.options.displayLegacyInstances
    ICT:putIfAbsent(t, expansion, {})
    return t[expansion]
end

local function getOrCreateResetTimerOptions()
    if not ICT.db.options.reset then
        ICT.db.options.reset = { [1] = true, [3] = false, [5] = false, [7] = true}
    end
    return ICT.db.options.reset
end

local function showInstanceInfo(info, expansion)
    if info.legacy == expansion then
        return getOrCreateDisplayLegacyInstances(expansion)[info.id]
    end
    return getOrCreateDisplayInstances()[info.id]
end

local function expansionContainsAll(expansion)
    local contains = function(info)
        if info.legacy == expansion then
            return getOrCreateDisplayLegacyInstances(expansion)[info.id]
        end
        return info.expansion ~= expansion or getOrCreateDisplayInstances()[info.id]
    end
    return ICT:containsAllValues(ICT.InstanceInfo, contains)
end

local function instanceContainsAll()
    local contains = function(info)
        return getOrCreateDisplayInstances()[info.id] and (not info.legacy or getOrCreateDisplayLegacyInstances(info.legacy)[info.id])
    end
    return ICT:containsAllValues(ICT.InstanceInfo, contains)
end

function Options:showInstances(instances)
    return ICT:containsAnyValue(instances, Options.showInstance)
end

function Options.showInstance(instance)
    local info = ICT.InstanceInfo[instance.id]
    if instance.legacy then
        return getOrCreateDisplayLegacyInstances(info.legacy)[info.id]
    end
    return getOrCreateDisplayInstances()[info.id]
end

local function checkInstance(info, value, expansion)
    if not expansion or info.expansion == expansion then
        getOrCreateDisplayInstances()[info.id] = value
    end
    if (not expansion and info.legacy) or (expansion and info.legacy == expansion) then
        getOrCreateDisplayLegacyInstances(info.legacy)[info.id] = value
    end
end

function Options:FlipMinimapIcon()
    if ICT.db.options.showMinimapIcon then
        ICT.LDBIcon:Show(addOnName)
    else
        ICT.LDBIcon:Hide(addOnName)
    end
end

function Options:FlipOptionsMenu()
    if ICT.db.options.multiPlayerView then
        ICT.frame.playerDropdown:Hide()
    else
        ICT.frame.playerDropdown:Show()
    end
end

local function createInfo()
    local info = ICT.DDMenu:UIDropDownMenu_CreateInfo()
    -- It seems you can't simply do not self.checked if keepShownOnClick is true
    -- otherwise on the first click the menu gets confused...
    info.keepShownOnClick = true
    return info
end

function Options:CreateOptionDropdown()
    local dropdown = ICT.DDMenu:Create_UIDropDownMenu("ICTOptions", ICT.frame)
    dropdown:SetPoint("TOP", ICT.frame, "BOTTOM", 0, 2)
    -- dropdown:SetPoint("TOPRIGHT", ICT.frame, "BOTTOMRIGHT")
    dropdown:SetAlpha(1)
    dropdown:SetIgnoreParentAlpha(true)

    -- Width set to slightly smaller than parent frame.
    ICT.DDMenu:UIDropDownMenu_SetWidth(dropdown, 160)
    ICT.DDMenu:UIDropDownMenu_SetText(dropdown, "Options")
    local db = ICT.db
    getOrCreateDisplayInstances()
    local currency = getOrCreateCurrencyOptions()
    local resets = getOrCreateResetTimerOptions()
    ICT:putIfAbsent(db.options, "verboseName", false)
    ICT:putIfAbsent(db.options, "multiPlayerView", false)
    ICT:putIfAbsent(db.options, "showResetTimers", true)
    ICT:putIfAbsent(db.options, "verboseCurrency", false)
    ICT:putIfAbsent(db.options, "verboseCurrencyTooltip", true)
    ICT:putIfAbsent(db.options, "groupMessage", true)
    ICT:putIfAbsent(db.options, "allQuests", false)
    ICT:putIfAbsent(db.options, "showQuests", true)
    ICT:putIfAbsent(db.options, "anchorLFG", true)

    ICT.DDMenu:UIDropDownMenu_Initialize(
        dropdown,
        function(self, level, menuList)
            if (level or 1) == 1 then
                -- Switches between full name with realm or simple name.
                local realmName = createInfo()
                realmName.text = "Realm Name"
                realmName.hasArrow = false
                realmName.checked = db.options.verboseName
                realmName.tooltipTitle = realmName.text
                realmName.tooltipOnButton = true
                realmName.tooltipText = "Shows [{realm name}] {player name} versus {player name}."
                realmName.func = function(self)
                    db.options.verboseName = not db.options.verboseName
                    ICT:DisplayPlayer()
                end
                ICT.DDMenu:UIDropDownMenu_AddButton(realmName)
            
                -- Switches between a single character and multiple characters to view.
                local verboseCurrency = createInfo()
                verboseCurrency.text = "Multi Character View"
                verboseCurrency.keepShownOnClick = true
                verboseCurrency.hasArrow = false
                verboseCurrency.checked = db.options.multiPlayerView
                verboseCurrency.tooltipTitle = verboseCurrency.text
                verboseCurrency.tooltipOnButton = true
                verboseCurrency.tooltipText = "Displays all selected characters in the frame or a single character selected with the drop down list."
                verboseCurrency.func = function(self)
                    db.options.multiPlayerView = not db.options.multiPlayerView
                    Options:FlipOptionsMenu()
                    ICT:DisplayPlayer()
                end
                ICT.DDMenu:UIDropDownMenu_AddButton(verboseCurrency)

                -- Turn on/off sending messages when leaving an instance.
                local groupMessage = createInfo()
                groupMessage.text = "Group Message"
                groupMessage.hasArrow = false
                groupMessage.checked = db.options.groupMessage
                groupMessage.tooltipTitle = groupMessage.text
                groupMessage.tooltipOnButton = true
                groupMessage.tooltipText = "Messages your party or raid on leaving an instance with the collected currency. Otherwise prints to your chat window only."
                groupMessage.func = function(self)
                    db.options.groupMessage = not db.options.groupMessage
                end
                ICT.DDMenu:UIDropDownMenu_AddButton(groupMessage)

                local players = createInfo()
                players.text = "Characters"
                players.menuList = players.text
                players.checked = ICT:containsAllValues(ICT.db.players, function(v) return not v.isDisabled end)
                players.hasArrow = true
                players.tooltipTitle = players.text
                players.tooltipOnButton = true
                players.tooltipText = "Enables and disables characters from view in the drop down selection (single view) or frame (multi character view)."
                players.func = function(self)
                    local wasDisabled = ICT:containsAnyValue(ICT.db.players, function(v) return v.isDisabled end)
                    for _, player in pairs(ICT.db.players) do
                        player.isDisabled = not wasDisabled
                    end
                    ICT:DisplayPlayer()
                end
                ICT.DDMenu:UIDropDownMenu_AddButton(players)

                local reset = createInfo()
                reset.text = "Reset Timers"
                reset.menuList = reset.text
                reset.checked = ICT:containsAllValues(resets)
                reset.hasArrow = true
                reset.func = function(self)
                    local wasChecked = ICT:containsAllValues(resets)
                    for k, _ in pairs(ICT.ResetInfo) do
                        resets[k] = not wasChecked
                    end
                    ICT:DisplayPlayer()
                end
                ICT.DDMenu:UIDropDownMenu_AddButton(reset)

                -- Create the instance options.
                local instances = createInfo()
                instances.text = "Instances"
                instances.menuList = instances.text
                instances.checked = instanceContainsAll()
                instances.hasArrow = true
                instances.func = function(self)
                    local wasChecked = instanceContainsAll()
                    for _, v in pairs(ICT.InstanceInfo) do
                        checkInstance(v, not wasChecked)
                    end
                    ICT:DisplayPlayer()
                end
                ICT.DDMenu:UIDropDownMenu_AddButton(instances)

                local quests = createInfo()
                quests.text = "Quests"
                quests.menuList = quests.text
                quests.checked = db.options.allQuests and db.options.showQuests
                quests.hasArrow = true
                quests.func = function(self)
                    local wasChecked = db.options.allQuests and db.options.showQuests
                    db.options.allQuests = not wasChecked
                    db.options.showQuests = not wasChecked
                    ICT:DisplayPlayer()
                end
                ICT.DDMenu:UIDropDownMenu_AddButton(quests)

                -- Create the currency options.
                local currencyInfo = createInfo()
                currencyInfo.text = "Currency"
                currencyInfo.menuList = currencyInfo.text
                currencyInfo.hasArrow = true
                currencyInfo.checked = ICT:containsAllValues(currency)
                currencyInfo.func = function(self)
                    local wasChecked = ICT:containsAllValues(currency)
                    for k, _ in pairs(ICT.CurrencyInfo) do
                        currency[k] = not wasChecked
                    end
                    ICT:DisplayPlayer()
                end
                ICT.DDMenu:UIDropDownMenu_AddButton(currencyInfo)
                ICT.DDMenu:UIDropDownMenu_AddSeparator()

                -- Indent to make up for missing icon.
                local display = createInfo()
                display.text = "      Frame"
                display.menuList = display.text
                display.midWidth = 1000
                display.notCheckable = true
                display.hasArrow = true
                ICT.DDMenu:UIDropDownMenu_AddButton(display)
            elseif level == 2 then
                if menuList == "Characters" then
                    for _, player in ICT:spairsByValue(ICT.db.players, Player.PlayerSort, Player.IsMaxLevel) do
                        local info = createInfo()
                        info.text = ICT.Player.GetName(player)
                        info.value = player.fullName
                        info.checked = not player.isDisabled
                        info.func = function(self)
                            player.isDisabled = not player.isDisabled
                            ICT:DisplayPlayer()
                        end
                        ICT.DDMenu:UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Reset Timers" then
                    for k, v in ICT:spairs(ICT.ResetInfo) do
                        local info = createInfo()
                        info.text = v.name
                        info.checked = resets[k]
                        info.func = function(self)
                            resets[k] = not resets[k]
                            ICT:DisplayPlayer()
                        end
                        ICT.DDMenu:UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Instances" then
                    -- Create a level for the expansions, then the specific instances.
                    for expansion, v in ICT:spairs(ICT.Expansions, ICT.ExpansionSort) do
                        local info = createInfo()
                        info.text = expansion
                        info.menuList = expansion
                        info.hasArrow = true
                        info.checked = expansionContainsAll(v)
                        info.func = function(self)
                            local wasChecked = expansionContainsAll(v)
                            for _, instance in ICT:fpairsByValue(ICT.InstanceInfo, Options.isExpansion(v)) do
                                checkInstance(instance, not wasChecked, ICT.Expansions[expansion])
                            end
                            ICT:DisplayPlayer()
                        end
                        ICT.DDMenu:UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Quests" then
                    -- Switches between all quests or only those available to the player.
                    local allAvailableQuests = createInfo()
                    allAvailableQuests.text = "Show Unavailable Quests"
                    allAvailableQuests.checked = db.options.allQuests
                    allAvailableQuests.func = function(self)
                        db.options.allQuests = not db.options.allQuests
                        ICT:DisplayPlayer()
                    end
                    ICT.DDMenu:UIDropDownMenu_AddButton(allAvailableQuests, level)

                    local showQuests = createInfo()
                    showQuests.text = "Show Quests"
                    showQuests.checked = db.options.showQuests
                    showQuests.func = function(self)
                        db.options.showQuests = not db.options.showQuests
                        ICT:DisplayPlayer()
                    end
                    ICT.DDMenu:UIDropDownMenu_AddButton(showQuests, level)
                elseif menuList == "Currency" then
                    for k, _ in ICT:spairs(ICT.CurrencyInfo, ICT.CurrencySort) do
                        local info = createInfo()
                        info.text = ICT:GetCurrencyName(k)
                        info.checked = currency[k]
                        info.func = function(self)
                            currency[k] = not currency[k]
                            ICT:DisplayPlayer()
                        end
                        ICT.DDMenu:UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == frameLabel then
                    local anchorLFG = createInfo()
                    anchorLFG.text = "Anchor to LFG"
                    anchorLFG.checked = db.options.anchorLFG
                    anchorLFG.tooltipTitle = anchorLFG.text
                    anchorLFG.tooltipOnButton = true
                    anchorLFG.tooltipText = "Brings up the frame when viewing the LFG frame otherwise detaches from the frame."
                    anchorLFG.func = function(self)
                        db.options.anchorLFG = not db.options.anchorLFG
                    end
                    ICT.DDMenu:UIDropDownMenu_AddButton(anchorLFG, level)

                    local minimap = createInfo()
                    minimap.text = "Show Minimap Icon"
                    minimap.checked = db.options.showMinimapIcon
                    minimap.func = function(self)
                        db.options.showMinimapIcon = not db.options.showMinimapIcon
                        ICT.db.minimap.hide = not db.options.showMinimapIcon
                        Options:FlipMinimapIcon()
                    end
                    ICT.DDMenu:UIDropDownMenu_AddButton(minimap, level)

                    -- Switches between short and long forms of currency.
                    local order = createInfo()
                    order.text = "Order Lock Last"
                    order.keepShownOnClick = true
                    order.hasArrow = false
                    order.checked = db.options.orderLockLast
                    order.tooltipTitle = order.text
                    order.tooltipOnButton = true
                    order.tooltipText = "Orders locked instances and completed quests after available instances and quests."
                    order.func = function(self)
                        db.options.orderLockLast = not db.options.orderLockLast
                        ICT:DisplayPlayer()
                    end
                    ICT.DDMenu:UIDropDownMenu_AddButton(order, level)

                    -- Switches between short and long forms of currency.
                    local verboseCurrency = createInfo()
                    verboseCurrency.text = "Verbose Currency"
                    verboseCurrency.keepShownOnClick = true
                    verboseCurrency.hasArrow = false
                    verboseCurrency.checked = db.options.verboseCurrency
                    verboseCurrency.tooltipTitle = verboseCurrency.text
                    verboseCurrency.tooltipOnButton = true
                    verboseCurrency.tooltipText = "Multiline currency view or a single line currency view."
                    verboseCurrency.func = function(self)
                        db.options.verboseCurrency = not db.options.verboseCurrency
                        ICT:DisplayPlayer()
                    end
                    ICT.DDMenu:UIDropDownMenu_AddButton(verboseCurrency, level)

                    -- Turns on/off instance and quest information in currency.
                    local verboseCurrencyTooltip = createInfo()
                    verboseCurrencyTooltip.text = "Verbose Currency Tooltip"
                    verboseCurrencyTooltip.hasArrow = false
                    verboseCurrencyTooltip.checked = db.options.verboseCurrencyTooltip
                    verboseCurrencyTooltip.tooltipTitle = verboseCurrencyTooltip.text
                    verboseCurrencyTooltip.tooltipOnButton = true
                    verboseCurrencyTooltip.tooltipText = "Shows instances and quests currency available and total currency for the hovered over currency"
                    verboseCurrencyTooltip.func = function(self)
                        db.options.verboseCurrencyTooltip = not db.options.verboseCurrencyTooltip
                        ICT:DisplayPlayer()
                    end
                    ICT.DDMenu:UIDropDownMenu_AddButton(verboseCurrencyTooltip, level)
                end
            elseif level == 3 then
                -- If we had another 3rd layer thing we need to check if menuList is an expansion.
                -- Now create a level for all the instances of that expansion.
                local expansion = ICT.Expansions[menuList]
                for _, v in ICT:spairsByValue(ICT.InstanceInfo, ICT.InstanceInfoSort, Options.isExpansion(expansion)) do
                    local info = createInfo()
                    info.text = GetRealZoneText(v.id)
                    info.arg1 = v
                    info.checked = showInstanceInfo(v, expansion)
                    info.func = function(self, instance)
                        checkInstance(instance, not showInstanceInfo(v, expansion), expansion)
                        ICT:DisplayPlayer()
                    end
                    ICT.DDMenu:UIDropDownMenu_AddButton(info, level)
                end
            end
        end
    )
end

-- Applied to instance infos.
function Options.isExpansion(expansion)
    -- Legacy case handles instances that are reused, presuming they aren't reused multiple times...
    return function(info) return info.expansion == expansion or info.legacy == expansion end
end

function Options:PrintMessage(text)
    if IsInGroup() and ICT.db.options.groupMessage then
        local type = IsInRaid() and "RAID" or "PARTY"
        SendChatMessage(text, type)
    else
        print(text)
    end
end