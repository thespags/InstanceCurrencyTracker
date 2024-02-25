local _, ICT = ...

local UI = ICT.UI
local Cells = {}
setmetatable(Cells, Cells)
ICT.Cells = Cells

function Cells:new(frame, font, width, height)
    local t = { indent = "", cells = {}, frame = frame, font = font, width = width, height = height}
    setmetatable(t, self)
    self.__index = self
    return t
end

function Cells:hide()
    for _, cell in pairs(self.cells) do
        cell.frame:Hide()
        _ = cell.ticker and cell.ticker:Cancel()
    end
end

function Cells:hideRows(x, startY, endY)
    for j=startY,endY do
        self(x, j):hide()
    end
    return startY < endY and endY or startY
end

function Cells:startSection(depth)
    self.indent = string.rep("  ", depth)
end

function Cells:endSection(x, startY, endY)
    self.indent = string.sub(self.indent, 1, -3)
    return self:hideRows(x, startY, endY or startY)
end

function Cells:cellWidth()
    return rawget(self, "width") or UI:getCellWidth()
end

function Cells:cellHeight()
    return rawget(self, "height") or UI:getCellHeight()
end

function Cells:fontSize()
    return rawget(self, "font") or UI:getFontSize()
end

function Cells:isSectionExpanded(key)
    key = self.frame:GetName() .. key
    return not ICT.db.options.collapsible[key]
end

-- Gets the associated cell or create it if it doesn't exist yet.
function Cells:__call(x, y)
    local name = string.format("ICTCell(%s, %s)", x, y)
    local cell = self.cells[name]

    if not cell then
        cell = ICT.Cell(self, x, y)
        cell.frame = CreateFrame("Button", name, self.frame, "InsecureActionButtonTemplate")
        cell.buttons = {}
        self.cells[name] = cell

        -- Create the string if necessary.
        cell.left = cell.frame:CreateFontString()
        cell.left:SetJustifyH("LEFT")
        cell.right = cell.frame:CreateFontString()
        cell.right:SetPoint("RIGHT", 4, 0)
        cell.right:SetJustifyH("RIGHT")

        cell.frame:RegisterForClicks("AnyUp")
        cell.frame:HookScript("OnClick",
            function()
                if cell.hookOnShiftClick and IsShiftKeyDown() then
                    cell.hookOnShiftClick()
                elseif cell.hookOnClick then
                    cell.hookOnClick()
                end
            end
        )
    end
    -- Reset the position if a section title.
    cell.left:SetPoint("LEFT")
    -- I'm setting the table to the metatable, there's probably a better practice.
    -- Instead, I have to use rawget to avoid a loop.
    local width = self:cellWidth()
    local height = self:cellHeight()
    local font = self:fontSize()
    cell.frame:SetSize(width, height)
    cell.frame:SetPoint("TOPLEFT", 2 + (x - 1) * width, -2 - (y - 1) * height)
    cell.left:SetFont(UI.font, font)
    cell.right:SetFont(UI.font, font)

    _ = cell.ticker and cell.ticker:Cancel()
    -- Remove any cell action so we can reuse the cell.
    for _, button in pairs(cell.buttons) do
        button:Hide()
    end
    cell.hookOnClick = nil
    cell.hookOnShiftClick = nil
    cell.frame:SetScript("OnEnter", nil)
    cell.frame:SetScript("OnLeave", nil)
    cell.frame:SetAttribute("type", nil)
    cell.frame:SetAttribute("item", nil)
    cell.frame:ClearHighlightTexture()
    cell.frame:ClearNormalTexture()
    cell.frame:ClearPushedTexture()
    cell.frame:ClearDisabledTexture()
    return cell
end

-- Gets the cell without reseting the information. Must exist.
function Cells:get(x, y)
    local name = string.format("ICTCell(%s, %s)", x, y)
    return self.cells[name]
end