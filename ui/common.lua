local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local UI = ICT.UI

function UI:printGearScore(tab, spec, tooltip, x, y)
    if TT_GS and tab:showGearScores() then
        local scoreColor = spec.gearScore and Colors:rgbPercentage2hex(TT_GS:GetQuality(spec.gearScore)) or nil
        local cell = tab.cells(x, y)
        y = cell:printValue(L["GearScore"], spec.gearScore, nil, scoreColor)
        tooltip:attach(cell)
        cell = tab.cells(x, y)
        y = cell:printValue(L["iLvl"], spec.ilvlScore, nil, scoreColor)
        tooltip:attach(cell)
    end
    return y
end