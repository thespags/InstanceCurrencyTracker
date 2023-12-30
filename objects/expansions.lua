local addOnName, ICT = ...

local log = ICT.log

ICT.WOTLK = 2
ICT.TBC = 1
ICT.Vanilla = 0
ICT.Expansions = {
    [ICT.WOTLK] = "Wrath of the Lich King",
    [ICT.TBC] = "The Burning Crusade",
    [ICT.Vanilla] = "Vanilla"
}
ICT.Expansion = LE_EXPANSION_LEVEL_CURRENT
ICT.MaxLevel = 80
if ICT.Vanilla == ICT.Expansion then
    ICT.MaxLevel = 25
elseif ICT.TBC == ICT.Expansion then
    ICT.MaxLevel = 70
elseif ICT.WOTLK == ICT.Expansion then
    ICT.MaxLevel = 80
else
    log.error("Expansion not configured for level cap %s", ICT.Expansion)
end
