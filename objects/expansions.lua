local addOnName, ICT = ...

ICT.WOTLK = 2
ICT.TBC = 1
ICT.VANILLA = 0
ICT.Expansions = {
    [ICT.WOTLK] = "Wrath of the Lich King",
    [ICT.TBC] = "The Burning Crusade",
    [ICT.VANILLA] = "Vanilla"
}
ICT.Expansion = LE_EXPANSION_LEVEL_CURRENT
ICT.MaxLevel = 80
if ICT.VANILLA == ICT.Expansion then
    ICT.MaxLevel = 25
elseif ICT.TBC == ICT.Expansion then
    ICT.MaxLevel = 70
elseif ICT.TBC == ICT.WOTLK then
    ICT.MaxLevel = 80
else
    ICT.log.error("Expansion not configured for level cap %s", ICT.Expansion)
end
