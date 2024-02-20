local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local LibAddonCompat = LibStub("LibAddonCompat-1.0")
local LibInstances = LibStub("LibInstances")
local Expansion = ICT.Expansion
local Instance = ICT.Instance
local Instances = ICT.Instances
local log = ICT.log
ICT.Player = {}
local Player = ICT.Player

-- Adds all the functions to the player.
function Player:new(player)
    player = player or {}
    setmetatable(player, self)
    self.__index = self
    ICT.putIfAbsent(player, "currency", {})
    ICT.putIfAbsent(player.currency, "maxWeekly", {})
    return player
end

-- Called when the addon is loaded to update any fields.
-- Only for the active player.
local loaded = false
function Player:onLoad()
    -- Apparently the guid can change so check it.
    self.guid = UnitGUID("Player")
    self.season = C_Seasons.GetActiveSeason()
    self:updateProfessions()
    if loaded then
        self:updateTalents()
        self:updateBags()
    else
        -- Delay loading until wow has loaded more.
        -- Talents calls self:updateGear() for us.
        -- updateGear needs time...
        ICT:throttleFunction("onLoad", 1, Player.updateTalents, ICT.UpdateDisplay)()
        -- Bank Bag name is sometimes nil.
        ICT:throttleFunction("onLoad", 2, Player.updateBags, ICT.UpdateDisplay)()
    end
    self:updateMoney()
    self:updateXP()
    self:updateDurability()
    self:updateGuild()
    self:updateResting()
    self:updateCooldowns()
    self:updatePets()
    self:updateWorldBuffs()
    self:updateConsumes()
    self:updateReputation()
    -- This may require previous info, e.g. skills and level, so calculate instance/currency 
    self:update()

    -- If the player did a name change, this attempts to reconcile 
    -- the old player using the guid.
    for k, v in pairs(ICT.db.players) do
        if v.guid == self.guid and self.fullName ~= k then
            ICT.db.players[k] = nil
            break
        end
    end
    local battleTag = select(2, BNGetInfo())
    -- Update battleTag for all similar players.s
    if self.battleTag and self.battleTag ~= battleTag then
        for k, v in pairs(ICT.db.players) do
            if self.battleTag == v.battleTag then
                v.battleTag = self.battleTag
            end
        end
    end
    self.battleTag = battleTag
    loaded = true
end

function Player:fromSeason(info, size)
    -- Associates sizes to a specific season. If we have multiple seasons with the same size, we will have to adjust.
    local f = info.seasons and info.seasons[size] or ICT:returnX(true)
    return f(self)
end

function Player:createInstances()
    self.instances = self.instances or {}
    for id, info in pairs(LibInstances:GetInfos()) do
        for _, size in pairs(info:getSizes()) do
            local key = Instance:key(id, size)
            if Instances.inExpansion(info, size) and self:fromSeason(info, size) then
                self.instances[key] = Instance:new(self.instances[key], info, size)
            else
                -- We have to remove they instance so we don't track it anymore.
                self.instances[key] = nil
            end
        end
    end
end

function Player:dailyReset()
    for _, currency in ipairs(ICT.Currencies) do
        self.currency.daily[currency.id] = self.currency.maxDaily[currency.id] or 0
    end
    for k, quest in pairs(ICT.Quests) do
        if quest:isDaily() then
            self.quests.completed[k] = false
        end
    end
end

function Player:weeklyReset()
    for _, currency in ipairs(ICT.Currencies) do
        self.currency.weekly[currency.id] = currency:calculateMaxRaid(self)
        self.currency.maxWeekly[currency.id] = currency:calculateMaxRaid(self)
    end
    for k, quest in pairs(ICT.Quests) do
        if quest:isWeekly() then
            self.quests.completed[k] = false
        end
    end
end

function Player:resetInstances()
    for _, instance in pairs(self.instances) do
        instance:resetIfNecessary(GetServerTime())
    end
end

local dungeons = {}
function Player:getDungeons(expansion)
    local key = self.fullName .. ":" .. (expansion and expansion or "")
    dungeons[key] = dungeons[key] or ICT:toTable(ICT:nspairsByValue(self.instances, ICT:fWith(Instance.isDungeon, expansion)))
    return dungeons[key]
end

local raids = {}
function Player:getRaids(expansion)
    local key = self.fullName .. ":" .. (expansion and expansion or "")
    raids[key] = raids[key] or ICT:toTable(ICT:nspairsByValue(self.instances, ICT:fWith(Instance.isRaid, expansion)))
    return raids[key]
end

function Player:calculateCurrency()
    for _, currency in ipairs(ICT.Currencies) do
        local id = currency.id
        self.currency.wallet[id] = currency:getAmount()
        self.currency.weekly[id] = currency:calculateAvailableRaid(self) + currency:calculateAvailableWeeklyQuest(self, currency)
        self.currency.daily[id] = currency:calculateAvailableDungeon(self) + currency:calculateAvailableDailyQuest(self, currency)
        self.currency.maxDaily[id] = currency:calculateMaxDungeon(self) + currency:calculateMaxDailyQuest(self, currency)
        self.currency.maxWeekly[id] = currency:calculateMaxRaid(self) + currency:calculateMaxWeeklyQuest(self, currency)
    end
end

function Player:availableCurrency(currency)
    if currency:showLimit() then
        local id = currency.id
        if not self.currency.weekly[id] or not self.currency.daily[id] then
            return 0
        end
        return self.currency.weekly[id] + self.currency.daily[id]
    end
    return nil
end

function Player:totalCurrency(currency)
    return self.currency.wallet[currency.id] or 0
end

function Player:calculateQuest()
    for k, quest in pairs(ICT.Quests) do
        self.quests.prereq[k] = quest.prereq(self)
        self.quests.completed[k] = quest:isCompleted()
    end
end

-- Updates instances and currencies.
-- We may want to decouple these things in the future.
function Player:update()
    for _, v in pairs(ICT.Resets) do
        v:reset()
    end
    for _, player in pairs(ICT.db.players) do
        player:resetInstances()
    end
    self:updateInstance()
    self:calculateCurrency()
    self:calculateQuest()
    self:calculateResetTimes()
end

local boonId = 349981

-- SpellId to chrono boon slot.
local worldBuffs = {
    [22817] = { slot = 17 },
    [22818] = { slot = 18 },
    [22820] = { slot = 19 },
    [22888] = { slot = 20 },
    [16609] = { slot = 21 },
    [24425] = { slot = 22 },
    [15366] = { slot = 23 },
    -- Darkmoon faire has a bunch of types defined in slot 23 with duration in slot 24.
    [23736] = { type = 25, slot = 24 },
    [23768] = { type = 25, slot = 24 },
    [23766] = { type = 25, slot = 24 },
    [23769] = { type = 25, slot = 24 },
    [23738] = { type = 25, slot = 24 },
    [23737] = { type = 25, slot = 24 },
    [23735] = { type = 25, slot = 24 },
    [430947] = { slot = 26 },
    -- Not boonable "world buffs".
    [430352] = {},
}

local function getBuff(i)
    return { UnitBuff("Player", i) }
end

function Player:updateWorldBuffs()
    local buffs = {}
    local i = 1
    local buff = getBuff(i)
    while buff[1] do
        local buffId = buff[10]
        if worldBuffs[buffId] then
            -- We have to convert from our computer's time to the server time.
            local expires = GetServerTime() + buff[6] - GetTime()
            buffs[buffId] = { duration = buff[5], expires = expires, booned = false }
        end
        if buffId == boonId then
            for k, v in ICT:fpairsByValue(worldBuffs, function(v) return v.slot end) do
                local duration = buff[v.slot]
                if (not v.type or buff[v.type] == k) and duration > 0 then
                    buffs[k] = { duration = duration, booned = true }
                end
            end
        end
        i = i + 1
        buff = getBuff(i)
    end
    self.worldBuffs = buffs
end

local itemBuffs = {
    [211813] = {},
    [211814] = {},
    [211815] = {},
    [211816] = {},
}

function Player:updateConsumes()
    local consumes = {}
    for k, v in pairs(itemBuffs) do
        local count = GetItemCount(k, true)
        consumes[k] = count > 0 and count or nil
    end
    self.consumes = consumes
end

function Player:calculateResetTimes()
    -- Look for 1, 3, 5, and 7 day resets.
    for _, instance in pairs(self.instances) do
        ICT.db.reset[instance:resetInterval()] = ICT.db.reset[instance:resetInterval()] or instance.reset
    end
    -- If we don't have a daily or weekly reset we can use the API.
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

function Player:addProfession(index, isSecondary)
    if index then
        local name, icon, rank, max, _, offset, skillLine, _  = LibAddonCompat:GetProfessionInfo(index)
        local spellId = offset and select(2, GetSpellBookItemInfo(offset + 1, "SPELL"))
        local profession = {
            name = name,
            skillLine = skillLine,
            icon = icon,
            rank = rank,
            max = max,
            spellId = spellId,
            isSecondary = isSecondary or false
        }
        tinsert(self.professions, profession)
    end
end

function Player:getProfessionRank(skillLine)
    for _, v in pairs(self.professions or {}) do
        if v.skillLine == skillLine then
            return v.rank
        end
    end
    return 0
end

function Player:updateProfessions()
    -- Reset skills in case one was dropped.
    self.professions = {}
    local first, second, _, fishing, cooking, firstAid = LibAddonCompat:GetProfessions()
    self:addProfession(first)
    self:addProfession(second)
    self:addProfession(cooking, true)
    self:addProfession(firstAid, true)
    self:addProfession(fishing, true)
    self:updateSkills()
end

function Player:updateSkills()
    ICT.TradeSkills:update(self)
end

function Player:getSpec(id)
    id = id or self.activeSpec or 1
    self:getSpecs()[id] = self:getSpecs()[id] or {}
    return self:getSpecs()[id]
end

function Player:getSpecs()
    self.specs = self.specs or {}
    return self.specs
end

function Player:updateTalents()
    self.activeSpec = GetActiveTalentGroup()
    for i=1,2 do
        ICT.Talents:updateSpec(self:getSpec(i), i)
    end
    self:updateGear()
end

function Player:recreatePets()
    for key, pet in pairs(self:getPets()) do
        pet.player = self
        self.pets[key] = ICT.Pet:new(pet)
    end
end

function Player:updatePets()
    self.pets = self.pets or {}
    local hasUI, isHunterPet = HasPetUI()
    if hasUI and isHunterPet then
        ICT.Talents:updatePet(self)
    end
end

function Player:getPets()
    return self.pets or {}
end

function Player:updateGear()
    local active = GetActiveTalentGroup()
    self.activeSpec = active
    self.specs = self.specs or { {}, {} }
    self.specs[active] = self.specs[active] or {}

    local items = {}
    for i=1,19 do
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink ~= nil then
            local item = {}

            local details = ICT:itemLinkSplit(itemLink)
            -- Use link instead of id so we don't have to worry about looking up an uncached value.
            item.link = itemLink
            -- Convert to number for our table lookup, Blizzard calls handle strings vs numbers.
            item.enchantId = tonumber(details[2])
            item.gems = {}
            item.gems[0] = details[3] and select(5, GetItemInfoInstant(details[3])) or nil
            item.gems[1] = details[4] and select(5, GetItemInfoInstant(details[4])) or nil
            item.gems[2] = details[5] and select(5, GetItemInfoInstant(details[5])) or nil
            item.gems[3] = details[6] and select(5, GetItemInfoInstant(details[6])) or nil
            item.gemTotal = ICT:sumNonNil({item.gems[0], item.gems[1], item.gems[2], item.gems[3]})

            -- Requires the server to be loaded so we have level and invType.
            local _, _, _, level, _, _, _, _, invType, icon, _, classId, subClassId = GetItemInfo(itemLink)
            item.level = level
            item.invType = invType
            item.icon = icon
            item.shouldEnchant = ICT.CheckSlotEnchant[i](self, classId, subClassId)
            item.sockets = {}
            item.extraSocket = 0
            item.socketTotals = 0

            local mixin = Item:CreateFromItemLink(itemLink)
            mixin:ContinueOnItemLoad(function()
                -- GetItemStats requites the item to be cached, so wait until the item is loaded.
                local stats = GetItemStats(itemLink, {})
                item.sockets.red = stats["EMPTY_SOCKET_RED"] or 0
                item.sockets.blue = stats["EMPTY_SOCKET_BLUE"] or 0
                item.sockets.yellow = stats["EMPTY_SOCKET_YELLOW"] or 0
                item.sockets.meta = stats["EMPTY_SOCKET_META"] or 0
                -- WOTLK has extra slots, while TBC and Vanilla do not.ß
                item.extraSocket = ICT.CheckSlotSocket[i] and ICT.CheckSlotSocket[i].check(self) or false
                item.socketTotals = ICT:sum(item.sockets) + (item.extraSocket and 1 or 0)
            end)
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
        if not name then
            log.info("no bag name %s", index)
        end
        local icon = select(5, GetItemInfoInstant(name))
        icon = icon ~= 134400 and icon or "Interface\\Addons\\InstanceCurrencyTracker\\icons\\backpack"
        bags[index] = { name = name, free = free, type = type, total = total, icon = icon }
        bagsTotal[type] = bagsTotal[type] or { free = 0, total = 0 }
        bagsTotal[type].free = bagsTotal[type].free + free
        bagsTotal[type].total = bagsTotal[type].total + total

        -- Handle cases if new bag types are added.
        if not ICT.BagFamily[type] then
            log.error(L["Unknown bag type %s (%s), please report this on the addon page."], type, name)
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
    self.restedXP = GetXPExhaustion()
end

function Player:updateResting()
    self.resting = IsResting()
    self.restedXP = GetXPExhaustion()
end

function Player:updateReputation()
    local reputationHeaders = {}
    ExpandAllFactionHeaders()
    local parent, subParent
    for i=1,GetNumFactions() do
        local _, _, standingId, min, max, value, _, _, isHeader, _, hasRep, _, isChild, factionId = GetFactionInfo(i)
        local t
        if not isHeader or hasRep then
            t = {
                factionId = factionId,
                standingId = standingId,
                min = min,
                max = max,
                hasRep = true,
                value = value,
                isHeader = isHeader
            }
        else
            t = {
                factionId = factionId,
                standingId = standingId,
                isHeader = isHeader
            }
        end
        if isHeader then
            t.children = {}
            if isChild then
                subParent = t
                tinsert(parent.children, t)
            else
                subParent = nil
                parent = t
                tinsert(reputationHeaders, t)
            end
        else
            -- Afaik, wow only has two levels of headers.
            local faction = subParent or parent
            _ = faction and tinsert(faction.children, t)
        end
    end
    self.reputationHeaders = reputationHeaders
end

function Player:recreateCooldowns()
    -- Ensure cooldowns have any new functions and values.
    for id, info in pairs(self.cooldowns or {}) do
        -- Accidentally had useless cooldowns in which aren't in the table so remove them.
        local new = ICT.Cooldowns[id]
        if new then
            self.cooldowns[id] = ICT.Cooldown:new(new.info)
            self.cooldowns[id].expires = info.expires
        else
            self.cooldowns[id] = nil
        end
    end
end

function Player:updateCooldowns()
    self.cooldowns = self.cooldowns or {}
    ICT.Cooldown:update(self)
end

function Player:getInstance(id, maxPlayers)
    return self.instances[Instance:key(id, maxPlayers)]
end

-- You gain 5% rested ever 8 hours, so every second equals the follow xp. 
local restedPerSecond = .05 / ( 8 * 60 * 60)
-- If you aren't resting you gain at a quarter of the rate, so divided by 4.
local notRestedPerSecond = restedPerSecond / 4
function Player:getRestedXP()
    -- This was added in later so safety check here.
    if self.resting == nil or not self.timestamp or not self.restedXP or not self.maxXP then
        return 0
    end
    local percentPerSecond = self.resting and restedPerSecond or notRestedPerSecond
    local timeElapsed = GetServerTime() - self.timestamp
    local percent = timeElapsed * percentPerSecond + (self.restedXP / self.maxXP)
    if percent > 1.5 then
        percent = 1.5
    end
	return percent
end

function Player:getName()
    return ICT.db.options.frame.verboseName and self.fullName or self.name
end

function Player:getShortName()
    return self.name
end

function Player:getFullName()
    return self.fullName
end

function Player:getNameWithIcon()
   return string.format("|T%s:%s|t%s", ICT.ClassIcons[self.class], ICT.UI.iconSize, self:getName())
end

function Player:getBattleTag()
    return self.battleTag or ""
end

function Player:getClassColor()
    local classColorHex = select(4, GetClassColor(self.class))
    -- From NIT: Safeguard for weakauras/addons that like to overwrite and break the GetClassColor() function.
    if not classColorHex then
        classColorHex = self.class == "SHAMAN" and "ff0070dd" or "ffffffff"
    end
    return classColorHex
end

function Player:isQuestVisible()
    return function(quest)
        return quest:isVisible() and (self:isQuestAvailable(quest) or not ICT.db.options.quests.hideUnavailable)
    end
end

function Player:isQuestAvailable(quest)
    return self.quests.prereq[quest.key]
end

function Player:isQuestCompleted(quest)
    return self.quests.completed[quest.key]
end

function Player:hasCooking(level)
    return self:getProfessionRank(185) >= (level or 1)
end

function Player:hasFishing(level)
    return self:getProfessionRank(356) >= (level or 1)
end

function Player:isEngineer(level)
    return self:getProfessionRank(202) >= (level or 1)
end

function Player:isEnchanter(level)
    return self:getProfessionRank(333) >= (level or 1)
end

function Player:isBlacksmith(level)
    return self:getProfessionRank(164) >= (level or 1)
end

function Player:isJewelCrafter(level)
    return self:getProfessionRank(755) >= (level or 1)
end

function Player:isLevel(level)
    return self.level >= level
end

function Player:isMaxLevel()
    return self:isLevel(Expansion.MaxLevel)
end

function Player:isCurrentPlayer()
    return self == ICT.Players:get()
end

function Player:isVisible()
    return not self.isDisabled
end

function Player:setVisible(checked)
    self.isDisabled = not checked
end

function Player:isEnabled()
    return self:isVisible() and self:isLevelVisible()
end

function Player:isLevelVisible()
    return self:isLevel(ICT.db.options.minimumLevel or Expansion.MaxLevel)
end

function Player:__eq(other)
    return self.fullName == other.fullName
end

function Player:__lt(other)
    return self.fullName < other.fullName
end

function Player:__tostring()
    return self.fullName
end