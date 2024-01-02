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

Expansion = {}
ICT.Expansion = Expansion

Expansion.value = LE_EXPANSION_LEVEL_CURRENT

function Expansion.isVanilla()
    return ICT.Vanilla == Expansion.value
end

function Expansion.isWOTLK()
    return ICT.WOTLK == Expansion.value
end

-- Whether or not the value was released, e.g. false if value is Vanilla and current is WOTLK.
function Expansion.active(value)
    return value <= Expansion.value
end

-- Whether the value is for the current expansion.
function Expansion.current(value)
    return value == Expansion.value
end

if Expansion.isVanilla() then
    Expansion.MaxLevel = 25
elseif ICT.TBC == Expansion.value then
    Expansion.MaxLevel = 70
elseif Expansion.isWOTLK() then
    Expansion.MaxLevel = 80
else
    Expansion.MaxLevel = 80
    log.error("Expansion not configured for level cap %s", Expansion.value)
end
