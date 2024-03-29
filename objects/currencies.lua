
local _, ICT = ...

local Currency = ICT.Currency

ICT.Frost = Currency:new(341)
ICT.DefilersScourgeStone = Currency:new(2711)
ICT.Triumph = Currency:new(301)
ICT.SiderealEssence = Currency:new(2589)
ICT.ChampionsSeal = Currency:new(241)
ICT.Conquest = Currency:new(221)
ICT.Valor = Currency:new(102)
ICT.Heroism = Currency:new(101)
ICT.Epicurean = Currency:new(81)
ICT.JewelcraftersToken = Currency:new(61)
ICT.StoneKeepersShard = Currency:new(161)
ICT.HonorPoints = Currency:new(1901)
-- Phase 3 dungeons grant conquest.
ICT.DungeonEmblem = ICT.Triumph

ICT.Currencies = {
    ICT.Frost,
    ICT.DefilersScourgeStone,
    ICT.Triumph,
    ICT.SiderealEssence,
    ICT.ChampionsSeal,
    ICT.Conquest,
    ICT.Valor,
    ICT.Heroism,
    ICT.Epicurean,
    ICT.JewelcraftersToken,
    ICT.StoneKeepersShard,
    ICT.HonorPoints,
}

-- Defines the sorting order based on the order above, as well as removing any currencies not available yet.
for k, v in ipairs(ICT.Currencies) do
    v.order = k
    if not v:inExpansion() then
       ICT.Currencies[k] = nil
    end
end