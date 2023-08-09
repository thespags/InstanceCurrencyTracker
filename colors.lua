local addOn, ICT = ...

function ICT:hex2rgbInteger(hex)
    return tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6)), tonumber("0x" .. hex:sub(7,8))
end

function ICT:hex2rgbPercentage(hex)
    local r, g, b = self:hex2rgbInteger(hex)
    return r / 255, g / 255, b / 255
end

function ICT:rgbInteger2hex(r, g, b)
    return string.format("FF%02X%02X%02X", r, g, b)
end

function ICT:rgbPercentage2hex(r, g, b)
    return self:rgbInteger2hex(r * 255, g * 255, b * 255)
end

local function inverseSrgbCompanding(color)
    local r, g, b = ICT:hex2rgbPercentage(color)

    -- Inverse Red, Green, and Blue
    r = r > 0.0405 and (((r + 0.055) / 1.055) ^ 2.4) or (r / 12.92)
    g = g > 0.0405 and (((g + 0.055) / 1.055) ^ 2.4) or (g / 12.92)
    b = b > 0.0405 and (((b + 0.055) / 1.055) ^ 2.4) or (b / 12.92)

    return r, g, b
end

local function srgbCompanding(r, g, b)
    -- Apply companding to Red, Green, and Blue
    r = r > 0.0031308 and (1.055 * r ^ (1 / 2.4) - 0.055) or (r * 12.92)
    g = g > 0.0031308 and (1.055 * g ^ (1 / 2.4) - 0.055) or (g * 12.92)
    b = b > 0.0031308 and (1.055 * b ^ (1 / 2.4) - 0.055) or (b * 12.92)

    return ICT:rgbPercentage2hex(r, g, b)
end

function ICT:gradient(color1, color2, mix)
   local r1, g1, b1 = inverseSrgbCompanding(color1)
   local r2, g2, b2 = inverseSrgbCompanding(color2)

   local r3 = r1 * mix + r2 * (1 - mix);
   local g3 = g1 * mix + g2 * (1 - mix);
   local b3 = b1 * mix + b2 * (1 - mix);

   return srgbCompanding(r3, g3, b3)
end

function ICT:naiveGradient(color1, color2, value) 
    local r1, g1, b1 = ICT:hex2rgbInteger(color1)
    local r2, g2, b2 = ICT:hex2rgbInteger(color2)
    local r3 = r2 + (r1 - r2) * value
    local g3 = g2 + (g1 - g2) * value
    local b3 = b2 + (b1 - b2) * value
    return ICT:rgbInteger2hex(r3, g3, b3)
end