local addOnName, ICT = ...

ICT.Options = {}
local Options = ICT.Options

-- Helper to set all the currencies as enabled.
local function getOrCreateCurrencyOptions()
    if not ICT.db.options.currency then
        ICT.db.options.currency = {}
        for k, _ in pairs(ICT.CurrencyInfo) do
            ICT.db.options.currency[k] = true
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

local function expansionContainsAll(expansion)
    local contains = function(v) return v.expansion ~= expansion or Options.showInstance(v) end
    return ICT:containsAllValues(ICT.InstanceInfo, contains)
end

local function instanceContainsAll(displayInstances)
    local contains = function(v) return displayInstances[v.id] end
    return ICT:containsAllValues(ICT.InstanceInfo, contains)
end

function Options:showInstances(instances)
    return ICT:containsAnyValue(instances, Options.showInstance)
end

function Options.showInstance(instance)
    return InstanceCurrencyDB.options.displayInstances[instance.id]
end

local function createInfo()
    local info = UIDropDownMenu_CreateInfo()
    -- It seems you can't simply do not self.checked if keepShownOnClick is true
    -- otherwise on the first click the menu gets confused...
    info.keepShownOnClick = true
    return info
end

function Options:CreateOptionDropdown()
    local dropdown = CreateFrame("FRAME", "ICTOptions", ICT.frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("BOTTOM", 0, 4)
    dropdown:SetAlpha(1)
    dropdown:SetIgnoreParentAlpha(true)

    -- Width set to slightly smaller than parent frame.
    UIDropDownMenu_SetWidth(dropdown, 160)
    UIDropDownMenu_SetText(dropdown, "Options")
    local db = ICT.db
    local displayInstances = getOrCreateDisplayInstances()
    local currency = getOrCreateCurrencyOptions()
    ICT:setDefaultValue(db.options, "verboseName", false)
    ICT:setDefaultValue(db.options, "showResetTimers", true)
    ICT:setDefaultValue(db.options, "verboseCurrency", false)
    ICT:setDefaultValue(db.options, "verboseCurrencyTooltip", true)
    ICT:setDefaultValue(db.options, "groupMessage", true)
    ICT:setDefaultValue(db.options, "allQuests", false)
    ICT:setDefaultValue(db.options, "showQuests", true)
    
    UIDropDownMenu_Initialize(
        dropdown,
        function(self, level, menuList)
            if (level or 1) == 1 then
                -- Switches between full name with realm or simple name.
                local realmName = createInfo()
                realmName.text = "Realm Name"
                realmName.hasArrow = false
                realmName.checked = db.options.verboseName
                realmName.func = function(self)
                    db.options.verboseName = not db.options.verboseName
                    ICT:DisplayPlayer()
                end
                UIDropDownMenu_AddButton(realmName)
                
                -- Switches reset timers on/off
                local resetTimers = createInfo()
                resetTimers.text = "Reset Timers"
                resetTimers.hasArrow = false
                resetTimers.checked = db.options.showResetTimers
                resetTimers.func = function(self)
                    db.options.showResetTimers = not db.options.showResetTimers
                    ICT:DisplayPlayer()
                end
                UIDropDownMenu_AddButton(resetTimers)

                -- Switches between short and long forms of currency.
                local verboseCurrency = createInfo()
                verboseCurrency.text = "Verbose Currency"
                verboseCurrency.keepShownOnClick = true
                verboseCurrency.hasArrow = false
                verboseCurrency.checked = db.options.verboseCurrency
                verboseCurrency.func = function(self)
                    db.options.verboseCurrency = not db.options.verboseCurrency
                    ICT:DisplayPlayer()
                end
                UIDropDownMenu_AddButton(verboseCurrency)

                -- Turns on/off instance and quest information in currency.
                local verboseCurrencyTooltip = createInfo()
                verboseCurrencyTooltip.text = "Verbose Currency Tooltip"
                verboseCurrencyTooltip.hasArrow = false
                verboseCurrencyTooltip.checked = db.options.verboseCurrencyTooltip
                verboseCurrencyTooltip.func = function(self)
                    db.options.verboseCurrencyTooltip = not db.options.verboseCurrencyTooltip
                    ICT:DisplayPlayer()
                end
                UIDropDownMenu_AddButton(verboseCurrencyTooltip)

                local groupMessage = createInfo()
                groupMessage.text = "Group Message"
                groupMessage.hasArrow = false
                groupMessage.checked = db.options.groupMessage
                groupMessage.func = function(self)
                    db.options.groupMessage = not db.options.groupMessage
                end
                UIDropDownMenu_AddButton(groupMessage)

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
                UIDropDownMenu_AddButton(quests)

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
                UIDropDownMenu_AddButton(currencyInfo)

                -- Create the old instance options.
                local instances = createInfo()
                instances.text = "Instances"
                instances.menuList = instances.text
                instances.checked = instanceContainsAll(displayInstances)
                instances.hasArrow = true
                instances.func = function(self)
                    local wasChecked = instanceContainsAll(displayInstances)
                    for _, v in pairs(ICT.InstanceInfo) do
                        displayInstances[v.id] = not wasChecked
                    end
                    ICT:DisplayPlayer()
                end
                UIDropDownMenu_AddButton(instances)
            elseif level == 2 then
                if menuList == "Currency" then
                    for k, _ in ICT:spairs(ICT.CurrencyInfo, ICT.CurrencySort) do
                        local info = createInfo()
                        info.text = ICT:GetCurrencyName(k)
                        info.checked = currency[k]
                        info.func = function(self)
                            currency[k] = not currency[k]
                            ICT:DisplayPlayer()
                        end
                        UIDropDownMenu_AddButton(info, level)
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
                            for _, instance in ICT:fpairs(ICT.InstanceInfo, Options.isExpansion(v)) do
                                displayInstances[instance.id] = not wasChecked
                            end
                            ICT:DisplayPlayer()
                        end
                        UIDropDownMenu_AddButton(info, level)
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
                    UIDropDownMenu_AddButton(allAvailableQuests, level)

                    local showQuests = createInfo()
                    showQuests.text = "Show Quests"
                    showQuests.checked = db.options.showQuests
                    showQuests.func = function(self)
                        db.options.showQuests = not db.options.showQuests
                        ICT:DisplayPlayer()
                    end
                    UIDropDownMenu_AddButton(showQuests, level)
                end
            elseif level == 3 then
                -- If we had another 3rd layer thing we need to check if menuList is an expansion.
                -- Now create a level for all the instances of that expansion.
                for _, v in ICT:spairsByValue(ICT.InstanceInfo, ICT.InstanceInfoSort, Options.isExpansion(ICT.Expansions[menuList])) do
                    local info = createInfo()
                    info.text = GetRealZoneText(v.id)
                    info.arg1 = v.id
                    info.checked = Options.showInstance(v)
                    info.func = function(self, id)
                        displayInstances[id] = not Options.showInstance(v)
                        ICT:DisplayPlayer()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end
    )
end

function Options.isExpansion(expansion)
    return function(id) return ICT.InstanceInfo[id].expansion == expansion end
end

function Options:PrintMessage(text)
    if IsInGroup() and ICT.db.options.groupMessage then
        local type = IsInRaid() and "RAID" or "PARTY"
        SendChatMessage(text, type)
    else
        print(text)
    end
end