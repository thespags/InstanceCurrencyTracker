local addOnName, ICT = ...

local LCInspector = LibStub("LibClassicInspector")
ICT.Player = {}
local Player = ICT.Player
local Instances = ICT.Instances
local Quests = ICT.Quests
local Currency = ICT.Currency

-- Adds "static" fields, 
-- Note: we may wnat to move this information to "onLoad",
-- as anything added won't get picked up by existing players.
function ICT.CreateCurrentPlayer()
    local fullName = Player.GetCurrentPlayer()
    if ICT.db.players[fullName] then
        return
    end
    print(string.format("[%s] Creating player: %s", addOnName, fullName))
    local player = Player:new()
    player.fullName = fullName
    player.name = UnitName("Player")
    player.realm = GetRealmName()
    player.class = select(2, UnitClass("Player"))
    player.faction = select(1, UnitFactionGroup("Player"))
    player.quests = {
        prereq = {},
        completed = {}
    }
    player.currency = {
        wallet = {},
        weekly = {},
        daily = {},
        maxDaily = {},
        -- There's no prereq for weekly currencies so no player based max weekly.
    }
    ICT.db.players[fullName] = player
    player:createInstances()
    -- Set transient information after copying main tables.
    player:dailyReset()
    player:weeklyReset()
    player:onLoad()
    return player
end

-- Adds all the functions to the player.
function Player:new(player)
    player = player or {}
    setmetatable(player, self)
    self.__index = self
    return player
end

-- Returns the provided player or current player if none provided.
function ICT.GetPlayer(playerName)
    playerName = playerName or Player.GetCurrentPlayer()
    local player = ICT.db.players[playerName]
    ICT.db.players[playerName] = player
    return player
end

-- Called when the addon is loaded to update any fields.
function Player:onLoad()
    self:updateSkills()
    -- Talents calls self:updateGear() for us.
    -- Delay loading talents(specifically gear) until wow has loaded more.
    ICT:throttleFunction("onLoad", 1, Player.updateTalents, ICT.UpdateDisplay)()
    -- Even with getItemInfoInstance we still fail on initial log in so delay.
    ICT:throttleFunction("onLoad", 1, Player.updateBags, ICT.UpdateDisplay)()
    self:updateMoney()
    self:updateGuild()
    self:updateXP()
    self:updateResting()
    self:updateCooldowns()
    -- This may require previous info, e.g. skills and level, so calculate instance/currency 
    self:update()

    -- If the player did a name change, this attempts to reconcile 
    -- the old player using the guid.
    self.guid = UnitGUID("Player")
    for k, v in pairs(ICT.db.players) do
        if v.guid == self.guid and self.fullName ~= k then
            ICT.db.players[k] = nil
            break
        end
    end
end

function Player:createInstances()
    self.instances = self.instances or {}

    -- TODO remove this in future versions when enough folks have "updated"
    if self.raids or self.dungeons or self.oldRaids then
        for k, v in pairs(self.raids) do
            local size = tonumber(string.match(k, ".*%((%d+)%)"))
            local key = Instances:key(v.id, size)
            self.instances[key] = Instances:new({}, v.id, size)
        end
        for _, v in pairs(self.dungeons) do
            local size = Instances.Resets[v.id][5]
            local key = Instances:key(v.id, size)
            self.instances[key] = Instances:new({}, v.id, size)
        end
        for k, v in pairs(self.oldRaids) do
            local size
	    if v.id == 249 then
                size = 40
            else
                size = next(Instances.Resets[v.id])
            end
            local key = Instances:key(v.id, size)
            self.instances[key] = Instances:new({}, v.id, size)
        end
        self.raids = nil
        self.dungeons = nil
        self.oldRaids = nil
    end

    for id, sizes in pairs(Instances.Resets) do
        for size, _  in pairs(sizes) do
            local key = Instances:key(id, size)
            self.instances[key] = Instances:new(self.instances[key], id, size)
        end
    end
end

function Player:dailyReset()
    for k, _ in pairs(ICT.CurrencyInfo) do
        self.currency.daily[k] = self.currency.maxDaily[k] or 0
    end
    for k, _ in pairs(ICT.QuestInfo) do
        self.quests.completed[k] = false
    end
end

function Player:weeklyReset()
    for k, _ in pairs(ICT.CurrencyInfo) do
        self.currency.weekly[k] = Currency:CalculateMaxRaidEmblems(k)(self)
    end
end

ICT.ResetInfo = {
    [1] = { name = "Daily", func = Player.dailyReset },
    [3] = { name = "3 Day", func = function() end },
    [5] = { name = "5 Day", func = function() end },
    [7] = { name = "Weekly", func = Player.weeklyReset },
}

function Player:resetInstances()
    local timestamp = GetServerTime()
    for k, v in pairs(ICT.db.reset) do
        if v < timestamp then
            print(string.format("[%s] %s reset, updating info.", addOnName, ICT.ResetInfo[k].name))
            for _, player in pairs(ICT.db.players) do
                ICT.ResetInfo[k].func(player)
            end
            -- There doesn't seem to be an API to get 3 or 5 day reset so recalculate from the last known piece.
            -- Keep going until we have a time in the future, the player may have not logged in a while.
            -- Less math to avoid an off by 1 error.
            while (ICT.db.reset[k] < timestamp) do
                ICT.db.reset[k] = ICT.db.reset[k] + k * ICT.OneDay
            end
        end
    end

    for _, instance in pairs(self.instances) do
        instance:resetIfNecessary(GetServerTime())
    end
end

local dungeons = {}
function Player:getDungeons()
    dungeons[self.fullName] = dungeons[self.fullName] or ICT:toTable(ICT:spairsByValue(self.instances, ICT.InstanceSort, function(v) return v.size == 5 and v.expansion == ICT.Expansions[ICT.WOTLK] end))
    return dungeons[self.fullName]
end

local raids = {}
function Player:getRaids()
    raids[self.fullName] = raids[self.fullName] or ICT:toTable(ICT:spairsByValue(self.instances, ICT.InstanceSort, function(v) return v.size > 5 and v.expansion == ICT.Expansions[ICT.WOTLK] end))
    return raids[self.fullName]
end

local oldRaids = {}
function Player:getOldRaids()
    oldRaids[self.fullName] = oldRaids[self.fullName] or ICT:toTable(ICT:spairsByValue(self.instances, ICT.InstanceSort, function(v) return v.size > 5 and (v.expansion < ICT.Expansions[ICT.WOTLK] or v.legacy) end))
    return oldRaids[self.fullName]
end

function Player:calculateCurrency()
    for k, _ in pairs(ICT.CurrencyInfo) do
        self.currency.wallet[k] = ICT:GetCurrencyAmount(k)
        -- There's no weekly raid quests so just add raid emblems.
        self.currency.weekly[k] = Currency:CalculateRaidEmblems(k)(self)
        self.currency.daily[k] = ICT:add(Currency:CalculateDungeonEmblems(k), Quests:CalculateAvailableDaily(k))(self)
        self.currency.maxDaily[k] = ICT:add(Currency:CalculateMaxDungeonEmblems(k), Quests:CalculateMaxDaily(k))(self)
    end
end

function Player:availableCurrency(tokenId)
    if ICT.CurrencyInfo[tokenId].unlimited then
        return "N/A"
    end
    if not self.currency.weekly[tokenId] or not self.currency.daily[tokenId] then
        return 0
    end
    return self.currency.weekly[tokenId] + self.currency.daily[tokenId]
end

function Player:calculateQuest()
    for k, quest in pairs(ICT.QuestInfo) do
        self.quests.prereq[k] = quest.prereq(self)
        self.quests.completed[k] = Quests:IsDailyCompleted(quest)
    end
end

-- Updates instances and currencies.
-- We may want to decouple these things in the future.
function Player:update()
    self:resetInstances()
    self:updateInstance()
    self:calculateCurrency()
    self:calculateQuest()
    self:calculateResetTimes()
end

function Player:calculateResetTimes()
    for _, instance in pairs(self:getOldRaids()) do
        -- Ony40 has a 5 day reset.
        if instance.id == 249 then
            ICT.db.reset[5] = ICT.db.reset[5] or instance.reset
        end
        -- AQ20, ZG, and ZA have 3 day resets.
        if instance.id == 509 or instance.id == 309 or instance.id == 568 then
            ICT.db.reset[3] = ICT.db.reset[3] or instance.reset
        end
    end
    ICT.db.reset[1] = ICT.db.reset[1] or C_DateAndTime.GetSecondsUntilDailyReset() + GetServerTime()
    ICT.db.reset[7] = ICT.db.reset[7] or C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime()
end

-- Get all saved instance information and lock the respective instance for the player.
function Player:updateInstance()
    local numSavedInstances = GetNumSavedInstances()
    for i=1, numSavedInstances do
        local _, _, reset, _, locked, _, _, _, maxPlayers, _, _, encounterProgress, _, instanceId = GetSavedInstanceInfo(i)
        local instance = self:getInstance(instanceId, maxPlayers)

        if locked and instance then
            instance:lock(reset, encounterProgress, i)
        end
    end
end

local remap = {
    [50310] = 2656,
    [29354] = 2656,
    [10248] = 2656,
    [3564] = 2656,
    [2576] = 2656,
    [2575] = 2656,
}
-- All these are fishing
local ignored = ICT:set(2383, 7731, 7732, 7620, 18248, 33095, 51294, 62734)
local SECONDARY_SKILLS = string.gsub(SECONDARY_SKILLS, ":", "")
local PROFICIENCIES = string.gsub(PROFICIENCIES, ":", "")
function Player:updateSkills()
    -- Skill list is always in same order, so we can get primary/secondary/weapon by checking the section headers.
    local professionCount = 0
    local isSecondary = false
    local profession = false
    -- Reset skills in case one was dropped.
    self.professions = {}

    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, max = GetSkillLineInfo(i)
        -- Herbliasm doesn't have a spell so swap to 'Find Herb', note this isn't localized...
        local nameOrId = name == "Herbalism" and 2383 or name
        local _, _, icon, _, _, _, spellId = GetSpellInfo(nameOrId)
        -- Ugly, but Swap (mining) or ignore (fishing),
        spellId = remap[spellId] or not ignored[spellId] and spellId or nil
        -- Note we aren't using anything besides professions, in the future we may want to display other attributes.
        if isHeader and name == TRADE_SKILLS then
            isSecondary = false
            profession = true
        elseif isHeader and name == SECONDARY_SKILLS then
            isSecondary = true
            profession = true
        elseif isHeader and string.find(name, COMBAT_RATING_NAME1) then
            profession = false
        elseif isHeader and string.find(name, PROFICIENCIES) then
            profession = false
        elseif isHeader and name == LANGUAGES_LABEL then
            profession = false
        end
        if not isHeader and profession and icon then
            professionCount = professionCount + 1;
            self.professions[professionCount] = {
                name = name,
                icon = icon,
                rank = rank,
                max = max,
                spellId = spellId,
                isSecondary = isSecondary
            }
        end
    end
end

function Player:updateTalents()
    local active = LCInspector:GetActiveTalentGroup(self.guid)
    self.specs = self.specs or { {}, {} }
    self.activeSpec = active
    for i=1,2 do
        local tab1, tab2, tab3 = LCInspector:GetTalentPoints(self.guid, i)
        if tab1 ~= nil and tab2 ~= nil and tab3 ~= nil then
            self.specs[i] = self.specs[i] or {}
            local specialization = LCInspector:GetSpecialization(self.guid, i)
            self.specs[i].name = specialization and LCInspector:GetSpecializationName(self.class, specialization, true) or ("Spec " .. i)
            self.specs[i].tab1, self.specs[i].tab2, self.specs[i].tab3 = tab1, tab2, tab3
        end
    end
    self:updateGear()
    self:updateGlyphs()
end

function Player:updateGlyphs()
    self.specs = self.specs or { {}, {} }
    for i=1,2 do 
        self.specs[i].glyphs = {}
        for j=1,6 do
            -- This icon is transparent, we could load the item and not the spell,
            -- it lacked it's own charm as all the glyphs for the same type and class are the same.
            -- Requires using stpain's data dump.
            -- https://github.com/stpain/guildbook/blob/930bb6682b83072e078ccdf341da87efc5169d97/ItemData.lua#L59721
            local enabled, type, spellId, icon = GetGlyphSocketInfo(j, i)
            self.specs[i].glyphs[j] = { enabled = enabled, type = type, spellId = spellId, icon = icon }
        end
    end
end

function Player:updateGear()
    local active = LCInspector:GetActiveTalentGroup(self.guid)
    self.specs = self.specs or { {}, {} }
    self.activeSpec = active
    self.specs[active] = self.specs[active] or {}

    local items = {}
    for i=1,19 do
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink ~= nil then
            local item = {}

            local details = ICT.itemLinkSplit(itemLink, ":")
            -- Use link instead of id so we don't have to worry about looking up an uncached value.
            item.link = itemLink
            -- Convert to number for our table lookup, Blizzard calls handle strings vs numbers.
            item.enchantId = tonumber(details[2])
            item.gems = {}
            item.gems[0] = details[3] and select(5, GetItemInfoInstant(details[3])) or nil
            item.gems[1] = details[4] and select(5, GetItemInfoInstant(details[4])) or nil
            item.gems[2] = details[5] and select(5, GetItemInfoInstant(details[5])) or nil
            item.gems[3] = details[6] and select(5, GetItemInfoInstant(details[6])) or nil
            item.gemTotal = ICT:sumNonNil(item.gems[0], item.gems[1], item.gems[2], item.gems[3])

            -- Requires the server to be loaded so we have level and invType.
            local _, _, _, level, _, _, _, _, invType, icon, _, classId, subClassId = GetItemInfo(itemLink)
            item.level = level
            item.invType = invType
            item.icon = icon
            item.shouldEnchant = ICT.CheckSlotEnchant[i](self, classId, subClassId)

            local stats = GetItemStats(itemLink, {})
            item.sockets = {}
            item.sockets.red = stats["EMPTY_SOCKET_RED"] or 0
            item.sockets.blue = stats["EMPTY_SOCKET_BLUE"] or 0
            item.sockets.yellow = stats["EMPTY_SOCKET_YELLOW"] or 0
            item.sockets.meta = stats["EMPTY_SOCKET_META"] or 0
            item.extraSocket = ICT.CheckSlotSocket[i] and ICT.CheckSlotSocket[i].check(self) or false
            item.socketTotals = ICT:sum(item.sockets) + (item.extraSocket and 1 or 0)

            items[i] = item
        end
    end
    self.specs[active].items = items

    if TT_GS then
        self.specs[active].gearScore, self.specs[active].ilvlScore = TT_GS:GetScore(self.guid)
    end
end

-- If we decide to work on other versions than WOTLK.
local GetBagName = GetBagName or C_Container.GetBagName
local GetContainerNumFreeSlots = GetContainerNumFreeSlots or C_Container.GetContainerNumFreeSlots;
local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots;

local function addBags(index, bags, bagsTotal)
    -- If nil then the slot is empty.
    local total = GetContainerNumSlots(index)
    if total > 0 then
        local name = GetBagName(index)
        -- Default Bank Bag doesn't have a name, so use the "Backpack" localized.
        name = name == "" and GetBagName(0) or name
        local free, type = GetContainerNumFreeSlots(index)
        -- By name requires the item in your inventory so store this for the player.
        local icon = select(5, GetItemInfoInstant(name))
        icon = icon ~= 134400 and icon or "Interface\\Addons\\InstanceCurrencyTracker\\icons\\backpack"
        bags[index] = { name = name, free = free, type = type, total = total, icon = icon }
        bagsTotal[type] = bagsTotal[type] or { free = 0, total = 0 }
        bagsTotal[type].free = bagsTotal[type].free + free
        bagsTotal[type].total = bagsTotal[type].total + total

        -- Handle cases if new bag types are added.
        if not ICT.BagFamily[type] then
            print(string.format("[%s] Unknown bag type %s (%s), please report this on the addon page.", addOnName, type, name))
            ICT.BagFamily[type] = { icon = 134400, name = "Unknown" }
        end
    end
end

local function updateBags(self, key, startIndex, length)
    local bags = {}
    local bagsTotal = {}
    -- Surprisingly this one thing that is 0-indexed in WOW.
    local endIndex = startIndex + length
    for index=startIndex,endIndex do
        addBags(index, bags, bagsTotal)
    end
    -- But wait, bank is -1, so handle it!
    if key == "bankBags" then
        addBags(-1, bags, bagsTotal)
    end
    self[key] = bags
    self[key .. "Total"] = bagsTotal
end

function Player:updateBags()
    updateBags(self, "bags", 0, NUM_BAG_SLOTS)
end

function Player:updateBankBags()
    -- BANK_CLOSED fires twice, but data is only on the first event, so skip the second...
    local type = select(2, GetContainerNumFreeSlots(-1))
    if type then
        updateBags(self, "bankBags", NUM_BAG_SLOTS + 1, NUM_BANKBAGSLOTS)
    end
end

local function getAverageDurability()
	local totalCurrent, totalMax = 0, 0
	for i=0,19 do
		local current, max = GetInventoryItemDurability(i)
		if current and max then
			totalCurrent = totalCurrent + current
			totalMax = totalMax + max
		end
	end
	if (totalMax == 0) then
		return 100
	end
	return (totalCurrent / totalMax) * 100
end

function Player:updateDurability()
    self.durability = getAverageDurability()
end

function Player:updateMoney()
    self.money = GetMoney() or 0
end

function Player:updateGuild()
    self.guild, self.guildRank, _ = GetGuildInfo("Player")
    self.guild = self.guild or "No Guild"
    self.guildRank = self.guildRank or ""
end

function Player:updateXP()
    self.currentXP = UnitXP("Player")
    self.maxXP = UnitXPMax("Player")
    self.level = UnitLevel("Player")
    self.restedXP = GetXPExhaustion();
end

function Player:updateResting()
    self.resting = IsResting()
    self.restedXP = GetXPExhaustion();
end

function Player:updateCooldowns()
    self.cooldowns = self.cooldowns or {}
    ICT.Cooldowns:updateCooldowns(self)
end

function Player:getInstance(id, maxPlayers)
    return self.instances[Instances:key(id, maxPlayers)]
end

-- You gain 5% rested ever 8 hours, so every second equals the follow xp. 
local restedPerSecond = .05 / ( 8 * 60 * 60)
-- If you aren't resting you gain at a quarter of the rate, so divided by 4.
local notRestedPerSecond = restedPerSecond / 4
function Player:getRestedXP()
    -- This was added in later so safety check here.
    if self.resting == nil or not self.time or not self.restedXP or not self.maxXP then
        return 0
    end
    local percentPerSecond = self.resting and restedPerSecond or notRestedPerSecond
    local timeElapsed = GetServerTime() - self.time
    local percent = timeElapsed * percentPerSecond + (self.restedXP / self.maxXP)
    if percent > 1.5 then
        percent = 1.5
    end
	return percent
end

function Player:getProfessionRank(id)
    local icon = select(3, GetSpellInfo(id))
    for _, v in pairs(self.professions or {}) do
        if v.icon == icon then
            return v.rank
        end
    end
    return 0
end

function Player:getName()
    return ICT.db.options.verboseName and self.fullName or self.name
end

function Player:getNameWithIcon()
   return string.format("|T%s:14|t%s", ICT.ClassIcons[self.class], self:getName())
end

function Player:getClassColor()
    local classColorHex = select(4, GetClassColor(self.class))
    -- From NIT: Safeguard for weakauras/addons that like to overwrite and break the GetClassColor() function.
    if not classColorHex then
        classColorHex = self.class == "SHAMAN" and "ff0070dd" or "ffffffff"
    end
    return classColorHex
end

function Player:isQuestAvailable()
    return function(quest)
        return ICT.db.options.currency[quest.tokenId] and (self.quests.prereq[quest.key] or ICT.db.options.allQuests)
    end
end

function Player:isEngineer(level)
    return self:getProfessionRank(51306) >= (level or 1)
end

function Player:isEnchanter(level)
    return self:getProfessionRank(51313) >= (level or 1)
end

function Player:isBlacksmith(level)
    return self:getProfessionRank(51300) >= (level or 1)
end

function Player:isMaxLevel()
    return self.level == ICT.MaxLevel
end

function Player:isCurrentPlayer()
    return self.fullName == Player.GetCurrentPlayer()
end

function Player:isEnabled()
    return not self.isDisabled and self:isLevelVisible()
end

function Player:isLevelVisible()
    return self.level >= (ICT.db.options.minimumLevel or ICT.MaxLevel)
end

function Player.PlayerSort(a, b)
    return a:getName() < b:getName()
end

function Player.GetCurrentPlayer()
    return string.format("[%s] %s", GetRealmName(), UnitName("Player"))
end