Options = {}

-- Helper to set all the currencies as enabled.
local function getOrCreateCurrencyOptions(db)
    if not db.options.currency then
        db.options.currency = {}
        for k, _ in pairs(Currency) do
            db.options.currency[k] = true
        end
    end
    return db.options.currency
end

local function expansionContainsAll(expansion, oldInstances)
    local contains = function(v) return v.expansion ~= expansion or oldInstances[v.id] end
    return Utils:containsAllValue(Instances.oldRaids, contains)
end

local function oldRaidsContainsAll(oldInstances)
    local contains = function(v) return oldInstances[v.id] end
    return Utils:containsAllValue(Instances.oldRaids, contains)
end

function Options:showInstances(instances)
    local contains = function(v) return v.expansion == nil or InstanceCurrencyDB.options.oldInstances[v.id] end
    return Utils:containsAnyValue(instances, contains)
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
    local oldInstances = db.options.oldInstances or {}
    db.options.oldInstances = oldInstances

    local currency = getOrCreateCurrencyOptions(db)

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
                info.checked = Utils:containsAllValue(currency)
                info.func = function(self)
                    for k, _ in pairs(Currency) do
                        currency[k] = not self.checked
                    end
                    DisplayPlayer()
                end
                UIDropDownMenu_AddButton(info)

                -- Create the old instance options.
                info.text = "Instances"
                info.menuList = info.text
                info.checked = oldRaidsContainsAll(oldInstances)
                info.hasArrow = true
                info.func = function(self)
                    for _, instance in pairs(Instances.oldRaids) do
                        oldInstances[instance.id] = not self.checked
                    end
                    DisplayPlayer()
                end
                UIDropDownMenu_AddButton(info)
            else
                if menuList == "Currency" then
                    for k, _ in Utils:spairs(Currency, CurrencySort) do
                        info.text = Utils:GetCurrencyName(k)
                        info.checked = currency[k]
                        info.func = function(self)
                            currency[k] = not currency[k]
                            DisplayPlayer()
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Instances" then
                    -- Create a level for the expansions, then the specific instances.
                    for expansion, _ in Utils:spairs(Expansions, ExpansionSort) do
                        info.text = expansion
                        info.menuList = expansion
                        info.hasArrow = true
                        info.checked = expansionContainsAll(expansion, oldInstances)
                        info.func = function(self)
                            for _, instance in Utils:fpairs(Instances.oldRaids, function(v) return v.expansion == expansion end) do
                                oldInstances[instance.id] = not self.checked
                            end
                            DisplayPlayer()
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end
                else
                    -- Now create a level for all the instances of that expansion.
                    for k, v in Utils:fpairs(Instances.oldRaids, function(v) return v.expansion == menuList end) do
                        info.text = k
                        info.arg1 = v.id
                        info.checked = oldInstances[v.id] or false
                        info.func = function(self, id)
                            oldInstances[id] = not self.checked
                            DisplayPlayer()
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end
                end
            end
        end
    )
end

function Options:InstanceViewable(instance)
    return not instance.expansion or db.options.oldInstances[instance.id]
end