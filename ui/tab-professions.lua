local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
local Colors = ICT.Colors
local UI = ICT.UI
local ProfessionsTab = {
}
ICT.ProfessionsTab = ProfessionsTab

-- Load all the recipe names to be searched through.
local matches = nil
local haystacks = {}
C_Timer.After(5, function()
    for _, infos in pairs(LibTradeSkillRecipes:GetCategories()) do
        for _, info in pairs(infos) do
            local name = select(1, GetSpellInfo(info.spellId))
            tinsert(haystacks, name)
        end
    end
end)

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

local infoFilter = function(info)
    local name = GetSpellInfo(info.spellId)
    return (not matches or matches[name]) and ICT.db.options.professions["showExpansion" .. info.expansionId]
end

function ProfessionsTab:printProfession(player, profession, x, y)
    local options = ICT.db.options.professions
    local skillLine = profession.skillLine
    local skills = player.skills[skillLine]
    local cell = self.cells(x, y)
    local sort = options.sortByDifficulty and infoDifficultySort(player) or infoSort
    y = cell:printSectionTitleValue(profession.name, string.format("%s/%s", profession.rank, profession.max))

    if cell:isSectionExpanded(profession.name) then
        if skills and ICT:size(skills) > 0 then
            self.cells.indent = "  "
            local expansion, section
            for _, info in ICT:spairsByValue(LibTradeSkillRecipes:GetCategorySpells(skillLine), sort, infoFilter) do
                if expansion ~= info.expansionId then
                    y = expansion and self.cells(x, y):hide() or y
                    expansion = info.expansionId
                    section = skillLine .. ":" .. expansion
                    y = self.cells(x, y):printSectionTitle(ICT.Expansions[expansion], section)
                end
                cell = self.cells(x, y)
                if cell:isSectionExpanded(section) then
                    local skill = skills[info.spellId]
                    local color = skill and getDifficultyColor(skill.difficulty) or "FF787878"
                    if skill or options.showUnknown then
                        y = cell:printLine(ICT:getColoredSpellLink(info.spellId, color))
                        local func = skill and player:isCurrentPlayer() and function() ICT:castTradeSkill(player, skillLine, GetSpellInfo(info.spellId)) end
                        cell:attachHyperLink(func)
                    end
                end
            end
            self.cells.indent = ""
        else
            cell = self.cells(x, y)
            y = cell:printLine(L["OpenTradeSkills"], Colors.text)
            if player:isCurrentPlayer() then
                cell:attachClick(function() self:updateSkills(player, skillLine) end)
            end
        end
    end
    return self.cells(x, y):hide()
end

function ProfessionsTab:updateSkills(player, skillLine)
    player.skills = player.skills or {}
    for _, p in pairs(player.professions or {}) do
        if p.skillLine == skillLine and p.spellId then
            CastSpellByID(p.spellId)
            for i=1,GetNumTradeSkills() do
                local name, difficulty = GetTradeSkillInfo(i)
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
    local y = 1
    y = self.cells(x, y):printPlayerTitle(player)
    player.skills = player.skills or {}

    for _, profession in pairs(player.professions or {}) do
        local skillLine = profession.skillLine
        if LibTradeSkillRecipes:GetSkillLines()[skillLine].hasRecipes and options["showProfession" .. skillLine] then
            y = self:printProfession(player, profession, x, y)
        end
    end
    return y
end

function ProfessionsTab:init()
    local editBox = UI:createEditBox(ICT.frame)
    self.editBox = editBox
    editBox:SetPoint("TOP", ICT.frame, "TOP", 0, -30)
    editBox:SetFont(UI.font, 14, "")
    editBox:SetSize(140, 24)
    editBox:SetAlpha(1)
    editBox:SetIgnoreParentAlpha(true)
    editBox:SetScript("OnTextChanged", function(self)
        local length = string.len(self:GetText())
        if length > 0 then
            matches = {}
            -- If the length is 1, relax the score.
            local score = length > 1 and 1 or 0
            for _, match in pairs(ICT.fzy.filter(self:GetText(), haystacks)) do
                if match[3] > score then
                    matches[haystacks[match[1]]] = true
                end
            end
        else
            matches = nil
        end
        UI:PrintPlayers()
    end)
    local clearEditBox = CreateFrame("Button", nil, ICT.frame, "UIPanelButtonTemplate")
    self.clearEditBox = clearEditBox
    clearEditBox:SetPoint("LEFT", editBox, "RIGHT", 5, 0)
    clearEditBox:SetSize(24, 24)
    clearEditBox:SetAlpha(1)
    clearEditBox:SetIgnoreParentAlpha(true)
    clearEditBox:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearEditBox:SetScript("OnClick", function()
        editBox:SetText("")
    end)
end

function ProfessionsTab:show()
    self.editBox:Show()
    self.frame:Show()
    self.clearEditBox:Show()
end

function ProfessionsTab:hide()
    self.editBox:Hide()
    self.frame:Hide()
    self.clearEditBox:Hide()
end