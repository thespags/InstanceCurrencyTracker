local addOnName, ICT = ...

ICT.Player = {}
local Player = ICT.Player
local Instances = ICT.Instances
local Quests = ICT.Quests
local Currency = ICT.Currency

local function dailyReset(player)
    Instances:ResetAll(player.dungeons)
    for k, _ in pairs(ICT.CurrencyInfo) do
        player.currency.daily[k] = player.currency.maxDaily[k] or 0
    end
    for k, _ in pairs(ICT.QuestInfo) do
        player.quests.completed[k] = false
    end
end

local function weeklyReset(player)
    Instances:ResetAll(player.raids)
    for k, _ in pairs(ICT.CurrencyInfo) do
        player.currency.weekly[k] = Currency:CalculateMaxRaidEmblems(k)(player)
    end
end

ICT.ResetInfo = {
    [1] = { name = "Daily", func = dailyReset },
    [3] = { name = "3 Day", func = function() end },
    [5] = { name = "5 Day", func = function() end },
    [7] = { name = "Weekly", func = weeklyReset },
}

function Player:Create()
    local player = {}
    player.name = UnitName("Player")
    player.realm = GetRealmName()
    player.fullName = Player.GetCurrentPlayer()
    player.class = select(2, UnitClass("Player"))
    player.faction = select(1, UnitFactionGroup("Player"))
    player.level = UnitLevel("Player")
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
    self:CreateInstances(player)
    -- Set transient information after copying main tables.
    dailyReset(player)
    weeklyReset(player)
    Player.OnLoad(player)
    return player
end

-- Creates instances in the transient tables if necessary.
-- The key is the English name with raid size if multiple sizes.
function Player:CreateInstances(player)
    player.dungeons = player.dungeons or {}
    player.raids = player.raids or {}
    player.oldRaids = player.oldRaids or {}
    for _, v in pairs(ICT.InstanceInfo) do
        if v.expansion == ICT.Expansions[ICT.WOTLK] then
            if #v.maxPlayers > 1 then
                for _, size in pairs(v.maxPlayers) do
                    self:addInstance(player.raids, v, size)
                end
            else
                self:addInstance(player.dungeons, v)
            end
        elseif v.expansion < ICT.Expansions[ICT.WOTLK] then
            self:addInstance(player.oldRaids, v)
        end
        if v.legacy then
            local instance = self:addInstance(player.oldRaids, v)
            instance.legacy = true
        end
    end
end

function Player:addInstance(t, info, size)
    local k = size and ICT:GetInstanceName(info.name, size) or info.name
    if not t[k] then
        local instance = { id = info.id, expansion = info.expansion, maxPlayers = size }
        ICT:LocalizeInstanceName(instance)
        Instances:Reset(instance)
        t[k] = instance
    end
    return t[k]
end

function Player:LocalizeInstanceNames(player)
    for _, v in pairs(player.dungeons) do
        ICT:LocalizeInstanceName(v)
    end
    for _, v in pairs(player.raids) do
        ICT:LocalizeInstanceName(v)
    end
    for _, v in pairs(player.oldRaids) do
        ICT:LocalizeInstanceName(v)
    end
end

function Player:ResetInstances()
    local timestamp = GetServerTime()
    for k, v in pairs(ICT.db.reset) do
        if v < timestamp then
            print(string.format("[%s] %s reset, updating info.", addOnName, ICT.ResetInfo[k].name))
            for _, player in pairs(ICT.db.players) do
                ICT.ResetInfo[k].func(player)
            end
            -- There doesn't seem to be an API to get 3 or 5 day reset so recalculate from the last known piece.
            -- Keep going until we have a time in the future, the player may have not logged in a while.
            while (ICT.db.reset[k] < timestamp) do
                ICT.db.reset[k] = ICT.db.reset[k] + k * 86400
            end
        end
    end
    -- Old raids have 3, 5 and 7 day resets... so use the instance specific timer.
    -- TODO: in the future we may want to link raids to their reset length.
    for _, player in pairs(ICT.db.players) do
        Player:OldRaidReset(player)
    end
end

function Player:OldRaidReset(player)
    Instances:ResetIfNecessary(player.oldRaids, GetServerTime())
end

function Player:CalculateCurrency(player)
    for k, _ in pairs(ICT.CurrencyInfo) do
        player.currency.wallet[k] = ICT:GetCurrencyAmount(k)
        -- There's no weekly raid quests so just add raid emblems.
        player.currency.weekly[k] = Currency:CalculateRaidEmblems(k)(player)
        player.currency.daily[k] = ICT:add(Currency:CalculateDungeonEmblems(k), Quests:CalculateAvailableDaily(k))(player)
        player.currency.maxDaily[k] = ICT:add(Currency:CalculateMaxDungeonEmblems(k), Quests:CalculateMaxDaily(k))(player)
    end
end

function Player:AvailableCurrency(player, tokenId)
    if ICT.CurrencyInfo[tokenId].unlimited then
        return "N/A"
    end
    if not player.currency.weekly[tokenId] or not player.currency.daily[tokenId] then
        return 0
    end
    return player.currency.weekly[tokenId] + player.currency.daily[tokenId]
end

function Player:CalculateQuest(player)
    for k, quest in pairs(ICT.QuestInfo) do
        player.quests.prereq[k] = quest.prereq(player)
        player.quests.completed[k] = Quests:IsDailyCompleted(quest)
    end
end

-- Updates instances and currencies.
-- We may want to decouple these things in the future.
function Player:Update(player)
    Player:ResetInstances()
    player = player or self:GetPlayer()
    Instances:Update(player)
    self:CalculateCurrency(player)
    self:CalculateQuest(player)
    self:CalculateResetTimes(player)
end

-- Returns the provided player or current player if none provided.
function Player:GetPlayer(playerName)
    playerName = playerName or Player.GetCurrentPlayer()
    if not ICT.db.players[playerName]  then
        print(string.format("[%s] Creating player: %s", addOnName, playerName))
    end
    local player = ICT.db.players[playerName] or Player:Create()
    ICT.db.players[playerName] = player
    return player
end

function Player:WipePlayer(playerName)
    if ICT.db.players[playerName] then
        ICT.db.players[playerName] = nil
        print(string.format("[%s] Wiped player: %s", addOnName, playerName))
    else
        print(string.format("[%s] Unknown player: %s", addOnName, playerName))
    end
    self:Update()
end

function Player:WipeRealm(realmName)
    local count = 0
    for name, _ in ICT:fpairsByValue(ICT.db.players, function(v) return v.realm == realmName end) do
        count = count + 1
        ICT.db.players[name] = nil
    end
    print(string.format("[%s] Wiped %s players on realm: %s", addOnName , count, realmName))
    self:Update()
end

function Player:WipeAllPlayers()
    local count = ICT:sum(ICT.db.players, ICT:ReturnX(1))
    ICT.db.players = {}
    print(string.format("[%s] Wiped %s players", addOnName, count))
    self:Update()
end

function Player:CalculateResetTimes(player)
    for _, instance in pairs(player.oldRaids) do
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

local SECONDARY_SKILLS = string.gsub(SECONDARY_SKILLS, ":", "")
local PROFICIENCIES = string.gsub(PROFICIENCIES, ":", "")
function Player.UpdateSkills(player)
    player = player or Player:GetPlayer()
    -- Skill list is always in same order, so we can get primary/secondary/weapon by checking the section headers.
    local professionCount = 0
    local isSecondary = false
    local profession = false
    -- Reset skills in case one was dropped.
    player.professions = {}

    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, max = GetSkillLineInfo(i)
        local spellId = name == "Herbalism" and 2383 or name
        local icon = select(3, GetSpellInfo(spellId))
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

            player.professions[professionCount] = {
                name = name,
                icon = icon,
                rank = rank,
                max = max,
                isSecondary = isSecondary
            }
        end
    end
end

local function getSpecs(player)
    player.specs = player.specs or {}
    return player.specs
end

function Player.UpdateTalents(player)
    player = player or Player:GetPlayer()
    local active = ICT.LCInspector:GetActiveTalentGroup(player.guid)
    local specs = getSpecs(player)
    player.activeSpec = active
    for i=1,2 do
        local tab1, tab2, tab3 = ICT.LCInspector:GetTalentPoints(player.guid, i)
        specs[i] = specs[i] or {}
        local specialization = ICT.LCInspector:GetSpecialization(player.guid, i)
        specs[i].name = specialization and ICT.LCInspector:GetSpecializationName(player.class, specialization, true) or ""
        specs[i].tab1, specs[i].tab2, specs[i].tab3 = tab1, tab2, tab3
        specs[i].glyphs = { ICT.LCInspector:GetGlyphs(player.guid, i) }
    end
    Player.UpdateGear()
end

function Player.UpdateGear(player)
    if TT_GS then
        player = player or Player:GetPlayer()
        local active = ICT.LCInspector:GetActiveTalentGroup(player.guid)
        local specs = getSpecs(player)
        specs[active] = specs[active] or {}
        specs[active].gearScore, specs[active].ilvlScore = TT_GS:GetScore(player.guid)
    end
end

ICT.BagFamily = {
    -- Generic
    [0] = { icon = 133655, name = "General" },
    -- Arrows ?
    [1] = { icon = 41165, name = "Arrows" },
    -- Bullets ?
    [2] = { icon = 249175, name = "Bullets" },
    -- Soul Shards
    [3] = { icon = 134075, name = "Soul Shards" },
    -- Herbalism ?
    [6] = { icon = 136246, name = select(1, GetSpellInfo(265820))},
    -- Enchanting ?
    [7] = { icon = 136244, name = select(1, GetSpellInfo(51313))},
    -- Leathworking 
    [8] = { icon = 133611, name = select(1, GetSpellInfo(51302))},
    -- Jewelcrafting ?
    [10] = { icon = 134071, name = select(1, GetSpellInfo(51311))},
    -- Mining ?
    [11] = { icon = 136248, name = select(1, GetSpellInfo(50310))},
    -- Inscription 
    [16] = { icon = 237171, name = select(1, GetSpellInfo(45357))},
    -- Engineering
    [128] = { icon = 136243, name = select(1, GetSpellInfo(51306))},
}
-- If we decide to work on other versions than WOTLK.
local GetBagName = GetBagName or C_Container.GetBagName
local GetContainerNumFreeSlots = GetContainerNumFreeSlots or C_Container.GetContainerNumFreeSlots;
local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots;

local function updateBags(player, key, startIndex, length)
    player[key] = {}
    player[key .. "Total"] = {}
    local bags = player[key]
    local bagsTotal = player[key .. "Total"]
    for k, _ in pairs(ICT.BagFamily) do
        bagsTotal[k] = { free = 0, total = 0 }
    end
    -- Surprisingly this one thing that is 0-indexed in WOW.
    local endIndex = startIndex + length
    for index=startIndex,endIndex do
        local free, type = GetContainerNumFreeSlots(index)
        local total = GetContainerNumSlots(index)
        local name = GetBagName(index)
        bags[index] = { name = name, free = free, type = type, total = total }
        bagsTotal[type].free = bagsTotal[type].free + free
        bagsTotal[type].total = bagsTotal[type].total + total
    end
end

function Player.UpdateBags(player)
    player = player or Player:GetPlayer()
    updateBags(player, "bags", 0, NUM_BAG_SLOTS)
end

function Player.UpdateBankBags(player)
    player = player or Player:GetPlayer()
    updateBags(player, "bankBags", NUM_BAG_SLOTS + 1, NUM_BANKBAGSLOTS)
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

function Player.UpdateDurability(player)
    player = player or Player:GetPlayer()
    player.durability = getAverageDurability()
end

function Player.UpdateMoney(player)
    player = player or Player:GetPlayer()
    player.money = GetMoney() or 0
end

function Player.UpdateGuild(player)
    player = player or Player:GetPlayer()
    player.guild, player.guildRank, _ = GetGuildInfo("Player")
    player.guild = player.guild or "No Guild"
end

function Player.UpdateXP(player)
    player = player or Player:GetPlayer()
    player.currentXP = UnitXP("Player")
    player.maxXP = UnitXPMax("Player")
    player.level = UnitLevel("Player")
    player.restedXP = GetXPExhaustion();
end

function Player.UpdateResting(player)
    player = player or Player:GetPlayer()
    player.resting = IsResting()
    player.restedXP = GetXPExhaustion();
end

function Player.OnLoad(player)
    player = player or Player:GetPlayer()
    -- Pass in player so we don't get in a bad case of recursion.
    Player:Update(player)
    Player.UpdateSkills(player)
    Player.UpdateTalents(player)
    Player.UpdateGear(player)
    Player.UpdateBags(player)
    Player.UpdateDurability(player)
    Player.UpdateMoney(player)
    Player.UpdateGuild(player)
    Player.UpdateXP(player)
    Player.UpdateResting(player)
    player.guid = UnitGUID("Player")

    for k, v in pairs(ICT.db.players) do
        if v.guid == player.guid and player.fullName ~= k then
            ICT.db.players[k] = nil
            break
        end
    end
end

function Player.GetName(player)
    return ICT.db.options.verboseName and player.fullName or player.name
end

function Player.GetNameWithIcon(player)
   return string.format("|T%s:14|t%s", ICT.ClassIcons[player.class], Player.GetName(player))
end

function Player.PlayerSort(a, b)
    return Player.GetName(a) < Player.GetName(b)
end

function Player.PlayerEnabled(player)
    return not player.isDisabled and player.level > 0--and Player.IsMaxLevel(player)
end

function Player.IsMaxLevel(player)
    return player.level == ICT.MaxLevel
end

function Player.GetCurrentPlayer()
    return string.format("[%s] %s", GetRealmName(), UnitName("Player"))
end

-- You gain 5% rested ever 8 hours, so every second equals the follow xp. 
local restedPerSecond = .05 / ( 8 * 60 * 60)
-- If you aren't resting you gain at a quarter of the rate, so divided by 4.
local notRestedPerSecond = restedPerSecond / 4
function Player.GetRestedXP(player)
    -- This was added in later so safety check here.
    if not player.resting or not player.time or not player.restedXP or not player.maxXP then
        return 0
    end
    local percentPerSecond = player.resting and restedPerSecond or notRestedPerSecond
    local timeElapsed = GetServerTime() - player.time
    local percent = timeElapsed * percentPerSecond + (player.restedXP / player.maxXP)
    if percent > 1.5 then
        percent = 1.5
    end
	return percent
end