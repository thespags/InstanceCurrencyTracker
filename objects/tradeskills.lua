local addOnName, ICT = ...

local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
local TradeSkills = {}
ICT.TradeSkills = TradeSkills


local function getSkillId(i)
    local spellLink = GetTradeSkillRecipeLink(i)
    local itemLink = GetTradeSkillItemLink(i)
    return spellLink and LibTradeSkillRecipes:GetInfoBySpellId(ICT:enchantLinkSplit(spellLink)[1])
    or itemLink and LibTradeSkillRecipes:GetInfoByItemId(ICT:itemLinkSplit(itemLink)[1])[1]
end

local function getCraftId(i)
    local id = select(7, GetSpellInfo(GetCraftInfo(i)))
    return LibTradeSkillRecipes:GetInfoBySpellId(id)
end

-- Opens the tradeskill window with a user click to then update skills.
function TradeSkills:openAndUpdate(player, skillLine)
    for _, p in pairs(player.professions or {}) do
        if p.skillLine == skillLine and p.spellId then
            CastSpellByID(p.spellId)
            TradeSkills.updateSkill(player)
            CloseTradeSkill()
            return
        end
    end
end

-- If a tradeskill window is open, then will update the skills.
function TradeSkills:update(player)
    player.skills = player.skills or {}
    local skills = GetNumTradeSkills()
    local getDifficulty, getTradeSkill
    if skills > 0 then
        getDifficulty = function(i) return select(2, GetTradeSkillInfo(i)) end
        getTradeSkill = getSkillId
    elseif GetNumCrafts then
        skills = GetNumCrafts()
        getDifficulty = function(i) return select(3, GetCraftInfo(i)) end
        getTradeSkill = getCraftId
    end
    for i=1,skills do
        local difficulty = getDifficulty(i)
        if difficulty == "header" then
        else
            local result = getTradeSkill(i)
            if result then
                local spellLink = GetSpellLink(result.spellId)
                local categoryId = result.categoryId
                player.skills[categoryId] = player.skills[categoryId] or {}
                player.skills[categoryId][result.spellId] = { link = spellLink, difficulty = difficulty }
            end
        end
    end
end