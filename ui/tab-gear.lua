local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Colors = ICT.Colors
local Player = ICT.Player
local Talents = ICT.Talents
local Tooltip = ICT.Tooltip
local Tooltips = ICT.Tooltips
local UI = ICT.UI

local GearTab = {
    paddings = {},
}
ICT.GearTab = GearTab

function GearTab:calculatePadding()
    local db = ICT.db
    self.paddings.pets = ICT:max(
        db.players,
        function(player) return ICT:sum(player:getPets(), function(v) return v:isVisible() and player:getSpec().pets[v:getName()] and 1 or 0 end) end,
        Player.isEnabled
    )
    self.paddings.items = ICT:max(db.players, function(player) return ICT:size(player:getSpec().items) end, Player.isEnabled)
    self.paddings.glyphs = ICT:max(db.players, function(player) return ICT:sum(player:getSpec().glyphs, function(v) return v.enabled and 1 or 0 end) end, Player.isEnabled)
    self.paddings.enchants = ICT:max(db.players, function(player) return ICT:sum(player:getSpec().items, function(v) return v.shouldEnchant and 1 or 0 end) end, Player.isEnabled)
    for i=1,2 do
        self.paddings[i] = {}
        self.paddings[i].pets = ICT:max(
            db.players,
            function(player) return ICT:sum(player:getPets(), function(v) return 
            v:isVisible() and player:getSpec(i).pets[v:getName()] and 1 or 0 end) end, Player.isEnabled
        )
        self.paddings[i].items = ICT:max(db.players, function(player) return ICT:size(player:getSpec(i).items) end, Player.isEnabled)
        self.paddings[i].glyphs = ICT:max(db.players, function(player) return ICT:sum(player:getSpec(i).glyphs, function(v) return v.enabled and 1 or 0 end) end, Player.isEnabled)
        self.paddings[i].enchants = ICT:max(db.players, function(player) return ICT:sum(player:getSpec(i).items, function(v) return v.shouldEnchant and 1 or 0 end) end, Player.isEnabled)
    end
end

function GearTab:getPadding(y, name, i)
    return y + (ICT.db.options.gear.showSpecs and self.paddings[i][name] or self.paddings[name])
end

function GearTab:printGlyph(spec, type, typeName, x, y)
    for index, glyph in ICT:fpairsByValue(spec.glyphs, function(v) return v.type == type and v.enabled end) do
        local name = ICT:getSpellLink(glyph.spellId)
        local nameWithIcon = name and string.format("%s|T%s:%s|t", name, glyph.icon, UI.iconSize) or L["Missing"]
        local cell = self.cells(x, y)
        y = cell:printValue(typeName .. " " .. index, nameWithIcon)
        cell:attachHyperLink()
    end
    return y
end

function GearTab:printGlyphs(player, spec, x, y)
    local cell = self.cells(x, y)
    y = cell:printSectionTitle(L["Glyphs"])
    if player:isCurrentPlayer() then
        cell:attachClick(Talents:viewGlyphs(spec.id))
        local tooltip = function(tooltip)
            tooltip:printTitle(L["Glyphs"])
            :printValue(L["Click"], L["Section"])
            :printValue(L["Shift Click"], L["Glyphs Shift Click"])
        end
        Tooltip:new(tooltip):attach(cell)
    end

    if self.cells:isSectionExpanded(L["Glyphs"]) then
        local padding = self:getPadding(y, "glyphs", spec.id)
        y = self:printGlyph(spec, 1, L["Major"], x, y)
        y = self:printGlyph(spec, 2, L["Minor"], x, y)
        y = self.cells:hideRows(x, y, padding)
    end
    return y
end

function GearTab:printSpec(player, x, y, spec)
    if (not ICT.db.options.gear.showSpecs and spec.id ~= player.activeSpec) or not Talents:isValidSpec(spec) then
        return y
    end
    -- If we only show one spec, then use a single key otherwise a key per spec id.
    local key = "Spec" .. (ICT.db.options.gear.showSpecs and spec.id or "")
    local icon = spec.icon and CreateSimpleTextureMarkup(spec.icon, UI.iconSize, UI.iconSize) or ""
    local sectionName = icon .. (spec.name or key)
    local cell = self.cells(x, y)
    local isActive = spec.id == player.activeSpec
    y = cell:printSectionTitle(sectionName, key, isActive and Colors.locked)

    if ICT.db.options.gear.showSpecs and player:isCurrentPlayer() then
        local tooltip = function(tooltip)
            tooltip:printTitle(L["Spec"])
            :printValue(L["Click"], L["Spec Click"])
            :printValue(L["Shift Click"], L["Spec Shift Click"])
        end
        Tooltip:new(tooltip):attach(cell)
        cell:attachClick(Talents:activateSpec(spec.id), Talents:viewSpec(spec.id))
    end
    if not self.cells:isSectionExpanded(key) then
        return self.cells(x, y):hide()
    end

    self.cells.indent = "  "

    local tooltip = Tooltips:specsSectionTooltip()
    cell = self.cells(x, y)
    y = cell:printValue(L["Talents"], string.format("%s/%s/%s", spec.tab1, spec.tab2, spec.tab3))
    tooltip:attach(cell)
    y = UI:printGearScore(self, spec, tooltip, x, y)

    -- For hunters, show pets.
    local padding = self:getPadding(y, "pets", spec.id)
    for _, pet in ICT:nspairsByValue(player:getPets(), ICT.Pet.isVisible) do
        if spec.pets and spec.pets[pet.name] then
            local specPet = spec.pets[pet.name]
            cell = self.cells(x, y)
            y = cell:printValue(string.format("|T%s:12:12|t%s", pet.icon, pet.name), string.format("%s|T%s:12:12|t", specPet.pointsSpent, specPet.talentIcon))
            if player:isCurrentPlayer() and pet.name == select(2, GetStablePetInfo(0)) then
                cell:attachClick(Talents:viewSpec(3, true))
            end
        end
    end
    y = self.cells:hideRows(x, y, padding)
    y = self.cells(x, y):hide()

    y = self:printGlyphs(player, spec, x, y)

    -- Requires spec activation so short circuit.
    if not spec.items then
        y = self.cells(x, y):printLine(L["ActivateSpecLoad"], Colors.text)
        return self.cells(x, y):hide()
    end

    y = self.cells:hideRows(x, y, padding)
    y = self.cells(x, y):hide()

    cell = self.cells(x, y)
    y = cell:printSectionTitle(L["Items"])

    if self.cells:isSectionExpanded(L["Items"]) then
        padding = self:getPadding(y, "items", spec.id)
        for k, item in pairs(spec.items or {}) do
            local text = ICT:addGems(k, item, true)
            cell = self.cells(x, y)
            y = cell:printValue(string.format("|T%s:14|t%s", item.icon, item.link), text)
            cell:attachHyperLink()
        end
        y = self.cells:hideRows(x, y, padding)
    end
    y = self.cells(x, y):hide()

    cell = self.cells(x, y)
    y = cell:printSectionTitle(L["Enchants"])
    if self.cells:isSectionExpanded(L["Enchants"]) then
        padding = self:getPadding(y, "enchants", spec.id)
        for _, item in ICT:fpairsByValue(spec.items, function(v) return v.shouldEnchant end) do
            local slot = ICT.ItemTypeToSlot[_G[select(9, GetItemInfo(item.link))]]
            local enchant = ICT:getEnchant(item.enchantId, slot) or L["Missing"]
            cell = self.cells(x, y)
            y = cell:printValue(_G[item.invType], enchant)
            cell:attachHyperLink()
        end
        y = self.cells:hideRows(x, y, padding)
    end
    y = self.cells(x, y):hide()
    self.cells.indent = ""
    return y
end

function GearTab:printPlayer(player, x)
    local y = 1
    y = self.cells(x, y):printPlayerTitle(player)
    if ICT.db.options.gear.showSpecs then
        for _, spec in pairs(player:getSpecs()) do
            y = self:printSpec(player, x, y, spec)
        end
    else
        local spec = player:getSpec()
        y = self:printSpec(player, x, y, spec)
    end
    return y
end

function GearTab:prePrint()
    self:calculatePadding()
end

function GearTab:show()
    self.frame:Show()
end

function GearTab:hide()
    self.frame:Hide()
end

function GearTab:showGearScores()
    return ICT.db.options.gear.showGearScores
end