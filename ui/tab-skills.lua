local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local BAR = LibStub("XLibSimpleBar-1.0")
local UI = ICT.UI
local SkillsTab = {}
ICT.SkillsTab = SkillsTab

function SkillsTab:printRunes(player, x, y)
    local classRunes = ICT.db.runes[player.class]
    local lastCategory
    y = self.cells(x, y):printSectionTitleValue(L["Runes"])
    self.cells:startSection(1)
    if self.cells:isSectionExpanded(L["Runes"]) then
        for id, rune in ICT:spairsByValue(classRunes or {}, function(l, r) return l.category < r.category end) do
            if lastCategory ~= rune.category then
                y = lastCategory and self.cells:endSection(x, y + 1) or y
                lastCategory = rune.category
                y = self.cells(x, y):printSectionTitle(ICT.SlotToItemType[rune.category], rune.category)
                self.cells:startSection(2)
            end
            if self.cells:isSectionExpanded(rune.category) then
                local cell = self.cells(x, y)
                y = cell:printValue(string.format("|T%s:12w|t%s", rune.icon, rune.name))
                if not (player.knownRunes or {})[id] then
                    cell.frame:SetAlpha(.5)
                end
            end
        end
        y = self.cells:endSection(x, y, self.padding)
    end
    return self.cells:endSection(x, y, y + 1)
end

function SkillsTab:printWeaponSkills(player, x, y)
    y = self.cells(x, y):printSectionTitleValue(L["Weapon Skills"])
    self.cells:startSection(1)
    if self.cells:isSectionExpanded(L["Weapon Skills"]) then
        for _, weaponSkill in ipairs(player.weaponSkills or {}) do
            local cell = self.cells(x, y)
            y = cell:printLine(weaponSkill.name)
            cell.bar = cell.bar or BAR:NewSimpleBar()
            cell.bar:Create(cell.frame, weaponSkill.rank, weaponSkill.max, UI:getCellWidth() / 2, UI:getCellHeight() * .9)
            cell.bar:SetPoint("TOPRIGHT", cell.frame, "TOPRIGHT")
            cell.bar:SetColor(0, 0, 1)
            cell.bar.fontString = cell.bar.fontString or cell.bar:CreateFontString()
            cell.bar.fontString:SetPoint("CENTER")
            cell.bar.fontString:SetFont(UI.font, UI:getFontSize() * .9)
            cell.bar.fontString:SetJustifyH("CENTER")
            cell.bar.fontString:SetText(string.format("%s / %s", weaponSkill.rank, weaponSkill.max))
            cell.bar:Show()
        end
    end
    return self.cells:endSection(x, y, y + 1)
end

function SkillsTab:printPlayer(player, x)
    local y = 1
    y = Expansion.isVanilla() and self:printRunes(player, x, y) or y
    y = self:printWeaponSkills(player, x, y)
    return y
end

function SkillsTab:show()
    self.frame:Show()
end

function SkillsTab:hide()
    self.frame:Hide()
end

function SkillsTab:prePrint()
    _ = Expansion.isVanilla() and self:calculatePadding()
end

function SkillsTab:calculatePadding()
    local classes = {}
    local max = {}

    for _, player in pairs(ICT.db.players) do
        if not classes[player.class] then
            classes[player.class] = true
            local values = {}
            for _, rune in pairs(ICT.db.runes[player.class] or {}) do
                if self.cells:isSectionExpanded(rune.category) then
                    -- Base is at least section title plus space plus one more.
                    values[rune.category] = (values[rune.category] or 2) + 1
                else
                    -- Section title plus space.
                    values[rune.category] = 2
                end
            end
            for category, value in pairs(values) do
                if not max[category] or max[category] < value then
                    max[category] = value
                end
            end
        end
    end
    -- Sum all the totals plus two more for section title.
    self.padding = ICT:sum(max) + 1
end