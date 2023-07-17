Instances = {}

local sameEmblemsPerBoss = function(emblemsPerEncounter)
    return function(instance) return emblemsPerEncounter * (instance.numEncounters - instance.encounterProgress) end
end

local sameEmblemsPerBossPerSize = function(emblems10, emblems25)
    return function(instance) return (instance.maxPlayers == 10 and emblems10 or emblems25) * (instance.numEncounters - instance.encounterProgress) end
end

-- If we have an instance lock index then check if the boss is killed.
local isBossKilled = function(instance, bossIndex)
    return instance.instanceIndex > 0 and select(3, GetSavedInstanceEncounterInfo(instance.instanceIndex, bossIndex)) or false
end

-- Checks if the last boss in the instance is killed, using the number of encounters as the last boss index.
local isLastBossKilled = function(instance)
    return isBossKilled(instance, instance.numEncounters)
end

local addOneLastBossAlive = function(instance)
    return isLastBossKilled(instance) and 0 or 1
end

local onePerBossPlusOneLastBoss = Utils:add(sameEmblemsPerBoss(1), addOneLastBossAlive)

-- Ulduar has different amounts per boss
-- FL(4)/Ignis(1)/Razorscale(1)/XT(2)/IC(2)/Kolo(1)/Auriaya(1)/Thorim(2)/Hodir(2)/Freya(5)/Mim(2)/Vezak(2)/Yogg(2)/Alg(2)
local ulduarEmblemsPerBoss = { 4, 1, 1, 2, 2, 1, 1, 2, 2, 5, 2, 2, 2, 2 }
-- Ulduar has a maximum number of emblems of 29
local maxUlduarEmblems = Utils:sum(ulduarEmblemsPerBoss)
local ulduarEmblems = function(instance)
    local emblems = maxUlduarEmblems
    if instance.instanceIndex > 0 then
        for i, ulduarEmblem in pairs(ulduarEmblemsPerBoss) do
            if isBossKilled(instance, i) then
                emblems = emblems - ulduarEmblem
            end
        end
    end
    return maxUlduarEmblems
end

-- Vault of Archavon drops a different token per boss
local voaIndex = {
    [Utils.Valor] = 1,
    [Utils.Conquest] = 2,
    [Utils.Triumph] = 3,
}
local voaEmblems = function(instance, tokenId)
    return (isBossKilled(instance, voaIndex[tokenId]) and 0 or 2)
end

local maxEmblemsPerSize = function(max10, max25)
    return function(v) return v.maxPlayers == 10 and max10 or max25 end
end

-- There's no clear API on getting the canonical name, and later instances are divided by 10 and 25 lockouts.
-- We could overload the id and max player for some formula, such as concatenating the two.
-- For readability of tables we will use English names instead of ids.
StaticInstances = {
    [574] = { name = "Utgarde Keep" },
    [575] = { name = "Utgarde Pinnacle" },
    [595] = { name = "The Culling of Stratholme" },
    [600] = { name = "Drak'Tharon Keep" },
    [604] = { name = "Gundrak" },
    [576] = { name = "The Nexus" },
    [578] = { name = "The Oculus" },
    [608] = { name = "The Violet Hold" },
    [602] = { name = "Halls of Lightning" },
    [599] = { name = "Halls of Stone" },
    [601] = { name = "Azjol-Nerub" },
    [619] = { name = "Ahn'kahet: The Old Kingdom" },
    [650] = { name = "Trial of the Champion" },
    [624] = { name = "Vault of Archavon", tokenIds = Utils:set(Utils.Triumph, Utils.Conquest, Utils.Valor), emblems = voaEmblems, maxEmblems = Utils:returnX(2) },
    [533] = { name = "Naxxramas", tokenIds = Utils:set(Utils.Valor), emblems = onePerBossPlusOneLastBoss, maxEmblems = Utils:returnX(16) },
    [615] = { name = "The Obsidian Sanctum", tokenIds = Utils:set(Utils.Valor), emblems = onePerBossPlusOneLastBoss, maxEmblems = Utils:returnX(5) },
    [616] = { name = "The Eye of Eternity", tokenIds = Utils:set(Utils.Valor), emblems = onePerBossPlusOneLastBoss, maxEmblems = Utils:returnX(2) },
    [603] = { name = "Ulduar", tokenIds = Utils:set(Utils.Conquest), emblems = ulduarEmblems, maxEmblems = Utils:returnX(maxUlduarEmblems) },
    [249] = { name = "Onyxia's Lair", tokenIds = Utils:set(Utils.Triumph), emblems = sameEmblemsPerBossPerSize(4, 5), maxEmblems = maxEmblemsPerSize(4, 5) },
    [649] = { name = "Trial of the Crusader", tokenIds = Utils:set(Utils.Triumph), emblems = sameEmblemsPerBossPerSize(4, 5), maxEmblems = maxEmblemsPerSize(20, 25) },
    [309] = { name = "Zul'Gurub" }
}
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
Instances.raids = {
    ["Vault of Archavon (10)"] = { id = 624, maxPlayers = 10, numEncounters = 3 },
    ["Vault of Archavon (25)"] = { id = 624, maxPlayers = 25, numEncounters = 3},
    ["Naxxramas (10)"] = { id = 533, maxPlayers = 10, numEncounters = 15},
    ["Naxxramas (25)"] = { id = 533, maxPlayers = 25, numEncounters = 15},
    ["The Obsidian Sanctum (10)"] = { id = 615, maxPlayers = 10, numEncounters = 4},
    ["The Obsidian Sanctum (25)"] = { id = 615, maxPlayers = 25, numEncounters = 4},
    ["The Eye of Eternity (10)"] = { id = 616, maxPlayers = 10, numEncounters = 1},
    ["The Eye of Eternity (25)"] = { id = 616, maxPlayers = 25, numEncounters = 1},
    ["Ulduar (10)"] = { id = 603, maxPlayers = 10, numEncounters = 14},
    ["Ulduar (25)"] = { id = 603, maxPlayers = 25, numEncounters = 14},
    ["Onyxia's Lair (10)"] = { id = 249, maxPlayers = 10, numEncounters = 1 },
    ["Onyxia's Lair (25)"] = { id = 249, maxPlayers = 25, numEncounters = 1},
    ["Trial of the Crusader (10)"] = { id = 649, maxPlayers = 10, numEncounters = 5 },
    ["Trial of the Crusader (25)"] = { id = 649, maxPlayers = 25, numEncounters = 5 }
}
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
        local _, _, reset, _, locked, _, _, _, maxPlayers, _, _, encounterProgress, _, instanceId = GetSavedInstanceInfo(i)

        if locked then
            local name = StaticInstances[instanceId].name
            self:Lock(player.dungeons[name], reset, encounterProgress, i)
            local raidName = name and Utils:GetInstanceName(name, maxPlayers)
            self:Lock(player.raids[raidName], reset, encounterProgress, i)
            self:Lock(player.oldRaids[name], reset, encounterProgress, i)
        end
    end
end

-- Sums all the emblems for the instances, and stores each instances into the instance's table.
local function sumEmblems(instances, op, filter)
    local emblems = 0
    for k, v in Utils:fpairs(instances, filter) do
        v.availableEmblems = op(v)
        emblems = emblems + v.availableEmblems
    end
    return emblems
end

function Instances:CalculateDungeonEmblems(instances)
    return sumEmblems(instances, sameEmblemsPerBoss(1), Utils.True)
end

function Instances:CalculateSiderealEssences(instances)
    return Utils:sum(instances, addOneLastBossAlive)
end

-- Trial of the Champion drops 1 Champion's Seals per encounter.
function Instances:CalculateChampionsSeals(instances)
    return sameEmblemsPerBoss(1)(instances[StaticInstances[650].name])
end