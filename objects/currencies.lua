
local _, ICT = ...

local Currency = ICT.Currency

ICT.ValorPoints = Currency:new(396)
ICT.JusticePoints = Currency:new(395, 4000)
ICT.HonorPoints = Currency:new(1901, 4000)
ICT.CataJewelcraftersToken = Currency:new(361)
ICT.ChefsAward = Currency:new(402)
ICT.DarkmoonPrizeTicket = Currency:new(515)
ICT.Frost = Currency:new(341)
ICT.DefilersScourgeStone = Currency:new(2711)
ICT.Triumph = Currency:new(301)
ICT.SiderealEssence = Currency:new(2589)
ICT.ChampionsSeal = Currency:new(241)
ICT.Conquest = Currency:new(221)
ICT.Valor = Currency:new(102)
ICT.Heroism = Currency:new(101)
ICT.Epicurean = Currency:new(81)
ICT.WotlkJewelcraftersToken = Currency:new(61)
ICT.StoneKeepersShard = Currency:new(161)
ICT.ObsidianFragment = Currency:new(3281, 160)
ICT.FissureStoneFragment = Currency:new(3148, 160)
ICT.MoteofDarkness = Currency:new(614)
ICT.EssenceofCorruptedDeathwing = Currency:new(615)


local ordered = {
    ICT.ValorPoints,
    ICT.JusticePoints,    
    ICT.ObsidianFragment,
    ICT.FissureStoneFragment,
    ICT.EssenceofCorruptedDeathwing,
    ICT.MoteofDarkness,
    ICT.HonorPoints,
    ICT.CataJewelcraftersToken,
    ICT.ChefsAward,
    ICT.DarkmoonPrizeTicket,
    ICT.DefilersScourgeStone,
    ICT.SiderealEssence,
    ICT.ChampionsSeal,
    ICT.Epicurean,
    ICT.WotlkJewelcraftersToken,
}
ICT.Currencies = {}

-- Defines the sorting order based on the order above, as well as removing any currencies not available yet.
for k, v in ipairs(ordered) do
    v.order = k
    if v:inExpansion() then
        table.insert(ICT.Currencies, v)
    end
end
