local addOnName, ICT = ...

ICT.Options = {}
local Options = ICT.Options

-- Helper to set all the currencies as enabled.
local function getOrCreateCurrencyOptions()
    local db = InstanceCurrencyDB
    if not db.options.currency then
        db.options.currency = {}
        for k, _ in pairs(ICT.CurrencyInfo) do
            db.options.currency[k] = true
        end
    end
    return db.options.currency
end

-- Defaults WOTLK instances as shown and old content as off.
local function getOrCreateDisplayInstances()
    local db = InstanceCurrencyDB
    if not db.options.displayInstances then
        db.options.displayInstances = {}
        for k, v in pairs(ICT.InstanceInfo) do
            db.options.displayInstances[k] = v.expansion == ICT.Expansions[ICT.WOTLK]
        end
    end
    return db.options.displayInstances
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

function Options:CreateOptionDropdown(f)
    local dropdown = CreateFrame("FRAME", "ICTOptions", f, "UIDropDownMenuTemplate")
    dropdown:SetPoint("BOTTOM")
    dropdown:SetAlpha(1)
    dropdown:SetIgnoreParentAlpha(true)

    -- Width set to slightly smaller than parent frame.
    UIDropDownMenu_SetWidth(dropdown, 180)
    UIDropDownMenu_SetText(dropdown, "Options")
    local db = InstanceCurrencyDB
    local displayInstances = getOrCreateDisplayInstances()
    local currency = getOrCreateCurrencyOptions()

    UIDropDownMenu_Initialize(
        dropdown,
        function(self, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
            if (level or 1) == 1 then
                -- Switches between full name with realm or simple name.
                info.text = "Show Realm Name"
                info.hasArrow = false
                info.checked = db.options.verboseName or false
                info.func = function(self)
                    db.options.verboseName = not self.checked
                    DisplayPlayer()
                end
                UIDropDownMenu_AddButton(info)

                -- Switches between short and long forms of currency.
                info.text = "Verbose Currency"
                info.hasArrow = false
                info.checked = db.options.verboseCurrency or false
                info.func = function(self)
                    db.options.verboseCurrency = not self.checked
                    DisplayPlayer()
                end
                UIDropDownMenu_AddButton(info)

                -- Turns off instance and quest information in currency.
                info.text = "Simple Currency Tooltip"
                info.hasArrow = false
                info.checked = db.options.simpleCurrencyTooltip or false
                info.func = function(self)
                    db.options.simpleCurrencyTooltip = not self.checked
                    DisplayPlayer()
                end
                UIDropDownMenu_AddButton(info)

                -- Switches between all quests or only those available to the player.
                info.text = "All Quests"
                info.hasArrow = false
                info.checked = db.options.allQuests or false
                info.func = function(self)
                    db.options.allQuests = not self.checked
                    DisplayPlayer()
                end
                UIDropDownMenu_AddButton(info)

                -- Create the currency options.
                info.text = "Currency"
                info.menuList = info.text
                info.hasArrow = true
                info.checked = ICT:containsAllValues(currency)
                info.func = function(self)
                    for k, _ in pairs(ICT.CurrencyInfo) do
                        currency[k] = not self.checked
                    end
                    DisplayPlayer()
                end
                UIDropDownMenu_AddButton(info)

                -- Create the old instance options.
                info.text = "Instances"
                info.menuList = info.text
                info.checked = instanceContainsAll(displayInstances)
                info.hasArrow = true
                info.func = function(self)
                    for _, v in pairs(ICT.InstanceInfo) do
                        displayInstances[v.id] = not self.checked
                    end
                    DisplayPlayer()
                end
                UIDropDownMenu_AddButton(info)
            else
                if menuList == "Currency" then
                    for k, _ in ICT:spairs(ICT.CurrencyInfo, ICT.CurrencySort) do
                        info.text = ICT:GetCurrencyName(k)
                        info.checked = currency[k]
                        info.func = function(self)
                            currency[k] = not currency[k]
                            DisplayPlayer()
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Instances" then
                    -- Create a level for the expansions, then the specific instances.
                    for expansion, v in ICT:spairs(ICT.Expansions, ICT.ExpansionSort) do
                        info.text = expansion
                        info.menuList = expansion
                        info.hasArrow = true
                        info.checked = expansionContainsAll(v)
                        info.func = function(self)
                            for _, instance in ICT.fpairs(ICT.InstanceInfo, Options.isExpansion(v)) do
                                displayInstances[instance.id] = not self.checked
                            end
                            DisplayPlayer()
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end
                else
                    -- Now create a level for all the instances of that expansion.
                    for _, v in ICT:spairsByValue(ICT.InstanceInfo, ICT.InstanceInfoSort, Options.isExpansion(ICT.Expansions[menuList])) do
                        info.text = GetRealZoneText(v.id)
                        info.arg1 = v.id
                        info.checked = Options.showInstance(v)
                        info.func = function(self, id)
                            displayInstances[id] = not self.checked
                            DisplayPlayer()
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end
                end
            end
        end
    )
end

function Options.isExpansion(expansion)
    return function(id) return ICT.InstanceInfo[id].expansion == expansion end
end
