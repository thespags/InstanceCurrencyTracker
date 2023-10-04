local addOnName, ICT = ...

local Talents = {}
ICT.Talents = Talents

-- This must be initialized after the talent frame is loaded.
local specNames

function Talents:updateSpec(spec, id)
    spec = spec or {}
    spec.id = id
    local max = 0
    local totalPoints = 0
    for i = 1,GetNumTalentTabs() do
        local name, icon, pointsSpent, _ = GetTalentTabInfo(i, false, false, id)
        pointsSpent = pointsSpent or 0
        spec["tab" .. i] = pointsSpent
        totalPoints = totalPoints + pointsSpent
        if pointsSpent > max then
            spec.name = name
            spec.icon = icon
        end
    end
    spec.totalPoints = totalPoints
    spec.glyphs = {}
    for j=1,6 do
        local enabled, type, spellId, icon = GetGlyphSocketInfo(j, id)
        spec.glyphs[j] = { enabled = enabled, type = type, spellId = spellId, icon = icon }
    end
    return spec
end

function Talents:isValidSpec(spec)
    return not(spec.tab1 == 0 and spec.tab2 == 0 and spec.tab3 == 0)
end

function Talents:updatePet(player)
    local icon, name, level, type, talent = GetStablePetInfo(0)
    local pet = ICT.Pet:new({ player = player, icon = icon, name = name, level = level, type = type, talent = talent })
    player.pets[name] = ICT.Pet:new(pet)

    local activeSpec = player:getSpec()
    activeSpec.pets = activeSpec.pets or {}
    local _, talentIcon, pointsSpent, fileName = GetTalentTabInfo(1, false, true, 1)
    activeSpec.pets[name] = { talentIcon = talentIcon, pointsSpent = pointsSpent, fileName = fileName }
end

function Talents:activateSpec(specId)
    return function()
        SetActiveTalentGroup(specId)
    end
end

function Talents:calculatePrimaryTab(specId, isPet)
    local t = {}
    -- Pets talent group is always 1 regardless of specId.
    specId = isPet and 1 or specId
    TalentFrame_UpdateSpecInfoCache(t, false, isPet, specId);
    ICT:printValues(t)
    return t.primaryTabIndex > 0 and t.primaryTabIndex or DEFAULT_TALENT_TAB
end

function Talents:viewSpec(specId, isPet, tab)
    return function()
        if not PlayerTalentFrame then
            TalentFrame_LoadUI()
        end
        specNames = specNames or { TALENT_SPEC_PRIMARY, TALENT_SPEC_SECONDARY, TALENT_SPEC_PET_PRIMARY, }
        if PlayerTalentFrameTitleText:GetText() == specNames[specId] and PlayerTalentFrame:IsShown() then
            HideUIPanel(PlayerTalentFrame)
            return
        end
        ShowUIPanel(PlayerTalentFrame)
        PlayerSpecTab_OnClick(_G["PlayerSpecTab" .. specId]);
        tab = tab or self:calculatePrimaryTab(specId, isPet or false)
        PlayerTalentTab_OnClick(_G["PlayerTalentFrameTab" .. tab]);
    end
end

function Talents:viewGlyphs(specId)
    TalentFrame_LoadUI()
    return self:viewSpec(specId, false, GLYPH_TALENT_TAB)
end