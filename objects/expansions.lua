local _, ICT = ...

local LibInstances = LibStub("LibInstances")
local log = ICT.log

ICT.Cata = 3
ICT.WOTLK = 2
ICT.TBC = 1
ICT.Vanilla = 0
ICT.Expansions = {
    [ICT.Cata] = "Cataclysm",
    [ICT.WOTLK] = "Wrath of the Lich King",
    [ICT.TBC] = "The Burning Crusade",
    [ICT.Vanilla] = "Vanilla"
}

Expansion = {}
ICT.Expansion = Expansion

Expansion.value = LE_EXPANSION_LEVEL_CURRENT
Expansion.MaxLevel = GetMaxLevelForExpansionLevel(LE_EXPANSION_LEVEL_CURRENT)

function Expansion.isVanilla()
    return ICT.Vanilla == Expansion.value
end

function Expansion.isWOTLK()
    return ICT.WOTLK == Expansion.value
end

function Expansion.isCata()
    return ICT.Cata == Expansion.value
end

-- Whether or not the value was released, e.g. false if value is Vanilla and current is WOTLK.
function Expansion.active(value)
    return value and value <= Expansion.value
end

function Expansion.max(value)
    return not value or Expansion.value <= value
end

function Expansion.min(value)
    return not value or Expansion.value >= value
end

-- Whether the value is for the current expansion.
function Expansion.current(value)
    return value == Expansion.value
end

function Expansion.isSod(player)
    return player.season == 2
end

function Expansion.isHardcore(player)
    return player.season == 3
end

function Expansion.hasGlyphs()
    return Expansion.isWOTLK() or Expansion.isCata()
end


local function hasHardcoreLock(player)
    -- Locks go away at level 60.
    return Expansion.isHardcore(player) and not player:isMaxLevel()
end

function Expansion.init()
    local pvpWeekend = {}
    if Expansion.isVanilla() then
        -- Only add hardcore locks if there's a player.
        local hasHardcore = false
        local hasSod = false
        for _, player in pairs(ICT.db.players) do
            if Expansion.isHardcore(player) then
                hasHardcore = true
            end
            if Expansion.isSod(player) then
                hasSod = true
            end
        end
        Expansion.MaxLevel = C_Seasons.GetActiveSeason() == 2 and 50 or 60
        for id, info in pairs(LibInstances:GetInfos()) do
            info.seasons = {}
            -- Hack to handle hardcore
            if hasHardcore then
                tinsert(info.sizes, 5)
                info.resets[5] = 1
                info.seasons[5] = hasHardcoreLock
            end
            -- Hack to handle Season of Discovery.
            if hasSod then
                if (id == 48 or id == 90) then
                    tinsert(info.sizes, 10)
                    info.resets[10] = 3
                    info.seasons[10] = Expansion.isSod
                elseif (id == 109) then
                    tinsert(info.sizes, 20)
                    info.resets[20] = 7
                    info.seasons[20] = Expansion.isSod
                end
            end
        end
        pvpWeekend["Alterac Valley"] = 1704412800
        pvpWeekend["Warsong Gulch"] = 1705017600
        pvpWeekend["Arathi Basin"] = 1705622400
        pvpWeekend["None"] = 1706227200
    elseif ICT.TBC == Expansion.value then
    elseif Expansion.isWOTLK() then
        pvpWeekend["Strand of the Ancients"] = 1704412800
        pvpWeekend["Alterac Valley"] = 1705017600
        pvpWeekend["Eye of the Storm"] = 1705622400
        pvpWeekend["Warsong Gulch"] = 1706227200
        pvpWeekend["Arathi Basin"] = 1706860800
    elseif Expansion.isCata() then
    end

    function Expansion.pvpWeekend()
        return pvpWeekend
    end

    local cycle = ICT.OneWeek * ICT:size(pvpWeekend)
    function Expansion.pvpCycle()
        return cycle
    end

    local length = ICT.OneDay * 3 + ICT.OneHour * 8
    function Expansion.pvpLength()
        return length
    end
end