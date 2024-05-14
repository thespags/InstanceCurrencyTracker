
local _, ICT = ...

local Currency = ICT.Currency

ICT.JusticePoints = Currency:new(395, 4000)
ICT.HonorPoints = Currency:new(1901, 4000)
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

local ordered = {
    ICT.JusticePoints,
    ICT.HonorPoints,
    ICT.DefilersScourgeStone,
    ICT.SiderealEssence,
    ICT.ChampionsSeal,
    ICT.Epicurean,
    ICT.JewelcraftersToken,
}
ICT.Currencies = {}

-- Defines the sorting order based on the order above, as well as removing any currencies not available yet.
for k, v in ipairs(ordered) do
    v.order = k
    if v:inExpansion() then
        table.insert(ICT.Currencies, v)
    end
end