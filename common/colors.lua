local addOn, ICT = ...

local Colors = {}
Colors.green = "FF00FF00"
Colors.red = "FFFF0000"
Colors.tooltipTitle = Colors.green
Colors.available = "FFFFFFFF"
Colors.queuedAvailable = "FF90C0FF"
Colors.section = "FFFFFF00"
Colors.subtitle = "FFFFCC00"
Colors.text = "FF9CD6DE"
Colors.locked = "FFFF00FF"
Colors.queuedLocked = "FFFFC0FF"
Colors.unavailable = Colors.red
ICT.Colors = Colors

function Colors:getQuestColor(player, quest)
    return (not player:isQuestAvailable(quest) and Colors.unavailable) or (player:isQuestCompleted(quest) and Colors.locked or Colors.available)
end

function Colors:getSelectedColor(selected)
    return selected and Colors.locked or Colors.available
end

function Colors:getSelectedQueueColor(selected)
    return selected and Colors.queuedLocked or Colors.queuedAvailable
end

function Colors:hex2rgbInteger(hex)
    return tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6)), tonumber("0x" .. hex:sub(7,8))
end

function Colors:hex2rgbPercentage(hex)
    local r, g, b = self:hex2rgbInteger(hex)
    return r / 255, g / 255, b / 255
end

function Colors:rgbInteger2hex(r, g, b)
    return string.format("FF%02X%02X%02X", r, g, b)
end

function Colors:rgbPercentage2hex(r, g, b)
    return self:rgbInteger2hex(r * 255, g * 255, b * 255)
end

local function flipInteger(r)
    if r < 128 then
        return r * 2
    elseif r > 128 then
        return math.ceil(r / 2)
    else
        return 255
    end
end

function Colors:flipHex(hex)
    local r, g, b = self:hex2rgbInteger(hex)
    return self:rgbInteger2hex(flipInteger(r), flipInteger(g), flipInteger(b))
end

function Colors:getItemScoreHex(itemLink)
    if TT_GS then
        local _, _, r, g, b = TT_GS:GetItemScore(itemLink)
        return self:rgbPercentage2hex(r, g, b)
    end
    return nil
end

function Colors:inverseSrgbCompanding(color)
    local r, g, b = self:hex2rgbPercentage(color)

    -- Inverse Red, Green, and Blue
    r = r > 0.0405 and (((r + 0.055) / 1.055) ^ 2.4) or (r / 12.92)
    g = g > 0.0405 and (((g + 0.055) / 1.055) ^ 2.4) or (g / 12.92)
    b = b > 0.0405 and (((b + 0.055) / 1.055) ^ 2.4) or (b / 12.92)

    return r, g, b
end

function Colors:srgbCompanding(r, g, b)
    -- Apply companding to Red, Green, and Blue
    r = r > 0.0031308 and (1.055 * r ^ (1 / 2.4) - 0.055) or (r * 12.92)
    g = g > 0.0031308 and (1.055 * g ^ (1 / 2.4) - 0.055) or (g * 12.92)
    b = b > 0.0031308 and (1.055 * b ^ (1 / 2.4) - 0.055) or (b * 12.92)

    return self:rgbPercentage2hex(r, g, b)
end

function Colors:gradient(color1, color2, mix)
   local r1, g1, b1 = self:inverseSrgbCompanding(color1)
   local r2, g2, b2 = self:inverseSrgbCompanding(color2)

   local r3 = r1 * mix + r2 * (1 - mix)
   local g3 = g1 * mix + g2 * (1 - mix)
   local b3 = b1 * mix + b2 * (1 - mix)

   return self:srgbCompanding(r3, g3, b3)
end

function Colors:naiveGradient(color1, color2, value) 
    local r1, g1, b1 = self:hex2rgbInteger(color1)
    local r2, g2, b2 = self:hex2rgbInteger(color2)
    local r3 = r2 + (r1 - r2) * value
    local g3 = g2 + (g1 - g2) * value
    local b3 = b2 + (b1 - b2) * value
    return self:rgbInteger2hex(r3, g3, b3)
end