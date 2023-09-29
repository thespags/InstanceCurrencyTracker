local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local UI = ICT.UI

function UI:printGearScore(tab, spec, tooltip, x, offset)
    if TT_GS and tab:showGearScores() then
        local scoreColor = spec.gearScore and Colors:rgbPercentage2hex(TT_GS:GetQuality(spec.gearScore)) or nil
        local cell = tab.cells:get(x, offset)
        offset = cell:printValue(L["GearScore"], spec.gearScore, nil, scoreColor)
        tooltip:attach(cell)
        cell = tab.cells:get(x, offset)
        offset = cell:printValue(L["iLvl"], spec.ilvlScore, nil, scoreColor)
        tooltip:attach(cell)
    end
    return offset
end