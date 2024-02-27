local _, ICT = ...

local LibInstances = LibStub("LibInstances")
local Colors = ICT.Colors
local UI = ICT.UI
local LFD = {}
ICT.LFD = LFD
LFGEnabledList = LFGEnabledList or {}

-- Required frame things to work...
-- LFDQueueFrame, LFDQueueFrame_Join, LFDQueueFrame_SetType, LFDQueueFrameRandom_UpdateFrame, LFDQueueFrameSpecificList_Update
-- LFGDungeonList_EvaluateListState, 

local sortActivityIds = function(a, b)
    -- Activity Ids are annoyingly not ordered by difficulty...
    a = a == 174 and 178 or a
    a = a == 175 and 177 or a
    b = b == 174 and 178 or b
    b = b == 175 and 177 or b
    return a >= b
end

local firstId = function(instance)
    local text
    for _, v in ICT:spairs(instance:activityIds(), sortActivityIds) do
        text = LFGConstructDeclinedMessage(v)
        if text == "" then
            return v, nil
        end
    end
    return nil, text
end

function LFD:anySelected(instance)
    return ICT:containsAnyValue(instance:activityIds(), function(v) return LFGEnabledList[v] end)
end

-- First available id in the instance if available.
function LFD:selectInstance(parent, instance)
    return function()
        if self:anySelected(instance) then
            for _, v in ICT:spairs(instance:activityIds(), sortActivityIds) do
                self:selectSpecific(parent, instance, v, false)()
            end
        else
            local v, text = firstId(instance)
            if v then
                self:selectSpecific(parent, instance, v, true)()
            elseif text then
                ICT:print(YOU_MAY_NOT_QUEUE_FOR_THIS .. text)
            end
        end
        -- Close the frame so our next call reopens it.
        UI.DropdownFrame:Hide()
        LFD:specificDropdown(parent, instance)()
    end
end

local hasSetup = false
function LFD:selectSpecific(parent, instance, v, value)
    return function()
        if not hasSetup then
            LFDQueueFrameSpecificList_Update()
            hasSetup = true
        end
        if value ~= nil then
            LFGEnabledList[v] = value
        else
            LFGEnabledList[v] = not LFGEnabledList[v]
        end
        SetLFGDungeonEnabled(v, LFGEnabledList[v])
        LFDQueueFrameSpecificList_Update()
        parent:printLFDInstance(instance)
    end
end

function LFD:specificDropdown(parent, instance)
    local f = function(frame)
        local _, queued = LFGDungeonList_EvaluateListState(LE_LFG_CATEGORY_LFD)
        local i = 0

        for k, v in ICT:spairs(instance:activityIds(), sortActivityIds) do
            i = i + 1
            local cell = frame.cells(1, i)
            local name = LibInstances:getGroupName(k)
            local text = LFGConstructDeclinedMessage(v)
            local button = cell:attachCheckButton("ICT" .. v, text ~= "")
            if text == "" then
                button:SetChecked(LFGEnabledList[v] or false)
                button:SetEnabled(not queued)
                button:SetScript("OnClick", self:selectSpecific(parent, instance, v))
            else
                cell:lockCheckButton(button)
                ICT.Tooltips:new(YOU_MAY_NOT_QUEUE_FOR_THIS, text):attach(cell)
            end
            -- Offsets the name for the button.
            cell:printLine("      " .. name, Colors.text)
        end
        return i
    end
    return UI:cellDropdown(parent, f)
end

function LFD:queue(parent)
    return function()
        if not hasSetup then
            LFDQueueFrameSpecificList_Update()
            hasSetup = true
        end

        local _, queued = LFGDungeonList_EvaluateListState(LE_LFG_CATEGORY_LFD)
        if queued then
            LeaveLFG(LE_LFG_CATEGORY_LFD)
        else
            LFDQueueFrame_Join()
        end
        C_Timer.After(1, function() 
            parent:printLFDType(LFDQueueFrame.type)
            UI.DropdownFrame:Hide()
            self:randomDropdown(parent)()
        end)
    end
end

function LFD:selectRandom(parent, id, name)
    return function()
        LFDQueueFrame_SetType(id)
        LFDQueueFrameRandom_UpdateFrame()
        parent:printLFDType(id, name)
        -- Close the frame so our next call reopens it.
        UI.DropdownFrame:Hide()
        self:randomDropdown(parent)()
    end
end

function LFD:randomDropdown(parent)
    local f = function(frame)
        local index = 0
        index = index + 1
        local cell = frame.cells(1, index)
        cell:printLFDType("specific", SPECIFIC_DUNGEONS)
        cell:attachClick(self:selectRandom(parent, "specific", SPECIFIC_DUNGEONS))

        for i=1, GetNumRandomDungeons() do
            local id, name = GetLFGRandomDungeonInfo(i)
            local isAvailableForAll, isAvailableForPlayer, hideIfNotJoinable = IsLFGDungeonJoinable(id)
            if isAvailableForPlayer or not hideIfNotJoinable then
                index = index + 1
                cell = frame.cells(1, index)
                if isAvailableForAll then
                    cell:attachClick(self:selectRandom(parent, id, name))
                end
                cell:printLFDType(id, name)
            end
        end
        return index
    end
    return UI:cellDropdown(parent, f)
end

function LFD:getName(expectedId)
    for i=1, GetNumRandomDungeons() do
        local id, name = GetLFGRandomDungeonInfo(i)
        local isAvailableForAll, isAvailableForPlayer, hideIfNotJoinable = IsLFGDungeonJoinable(id)
        if isAvailableForPlayer or not hideIfNotJoinable then
            if isAvailableForAll and expectedId == id then
                return name
            end
        end
    end
    return ""
end