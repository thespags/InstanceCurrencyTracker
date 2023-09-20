local addOnName, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Colors = ICT.Colors
local Tooltips = ICT.Tooltips
local UI = ICT.UI

function UI:countdown(expires, duration, startColor, endColor)
    if expires then
        local timeLeft = math.max(expires - GetServerTime(), 0)
        startColor = startColor or Colors.green
        endColor = endColor or Colors.red
        local color = duration and duration > 0 and Colors:gradient(startColor, endColor, timeLeft / duration) or endColor
        return timeLeft == 0 and "Ready" or ICT:DisplayTime(timeLeft), color
    end
    return "N/A"
end

function UI:hideTickers()
    for _, v in pairs(self.tickers) do
        v.ticker:Cancel()
        if v.frame then v.frame:Hide() end
    end
end

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

function UI:specsSectionTooltip()
    return Tooltips:new(L["Specs"])
    :printPlain("Displays specs, glyphs. If TacoTip is available, displays gearscore and iLvl as well.")
    :printPlain("\nNote: Gearscore and iLvl are the last equipped gear for a specific spec.")
    :printPlain("i.e. change spec before changing gear to have the most accurate data.")
    :create("ICTSpecsSectionTooltip")
end
