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

-- Returns true if all values or mapped values in the table are true, otherwise false.
local function containsAll(t, filter, op)
    for _, v in pairs(t) do
        if (not filter or filter(v)) and ((op and not op(v)) or not v) then
            return false
        end
    end
    return true
end

local function expansionContainsAll(expansion, oldInstances)
    local filter = function(v) return v.expansion == expansion end
    local contains = function(v) return oldInstances[v.id] end
    return containsAll(Instances.oldRaids, filter, contains)
end

local function oldRaidsContainsAll(oldInstances)
    local contains = function(v) return oldInstances[v.id] end
    return containsAll(Instances.oldRaids, ReturnX(true), contains)
end

function CreateOptionDropdown(db, f)
    local dropdown = CreateFrame("FRAME", "ICTOptions", f, "UIDropDownMenuTemplate")
    dropdown:SetPoint("BOTTOM")
    dropdown:SetAlpha(1)
    dropdown:SetIgnoreParentAlpha(true)

    -- Width set to slightly smaller than parent frame.
    UIDropDownMenu_SetWidth(dropdown, 180)
    UIDropDownMenu_SetText(dropdown, "Options")
    local oldInstances = db.options.oldInstances or {}
    db.options.oldInstances = oldInstances

    local currency = getOrCreateCurrencyOptions(db)

    UIDropDownMenu_Initialize(
        dropdown,
        function(self, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
            if (level or 1) == 1 then
                -- Create the currency options.
                info.text = "Currency"
                info.menuList = info.text
                info.hasArrow = true
                info.checked = containsAll(currency)
                info.func = function(self)
                    for k, _ in pairs(Currency) do
                        currency[k] = not self.checked
                    end
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