
local addOnName, ICT = ...

local Currency = ICT.Currency

ICT.Triumph = Currency:new(301)
ICT.SiderealEssence = Currency:new(2589)
ICT.ChampionsSeal = Currency:new(241)
ICT.Conquest = Currency:new(221)
ICT.Valor = Currency:new(102)
ICT.Heroism = Currency:new(101)
ICT.Epicurean = Currency:new(81)
ICT.JewelcraftersToken = Currency:new(61)
ICT.StoneKeepersShards = Currency:new(161)
ICT.WintergraspMark = Currency:new(126)
-- Phase 3 dungeons grant conquest.
ICT.DungeonEmblem = ICT.Conquest

ICT.Currencies = {
    ICT.Triumph,
    ICT.SiderealEssence,
    ICT.ChampionsSeal,
    ICT.Conquest,
    ICT.Valor,
    ICT.Heroism,
    ICT.Epicurean,
    ICT.JewelcraftersToken,
    ICT.StoneKeepersShard,
    ICT.WintergraspMark,
}

for k, v in ipairs(ICT.Currencies) do
    v.order = k
end