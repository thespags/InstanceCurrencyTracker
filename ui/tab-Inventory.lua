local _, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local log = ICT.log
local InventoryTab = {}
ICT.InventoryTab = InventoryTab

local function getBaganatorData(player)
    if BAGANATOR_SUMMARIES and BAGANATOR_SUMMARIES.Characters and BAGANATOR_SUMMARIES.Characters.ByRealm then
        return BAGANATOR_SUMMARIES.Characters.ByRealm[player.realm][player.name]
    end
    log.warning("Bagnator API has changed. ICT needs to update.")
    return nil
end

local function transform(id, amounts)
    local name, link, quality, level, _, _, _, _, _, _, _, type = GetItemInfo(id)
    return {
        name = name,
        link = link,
        quality = quality,
        level = level,
        type = type,
        amounts = amounts
    }
end

local function filter(id)
    return function(item)
        return item.type == id
    end
end

local function sort(a, b)
    if a.type and b.type and a.type ~= b.type then
        return a.type < b.type
    else
        return a.name < b.name
    end
end

function InventoryTab:printPlayer(player, x)
    local y = 1
    player.skills = player.skills or {}

    local data = getBaganatorData(player) or {}
    local items = {}
    local types = {}
    for id, v in pairs(data) do
        local baganatorPrefix = string.sub(id, 1, 2)
        if baganatorPrefix == "i:" then
            id = string.sub(id, 3)
        elseif baganatorPrefix == "g:" then
            id = string.match(id, "g:item:(%w+):")
        else
            log.error("unknown baganatorPrefix: %s", id)
        end
        local item = transform(id, v)
        items[id] = item
        types[item.type or -1] = true
    end

    for i = 0,Enum.ItemClassMeta.NumValues-1 do
        local type = GetItemClassInfo(i)
        if type and types[i] then
            local cell = self.cells(x, y)
            y = cell:printSectionTitle(type)
            if self.cells:isSectionExpanded(type) then
                for _, item in ICT:spairsByValue(items, sort, filter(i)) do
                    cell = self.cells(x, y)
                    local total = item.amounts.bags + item.amounts.bank + item.amounts.equipped + item.amounts.mail
                    y = cell:printValue(item.link, total > 1 and total or "")
                    if item.amounts.equipped > 0 then
                        cell.frame:SetNormalTexture("groupfinder-highlightbar-green")
                    end
                    cell:attachHyperLink()
                end
            end
            y = self.cells(x, y):hide()
        end
    end


    -- add sorts, by name, by quality, by amount
    -- fix no bag found in my own stuff.

    return y
end

function InventoryTab:show()
    self.frame:Show()
end

function InventoryTab:hide()
    self.frame:Hide()
end
