local lib, oldminor = LibStub:NewLibrary("LibInstances", 1)

-- Already loaded
if not lib then
    return
end

local groups = {}
local infos = {}
local Instances = {}

function lib:GetInfos()
    return infos
end

function lib:GetInfo(id)
    return infos[id]
end

function lib:addInstance(id, info)
    info.id = id
    infos[id] = Instances:new(info)
end

function Instances:new(info)
    setmetatable(info, self)
    self.__index = self
    return info
end

function Instances:getSizes()
    return self.sizes
end

function Instances:getExpansion(size)
    -- Ignore Onyxia 40 now with cata.
    -- if self.legacy and self.legacy.size == size then
    --     return self.legacy.expansion
    -- end
    return self.expansion
end

-- This may change in the future if instances with the same size get legacy-ed...
function Instances:getLegacySize()
    return self.legacy and self.legacy.size or nil
end

function Instances:getResetInterval(size)
    local interval = self.resets[size]
    assert(interval, string.format("Unknown size for: ID=%s size=%s", self.id, size))
    return interval
end

function Instances:getLastBossIndex()
    return self.lastBossIndex
end

function Instances:getEncounters()
    return self.encounters
end

-- This doesn't make sense for zones with subzones (like Scarlet Monastery and Dire Maul)
function Instances:getActivityId(size, difficulty)
    local activities = (self.activities[size] or {})
    local activityId = activities[math.min(difficulty, #activities)]
    return activityId
end

function Instances:getEncountersKilledByIndex(index)
    local instanceId = select(14, GetSavedInstanceInfo(index))
    assert(self.id == instanceId, string.format("GetSavedInstanceInfo InstanceID does not match: ExpectedID=%s, ID=%s Index%s", self.id, instanceId, index))
    local encountersKilled = {}
    for k, _ in pairs(self.encounters) do
        encountersKilled[k] = select(3, GetSavedInstanceEncounterInfo(index, k))
    end
    return encountersKilled
end

function lib:getEncountersKilledByInstanceId()
    for i=1, GetNumSavedInstances() do
        local id = select(14, GetSavedInstanceInfo(i))
        if id == self.id then
            return lib:getEncountersKilledByIndex(i)
        end
    end
    local encountersKilled = {}
    for k, _ in pairs(self.encounters) do
        encountersKilled[k] = 0
    end
    return encountersKilled
end

function lib:addGroup(id, name)
    groups[id] = name
end

function lib:getGroup(id)
    return groups[id]
end