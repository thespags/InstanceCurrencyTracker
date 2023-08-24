local addOnName, ICT = ...

local DDM = LibStub("LibUIDropDownMenu-4.0")
ICT.Options = {}
local Options = ICT.Options
local Cooldowns = ICT.Cooldowns
local Instances = ICT.Instances
local Player = ICT.Player

-- Helper to set all the currencies as enabled.
function ICT.getOrCreateCurrencyOptions()
    if not ICT.db.options.currency then
        ICT.db.options.currency = {}

        for _, v in ipairs(ICT.Currencies) do
            -- Display heroism and lower by default. (i.e. recent currency as new ones are added to the front of the table).
            ICT.db.options.currency[v.id] = v <= ICT.Heroism
        end
    end
    return ICT.db.options.currency
end

function ICT.getOrCreateDifficultyOptions()
    if not ICT.db.options.difficulty then
        ICT.db.options.difficulty = {}
        local size = #Instances.Difficulty
        for k, _ in ipairs(Instances.Difficulty) do
            ICT.db.options.difficulty[k] = k == size
        end
    end
    return ICT.db.options.difficulty
end

-- Defaults WOTLK instances as shown and old content as off.
function ICT.getOrCreateDisplayInstances()
    if not ICT.db.options.displayInstances then
        ICT.db.options.displayInstances = {}
        for k, v in pairs(Instances.infos()) do
            ICT.db.options.displayInstances[k] = v.expansion == ICT.Expansions[ICT.WOTLK]
        end
    end
    return ICT.db.options.displayInstances
end

-- Defaults WOTLK cooldowns as shown and old content as off.
function ICT.getOrCreateDisplayCooldowns()
    if not ICT.db.options.displayCooldowns then
        ICT.db.options.displayCooldowns = {}
        for k, v in pairs(Cooldowns.spells) do
            ICT.db.options.displayCooldowns[k] = v.expansion == ICT.Expansions[ICT.WOTLK]
        end
    end
    return ICT.db.options.displayCooldowns
end

function ICT.getOrCreateDisplayLegacyInstances(expansion)
    ICT:putIfAbsent(ICT.db.options, "displayLegacyInstances", {})
    local t = ICT.db.options.displayLegacyInstances
    ICT:putIfAbsent(t, expansion, {})
    return t[expansion]
end

function ICT.getOrCreateResetTimerOptions()
    if not ICT.db.options.reset then
        ICT.db.options.reset = { [1] = true, [3] = false, [5] = false, [7] = true}
    end
    return ICT.db.options.reset
end

local function expansionContainsAllInstances(expansion)
    local contains = function(info)
        -- todo check how onyxia 40 works, my attempt is that it shoudl rewrite the expansion and we don't need "legacy"
        if info.legacy == expansion then
            return ICT.getOrCreateDisplayLegacyInstances(expansion)[info.id]
        end
        return info.expansion ~= expansion or ICT.getOrCreateDisplayInstances()[info.id]
    end
    return ICT:containsAllValues(Instances.infos(), contains)
end

local function instanceContainsAll()
    return ICT:containsAllValues(Instances.infos(), Instances.isVisible)
end

local function checkInstance(info, value, expansion)
    if not expansion or info.expansion == expansion then
        ICT.getOrCreateDisplayInstances()[info.id] = value
    end
    if (not expansion and info.legacy) or (expansion and info.legacy == expansion) then
        ICT.getOrCreateDisplayLegacyInstances(info.legacy)[info.id] = value
    end
end

local function expansionContainsAllCooldowns(expansion)
    local contains = function(cooldown)
        return cooldown.expansion ~= expansion or cooldown:isVisible()
    end
    return ICT:containsAllValues(Cooldowns.spells, contains)
end

local function cooldownContainsAll()
    return ICT:containsAllValues(Cooldowns.spells, Cooldowns.isVisible)
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

function Options:FlipSlider()
    if ICT.db.options.showLevelSlider then
        ICT.frame.levelSlider:Show()
    else
        ICT.frame.levelSlider:Hide()
    end
end

local function createInfo(text)
    local info = DDM:UIDropDownMenu_CreateInfo()
    info.text = text
    -- It seems you can't simply do not self.checked if keepShownOnClick is true
    -- otherwise on the first click the menu gets confused...
    info.keepShownOnClick = true
    return info
end

local function addPlayerOption(title, key, level, tooltip)
    local info = createInfo(title)
    info.arg1 = ICT.db.options
    info.checked = ICT.db.options.player[key]
    info.func = function(self, options)
        options.player[key] = not options.player[key]
        ICT:PrintPlayers()
    end
    if tooltip then
        info.tooltipTitle = title
        info.tooltipOnButton = true
        info.tooltipText = tooltip
    end
    DDM:UIDropDownMenu_AddButton(info, level)
end

function Options:CreateOptionDropdown()
    local dropdown = DDM:Create_UIDropDownMenu("ICTOptions", ICT.frame)
    ICT.frame.options = dropdown
    dropdown:SetPoint("TOP", ICT.frame, "BOTTOM", 0, 2)
    dropdown:SetAlpha(1)
    dropdown:SetIgnoreParentAlpha(true)

    -- Width set to slightly smaller than parent frame.
    DDM:UIDropDownMenu_SetWidth(dropdown, 160)
    DDM:UIDropDownMenu_SetText(dropdown, "Options")
    local options = ICT.db.options
    options.player = options.player or {}
    ICT.getOrCreateDisplayInstances()
    ICT.getOrCreateDisplayCooldowns()
    local currency = ICT.getOrCreateCurrencyOptions()
    local resets = ICT.getOrCreateResetTimerOptions()
    --local difficulty = ICT.getOrCreateDifficultyOptions()

    ICT:putIfAbsent(options, "verboseName", false)
    ICT:putIfAbsent(options, "multiPlayerView", false)
    ICT:putIfAbsent(options, "groupMessage", true)
    ICT:putIfAbsent(options, "showResetTimers", true)
    ICT:putIfAbsent(options, "allQuests", false)
    ICT:putIfAbsent(options, "showQuests", true)
    ICT:putIfAbsent(options, "anchorLFG", true)
    ICT:putIfAbsent(options, "showMinimapIcon", false)
    ICT:putIfAbsent(options, "orderLockLast", false)
    ICT:putIfAbsent(options, "verboseCurrency", false)
    ICT:putIfAbsent(options, "verboseCurrencyTooltip", true)
    ICT:putIfAbsent(options, "showLevelSlider", true)
    ICT:putIfAbsent(options.player, "showLevel", true)
    ICT:putIfAbsent(options.player, "showGuild", true)
    ICT:putIfAbsent(options.player, "showMoney", true)
    ICT:putIfAbsent(options.player, "showDurability", true)
    ICT:putIfAbsent(options.player, "showXP", true)
    ICT:putIfAbsent(options.player, "showRestedXP", true)
    ICT:putIfAbsent(options.player, "showRestedState", true)
    ICT:putIfAbsent(options.player, "showBags", true)
    ICT:putIfAbsent(options.player, "showBankBags", true)
    ICT:putIfAbsent(options.player, "showSpecs", true)
    ICT:putIfAbsent(options.player, "showGearScores", true)
    ICT:putIfAbsent(options.player, "showProfessions", true)

    DDM:UIDropDownMenu_Initialize(
        dropdown,
        function(self, level, menuList)
            if (level or 1) == 1 then
                -- Switches between full name with realm or simple name.
                local realmName = createInfo("Realm Name")
                realmName.hasArrow = false
                realmName.checked = options.verboseName
                realmName.tooltipTitle = realmName.text
                realmName.tooltipOnButton = true
                realmName.tooltipText = "Shows [{realm name}] {player name} versus {player name}."
                realmName.func = function(self)
                    options.verboseName = not options.verboseName
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(realmName)

                -- Switches between a single character and multiple characters to view.
                local multiPlayerView = createInfo("Multi Character View")
                multiPlayerView.hasArrow = false
                multiPlayerView.checked = options.multiPlayerView
                multiPlayerView.tooltipTitle = multiPlayerView.text
                multiPlayerView.tooltipOnButton = true
                multiPlayerView.tooltipText = "Displays all selected characters in the frame or a single character selected with the drop down list."
                multiPlayerView.func = function(self)
                    options.multiPlayerView = not options.multiPlayerView
                    self:FlipOptionsMenu()
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(multiPlayerView)

                -- Turn on/off sending messages when leaving an instance.
                local groupMessage = createInfo("Group Message")
                groupMessage.hasArrow = false
                groupMessage.checked = options.groupMessage
                groupMessage.tooltipTitle = groupMessage.text
                groupMessage.tooltipOnButton = true
                groupMessage.tooltipText = "Messages your party or raid on leaving an instance with the collected currency. Otherwise prints to your chat window only."
                groupMessage.func = function(self)
                    options.groupMessage = not options.groupMessage
                end
                DDM:UIDropDownMenu_AddButton(groupMessage)

                local characterInfo = createInfo("Character Info")
                characterInfo.menuList = characterInfo.text
                characterInfo.midWidth = 1000
                characterInfo.checked = ICT:containsAllValues(options.player)
                characterInfo.hasArrow = true
                characterInfo.tooltipTitle = characterInfo.text
                characterInfo.tooltipOnButton = true
                characterInfo.tooltipText = "Enables and disables information about a character to appear."
                characterInfo.func = function(self)
                    local wasChecked = ICT:containsAllValues(options.player)
                    for k, _ in pairs(options.player) do
                        options.player[k] = not wasChecked
                    end
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(characterInfo)

                local players = createInfo()
                players.text = "Characters"
                players.menuList = players.text
                players.checked = ICT:containsAllValues(ICT.db.players, Player.isEnabled)
                players.hasArrow = true
                players.tooltipTitle = players.text
                players.tooltipOnButton = true
                players.tooltipText = "Enables and disables characters from view in the drop down selection (single view) or frame (multi character view)."
                players.func = function(self)
                    local wasChecked = ICT:containsAllValues(ICT.db.players, Player.isEnabled)
                    for _, player in pairs(ICT.db.players) do
                        player.isDisabled = wasChecked
                    end
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(players)

                local reset = createInfo("Reset Timers")
                reset.menuList = reset.text
                reset.checked = ICT:containsAllValues(resets)
                reset.hasArrow = true
                reset.func = function(self)
                    local wasChecked = ICT:containsAllValues(resets)
                    for k, _ in pairs(ICT.ResetInfo) do
                        resets[k] = not wasChecked
                    end
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(reset)

                local instances = createInfo("Instances")
                instances.menuList = instances.text
                instances.checked = instanceContainsAll()
                instances.hasArrow = true
                instances.func = function(self)
                    local wasChecked = instanceContainsAll()
                    for _, v in pairs(Instances.infos()) do
                        checkInstance(v, not wasChecked)
                    end
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(instances)

                -- local difficulties = createInfo("Difficulty")
                -- difficulties.menuList = difficulties.text
                -- difficulties.checked = ICT:containsAllValues(difficulty)
                -- difficulties.hasArrow = true
                -- difficulties.func = function(self)
                --     local wasChecked = ICT:containsAllValues(difficulty)
                --     for k, _ in ipairs(Instances.difficulty) do
                --         difficulty[k] = not wasChecked
                --     end
                --     ICT:PrintPlayers()
                -- end
                -- DDM:UIDropDownMenu_AddButton(difficulties)

                local quests = createInfo("Quests")
                quests.menuList = quests.text
                quests.checked = options.allQuests and options.showQuests
                quests.hasArrow = true
                quests.func = function(self)
                    local wasChecked = options.allQuests and options.showQuests
                    options.allQuests = not wasChecked
                    options.showQuests = not wasChecked
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(quests)

                -- Create the currency options.
                local currencies = createInfo("Currency")
                currencies.menuList = currencies.text
                currencies.hasArrow = true
                currencies.checked = ICT:containsAllValues(currency)
                currencies.func = function(self)
                    local wasChecked = ICT:containsAllValues(currency)
                    for _, v in ipairs(ICT.Currencies) do
                        v:setVisible(not wasChecked)
                    end
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(currencies)

                local cooldowns = createInfo("Cooldowns")
                cooldowns.menuList = cooldowns.text
                cooldowns.checked = cooldownContainsAll()
                cooldowns.hasArrow = true
                cooldowns.func = function(self)
                    local wasChecked = cooldownContainsAll()
                    for _, cooldown in pairs(Cooldowns.spells) do
                        cooldown:setVisible(not wasChecked)
                    end
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(cooldowns)

                DDM:UIDropDownMenu_AddSeparator()

                -- Indent to make up for missing icon.
                local display = createInfo("      Frame")
                display.menuList = "Frame"
                display.midWidth = 1000
                display.notCheckable = true
                display.hasArrow = true
                DDM:UIDropDownMenu_AddButton(display)
            elseif level == 2 then
                if menuList == "Characters" then
                    for _, player in ICT:nspairsByValue(ICT.db.players, Player.isLevelVisible) do
                        local info = createInfo(player:getName())
                        info.value = player.fullName
                        info.checked = not player.isDisabled
                        info.func = function(self)
                            player.isDisabled = not player.isDisabled
                            ICT:PrintPlayers()
                        end
                        DDM:UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Reset Timers" then
                    for k, v in ICT:spairs(ICT.ResetInfo) do
                        local info = createInfo(v.name)
                        info.checked = resets[k]
                        info.func = function(self)
                            resets[k] = not resets[k]
                            ICT:PrintPlayers()
                        end
                        DDM:UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Instances" then
                    -- Create a level for the expansions, then the specific instances.
                    for expansion, v in ICT:spairs(ICT.Expansions, ICT.ExpansionSort) do
                        local info = createInfo(expansion)
                        info.menuList = menuList .. ":" .. expansion
                        info.hasArrow = true
                        info.checked = expansionContainsAllInstances(v)
                        info.func = function(self)
                            local wasChecked = expansionContainsAllInstances(v)
                            for _, instance in ICT:fpairsByValue(Instances.infos(), ICT:fWith(Instances.fromExpansion, v)) do
                                checkInstance(instance, not wasChecked, ICT.Expansions[expansion])
                            end
                            ICT:PrintPlayers()
                        end
                        DDM:UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Difficulty" then
                    -- for k, v in ipairs(Instances.Difficulty) do
                    --     local info = createInfo(v)
                    --     info.checked = difficulty[k]
                    --     info.func = function(self)
                    --         difficulty[k] = not difficulty[k]
                    --         ICT:PrintPlayers()
                    --     end
                    --     DDM:UIDropDownMenu_AddButton(info, level)
                    -- end
                elseif menuList == "Quests" then
                    -- Switches between all quests or only those available to the player.
                    local allAvailableQuests = createInfo("Show Unavailable Quests")
                    allAvailableQuests.checked = options.allQuests
                    allAvailableQuests.func = function(self)
                        options.allQuests = not options.allQuests
                        ICT:PrintPlayers()
                    end
                    DDM:UIDropDownMenu_AddButton(allAvailableQuests, level)

                    local showQuests = createInfo("Show Quests")
                    showQuests.checked = options.showQuests
                    showQuests.func = function(self)
                        options.showQuests = not options.showQuests
                        ICT:PrintPlayers()
                    end
                    DDM:UIDropDownMenu_AddButton(showQuests, level)
                elseif menuList == "Currency" then
                    for _, v in ipairs(ICT.Currencies) do
                        local info = createInfo(v:getName())
                        info.checked = v:isVisible()
                        info.func = function(self)
                            v:setVisible()
                            ICT:PrintPlayers()
                        end
                        DDM:UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Cooldowns" then
                    -- Create a level for the expansions, then the specific cooldown.
                    for expansion, v in ICT:spairs(ICT.Expansions, ICT.ExpansionSort) do
                        local info = createInfo(expansion)
                        info.menuList = menuList .. ":" .. expansion
                        info.hasArrow = true
                        info.checked = expansionContainsAllCooldowns(v)
                        info.func = function(self)
                            local wasChecked = expansionContainsAllCooldowns(v)
                            for _, cooldown in ICT:fpairsByValue(Cooldowns.spells, ICT:fWith(Cooldowns.fromExpansion, v)) do
                                cooldown:setVisible(not wasChecked)
                            end
                            ICT:PrintPlayers()
                        end
                        DDM:UIDropDownMenu_AddButton(info, level)
                    end
                elseif menuList == "Frame" then
                    local anchorLFG = createInfo("Anchor to LFG")
                    anchorLFG.checked = options.anchorLFG
                    anchorLFG.tooltipTitle = anchorLFG.text
                    anchorLFG.tooltipOnButton = true
                    anchorLFG.tooltipText = "Brings up the frame when viewing the LFG frame otherwise detaches from the frame."
                    anchorLFG.func = function(self)
                        options.anchorLFG = not options.anchorLFG
                    end
                    DDM:UIDropDownMenu_AddButton(anchorLFG, level)

                    local minimap = createInfo("Show Minimap Icon")
                    minimap.checked = options.showMinimapIcon
                    minimap.func = function(self)
                        options.showMinimapIcon = not options.showMinimapIcon
                        ICT.db.minimap.hide = not options.showMinimapIcon
                        self:FlipMinimapIcon()
                    end
                    DDM:UIDropDownMenu_AddButton(minimap, level)

                    -- Switches between short and long forms of currency.
                    local order = createInfo("Order Lock Last")
                    order.hasArrow = false
                    order.checked = options.orderLockLast
                    order.tooltipTitle = order.text
                    order.tooltipOnButton = true
                    order.tooltipText = "Orders locked instances and completed quests after available instances and quests."
                    order.func = function(self)
                        options.orderLockLast = not options.orderLockLast
                        ICT:PrintPlayers()
                    end
                    DDM:UIDropDownMenu_AddButton(order, level)

                    -- Switches between short and long forms of currency.
                    local verboseCurrency = createInfo("Verbose Currency")
                    verboseCurrency.hasArrow = false
                    verboseCurrency.checked = options.verboseCurrency
                    verboseCurrency.tooltipTitle = verboseCurrency.text
                    verboseCurrency.tooltipOnButton = true
                    verboseCurrency.tooltipText = "Multiline currency view or a single line currency view."
                    verboseCurrency.func = function(self)
                        options.verboseCurrency = not options.verboseCurrency
                        ICT:PrintPlayers()
                    end
                    DDM:UIDropDownMenu_AddButton(verboseCurrency, level)

                    -- Turns on/off instance and quest information in currency.
                    local verboseCurrencyTooltip = createInfo("Verbose Currency Tooltip")
                    verboseCurrencyTooltip.hasArrow = false
                    verboseCurrencyTooltip.checked = options.verboseCurrencyTooltip
                    verboseCurrencyTooltip.tooltipTitle = verboseCurrencyTooltip.text
                    verboseCurrencyTooltip.tooltipOnButton = true
                    verboseCurrencyTooltip.tooltipText = "Shows instances and quests currency available and total currency for the hovered over currency."
                    verboseCurrencyTooltip.func = function(self)
                        options.verboseCurrencyTooltip = not options.verboseCurrencyTooltip
                        ICT:PrintPlayers()
                    end
                    DDM:UIDropDownMenu_AddButton(verboseCurrencyTooltip, level)

                    local levelSlider = createInfo("Show Minimum Level Slider")
                    levelSlider.hasArrow = false
                    levelSlider.checked = options.showLevelSlider
                    levelSlider.tooltipTitle = levelSlider.text
                    levelSlider.tooltipOnButton = true
                    levelSlider.tooltipText = "Displays the slider bar to control minimum character level."
                    levelSlider.func = function(self)
                        options.showLevelSlider = not options.showLevelSlider
                        self:FlipSlider()
                    end
                    DDM:UIDropDownMenu_AddButton(levelSlider, level)
                elseif menuList == "Character Info" then
                    addPlayerOption("Show Level", "showLevel", level)
                    addPlayerOption("Show Guild", "showGuild", level)
                    addPlayerOption("Show Guild Rank", "showGuildRank", level)
                    addPlayerOption("Show Gold", "showMoney", level)
                    addPlayerOption("Show Durability", "showDurability", level)
                    addPlayerOption("Show XP", "showXP", level)
                    addPlayerOption("Show Rested XP", "showRestedXP", level)
                    addPlayerOption("Show Resting State", "showRestedState", level)
                    addPlayerOption("Show Bags", "showBags", level)
                    addPlayerOption("Show Bank Bags", "showBankBags", level)
                    addPlayerOption("Show Specs", "showSpecs", level)
                    addPlayerOption("Show Gear Scores", "showGearScores", level, "If TacoTip is available, this will display gear scores for each spec respectively.")
                    addPlayerOption("Show Professions", "showProfessions", level)
                end
            elseif level == 3 then
                -- If we had another 3rd layer thing we need to check if menuList is an expansion.
                -- Now create a level for all the instances of that expansion.
                local subList, expansion = menuList:match("([%w%s]+):([%w%s]+)")
                expansion = ICT.Expansions[expansion]
                if subList == "Instances" then
                    local lastSize
                    for _, v in ICT:spairsByValue(Instances.infos(), ICT.InstanceOptionSort, ICT:fWith(Instances.fromExpansion, expansion)) do
                        local size =  v.legacy == expansion and v.legacySize or v.size
                        if lastSize and lastSize ~= size then
                            DDM:UIDropDownMenu_AddSeparator(level)
                        end
                        lastSize = size
                        local info = createInfo(GetRealZoneText(v.id))
                        info.arg1 = v
                        info.checked = v:isVisible(expansion)
                        info.func = function(self, instance)
                            checkInstance(instance, not v:isVisible(expansion), expansion)
                            ICT:PrintPlayers()
                        end
                        DDM:UIDropDownMenu_AddButton(info, level)
                    end
                elseif subList == "Cooldowns" then
                    -- Now create a level for all the cooldowns of that expansion.
                    local lastSkill
                    for _, v in ICT:nspairsByValue(Cooldowns.spells, ICT:fWith(Cooldowns.fromExpansion, expansion)) do
                        if lastSkill and lastSkill ~= v.skillId then
                            DDM:UIDropDownMenu_AddSeparator(level)
                        end
                        lastSkill = v.skillId
                        local info = createInfo(v.name)
                        info.arg1 = v
                        info.checked = v:isVisible()
                        info.func = function(self, cooldown)
                            cooldown:setVisible()
                            ICT:PrintPlayers()
                        end
                        DDM:UIDropDownMenu_AddButton(info, level)
                    end
                end
            end
        end
    )
end

function Options:PrintMessage(text)
    if IsInGroup() and ICT.db.options.groupMessage then
        local type = IsInRaid() and "RAID" or "PARTY"
        SendChatMessage(text, type)
    else
        print(text)
    end
end

function Options:SetPlayerDropdown(player)
    DDM:UIDropDownMenu_SetText(ICT.frame.playerDropdown, player:getName())
end

function Options:CreatePlayerDropdown()
    local playerDropdown = DDM:Create_UIDropDownMenu("PlayerSelection", ICT.frame)
    ICT.frame.playerDropdown = playerDropdown
    playerDropdown:SetPoint("TOP", ICT.frame, 0, -30)
    playerDropdown:SetAlpha(1)
    playerDropdown:SetIgnoreParentAlpha(true)
    -- Width set to slightly smaller than parent frame.
    DDM:UIDropDownMenu_SetWidth(playerDropdown, 160)

    DDM:UIDropDownMenu_Initialize(
        playerDropdown,
        function()
            local info = DDM:UIDropDownMenu_CreateInfo()
            for _, player in ICT:nspairsByValue(ICT.db.players, Player.isPlayerEnabled) do
                info.text = player:getNameWithIcon()
                info.value = player.fullName
                info.checked = ICT.selectedPlayer == player.fullName
                info.func = function(self)
                    ICT.selectedPlayer = self.value
                    DDM:UIDropDownMenu_SetText(playerDropdown, player:getName())
                    ICT:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(info)
            end
        end
    )
    self:FlipOptionsMenu()
end