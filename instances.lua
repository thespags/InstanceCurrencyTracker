Instances = {}

Instances.dungeons = {
    ["Utgarde Keep"] = { id = 574, numEncounters = 3 },
    ["Utgarde Pinnacle"] = { id = 575, numEncounters = 4 },
    ["The Culling of Stratholme"] = { id = 595, numEncounters = 5 },
    ["Drak'Tharon Keep"] = { id = 600, numEncounters = 4 },
    ["Gundrak"] = { id = 604, numEncounters = 5 },
    ["The Nexus"] = { id = 576, numEncounters = 5 },
    ["The Oculus"] = { id = 578, numEncounters = 4 },
    ["The Violet Hold"] = { id = 608, numEncounters = 3 },
    ["Halls of Lightning"] = { id = 602, numEncounters = 4 },
    ["Halls of Stone"] = { id = 599, numEncounters = 4 },
    ["Azjol-Nerub"] = { id = 601, numEncounters = 3 },
    ["Ahn'kahet: The Old Kingdom"] = { id = 619, numEncounters = 5 },
    ["Trial of the Champion"] = { id = 650, numEncounters = 3 },
    --["Pit of Saron"] = { id = ?, numEncounters = 3 },
    --["The Forge of Souls"] = { id = ?, numEncounters = 3 },
    --["Halls of Reflection"] = { id = ?, numEncounters = 3 }
}
-- 1 Emblem per boss in dungeons + 2 for daily normal quest
Instances.maxDungeonEmblems = Utils:sum(Instances.dungeons, function(v) return v.numEncounters end) + Quests.DailyNormalEmblems
-- 1 Sidereal Essence per dungeon
Instances.maxSiderealEssence = Utils:sum(Instances.dungeons, function(_) return 1 end)
Instances.raids = {
    -- Vault of Archavon doesn't have a specific token, each boss is different.
    ["Vault of Archavon (10)"] = { id = 624, maxPlayers = 10, numEncounters = 3, encounterEmblems = 2 },
    ["Vault of Archavon (25)"] = { id = 624, maxPlayers = 25, numEncounters = 3, encounterEmblems = 2 },
    ["Naxxramas (10)"] = { id = 533, maxPlayers = 10, numEncounters = 15, tokenId = Utils.Valor, encounterEmblems = 1 },
    ["Naxxramas (25)"] = { id = 533, maxPlayers = 25, numEncounters = 15, tokenId = Utils.Valor, encounterEmblems = 1 },
    ["The Obsidian Sanctum (10)"] = { id = 615, maxPlayers = 10, numEncounters = 4, tokenId = Utils.Valor, encounterEmblems = 1 },
    ["The Obsidian Sanctum (25)"] = { id = 615, maxPlayers = 25, numEncounters = 4, tokenId = Utils.Valor, encounterEmblems = 1 },
    ["The Eye of Eternity (10)"] = { id = 616, maxPlayers = 10, numEncounters = 1, tokenId = Utils.Valor, encounterEmblems = 1 },
    ["The Eye of Eternity (25)"] = { id = 616, maxPlayers = 25, numEncounters = 1, tokenId = Utils.Valor, encounterEmblems = 1 },
    ["Ulduar (10)"] = { id = 603, maxPlayers = 10, numEncounters = 14, tokenId = Utils.Conquest },
    ["Ulduar (25)"] = { id = 603, maxPlayers = 25, numEncounters = 14, tokenId = Utils.Conquest },
    ["Onyxia's Lair (10)"] = { id = 249, maxPlayers = 10, numEncounters = 1, tokenId = Utils.Triumph, encounterEmblems = 4 },
    ["Onyxia's Lair (25)"] = { id = 249, maxPlayers = 25, numEncounters = 1, tokenId = Utils.Triumph, encounterEmblems = 5 },
    ["Trial of the Crusader (10)"] = { id = 649, maxPlayers = 10, numEncounters = 5, tokenId = Utils.Triumph, encounterEmblems = 4 },
    ["Trial of the Crusader (25)"] = { id = 649, maxPlayers = 25, numEncounters = 5, tokenId = Utils.Triumph, encounterEmblems = 5 }
}
-- FL(4)/Ignis(1)/Razorscale(1)/XT(2)/IC(2)/Kolo(1)/Auriaya(1)/Thorim(2)/Hodir(2)/Freya(5)/Mim(2)/Vezak(2)/Yogg(2)/Alg(2)
local ulduarEmblems = { 4, 1, 1, 2, 2, 1, 1, 2, 2, 5, 2, 2, 2, 2 }
-- Ulduar has a maximum number of emblems of 29
local maxUlduarEmblems = Utils:sum(ulduarEmblems)
Instances.oldRaids = {
    ["Zul'Gurub"] = { id = 309, numEncounters = 10 }
}

-- Reset all saved instance information.
function Instances:ResetAll(instances)
    for _, instance in pairs(instances) do
        self:Reset(instance)
    end
end

-- Reset saved instance information.
function Instances:ResetIfNecessary(instances, timestamp)
    for _, instance in pairs(instances) do
        if instance.reset and instance.reset < timestamp then
            self:Reset(instance)
        end
    end
end

function Instances:Reset(instance)
    instance.locked = false
    instance.reset = nil
    instance.encounterProgress = 0
    instance.instanceIndex = 0
end

-- Lock the specified instance with the provided information.
function Instances:Lock(instance, reset, encounterProgress, i)
    if instance then
        instance.locked = true
        instance.reset = reset
        instance.encounterProgress = encounterProgress
        instance.instanceIndex = i
    end
end

function Instances:Update(player)
    -- Get all saved instance information and lock the respective instance for the player.
    local numSavedInstances = GetNumSavedInstances()
    for i=1, numSavedInstances do
        local name, _, reset, _, locked, _, _, _, maxPlayers, _, _, encounterProgress, _, _ = GetSavedInstanceInfo(i)

        if locked then   
            self:Lock(player.dungeons[name], reset, encounterProgress, i)
            local raidName = Utils:ToRaidName(name, maxPlayers)
            self:Lock(player.raids[raidName], reset, encounterProgress, i)
            self:Lock(player.oldRaids[name], reset, encounterProgress, i)
        end
    end
end

-- If we have an instance lock index then check if the boss is killed.
local isBossKilled = function(instance, bossIndex)
    return instance.instanceIndex > 0 and select(3, GetSavedInstanceEncounterInfo(instance.instanceIndex, bossIndex)) or false
end

-- Checks if the last boss in the instance is killed,
-- using the number of encounters as the last boss index.
local isLastBossKilled = function(instance)
    return isBossKilled(instance, instance.numOfEncounters)
end

local sameEmblemsPerBoss = function(k)
    return function(v) return k * (v.numEncounters - v.encounterProgress) end
end

local addOneLastBossAlive = function(v)
    return isLastBossKilled(v) and 0 or 1
end

local tokenFilter = function(id)
     return function(v) return v.tokenId == id end
end

function Instances:CalculateDungeonEmblems(instances)
    return Utils:sum(instances, sameEmblemsPerBoss(1))
end

function Instances:CalculateSiderealEssences(instances)
    return Utils:sum(instances, addOneLastBossAlive)
end

function Instances:CalculateVoaEmblems(raids, index)
    local voa10 = raids["Vault of Archavon (10)"]
    local voa25 = raids["Vault of Archavon (25)"]
    return (isBossKilled(voa10, index) and 0 or voa10.encounterEmblems)
    + (isBossKilled(voa25, index) and 0 or voa25.encounterEmblems)
end

function Instances:CalculateEmblemsOfValor(raids)
    local emblems = self:CalculateVoaEmblems(raids, 1)
    for _, v in Utils:fpairs(raids, tokenFilter(Utils.Valor)) do
        emblems = emblems
        + sameEmblemsPerBoss(v.encounterEmblems)(v)
        -- Last boss of eoe/os/naxx give an extra token
        + addOneLastBossAlive(v)
    end
    return emblems
end

function Instances:CalculateEmblemsOfConquest(raids)
    local emblems = self:CalculateVoaEmblems(raids, 2)
    for _, v in Utils:fpairs(raids, tokenFilter(Utils.Conquest)) do
        -- Ulduar has different amounts per boss
        if v.instanceIndex > 0 then
            for i, ulduarEmblem in pairs(ulduarEmblems) do
                if not isBossKilled(v, i) then
                    emblems = emblems + ulduarEmblem
                end
            end
        else
            emblems = emblems + maxUlduarEmblems
        end
    end
    return emblems
end

function Instances:CalculateEmblemsOfTriumph(raids)
    local emblems = self:CalculateVoaEmblems(raids, 3)
    for _, v in Utils:fpairs(raids, tokenFilter(Utils.Triumph)) do
        emblems = emblems + sameEmblemsPerBoss(v.encounterEmblems)(v)
    end
    return emblems
end

-- Trial of the Champion drops 1 Champion's Seals per encounter.
function Instances:CalculateChampionsSeals(instances)
    return sameEmblemsPerBoss(1)(instances["Trial of the Champion"])
end