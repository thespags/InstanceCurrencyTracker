local _, ICT = ...

local BAR = LibStub("XLibSimpleBar-1.0")
local UI = ICT.UI
local ReputationTab = {}
ICT.ReputationTab = ReputationTab

function ReputationTab:printReputation(x, y, faction, depth)
    local name = faction.factionId and GetFactionInfoByID(faction.factionId) or BINDING_HEADER_OTHER
    if faction.isHeader and y > 2 then
        y = self.cells(x, y):hide()
    end
    local cell = self.cells(x, y)
    y = faction.isHeader and cell:printSectionTitle(name) or cell:printLine(name)
    if faction.hasRep then
        local color = FACTION_BAR_COLORS[faction.standingId]
        cell.bar = cell.bar or BAR:NewSimpleBar()
        local cap = faction.max - faction.min
        local value = faction.value - faction.min
        cell.bar:Create(cell.frame, value, cap, UI:getCellWidth() / 2, UI:getCellHeight() * .9)
        cell.bar:SetPoint("TOPRIGHT", cell.frame, "TOPRIGHT")
        cell.bar:SetColor(color.r, color.g, color.b)
        cell.bar.fontString = cell.bar.fontString or cell.bar:CreateFontString()
        cell.bar.fontString:SetPoint("CENTER")
        cell.bar.fontString:SetFont(UI.font, UI:getFontSize() * .9)
        cell.bar.fontString:SetJustifyH("CENTER")
        cell.bar.fontString:SetText(string.format("%s / %s", value, cap))
        cell.bar:Show()
    end
    if faction.isHeader then
        if self.cells:isSectionExpanded(name) then
            self.cells:startSection(depth)
            for _, v in pairs(faction.children or {}) do
                y = ReputationTab:printReputation(x, y, v, depth + 1)
            end
            y = self.cells:endSection(x, y)
        end
    end
    return y
end

function ReputationTab:printPlayer(player, x)
    local y = 1
    for _, v in pairs(player.reputationHeaders or {}) do
        y = self:printReputation(x, y, v, 1)
    end
    return y
end

function ReputationTab:show()
    self.frame:Show()
end

function ReputationTab:hide()
    self.frame:Hide()
end
