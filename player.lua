Player = {}

function Player:CalculateCurrency(player)
    player.availableDungeonEmblems = Instances:CalculateDungeonEmblems(player.dungeons) + Quests:CalculateDailyNormal()
    player.availableHeroicDungeonEmblems = Quests:CalculateDailyHeroic()
    player.currentSiderealEssences = Utils:GetCurrency(Utils.SiderealEssence)
    player.availableSiderealEssences = Instances:CalculateSiderealEssences(player.dungeons)
    player.currentEmblemsOfHeroism = Utils:GetCurrency(Utils.Heroism)
    -- Always 0 now in Phase 3
    player.availableEmblemsOfHeroism = 0
    player.currentEmblemsOfValor = Utils:GetCurrency(Utils.Valor)
    player.availableEmblemsOfValor = Instances:CalculateEmblemsOfValor(player.raids)
    player.currentEmblemsOfConquest = Utils:GetCurrency(Utils.Conquest)
    player.availableEmblemsOfConquest = Instances:CalculateEmblemsOfConquest(player.raids)
    player.currentEmblemsOfTriumph = Utils:GetCurrency(Utils.Triumph)
    player.availableEmblemsOfTriumph = Instances:CalculateEmblemsOfTriumph(player.raids)
    player.currentChampionsSeals = Utils:GetCurrency(Utils.ChampionsSeal)
    player.availableChampionsSeals = Quests:CalculateChampionsSeals() + Instances:CalculateChampionsSeals(player.dungeons)
end

function Player:Create()
    local player = {}
    player.name = UnitName("Player")
    player.realm = GetRealmName()
    player.fullName = Utils:GetFullName()
    player.class = select(2, UnitClass("Player"))
    player.level = UnitLevel("Player")
    player.dungeons = CopyTable(Instances.dungeons)
    player.raids = CopyTable(Instances.raids)
    player.oldRaids = CopyTable(Instances.oldRaids)
    -- Set transient information after copying main tables.
    self:DailyReset(player)
    self:WeeklyReset(player)
    Instances:ResetAll(player.oldRaids)
    return player
end

function Player:DailyReset(player)
    Instances:ResetAll(player.dungeons)
    player.availableDungeonEmblems = Instances.maxDungeonEmblems
    player.availableSiderealEssence = Instances.maxSiderealEssence
    player.availableTriumphDungeonEmblems = 5
    player.dailyReset = C_DateAndTime.GetSecondsUntilDailyReset() + GetServerTime()
end

function Player:WeeklyReset(player)
    Instances:ResetAll(player.raids)
    player.weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset() + GetServerTime()
end

function Player:OldRaidReset(player)
    Instances:ResetIfNecessary(player.oldRaids, GetServerTime())
end

-- Make these options?
local titleColor = "|cFFFFFF00"
local lockedColor = "|c00FF00FF"
local availableColor = "|cFFFFFFFF"

Player.PrintCurrencyShort = function(name, current, available, show)
    return show and { 
        titleColor .. name .. "|r "
        .. availableColor .. (current or "n/a") 
        .. " (" .. (available or "n/a") .. ")|r" 
    } or {}
end

Player.PrintCurrencyVerbose = function(name, current, available, show)
    return show and { 
        titleColor .. name .. "|r",
        availableColor .. "Available  " .. (available or "n/a") .. "|r",
        availableColor .. "Current     " .. (current or "n/a") .. "|r"
    } or {}
end

function Player:ToName(v)
    local name = GetRealZoneText(v.id)
    return v.maxPlayers and string.format("%s (%s)", name, v.maxPlayers) or name
end

function Player:PrintInstances(title, instances, showLocked, showAvailable)
    local names = {}
    for _, v in pairs(instances) do
        names[self:ToName(v)] = v
    end

    local text = {}
    if showLocked or showAvailable then
        table.insert(text, titleColor .. title .. "|r")
    end

    if showAvailable then
        for name, v in Utils:spairs(names) do
            if not v.locked then
                table.insert(text, availableColor .. name .. "|r")
            end
        end
    end

    if showLocked then
        for name, v in Utils:spairs(names) do
            if v.locked then
                table.insert(text, lockedColor .. string.format("%s   %s/%s", name, v.encounterProgress, v.numEncounters) .. "|r")
            end
        end
    end

    return text
end