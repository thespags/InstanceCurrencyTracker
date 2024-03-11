local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
local Colors = ICT.Colors
local Expansion = ICT.Expansion
local log = ICT.log
local Tooltips = ICT.Tooltips
local TradeSkills = ICT.TradeSkills
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
        log.error("Unknown difficulty %s", difficulty or "")
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
    -- Filter by matches and expansions if there is more than one otherwise always show if only vanilla.
    return (not matches or matches[name]) and (ICT.db.options.professions["showExpansion" .. info.expansionId] or Expansion.isVanilla())
end

function ProfessionsTab:printProfession(player, profession, x, y)
    local options = ICT.db.options
    local skillLine = profession.skillLine
    local skills = player.skills[skillLine]
    local cell = self.cells(x, y)
    local sort = options.sort.orderByDifficulty and infoDifficultySort(player) or infoSort
    y = cell:printSectionTitleValue(profession.name, string.format("%s/%s", profession.rank, profession.max))

    self.cells:startSection(1)
    if self.cells:isSectionExpanded(profession.name) then
        if skills and ICT:size(skills) > 0 then
            local expansion, section
            for _, info in ICT:spairsByValue(LibTradeSkillRecipes:GetCategorySpells(skillLine), sort, infoFilter) do
                if Expansion.isVanilla() then
                    local skill = skills[info.spellId]
                    local color = skill and getDifficultyColor(skill.difficulty) or "FF787878"
                    if skill or options.professions.showUnknown then
                        cell = self.cells(x, y)
                        -- Vanilla doesn't have sharing spell links unless it's enchantment.
                        local link = info.itemId and ICT:getColoredItemLink(info.itemId, color)
                            or ICT:getColoredSpellLink(info.spellId, color)
                        y = cell:printLine(link)
                        local func = skill and player:isCurrentPlayer() and function() ICT:castTradeSkill(player, skillLine, GetSpellInfo(info.spellId)) end
                        cell:attachHyperLink(func)
                    end
                else
                    if expansion ~= info.expansionId then
                        y = expansion and self.cells:endSection(x, y + 1) or y
                        expansion = info.expansionId
                        section = skillLine .. ":" .. expansion
                        y = self.cells(x, y):printSectionTitle(ICT.Expansions[expansion], section)
                        self.cells:startSection(2)
                    end
                    if self.cells:isSectionExpanded(section) then
                        local skill = skills[info.spellId]
                        local color = skill and getDifficultyColor(skill.difficulty) or "FF787878"
                        if skill or options.professions.showUnknown then
                            cell = self.cells(x, y)
                            -- Vanilla doesn't have sharing spell links.
                            local link = Expansion.isVanilla() and info.itemId and ICT:getColoredItemLink(info.itemId, color)
                                or ICT:getColoredSpellLink(info.spellId, color)
                            y = cell:printLine(link)
                            local func = skill and player:isCurrentPlayer() and function() ICT:castTradeSkill(player, skillLine, GetSpellInfo(info.spellId)) end
                            cell:attachHyperLink(func)
                        end
                    end
                end
            end
            -- Close any remaining expansion.
            y = expansion and self.cells:endSection(x, y) or y
        else
            cell = self.cells(x, y)
            if player:isCurrentPlayer() then
                y = cell:printLine(L["OpenTradeSkills"], Colors.text)
                cell:attachClick(function() TradeSkills:openAndUpdate(player, skillLine) end)
            else
                y = cell:printLine(L["OpenTradeSkillsOther"], Colors.text)
            end
        end
    end
    return self.cells:endSection(x, y, y + 1)
end

function ProfessionsTab:printPlayer(player, x)
    local options = ICT.db.options.professions
    local y = 1
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
    Tooltips:info(editBox, L["Search Trade Skills"], L["SearchTradeSkillsTooltip"])
    :SetPoint("RIGHT", editBox, "LEFT", 0, 0)
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