local VERSION = "3.2.18"

local config = {
    timeFormat = {
        ["labels"] = 1,
        ["colons"] = 2,
        ["hours"] = 3,
        ["hoursAndMinutes"] = 4,
        ["minutes"] = 5,
        ["percent"] = 6,
    },
    resetMode = {
        ["player"] = 2,
        ["realm"] = 3,
        ["all"] = 4,
    },
    colors = {
        {255, 0, 0},
        {255, 65, 0},
        {255, 96, 0},
        {255, 123, 0},
        {255, 147, 0},
        {255, 170, 0},
        {255, 192, 0},
        {255, 214, 0},
        {255, 235, 0},
        {255, 255, 0},
        {240, 255, 0},
        {223, 255, 0},
        {206, 255, 0},
        {187, 255, 0},
        {167, 255, 0},
        {144, 255, 0},
        {117, 255, 0},
        {83, 255, 0},
        {0, 255, 0},
        {0, 255, 0},
    },
    realmName = GetRealmName(),
    unitName = UnitName("player"),
    isHorde = UnitFactionGroup("player") == "Horde",
}

local transmuteId=54020


-- local Tracker = {
--     update_frequency = 1,
--     spells = {
--         [17187] = {label = "Transmute", icon = 134459},
--         [18560] = {label = "Mooncloth", icon = 132895},
--         [19566] = {label = "Salt Shaker", icon = 132836}
--     }
-- }

local Tracker = {
    update_frequency = 1,
    spells = {
        -- Start Vanilla
        -- Transmute
        [17564] = {label = "Transmute"},
        -- Salt Shaker
        [19566] = {},
        -- Mooncloth
        [18560] = {},
        -- End Vanilla/Start TBC
        -- Spellcloth
        [31373] = {},
        -- Shadowcloth
        [36686] = {},
        -- Primial Moonthcloth
        [26751] = {},
        -- Void Sphere
        [28028] = {},
        -- Brilliant Glass
        [47280] = {},
        -- End TBC/Start WOTLK
        -- Moonshroud
        [56001] = {},
        -- Ebonweave
        [56002] = {},
        -- Spellweave
        [56003] = {},
        -- Glacial Bag
        [56005] = {},
        -- Northrend Alchemy Research
        [60893] = {},
        -- Minor Inscription Research
        [61288] = {},
        -- Major Inscription Research
        [61177] = {},
        -- Icy Prism
        [62242] = {},
        -- Smelt Titanstell
        [55208] = {},
        -- Mysterious Egg
        [39878] = {duration = 590400},
    }
}

local Tracker = {
    -- spells = {
    --     -- TBC
    --     -- Void Sphere
    --     [28028] = { icon = 132886 },
    --     -- Brilliant Glass
    --     [47280] = { icon = 134096 },
    --     -- WOTLK
    --     -- Moonshroud
    --     [56001] = { icon = 237025 },
    --     -- Ebonweave
    --     [56002] = { icon = 237022 },
    --     -- Spellweave
    --     [56003] = {icon = 237026},
    --     -- Glacial Bag
    --     [56005] = {icon = 133666},
    --     -- Northrend Alchemy Research
    --     [60893] = {name = "Alchemy Research", icon = 136240},
    --     -- Minor Inscription Research
    --     [61288] = {name = "Minor Research", icon = 237083},
    --     -- Major Inscription Research
    --     [61177] = {name = "Major Research", icon = 237070},
    --     -- Icy Prism
    --     [62242] = {icon = 134095},
    --     -- Smelt Titanstell
    --     [55208] = {icon = 237046},
    -- },
    transmutes = {
        -- Transmute: Eternal Might
        [54020] = true,
        -- Transmute: Ametrine
        [66658] = true,
        -- Transmute: Cardinal Ruby
        [66659] = true,
        -- Transmute: King's Amber
        [66660] = true,
        -- Transmute: Dreadstone
        [66662] = true,
        -- Transmute: Eye of Zul
        [66664] = true,
        -- Transmute: Majestic Zircon
        [66663] = true,
        -- Transmute: Eternal Air to Earth
        [53777] = true,
        -- Transmute: Eternal Air to Water
        [53776] = true,
        -- Transmute: Eternal Earth to Air
        [53781] = true,
        -- Transmute: Eternal Earth to Shadow
        [53782] = true,
        -- Transmute: Eternal Fire to Life
        [53775] = true,
        -- Transmute: Eternal Fire to Water
        [53774] = true,
        -- Transmute: Eternal Life to Fire
        [53773] = true,
        -- Transmute: Eternal Life to Shadow
        [53771] = true,
        -- Transmute: Eternal Shadow to Earth
        [53779] = true,
        -- Transmute: Eternal Shadow to Life
        [53780] = true,
        -- Transmute: Eternal Water to Air
        [53783] = true,
        -- Transmute: Eternal Water to Fire
        [53784] = true,
    },
    items = {
        [39878] = {name = "Mysterious Egg", icon = 132833, duration = 590400},
    },
}

for k,_ in pairs(Tracker.spells) do
    local name,_,icon=GetSpellInfo(k)
    if Tracker.spells[k].name==nil then
        Tracker.spells[k].name=name
    end
    if Tracker.spells[k].icon==nil then
        Tracker.spells[k].icon=icon
    end
    Tracker.spells[k].duration=GetSpellBaseCooldown(k)/1000
end
for k,_ in pairs(Tracker.items) do
    if Tracker.items[k].icon==nil then
        Tracker.items[k].icon = select(5, GetItemInfoInstant(k))
    end
end

local zoneIds = {
    [126] = true,
    [1453] = true,
    [1454] = true,
    [1455] = true,
    [1456] = true,
    [1457] = true,
    [1458] = true,
    [1947] = true,
    [1954] = true,
    [1955] = true,
}
local subzoneIds = {
    [35] = true,
    [42] = true,
    [69] = true,
    [75] = true,
    [87] = true,
    [108] = true,
    [117] = true,
    [131] = true,
    [144] = true,
    [147] = true,
    [150] = true,
    [159] = true,
    [222] = true,
    [228] = true,
    [321] = true,
    [340] = true,
    [348] = true,
    [349] = true,
    [362] = true,
    [378] = true,
    [380] = true,
    [392] = true,
    [415] = true,
    [431] = true,
    [442] = true,
    [460] = true,
    [467] = true,
    [484] = true,
    [489] = true,
    [496] = true,
    [513] = true,
    [541] = true,
    [608] = true,
    [976] = true,
    [1099] = true,
    [1116] = true,
    [1438] = true,
    [2255] = true,
    [2368] = true,
    [2369] = true,
    [2408] = true,
    [3317] = true,
    [3425] = true,
    [3462] = true,
    [3488] = true,
    [3536] = true,
    [3538] = true,
    [3552] = true,
    [3554] = true,
    [3565] = true,
    [3576] = true,
    [3584] = true,
    [3613] = true,
    [3626] = true,
    [3644] = true,
    [3645] = true,
    [3665] = true,
    [3683] = true,
    [3684] = true,
    [3712] = true,
    [3738] = true,
    [3744] = true,
    [3745] = true,
    [3754] = true,
    [3769] = true,
    [3772] = true,
    [3828] = true,
    [3844] = true,
    [3918] = true,
    [3938] = true,
    [3951] = true,
    [3988] = true,
    [3991] = true,
    [3998] = true,
    [4000] = true,
    [4003] = true,
    [4018] = true,
    [4023] = true,
    [4032] = true,
    [4106] = true,
    [4108] = true,
    [4113] = true,
    [4122] = true,
    [4152] = true,
    [4158] = true,
    [4159] = true,
    [4161] = true,
    [4165] = true,
    [4177] = true,
    [4186] = true,
    [4204] = true,
    [4206] = true,
    [4211] = true,
    [4275] = true,
    [4284] = true,
    [4291] = true,
    [4312] = true,
    [4317] = true,
    [4323] = true,
    [4361] = true,
    [4379] = true,
    [4418] = true,
    [4422] = true,
    [4427] = true,
    [4428] = true,
    [4429] = true,
    [4441] = true,
    [4477] = true,
}

local zones = {}
for zoneId,_ in pairs(zoneIds) do
    zones[C_Map.GetMapInfo(zoneId).name] = true
end
local subzones = {}
for areaId,_ in pairs(subzoneIds) do
    subzones[C_Map.GetAreaInfo(areaId)] = true
end

function Tracker:Trigger(allStates)
    local cpuTime = self:GetTime64()
    if self.trigger_exp and cpuTime <= self.trigger_exp or self.leftWorld then
        return
    end
    self.trigger_exp = cpuTime + (aura_env.config.timerInterval == 1 and 1 or 60)
    
    if not self.initialized then return end
    self:Update()
    self:Display(allStates)
    return true
end

function Tracker:events(...)
    if self:newItem(...) then return true end
    if self:enterWorld(...) then return true end
    self:clicker(...)
    return false
end

function Tracker:enterWorld(e,login, reload)
    if e == "PLAYER_LEAVING_WORLD" then
        self.leftWorld = true
    elseif self.leftWorld and e == "PLAYER_ENTERING_WORLD" and not login and not reload then
        self.leftWorld = false
        self.trigger_exp = self:GetTime64() + 2
    else
        return false
    end
    return true
end

function Tracker:getVerTable(verString)
    local verTable={}
    local verIndex=1
    for k,_ in gmatch(verString,"%f[%d][%d]+%f[%D]") do
        verTable[verIndex]=k
        verIndex=verIndex+1
    end
    return unpack(verTable)
end

function Tracker:GetSavedData()
    local savedData = aura_env.saved.ProfessionCDTracker
    aura_env.saved.ProfessionCDTracker = savedData
    if not savedData.realms or aura_env.config.resetMode == config.resetMode.all then
        savedData.realms = {}
        savedData.disabledNames = {}
        print("Profession Cooldown Tracker - wiping realms and filters.")
    end
    return savedData
end

function Tracker:Migrate()
    if not aura_env.saved then
        aura_env.saved = {}
    end
    local savedData = aura_env.saved.ProfessionCDTracker or {}
    if savedData.version then
        local s1,s2 = self:getVerTable(savedData.version)
        local v1,v2 = self:getVerTable(VERSION)
        savedData.version = s1 == v1 and s2 == v2 and savedData.version
    end
    if not savedData.version then
        savedData = {}
        savedData.version = VERSION
        print("Profession Cooldown Tracker incompatible version detected - wiping saved cooldowns.")
    end
    if not savedData.disabledNames then savedData.disabledNames = {} end
    if savedData.lockProfessions == nil then savedData.lockProfessions = true end
    aura_env.saved.ProfessionCDTracker = savedData
    self.initialized = true
end

function Tracker:AreProfessionsLocked()
    local savedData = self:GetSavedData()
    return savedData.lockProfessions and not aura_env.config.showAllProfessions
end

function Tracker:Update()
    local savedData = self:GetSavedData()
    config.zoneCheck = self:DoZoneCheck()
    local realmData = self:UpdateRealmData(savedData)
    self:UpdatePlayerData(config.unitName, savedData, realmData)
end

function Tracker:DoZoneCheck()
    if not aura_env.config.zoneCheck then
        return true
    end
    if aura_env.config.taxiException and UnitOnTaxi("player") then
        return true
    end
    local zone = GetRealZoneText()
    local subzone = GetSubZoneText()
    return zones[zone] ~= nil
    or subzones[subzone] ~= nil
    or (zone ~= nil and (
            string.find(zone, "Tavern")
            or string.find(subzone, "Tavern")
            or string.find(zone, "Inn")
            or string.find(subzone, "Inn")))
end

function Tracker:UpdateRealmData(savedData)
    local realmData = savedData.realms[config.realmName]
    if not realmData or not realmData.characters or aura_env.config.resetMode == config.resetMode.realm then
        realmData = {characters = {}}
        savedData.realms[config.realmName] = realmData
    end
    return realmData
end

function Tracker:UpdatePlayerData(unitName, savedData, realmData)
    local playerData = realmData.characters[unitName]
    if not playerData or not playerData.cooldowns or aura_env.config.resetMode == config.resetMode.player then
        playerData = {cooldowns = {}, itemCooldowns = {}}
        print"Profession Cooldown Tracker - Wiping player data"
    end
    for spellId, _ in pairs(self.spells) do
        self:UpdateSpellData(spellId, playerData)
    end
    realmData.characters[unitName] = playerData
end

function Tracker:ConvertFrom32bitNegative(in32)
    return in32 >= 0x80000000 / 1e3 -- Is a 32bit negative value?
    and in32 - 0x100000000 / 1e3 -- covert to a negative
    or in32 -- if positive return original
end

function Tracker:GetTime64()
    return self:ConvertFrom32bitNegative(GetTime())
end

function Tracker:UpdateSpellData(inSpellId, playerData)
    local spellData = playerData.cooldowns[inSpellId] or {}
    local playerSpell=false
    local spellId
    if inSpellId==transmuteId then
        for kId, _ in pairs(self.transmutes) do
            spellId=kId
            playerSpell=IsPlayerSpell(spellId)
            if playerSpell then break end
        end
    else
        spellId=inSpellId
        playerSpell=IsPlayerSpell(spellId)
    end
    
    if playerSpell then
        local now = self:GetTime64()
        local serverNow = GetServerTime()
        local start, duration = GetSpellCooldown(spellId)
        if not start then
            return
        end
        -- Check duration to filter out spell lock, wands and other CD triggers
        if start ~= 0 and duration ~= self.spells[inSpellId].duration then return end
        -- since start is relative to computer uptime it can be a negative if the cooldown started before you restarted your pc.
        start = self:ConvertFrom32bitNegative(start)
        if start > now then -- start negative 32b overflow while now is still negative (over 24d 20h 31m PC uptime)
            start = start - 0x100000000 / 1e3 -- adjust relative to negative now
        end
        spellData.expiration = start - now + serverNow + duration
    else
        spellData = nil
    end
    playerData.cooldowns[inSpellId] = spellData
end

function Tracker:UpdateItemData(inItemId, timeStamp)
    local savedData = self:GetSavedData()
    local itemCooldowns = savedData.realms[config.realmName].characters[config.unitName].itemCooldowns
    local itemData = itemCooldowns[inItemId] or {}
    itemCooldowns[inItemId] = itemData
    
    itemData.expiration = timeStamp + self.items[inItemId].duration
end

function Tracker:PlayWork()
    if config.isHorde then
        PlaySound(6197, "Dialog", false)
    else
        PlaySound(6286, "Dialog", false)
    end
end

function Tracker:PlayDone()
    if config.isHorde then
        PlaySound(6192, "Dialog", false)
    else
        PlaySound(6290, "Dialog", false)
    end
end

local displayTypes = {
    "spells",
    "items",
}
function Tracker:Display(allStates)
    local savedData = self:GetSavedData()
    local hideUntilReady = aura_env.config.hideUntilReady
    local lockProfessions = self:AreProfessionsLocked()
    local maxExpiration = 1
    local isSpell
    local sec2Expire
    local CPUTime = self:GetTime64()
    local serverNow = GetServerTime()
    local serverToCPUDiff = CPUTime - serverNow
    for realmName, realmData in pairs(savedData.realms) do
        for charName, charData in pairs(realmData.characters) do
            for displayType, _ in pairs(displayTypes) do
                isSpell = displayType == 1
                local cooldowns = isSpell and charData.cooldowns or charData.itemCooldowns
                for id, data in pairs(cooldowns) do
                    local info = isSpell and self.spells[id] or self.items[id]
                    if info then
                        local fullName = self:FormatName(realmName, charName, info.name)
                        if not savedData.disabledNames[fullName] then
                            savedData.disabledNames[fullName] = {
                                state = false,
                                clicked = false,
                            }
                        end
                        local ready = data.expiration + serverToCPUDiff <= CPUTime
                        if data.ready ~= nil and data.ready ~= ready and aura_env.config.soundNotifications then
                            if ready then
                                self.PlayDone()
                            else
                                self.PlayWork()
                            end
                        end
                        data.ready = ready
                        data.show = not (savedData.disabledNames[fullName].state and lockProfessions)
                        and config.zoneCheck
                        and (not hideUntilReady or ready)
                        sec2Expire = data.expiration - serverNow
                        if sec2Expire > maxExpiration and data.show then
                            maxExpiration = sec2Expire
                        end
                    else
                        cooldowns[id] = nil
                    end
                end
            end
        end
    end
    local progressType = aura_env.config.progressType == 1 and "timed" or "static"
    for realmName, realmData in pairs(savedData.realms) do
        for charName, charData in pairs(realmData.characters) do
            for displayType, _ in pairs(displayTypes) do
                isSpell = displayType == 1
                local cooldowns = isSpell and charData.cooldowns or charData.itemCooldowns
                for id, data in pairs(cooldowns) do
                    local localExpiration = data.expiration + serverToCPUDiff
                    local info = isSpell and self.spells[id] or self.items[id]
                    local fullName, name = self:FormatName(realmName, charName, info.name)
                    local remainingTime = localExpiration - CPUTime
                    local actualRemaining = remainingTime
                    local totalBarTime = aura_env.config.progressType == 1 and info.duration or maxExpiration
                    if remainingTime <= 0 then
                        remainingTime = 0
                        if localExpiration <=0 then
                            localExpiration = 1
                        end
                    end
                    aura_env.dprint(format("Name:%s, Remains:%d, Duration:%d",fullName,remainingTime,info.duration))
                    allStates[fullName] = {
                        index = fullName,
                        changed = true,
                        show = data.show,
                        name = name,
                        icon = info.icon,
                        
                        progressType = progressType,
                        duration = info.duration,
                        expirationTime = localExpiration,
                        value = remainingTime,
                        total = maxExpiration,
                        tooltip = "Click to Show or Hide cooldown",
                        
                        totalBarTime = totalBarTime,
                        actualRemaining = actualRemaining
                    }
                end
            end
        end
    end
end

local newItems = {bags = {}}
function Tracker:newItem(e,arg1)
    if e == "BAG_NEW_ITEMS_UPDATED" then
        newItems.timestamp = GetServerTime()
    elseif e == "BAG_UPDATE" and arg1 and arg1 >= 0 then
        newItems.looting = true
        newItems.bags[arg1] = true
    elseif e == "BAG_UPDATE_DELAYED" and newItems.looting then
        if newItems.timestamp then
            for itemId, _ in pairs(self.items) do
                if self:itemFound(itemId, newItems.bags) then
                    self:UpdateItemData(itemId, newItems.timestamp)
                end
            end
            newItems.timestamp = false
        end
        newItems = {bags = {}}
        newItems.looting = false
    else
        return false
    end
    return true
end

function Tracker:itemFound(itemId,bags)
    local itemCount = GetItemCount(itemId)
    if itemCount and itemCount > 0 then
        for bag, _ in pairs(bags) do
            for slot=C_Container.GetContainerNumSlots(bag),1,-1 do
                if C_Container.GetContainerItemID(bag,slot) == itemId and C_NewItems.IsNewItem(bag, slot) then
                    C_NewItems.RemoveNewItem(bag, slot)
                    return true
                end
            end
        end
    end
    return false
end

function Tracker:color(value, total)
    value = value>=0 and value or 0
    local progress = floor(20.5-value/total*19)
    --if progress > 20 or progress < 1 then print(progress,value,total) end
    local color = config.colors[progress]
    local r = color[1]/255
    local g = color[2]/255
    local b = color[3]/255
    return r,g,b,1
end

function Tracker:clicker(event,button)
    if (event == "GLOBAL_MOUSE_DOWN" or event == "GLOBAL_MOUSE_UP") then
        local keyCheck = IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown()
        if keyCheck or not self:AreProfessionsLocked() then
            local savedData = self:GetSavedData()
            for name, disabledName in pairs(savedData.disabledNames) do
                local region = WeakAuras.GetRegion(aura_env.id,name)
                if region then
                    local clicked = region:IsMouseOver() and event == "GLOBAL_MOUSE_DOWN" and button == "LeftButton"
                    if keyCheck then
                        if clicked and not aura_env.config.showAllProfessions then
                            savedData.lockProfessions = not savedData.lockProfessions
                        end
                    else
                        local cloneState = disabledName
                        if clicked ~= cloneState.clicked and not self:AreProfessionsLocked() then
                            cloneState.state = clicked ~= cloneState.state
                            cloneState.clicked = clicked
                            local alpha = disabledName.state and 0.4 or 1
                            region:SetAlpha(alpha)
                        end
                    end
                end
            end
        end
    end
end

aura_env.config.cooldownColor[4] = 1
aura_env.config.readyColor[4] = 1
function Tracker:GetDurationString()
    
    if not aura_env.state.totalBarTime then return end
    local savedData = self:GetSavedData()
    local disabledName = savedData.disabledNames[aura_env.state.index]
    local alpha = disabledName.state and 0.4 or 1
    aura_env.region:SetAlpha(alpha)
    
    local ret = "ready"
    local expiration = aura_env.state.expirationTime
    local value = aura_env.state.value
    local now = self:GetTime64()
    if value > 0 then
        if aura_env.config.monoCooldownBar then
            aura_env.region:Color(unpack(aura_env.config.cooldownColor))
        else
            aura_env.region:Color(self:color(value, aura_env.state.totalBarTime))
        end
        local ds = math.floor(expiration - now)
        local d = math.floor(ds / 86400)
        ds = ds % 86400
        local h = math.floor(ds / 3600)
        ds = ds % 3600
        local m = math.floor(ds / 60)
        ds = ds % 60
        local s = math.floor(ds)
        ret = self:FormatTime(d, h, m, s, aura_env.state.duration, math.floor(expiration - now))
    else
        aura_env.region:Color(unpack(aura_env.config.readyColor))
    end
    return ret
end

function Tracker:FormatName(realm, character, spell)
    local fRealm = format("[%s] ", realm)
    local fName = format("%s: %s",character,spell)
    local fullName = fRealm .. fName
    return fullName, aura_env.config.showRealm and fullName or fName
end

function Tracker:FormatTime(d, h, m, s, duration, timeLeft)
    local timeFormat = aura_env.config.timeFormat
    local timeFormatPrecision = aura_env.config.timeFormatPrecision
    local tf = config.timeFormat
    
    if timeFormat == tf.labels or timeFormat == tf.colons then
        local out = {}
        local delimeter = timeFormat == tf.labels and " " or ":"
        local suffix = function(label)
            return timeFormat == tf.labels and label or ""
        end
        local makeformat = function()
            return #out < 1 and "%s%s" or "%02s%s"
        end
        if d ~= 0 then
            out[#out + 1] = string.format(makeformat(), d, suffix("d"))
        end
        if #out ~= 0 or h ~= 0 then
            out[#out + 1] = string.format(makeformat(), h, suffix("h"))
        end
        if #out ~= 0 or m ~= 0 then
            out[#out + 1] = string.format(makeformat(), m, suffix("m"))
        end
        if aura_env.config.timerInterval == 1 and (#out ~= 0 or s ~= 0) then
            out[#out + 1] = string.format(makeformat(), s, suffix("s"))
        end
        local res = table.concat(out, delimeter)
        if aura_env.config.expiryTimeFormat >= 2 then
            local sourceTime
            local seconds = 0
            if aura_env.config.expiryTimeFormat == 3 then
                local osTime = time()
                seconds = osTime % 60
                osTime = osTime - seconds
                sourceTime = C_DateAndTime.GetCalendarTimeFromEpoch(1e6*osTime)
            else
                sourceTime = C_DateAndTime.GetCurrentCalendarTime()
            end
            local targetTime = C_DateAndTime.AdjustTimeByMinutes(sourceTime, floor((timeLeft + s+seconds) / 60))
            res = res..format(" (%02d:%02d)",targetTime.hour, targetTime.minute)
        end
        return res
    elseif timeFormat == tf.hours then
        local hours = d * 24 + h + m / 60 + s / 3600
        return string.format("%." .. timeFormatPrecision .. "fh", hours)
    elseif timeFormat == tf.hoursAndMinutes then
        local hours = d * 24 + h
        local minutes = m + s / 60
        return string.format("%.0fh %." .. timeFormatPrecision .. "fm", hours, minutes)
    elseif timeFormat == tf.minutes then
        local minutes = d * 24 * 60 + h * 60 + m + s / 60
        return string.format("%." .. timeFormatPrecision .. "fm", minutes)
    elseif timeFormat == tf.percent then
        local total = d * 86400 + h * 3600 + s
        local pct = total / duration * 100
        return string.format("%." .. timeFormatPrecision .. "f%%", pct)
    end
end

aura_env.dprint = function(...)
    if not aura_env.config.verbose then
        return
    end
    print(...)
end

aura_env.Tracker = Tracker
Tracker:Migrate()

