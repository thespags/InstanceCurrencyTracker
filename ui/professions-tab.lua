local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
local Colors = ICT.Colors
local Player = ICT.Player
local UI = ICT.UI

local ProfessionsTab = {
}
ICT.ProfessionsTab = ProfessionsTab

local getDifficultyColor = function(difficulty)
    if difficulty == "difficult" then
        return "FFFF0000"
    elseif difficulty == "optimal" then
        return "FFEE783C"
    elseif difficulty == "medium" then
        return "FFEEEE00"
    elseif difficulty == "easy" then
        return "FF3CB33C"
    elseif difficulty ==  "trivial" then
        return "FFFFFFFF"
    else
        ICT:print("Unknown difficulty %s", difficulty or "")
        return "FFFFFFFF"
    end
end

local getDifficultyValue = function(difficulty)
    if  difficulty == "difficult" then
        return 5
    elseif difficulty == "optimal" then
        return 4
    elseif difficulty == "medium" then
        return 3
    elseif difficulty == "easy" then
        return 2
    elseif difficulty ==  "trivial" then
        return 1
    else
        return 0
    end
end

local infoSort = function(left, right)
    if left.expansionId == right.expansionId then

        return GetSpellInfo(left.spellId) < GetSpellInfo(right.spellId)
    end
    return left.expansionId > right.expansionId
end

local infoDifficultySort = function(player)
    return function(left, right)
        if left.expansionId == right.expansionId then
            local leftSkill = player.skills[left.categoryId][left.spellId]
            local rightSkill = player.skills[right.categoryId][right.spellId]
            local leftDifficulty = leftSkill and getDifficultyValue(leftSkill.difficulty) or -1
            local rightDifficulty = rightSkill and getDifficultyValue(rightSkill.difficulty) or -1
            if leftDifficulty == rightDifficulty then
                return GetSpellInfo(left.spellId) < GetSpellInfo(right.spellId)
            end
            return leftDifficulty > rightDifficulty
        end
        return left.expansionId > right.expansionId
    end
end

local infoFilter = function(v)
    return ICT.db.options.professions["showExpansion" .. v.expansionId]
end

function ProfessionsTab:printProfession(player, profession, x, offset)
    local options = ICT.db.options.professions
    local skillLine = profession.skillLine
    local skills = player.skills[skillLine]
    local cell = self.cells:get(x, offset)
    local sort = options.difficultySort and infoDifficultySort(player) or infoSort
    offset = cell:printSectionTitleValue(profession.name, string.format("%s/%s", profession.rank, profession.max))

    if cell:isSectionExpanded(profession.name) then
        if skills and ICT:size(skills) > 0 then
            self.cells.indent = "  "
            local expansion, section
            for _, info in ICT:spairsByValue(LibTradeSkillRecipes:GetCategorySpells(skillLine), sort, infoFilter) do
                if expansion ~= info.expansionId then
                    offset = expansion and self.cells:get(x, offset):hide() or offset
                    expansion = info.expansionId
                    section = skillLine .. ":" .. expansion
                    offset = self.cells:get(x, offset):printSectionTitle(ICT.Expansions[expansion], section)
                end
                cell = self.cells:get(x, offset)
                if cell:isSectionExpanded(section) then
                    local skill = skills[info.spellId]
                    local color = skill and getDifficultyColor(skill.difficulty) or "FF787878"
                    if skill or options.showUnknown then
                        offset = cell:printLine(ICT:getColoredSpellLink(info.spellId, color))
                        local func = skill and player:isCurrentPlayer() and function() ICT:castTradeSkill(player, skillLine, GetSpellInfo(info.spellId)) end
                        cell:attachHyperLink(func)
                    end
                end
            end
            self.cells.indent = ""
        else
            cell = self.cells:get(x, offset)
            offset = cell:printLine(L["OpenTradeSkills"], ICT.textColor)
            if player:isCurrentPlayer() then
                cell:attachClick(function() self:updateSkills(player, skillLine) end)
                cell.frame:SetHighlightTexture("auctionhouse-nav-button-highlight")
            end
        end
    end
    return self.cells:get(x, offset):hide()
end

function ProfessionsTab:updateSkills(player, skillLine)
    player.skills = player.skills or {}
    for _, p in pairs(player.professions or {}) do
        if p.skillLine == skillLine and p.spellId then
            print(p.name .. " " .. p.spellId .. " " .. GetNumTradeSkills())
            CastSpellByID(p.spellId)
            for i=1,GetNumTradeSkills() do
                local name, difficulty = GetTradeSkillInfo(i)
                print(name)
                if name and difficulty ~= "header" then
                    local spellLink = GetTradeSkillRecipeLink(i)
                    local id = tonumber(ICT:enchantLinkSplit(spellLink)[1])
                    if id then
                        local categoryId = LibTradeSkillRecipes:GetInfoBySpellId(id).categoryId
                        player.skills[categoryId] = player.skills[categoryId] or {}
                        player.skills[categoryId][id] = { link = spellLink, difficulty = difficulty }
                    end
                end
            end
            CloseTradeSkill()
            return
        end
    end
end

function ProfessionsTab:printPlayer(player, x)
    local options = ICT.db.options.professions
    local offset = 1
    offset = self.cells:get(x, offset):printPlayerTitle(player)
    player.skills = player.skills or {}

    for _, profession in pairs(player.professions or {}) do
        local skillLine = profession.skillLine
        if LibTradeSkillRecipes:GetSkillLines()[skillLine].hasRecipes and options["showProfession" .. skillLine] then
            offset = self:printProfession(player, profession, x, offset)
        end
    end
    return offset
end

function ProfessionsTab:prePrint()
end

function ProfessionsTab:show()
    self.frame:Show()
end

function ProfessionsTab:hide()
    self.frame:Hide()
end
