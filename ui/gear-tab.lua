local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local Player = ICT.Player
local UI = ICT.UI

local GearTab = {
    paddings = {},
}
ICT.GearTab = GearTab

function GearTab:calculatePadding()
    local db = ICT.db
    self.paddings.pets = ICT:max(
        db.players,
        function(player) return ICT:sum(player:getPets(), function(v) return 
        v:isVisible() and player:getSpec().pets[v:getName()] and 1 or 0 end) end, Player.isEnabled
    )
    self.paddings.items = ICT:max(db.players, function(player) return ICT:size(player:getSpec().items or {}) end, Player.isEnabled)
    self.paddings.glyphs = ICT:max(db.players, function(player) return ICT:sum(player:getSpec().glyphs or {}, function(v) return v.enabled and 1 or 0 end) end, Player.isEnabled)
    self.paddings.enchants = ICT:max(db.players, function(player) return ICT:sum(player:getSpec().items or {}, function(v) return v.shouldEnchant and 1 or 0 end) end, Player.isEnabled)
    for i=1,2 do
        self.paddings[i] = {}
        self.paddings[i].pets = ICT:max(
            db.players,
            function(player) return ICT:sum(player:getPets(), function(v) return 
            v:isVisible() and player:getSpec(i).pets[v:getName()] and 1 or 0 end) end, Player.isEnabled
        )
        self.paddings[i].items = ICT:max(db.players, function(player) return ICT:size(player:getSpec(i).items or {}) end, Player.isEnabled)
        self.paddings[i].glyphs = ICT:max(db.players, function(player) return ICT:sum(player:getSpec(i).glyphs or {}, function(v) return v.enabled and 1 or 0 end) end, Player.isEnabled)
        self.paddings[i].enchants = ICT:max(db.players, function(player) return ICT:sum(player:getSpec(i).items or {}, function(v) return v.shouldEnchant and 1 or 0 end) end, Player.isEnabled)
    end
end

function GearTab:getPadding(offset, name, i)
    return offset + (ICT.db.options.gear.showSpecs and self.paddings[i][name] or self.paddings[name])
end

function GearTab:printGlyph(spec, type, typeName, x, offset)
    for index, glyph in ICT:fpairsByValue(spec.glyphs or {}, function(v) return v.type == type and v.enabled end) do
        local name = ICT:getSpellLink(glyph.spellId)
        local nameWithIcon = name and string.format("%s|T%s:14|t", name, glyph.icon) or L["Missing"]
        local cell = self.cells:get(x, offset)
        offset = cell:printValue(typeName .. " " .. index, nameWithIcon)
        cell:attachHyperLink()
    end
    return offset
end

function GearTab:printSpec(player, x, offset, spec)
    if not ICT.db.options.gear.showSpecs and spec.id ~= player.activeSpec then
        return offset
    end
    -- If we only show one spec, then use a single key otherwise a key per spec id.
    local key = "Spec" .. (ICT.db.options.gear.showSpecs and spec.id or "")
    local icon = spec.icon and CreateSimpleTextureMarkup(spec.icon, 14, 14) or ""
    local sectionName = icon .. (spec.name or key)
    local cell = self.cells:get(x, offset)
    local isActive = spec.id == player.activeSpec
    offset = cell:printSectionTitle(sectionName, key, isActive and ICT.lockedColor)

    if ICT.db.options.gear.showSpecs and player:isCurrentPlayer() then
        local f = function() SetActiveTalentGroup(spec.id) end
        local tooltip = ICT.Tooltips:new(L["Activate Spec"]):printPlain(L["Activate Spec Body"])
        cell:attachButton("ICTSetSpec", tooltip, f):SetEnabled(not isActive)
    end
    if not cell:isSectionExpanded(key) then
        return self.cells:get(x, offset):hide()
    end

    self.cells.indent = "  "

    local tooltip = UI:specsSectionTooltip()
    cell = self.cells:get(x, offset)
    offset = cell:printValue(L["Talents"], string.format("%s/%s/%s", spec.tab1, spec.tab2, spec.tab3))
    tooltip:attach(cell)
    offset = UI:printGearScore(self, spec, tooltip, x, offset)

    -- For hunters , how pets.
    local padding = self:getPadding(offset, "pets", spec.id)
    for _, pet in ICT:nspairsByValue(player:getPets(), ICT.Pet.isVisible) do
        if spec.pets and spec.pets[pet.name] then
            local specPet = spec.pets[pet.name]
            cell = self.cells:get(x, offset)
            offset = cell:printValue(string.format("|T%s:12:12|t%s", pet.icon, pet.name), string.format("%s|T%s:12:12|t", specPet.pointsSpent, specPet.talentIcon))
        end
    end

    -- Requires spec activation so short circuit.
    if not spec.items then
        offset = self.cells:get(x, offset):printLine(L["ActivateSpecLoad"], ICT.textColor)
        return self.cells:get(x, offset):hide()
    end

    offset = self.cells:hideRows(x, offset, padding)
    offset = self.cells:get(x, offset):hide()

    cell = self.cells:get(x, offset)
    offset = cell:printSectionTitle(L["Items"])

    if cell:isSectionExpanded(L["Items"]) then
        padding = self:getPadding(offset, "items", spec.id)
        for k, item in pairs(spec.items or {}) do
            local text = ICT:addGems(k, item, true)
            cell = self.cells:get(x, offset)
            offset = cell:printValue(string.format("|T%s:14|t%s", item.icon, item.link), text)
            cell:attachHyperLink()
        end
        offset = self.cells:hideRows(x, offset, padding)
    end
    offset = self.cells:get(x, offset):hide()

    cell = self.cells:get(x, offset)
    offset = cell:printSectionTitle(L["Glyphs"])
    if cell:isSectionExpanded(L["Glyphs"]) then
        local padding = self:getPadding(offset, "glyphs", spec.id)
        offset = self:printGlyph(spec, 1, L["Major"], x, offset)
        offset = self:printGlyph(spec, 2, L["Minor"], x, offset)
        offset = self.cells:hideRows(x, offset, padding)
    end
    offset = self.cells:get(x, offset):hide()

    cell = self.cells:get(x, offset)
    offset = cell:printSectionTitle(L["Enchants"])
    if cell:isSectionExpanded(L["Enchants"]) then
        padding = self:getPadding(offset, "enchants", spec.id)
        for _, item in ICT:fpairsByValue(spec.items or {}, function(v) return v.shouldEnchant end) do
            local slot = ICT.ItemTypeToSlot[_G[select(9, GetItemInfo(item.link))]]
            local enchant = ICT:getEnchant(item.enchantId, slot) or L["Missing"]
            cell = self.cells:get(x, offset)
            offset = cell:printValue(_G[item.invType], enchant)
            cell:attachHyperLink()
        end
        offset = self.cells:hideRows(x, offset, padding)
    end
    offset = self.cells:get(x, offset):hide()
    self.cells.indent = ""
    return offset
end

function GearTab:printPlayer(player, x)
    local offset = 1
    offset = self.cells:get(x, offset):printPlayerTitle(player)
    if ICT.db.options.gear.showSpecs then
        for _, spec in pairs(player:getSpecs()) do
            offset = self:printSpec(player, x, offset, spec)
        end
    else
        local spec = player:getSpec()
        offset = self:printSpec(player, x, offset, spec)
    end
    return offset
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