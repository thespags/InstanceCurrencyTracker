local addOnName, ICT = ...

ICT.Instances = {}
local Instances = ICT.Instances

function Instances:new(instance, id, size)
    instance = instance or {}
    setmetatable(instance, self)
    self.__index = self
    instance.id = id
    instance.size = size
    local info = Instances.Expansions[id]
    instance.expansion = size == info.legacySize and info.legacy or info.expansion
    instance.legacy = size == info.legacySize and info.legacy or nil
    instance:localizeName()
    instance:resetIfNecessary()
    instance.encounterSize = #instance:encounters()
    return instance
end

function Instances:key(v, size)
    return string.format("%s (%s)", v, size)
end

function Instances:getName()
    return self.name
end

function Instances:localizeName()
    local name = GetRealZoneText(self.id)
    local sizes = ICT:size(Instances.Resets[self.id])
    self.name = sizes > 1 and self:key(name, self.size) or name
end

-- Lock the specified instance with the provided information.
function Instances:lock(reset, encounterProgress, i)
    self.locked = true
    self.reset = reset + GetServerTime()
    self.encounterProgress = encounterProgress
    self.instanceIndex = i
    self.encounterKilled = {}
    for k, _ in pairs(Instances.Encounters[self.id].names) do
        self.encounterKilled[k] = select(3, GetSavedInstanceEncounterInfo(self.instanceIndex, k))
    end
end

-- Reset if the reset timer has elapsed or no reset
function Instances:resetIfNecessary(timestamp)
    if not self.reset or (timestamp and self.reset < timestamp) then
        self.locked = false
        self.reset = nil
        self.encounterProgress = 0
        self.encounterKilled = {}
        self.instanceIndex = 0
        self.available = {}
    end
end

function Instances:resetInterval()
    return Instances.Resets[self.id][self.size]
end

function Instances:activityId(difficulty)
    -- Use the provided difficulty or default to the highest. 
    difficulty = difficulty or self:isDungeon() and #ICT.DifficultyInfo or #ICT.RaidDifficulty
    -- Finds the type of activity, beta rune or raid 10 id, for an instance.
    local activityId = Instances.ActivityIdLookups[self.expansion][self.size][difficulty]
    -- Now find the instances specific id for that type.
    return Instances.Activities[self.id][activityId]
end

-- Is any difficulty of this instance queued?
function Instances:queued()
    local info = C_LFGList.GetActiveEntryInfo()
    local queuedIds = info and info.activityIDs or {}
    return #queuedIds > 0 and ICT:containsAnyValue(self:difficulties(), function(v) return tContains(queuedIds, self:activityId(v.id)) end)
end

function Instances:difficulties()
    return self:isDungeon() and ICT.DifficultyInfo or ICT.RaidDifficulty
end

function Instances:enqueue(queuedIds, shouldMessage)
    local queueCategory = queuedIds[1] and C_LFGList.GetActivityInfoTable(queuedIds[1]).categoryID
    local instanceCategory = C_LFGList.GetActivityInfoTable(self:activityId()).categoryID

    if queueCategory and queueCategory ~= instanceCategory then
        ICT:oprint("Ignoring %s, as Blizzard doesn't let you queue raids and dungeons together.", "lfg", self:getName())
        return
    end

    for _, difficulty in pairs(self:difficulties()) do
        local activityId = self:activityId(difficulty.id)
        local remove = tContains(queuedIds, activityId)
        local ignore = not difficulty:isVisible()
        local f = (remove or ignore) and tDeleteItem or table.insert
        -- Don't initiate a search if we weren't already searching. This seems to work but sometimes doesn't and I'm not sure why yet.
        if ICT.searching then
            LFGBrowseActivityDropDown_ValueSetSelected(LFGBrowseFrame.ActivityDropDown, activityId, not (remove or ignore));
        end
        f(queuedIds, activityId)
        -- Response back to the user to see what was queued/dequeued.
        if shouldMessage and not ignore then
            local message = remove and "Dequeuing %s" or "Enqueuing %s"
            local name = self:getName() .. (self:isDungeon() and ", " .. difficulty:getName() or "")
            ICT:oprint(message, "lfg", name)
        end
    end
end

function Instances:numOfEncounters()
    return self.encounterSize
end

function Instances:encounters()
    return Instances.Encounters[self.id].names or {}
end

function Instances:encountersLeft()
    return self:numOfEncounters() - self.encounterProgress
end

function Instances:isEncounterKilled(index)
    return self.encounterKilled and self.encounterKilled[index] or false
end

function Instances:hasCurrency(currency)
    local info = self.currency[self.id]
    return info and info.currencies[currency] or false
end

function Instances:currencies()
    local info = self.currency[self.id]
    return info and info.currencies or {}
end

function Instances:availableCurrency(currency)
    local info = self.currency[self.id]
    return info and info.availableCurrency(self, currency) or 0
end

function Instances:maxCurrency(currency)
    local info = self.currency[self.id]
    return info and info.maxCurrency(self, currency) or 0
end

function Instances:fromExpansion(expansion)
    -- Legacy case handles instances that are reused, presuming they aren't reused multiple times...
    return self.expansion == expansion or self.legacy == expansion
end

-- Is this instance a raid and if provided, a raid from the expansion?
function Instances:isRaid(expansion)
    return self.size > 5 and (not expansion or self:fromExpansion(expansion))
end

-- Is this instance a dungeon and if provided, a dungeon from the expansion?
function Instances:isDungeon(expansion)
    return self.size == 5 and (not expansion or self:fromExpansion(expansion))
end

function Instances:isVisible()
    return ICT.db.options.displayInstances[self.expansion][self.id]
end

function Instances:setVisible(v)
    ICT.db.options.displayInstances[self.expansion][self.id] = v
end

-- This comparison groups instances with the same name together across multiple sizes.
-- This is intended for sorting with respect to dungeons and raids separately.
function Instances:__lt(other)
    if ICT.db.options.frame.orderLockLast then
        if self.locked and not other.locked then
            return false
        end
        if not self.locked and other.locked then
            return true
        end
    end

    -- Later expansions appear earlier in our lists...
    if self.expansion == other.expansion or self.legacy == other.expansion or self.expansion == other.legacy then
        if self.name == other.name then
            return self.size < other.size
        end
        return self.name < other.name
    end
    return self.expansion > other.expansion
end

local function compare(a, b, aSize, bSize)
    aSize = aSize or a.size
    bSize = bSize or b.size

    if aSize == bSize then
        return a.name < b.name
    end
    return aSize < bSize
end

-- This comparison sorts by size before name.
-- This is intended for sorting with dungeons and raids togther.ß
function ICT.InstanceOptionSort(a, b)
    -- Later expansions appear earlier in our lists...
    if a.expansion == b.expansion then
        return compare(a, b)
    elseif a.legacy == b.expansion then
        return compare(a, b, a.legacySize, b.size)
    elseif a.expansion == b.legacy then
        return compare(a, b, a.size, b.legacySize)
    end
    return a.expansion > b.expansion
end

-- Start currency helpers
local sameEmblemsPerBoss = function(emblemsPerEncounter)
    return function(instance)
        return emblemsPerEncounter * instance:encountersLeft()
    end
end

local sameEmblemsPerBossPerSize = function(emblems10, emblems25)
    return function(instance)
        return (instance.size == 10 and emblems10 or instance.size == 25 and emblems25 or 0) * instance:encountersLeft()
    end
end

-- Checks if the last boss in the instance is killed, using the number of encounters as the last boss index.
local isLastBossKilled = function(instance)
    local index = Instances.Encounters[instance.id].lastBossIndex
    return instance:isEncounterKilled(index)
end

local addOneLastBossAlive = function(instance)
    return isLastBossKilled(instance) and 0 or 1
end

local onePerBossPlusOneLastBoss = ICT:add(sameEmblemsPerBoss(1), addOneLastBossAlive)

-- Ulduar has different amounts per boss
-- FL(4)/Ignis(1)/Razorscale(1)/XT(2)/IC(2)/Kolo(1)/Auriaya(1)/Thorim(2)/Hodir(2)/Freya(5)/Mim(2)/Vezak(2)/Yogg(2)/Alg(2)
local ulduarEmblemsPerBoss = { 4, 1, 1, 2, 2, 1, 1, 2, 2, 5, 2, 2, 2, 2 }
-- Ulduar has a maximum number of emblems of 29
Instances.MaxUlduarEmblems = ICT:sum(ulduarEmblemsPerBoss)
local ulduarEmblems = function(instance)
    local emblems = Instances.MaxUlduarEmblems
    if instance.instanceIndex > 0 then
        for i, ulduarEmblem in pairs(ulduarEmblemsPerBoss) do
            if instance:isEncounterKilled(i) then
                emblems = emblems - ulduarEmblem
            end
        end
    end
    return emblems
end

-- Vault of Archavon drops a different token per boss
local voaIndex = {
    [ICT.Valor] = 1,
    [ICT.Conquest] = 2,
    [ICT.Triumph] = 3,
}
local voaEmblems = function(instance, currency)
    return instance:isEncounterKilled(voaIndex[currency]) and 0 or 2
end

local maxEmblemsPerSize = function(emblemsPer10, emblemsPer25)
    return function(instance)
        return (instance.size == 10 and emblemsPer10 or instance.size == 25 and emblemsPer25 or 0) * instance:numOfEncounters()
    end
end

local dungeonEmblems = ICT:set(ICT.DungeonEmblem, ICT.SiderealEssence)
local totcEmblems = ICT:set(ICT.DungeonEmblem, ICT.SiderealEssence, ICT.ChampionsSeal)
local availableDungeonEmblems = function(instance, currency)
    if currency == ICT.SiderealEssence then
        return isLastBossKilled(instance) and 0 or 1
    elseif currency == ICT.DungeonEmblem or currency == ICT.ChampionsSeal then
        return sameEmblemsPerBoss(1)(instance)
    end
end
local maxDungeonEmblems = function(instance, currency)
    if currency == ICT.SiderealEssence then
        return 1
    elseif currency == ICT.DungeonEmblem or currency == ICT.ChampionsSeal then
        return instance:numOfEncounters()
    end
end

local maxNumEncountersPlusOne = function(instance) return instance:numOfEncounters() + 1 end

Instances.currency = {
    -- Utgarde Keep
    [574] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Utgarde Pinnacle
    [575] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- The Culling of Stratholme
    [595] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Drak'Tharon Keep
    [600] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Gundrak
    [604] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- The Nexus
    [576] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- The Oculus
    [578] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Violet Hold
    [608] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Halls of Lightning
    [602] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Halls of Stone
    [599] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- "Azjol-Nerub
    [601] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Ahn'kahet: The Old Kingdom
    [619] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Trial of the Champion"
    [650] = { currencies = totcEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Vault of Archavon
    [624] = { currencies = ICT:set(ICT.Triumph, ICT.Conquest, ICT.Valor), availableCurrency = voaEmblems, maxCurrency = ICT:ReturnX(2) },
    -- Naxxramas
    [533] = { currencies = ICT:set(ICT.Valor), availableCurrency = onePerBossPlusOneLastBoss, maxCurrency = maxNumEncountersPlusOne },
    -- The Obsidian Sanctum
    [615] = { currencies = ICT:set(ICT.Valor), availableCurrency = onePerBossPlusOneLastBoss, maxCurrency = maxNumEncountersPlusOne },
    -- The Eye of Eternity
    [616] = { currencies = ICT:set(ICT.Valor), availableCurrency = onePerBossPlusOneLastBoss, maxCurrency = maxNumEncountersPlusOne },
    -- Ulduar
    [603] = { currencies = ICT:set(ICT.Conquest), availableCurrency = ulduarEmblems, maxCurrency = ICT:ReturnX(Instances.MaxUlduarEmblems) },
    -- Onyxia's Lair
    [249] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBossPerSize(4, 5), maxCurrency = maxEmblemsPerSize(4, 5) },
    -- Trial of the Crusader
    [649] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBossPerSize(4, 5), maxCurrency = maxEmblemsPerSize(4, 5) },
}
-- End Currency Helpers

ICT.WOTLK = 2
ICT.TBC = 1
ICT.VANILLA = 0
ICT.Expansions = {
    [ICT.WOTLK] = "Wrath of the Lich King",
    [ICT.TBC] = "The Burning Crusade",
    [ICT.VANILLA] = "Vanilla"
}

-- Attaches the localize name to info for sorting in the options menu.
local infos
function Instances.infos()
    if infos then
        return infos
    end
    infos = {}
    for _, v in pairs(Instances.Expansions) do
        local info = Instances:new({}, v.id, v.size)
        -- Drop size from name.
        info.name = GetRealZoneText(info.id)
        tinsert(infos, info)

        -- todo check if this is needed?
        if v.legacy then
            info = Instances:new({}, v.id, v.legacySize)
            info.name = GetRealZoneText(info.id)
            tinsert(infos, info)
        end
    end
    return infos
end

Instances.Encounters = {
    [33] = { lastBossIndex = 8, names = { "Rethilgore", "Razorclaw the Butcher", "Baron Silverlaine", "Commander Springvale", "Odo the Blindwatcher", "Fenrus the Devourer", "Wolf Master Nandos", "Archmage Arugal" }, },
    [36] = { lastBossIndex = 7, names = { "Rhahk'zor", "Sneed", "Gilnid", "Mr. Smite", "Cookie", "Captain Greenskin", "Edwin VanCleef" }, },
    [43] = { lastBossIndex = 8, names = { "Lady Anacondra", "Lord Cobrahn", "Kresh", "Lord Pythas", "Skum", "Lord Serpentis", "Verdan the Everliving", "Mutanus the Devourer" }, },
    [47] = { lastBossIndex = 6, names = { "Roogug", "Death Speaker Jargba", "Aggem Thorncurse", "Overlord Ramtusk", "Agathelos the Raging", "Charlga Razorflank" }, },
    [48] = { lastBossIndex = 7, names = { "Ghamoo-ra", "Lady Sarevess", "Gelihast", "Lorgus Jett", "Old Serra'kis", "Twilight Lord Kelris", "Aku'mai" }, },
    [70] = { lastBossIndex = 7, names = { "Revelosh", "The Lost Dwarves", "Ironaya", "Ancient Stone Keeper", "Galgann Firehammer", "Grimlok", "Archaedas" }, },
    [90] = { lastBossIndex = 5, names = { "Grubbis", "Viscous Fallout", "Electrocutioner 6000", "Crowd Pummeler 9-60", "Mekgineer Thermaplugg" }, },
    [109] = { lastBossIndex = 7, names = { "Avatar of Hakkar", "Jammal'an the Prophet", "Dreamscythe", "Weaver", "Morphaz", "Hazzas", "Shade of Eranikus" }, },
    [129] = { lastBossIndex = 4, names = { "Tuten'kash", "Mordresh Fire Eye", "Glutton", "Amnennar the Coldbringer" }, },
    [189] = { lastBossIndex = 7, names = { "Interrogator Vishas", "Bloodmage Thalnos", "Houndmaster Loksey", "Arcanist Doan", "Herod", "High Inquisitor Fairbanks", "High Inquisitor Whitemane" }, },
    [209] = { lastBossIndex = 8, names = { "Hydromancer Velratha", "Ghaz'rilla", "Antu'sul", "Theka the Martyr", "Witch Doctor Zum'rah", "Nekrum Gutchewer", "Shadowpriest Sezz'ziz", "Chief Ukorz Sandscalp" }, },
    [229] = { lastBossIndex = 14, names = { "Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone", "Mother Smolderweb", "Urok Doomhowl", "Quartermaster Zigris", "Halycon", "Gizrul the Slavener", "Overlord Wyrmthalak", "Pyroguard Emberseer", "Solakar Flamewreath", "Warchief Rend Blackhand", "The Beast", "General Drakkisath" }, },
    [230] = { lastBossIndex = 19, names = { "High Interrogator Gerstahn", "Lord Roccor", "Houndmaster Grebmar", "Ring of Law", "Pyromancer Loregrain", "Lord Incendius", "Warder Stilgiss", "Fineous Darkvire", "Bael'Gar", "General Angerforge", "Golem Lord Argelmach", "Hurley Blackbreath", "Phalanx", "Ribbly Screwspigot", "Plugger Spazzring", "Ambassador Flamelash", "The Seven", "Magmus", "Emperor Dagran Thaurissan" }, },
    [249] = { lastBossIndex = 1, names = { "Onyxia" }, },
    [269] = { lastBossIndex = 3, names = { "Aeonus", "Chrono Lord Deja", "Temporus" }, },
    [309] = { lastBossIndex = 10, names = { "High Priestess Jeklik", "High Priest Venoxis", "High Priestess Mar'li", "Bloodlord Mandokir", "Edge of Madness", "High Priest Thekal", "Gahz'ranka", "High Priestess Arlokk", "Jin'do the Hexxer", "Hakkar" }, },
    [329] = { lastBossIndex = 13, names = { "Hearthsinger Forresten", "Timmy the Cruel", "Commander Malor", "Willey Hopebreaker", "Instructor Galford", "Balnazzar", "The Unforgiven", "Baroness Anastari", "Nerub'enkan", "Maleki the Pallid", "Magistrate Barthilas", "Ramstein the Gorger", "Lord Aurius Rivendare" }, },
    [349] = { lastBossIndex = 8, names = { "Noxxion", "Razorlash", "Tinkerer Gizlock", "Lord Vyletongue", "Celebras the Cursed", "Landslide", "Rotgrip", "Princess Theradras" }, },
    [389] = { lastBossIndex = 4, names = { "Oggleflint", "Jergosh the Invoker", "Bazzalan", "Taragaman the Hungerer" }, },
    [409] = { lastBossIndex = 10, names = { "Lucifron", "Magmadar", "Gehennas", "Garr", "Shazzrah", "Baron Geddon", "Sulfuron Harbinger", "Golemagg the Incinerator", "Majordomo Executus", "Ragnaros" }, },
    [429] = { lastBossIndex = 16, names = { "Zevrim Thornhoof", "Hydrospawn", "Lethtendris", "Alzzin the Wildshaper", "Tendris Warpwood", "Illyanna Ravenoak", "Magister Kalendris", "Immol'thar", "Prince Tortheldrin", "Guard Mol'dar", "Stomper Kreeg", "Guard Fengus", "Guard Slip'kik", "Captain Kromcrush", "Cho'Rush the Observer", "King Gordok" }, },
    [469] = { lastBossIndex = 8, names = { "Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer", "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", "Nefarian" }, },
    [509] = { lastBossIndex = 6, names = { "Kurinnaxx", "General Rajaxx", "Moam", "Buru the Gorger", "Ayamiss the Hunter", "Ossirian the Unscarred" }, },
    [531] = { lastBossIndex = 9, names = { "The Prophet Skeram", "Silithid Royalty", "Battleguard Sartura", "Fankriss the Unyielding", "Viscidus", "Princess Huhuran", "Twin Emperors", "Ouro", "C'thun" }, },
    [532] = { lastBossIndex = 11, names = { "Attumen the Huntsman", "Moroes", "Maiden of Virtue", "Opera Hall", "The Curator", "Terestian Illhoof", "Shade of Aran", "Netherspite", "Chess Event", "Prince Malchezaar", "Nightbane" }, },
    [533] = { lastBossIndex = 15, names = { "Anub'Rekhan", "Grand Widow Faerlina", "Maexxna", "Noth the Plaguebringer", "Heigan the Unclean", "Loatheb", "Instructor Razuvious", "Gothik the Harvester", "The Four Horsemen", "Patchwerk", "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad" }, },
    [534] = { lastBossIndex = 5, names = { "Rage Winterchill", "Anetheron", "Kaz'rogal", "Azgalor", "Archimonde" }, },
    [540] = { lastBossIndex = 4, names = { "Blood Guard Porung", "Grand Warlock Nethekurse", "Warbringer O'mrogg", "Warchief Kargath Bladefist" }, },
    [542] = { lastBossIndex = 3, names = { "The Maker", "Keli'dan the Breaker", "Broggok" }, },
    [543] = { lastBossIndex = 3, names = { "Omor the Unscarred", "Vazruden the Herald", "Watchkeeper Gargolmar" }, },
    [544] = { lastBossIndex = 1, names = { "Magtheridon" }, },
    [545] = { lastBossIndex = 3, names = { "Hydromancer Thespia", "Mekgineer Steamrigger", "Warlord Kalithresh" }, },
    [546] = { lastBossIndex = 4, names = { "Ghaz'an", "Hungarfen", "Swamplord Musel'ek", "The Black Stalker" }, },
    [547] = { lastBossIndex = 3, names = { "Mennu the Betrayer", "Quagmirran", "Rokmar the Crackler" }, },
    [548] = { lastBossIndex = 6, names = { "Hydross the Unstable", "The Lurker Below", "Leotheras the Blind", "Fathom-Lord Karathress", "Morogrim Tidewalker", "Lady Vashj" }, },
    [550] = { lastBossIndex = 4, names = { "Al'ar", "Void Reaver", "High Astromancer Solarian", "Kael'thas Sunstrider" }, },
    [552] = { lastBossIndex = 4, names = { "Dalliah the Doomsayer", "Harbinger Skyriss", "Wrath-Scryer Soccothrates", "Zereketh the Unbound" }, },
    [553] = { lastBossIndex = 5, names = { "Commander Sarannis", "High Botanist Freywinn", "Laj", "Thorngrin the Tender", "Warp Splinter" }, },
    [554] = { lastBossIndex = 5, names = { "Nethermancer Sepethrea", "Pathaleon the Calculator", "Mechano-Lord Capacitus", "Gatewatcher Gyro-Kill", "Gatewatcher Iron-Hand" }, },
    [555] = { lastBossIndex = 4, names = { "Ambassador Hellmaw", "Blackheart the Inciter", "Murmur", "Grandmaster Vorpil" }, },
    [556] = { lastBossIndex = 3, names = { "Talon King Ikiss", "Darkweaver Syth", "Anzu" }, },
    [557] = { lastBossIndex = 4, names = { "Nexus-Prince Shaffar", "Pandemonius", "Yor", "Tavarok" }, },
    [558] = { lastBossIndex = 2, names = { "Exarch Maladaar", "Shirrak the Dead Watcher" }, },
    [560] = { lastBossIndex = 3, names = { "Lieutenant Drake", "Epoch Hunter", "Captain Skarloc" }, },
    [564] = { lastBossIndex = 9, names = { "High Warlord Naj'entus", "Supremus", "Shade of Akama", "Teron Gorefiend", "Gurtogg Bloodboil", "Reliquary of Souls", "Mother Shahraz", "The Illidari Council", "Illidan Stormrage" }, },
    [565] = { lastBossIndex = 2, names = { "High King Maulgar", "Gruul the Dragonkiller" }, },
    [568] = { lastBossIndex = 6, names = { "Akil'zon", "Nalorakk", "Jan'alai", "Halazzi", "Hex Lord Malacrass", "Zul'jin" }, },
    [574] = { lastBossIndex = 3, names = { "Prince Keleseth", "Skarvold & Dalronn", "Ingvar the Plunderer" }, },
    [575] = { lastBossIndex = 4, names = { "Svala Sorrowgrave", "Gortok Palehoof", "Skadi the Ruthless", "King Ymiron" }, },
    [576] = { lastBossIndex = 4, names = { "Grand Magus Telestra", "Anomalus", "Ormorok the Tree-Shaper", "Keristrasza" }, },
    [578] = { lastBossIndex = 4, names = { "Drakos the Interrogator", "Varos Cloudstrider", "Mage-Lord Urom", "Ley-Guardian Eregos" }, },
    [580] = { lastBossIndex = 6, names = { "Kalecgos", "Brutallus", "Felmyst", "Eredar Twins", "M'uru", "Kil'jaeden" }, },
    [585] = { lastBossIndex = 4, names = { "Kael'thas Sunstrider", "Priestess Delrissa", "Selin Fireheart", "Vexallus" }, },
    [595] = { lastBossIndex = 4, names = { "Meathook", "Salram the Fleshcrafter", "Chrono-Lord Epoch", "Mal'ganis" }, },
    [599] = { lastBossIndex = 4, names = { "Krystallus", "Maiden of Grief", "Tribunal of Ages", "Sjonnir the Ironshaper" }, },
    [600] = { lastBossIndex = 4, names = { "Trollgore", "Novos the Summoner", "King Dred", "The Prophet Tharon'ja" }, },
    [601] = { lastBossIndex = 3, names = { "Krik'thir the Gatewatcher", "Hadronox", "Anub'arak" }, },
    [602] = { lastBossIndex = 4, names = { "General Bjarngrim", "Volkhan", "Ionar", "Loken" }, },
    [603] = { lastBossIndex = 14, names = { "Flame Leviathan", "Ignis the Furnace Master", "Razorscale", "XT-002 Deconstructor", "The Iron Council", "Kologarn", "Auriaya", "Hodir", "Thorim", "Freya", "Mimiron", "General Vezax", "Yogg-Saron", "Algalon the Observer" }, },
    [604] = { lastBossIndex = 4, names = { "Slad'ran", "Drakkari Colossus", "Moorabi", "Gal'darah", "Eck the Ferocious" }, },
    [608] = { lastBossIndex = 3, names = { "First Prisoner", "Second Prisoner", "Cyanigosa" }, },
    [615] = { lastBossIndex = 4, names = { "Vesperon", "Tenebron", "Shadron", "Sartharion" }, },
    [616] = { lastBossIndex = 1, names = { "Malygos" }, },
    [619] = { lastBossIndex = 4, names = { "Elder Nadox", "Prince Taldaram", "Jedoga Shadowseeker", "Herald Volazj", "Amanitar" }, },
    [624] = { lastBossIndex = 4, names = { "Archavon the Stone Watcher", "Emalon the Storm Watcher", "Koralon the Flame Watcher", "Toravon the Ice Watcher" }, },
    --[631] = { lastBossIndex = 12, names = { "Lord Marrowgar", "Lady Deathwhisper", "Icecrown Gunship Battle", "Deathbringer Saurfang", "Festergut", "Rotface", "Professor Putricide", "Blood Council", "Queen Lana'thel", "Valithria Dreamwalker", "Sindragosa", "The Lich King" }, },
    --[632] = { lastBossIndex = 2, names = { "Bronjahm", "Devourer of Souls" }, },
    [649] = { lastBossIndex = 5, names = { "Northrend Beasts", "Lord Jaraxxus", "Faction Champions", "Val'kyr Twins", "Anub'arak" }, },
    [650] = { lastBossIndex = 3, names = { "Grand Champions", "Argent Champion", "The Black Knight" }, },
    --[658] = { lastBossIndex = 3, names = { "Forgemaster Garfrost", "Krick", "Overlrod Tyrannus" }, },
    --[668] = { lastBossIndex = 3, names = { "Falric", "Marwyn", "Escaped from Arthas" }, },
    --[724] = { lastBossIndex = 4, names = { "Baltharus the Warborn", "Saviana Ragefire", "General Zarithrian", "Halion" }, },
}

-- Size here is the smallest for the specific raid, we use this for sorting.
Instances.Expansions = {
    [249] = { expansion = 2, id = 249, legacy = 0, legacySize = 40, size = 10, },
    [269] = { expansion = 1, id = 269, size = 5, },
    [309] = { expansion = 0, id = 309, size = 20, },
    [409] = { expansion = 0, id = 409, size = 40, },
    [469] = { expansion = 0, id = 469, size = 40, },
    [509] = { expansion = 0, id = 509, size = 20, },
    [531] = { expansion = 0, id = 531, size = 40, },
    [532] = { expansion = 1, id = 532, size = 10, },
    [533] = { expansion = 2, id = 533, size = 10, },
    [534] = { expansion = 1, id = 534, size = 25, },
    [540] = { expansion = 1, id = 540, size = 5, },
    [542] = { expansion = 1, id = 542, size = 5, },
    [543] = { expansion = 1, id = 543, size = 5, },
    [544] = { expansion = 1, id = 544, size = 25, },
    [545] = { expansion = 1, id = 545, size = 5, },
    [546] = { expansion = 1, id = 546, size = 5, },
    [547] = { expansion = 1, id = 547, size = 5, },
    [548] = { expansion = 1, id = 548, size = 25, },
    [550] = { expansion = 1, id = 550, size = 25, },
    [552] = { expansion = 1, id = 552, size = 5, },
    [553] = { expansion = 1, id = 553, size = 5, },
    [554] = { expansion = 1, id = 554, size = 5, },
    [555] = { expansion = 1, id = 555, size = 5, },
    [556] = { expansion = 1, id = 556, size = 5, },
    [557] = { expansion = 1, id = 557, size = 5, },
    [558] = { expansion = 1, id = 558, size = 5, },
    [560] = { expansion = 1, id = 560, size = 5, },
    [564] = { expansion = 1, id = 564, size = 25, },
    [565] = { expansion = 1, id = 565, size = 25, },
    [568] = { expansion = 1, id = 568, size = 10, },
    [574] = { expansion = 2, id = 574, size = 5, },
    [575] = { expansion = 2, id = 575, size = 5, },
    [576] = { expansion = 2, id = 576, size = 5, },
    [578] = { expansion = 2, id = 578, size = 5, },
    [580] = { expansion = 1, id = 580, size = 25, },
    [585] = { expansion = 1, id = 585, size = 5, },
    [595] = { expansion = 2, id = 595, size = 5, },
    [599] = { expansion = 2, id = 599, size = 5, },
    [600] = { expansion = 2, id = 600, size = 5, },
    [601] = { expansion = 2, id = 601, size = 5, },
    [602] = { expansion = 2, id = 602, size = 5, },
    [603] = { expansion = 2, id = 603, size = 10, },
    [604] = { expansion = 2, id = 604, size = 5, },
    [608] = { expansion = 2, id = 608, size = 5, },
    [615] = { expansion = 2, id = 615, size = 10, },
    [616] = { expansion = 2, id = 616, size = 10, },
    [619] = { expansion = 2, id = 619, size = 5, },
    [624] = { expansion = 2, id = 624, size = 10, },
    --[631] = { expansion = 2, id = 631, size = 10, },
    --[632] = { expansion = 2, id = 632, size = 5, },
    [649] = { expansion = 2, id = 649, size = 10, },
    [650] = { expansion = 2, id = 650, size = 5, },
    --[658] = { expansion = 2, id = 658, size = 5, },
    --[668] = { expansion = 2, id = 668, size = 5, },
    --[724] = { expansion = 2, id = 724, size = 10, },
}

-- Corresponds to the number of days on the lockout for the size.
Instances.Resets = {
    [249] = { [10] = 7, [25] = 7, [40] = 5, },
    [269] = { [5] = 1, },
    [309] = { [20] = 3, },
    [409] = { [40] = 7, },
    [469] = { [40] = 7, },
    [509] = { [20] = 3, },
    [531] = { [40] = 7, },
    [532] = { [10] = 7, },
    [533] = { [10] = 7, [25] = 7, },
    [534] = { [25] = 7, },
    [540] = { [5] = 1, },
    [542] = { [5] = 1, },
    [543] = { [5] = 1, },
    [544] = { [25] = 7, },
    [545] = { [5] = 1, },
    [546] = { [5] = 1, },
    [547] = { [5] = 1, },
    [548] = { [25] = 7, },
    [550] = { [25] = 7, },
    [552] = { [5] = 1, },
    [553] = { [5] = 1, },
    [554] = { [5] = 1, },
    [555] = { [5] = 1, },
    [556] = { [5] = 1, },
    [557] = { [5] = 1, },
    [558] = { [5] = 1, },
    [560] = { [5] = 1, },
    [564] = { [25] = 7, },
    [565] = { [25] = 7, },
    [568] = { [10] = 7, },
    [574] = { [5] = 1, },
    [575] = { [5] = 1, },
    [576] = { [5] = 1, },
    [578] = { [5] = 1, },
    [580] = { [25] = 7, },
    [585] = { [5] = 1, },
    [595] = { [5] = 1, },
    [599] = { [5] = 1, },
    [600] = { [5] = 1, },
    [601] = { [5] = 1, },
    [602] = { [5] = 1, },
    [603] = { [10] = 7, [25] = 7, },
    [604] = { [5] = 1, },
    [608] = { [5] = 1, },
    [615] = { [10] = 7, [25] = 7, },
    [616] = { [10] = 7, [25] = 7, },
    [619] = { [5] = 1, },
    [624] = { [10] = 7, [25] = 7, },
    --[631] = { [10] = 7, [25] = 7, },
    --[632] = { [5] = 1, },
    [649] = { [10] = 7, [25] = 7, },
    [650] = { [5] = 1, },
    --[658] = { [5] = 1, },
    --[668] = { [5] = 1, },
    --[724] = { [10] = 7, [25] = 7, },
}

-- How to find the activity id for a specific zone, size and difficulty.
Instances.ActivityIdLookups = {
    [0] = { [5] = { 285 }, [20] = { 290 }, [40] = { 290 }, },
    [1] = { [5] = { 286 }, [10] = { 291 }, [25] = { 291 }, },
    [2] = { [5] = { 287, 289, 311, 312, 314 }, [10] = { 292 }, [25] = { 293 }, },
}

-- The id for LFG selection.
Instances.Activities = {
    [33] = { [285] = 800, [294] = 1084, },
    [34] = { [285] = 802, },
    [36] = { [285] = 799, },
    [43] = { [285] = 796, },
    [47] = { [285] = 804, },
    [48] = { [285] = 801, },
    [70] = { [285] = 807, },
    [90] = { [285] = 803, },
    [109] = { [285] = 810, },
    [129] = { [285] = 806, },
    [189] = { [285] = 829, [294] = 1081, },
    [209] = { [285] = 808, },
    [229] = { [285] = 812, [290] = 837, },
    [230] = { [285] = 811, [294] = 1083, },
    [249] = { [290] = 838, [292] = 1156, [293] = 1099, },
    [269] = { [286] = 831, [288] = 907, },
    [289] = { [285] = 797, },
    [309] = { [290] = 836, },
    [329] = { [285] = 816, },
    [349] = { [285] = 809, },
    [389] = { [285] = 798, },
    [409] = { [290] = 839, },
    [429] = { [285] = 815, },
    [469] = { [290] = 840, },
    [509] = { [290] = 842, },
    [531] = { [290] = 843, },
    [532] = { [291] = 844, },
    [533] = { [292] = 841, [293] = 1098, },
    [534] = { [291] = 849, },
    [540] = { [286] = 819, [288] = 914, },
    [542] = { [286] = 818, [288] = 912, },
    [543] = { [286] = 817, [288] = 913, },
    [544] = { [291] = 845, },
    [545] = { [286] = 822, [288] = 910, },
    [546] = { [286] = 821, [288] = 911, },
    [547] = { [286] = 820, [288] = 909, [294] = 1082, },
    [548] = { [291] = 848, },
    [550] = { [291] = 847, },
    [552] = { [286] = 834, [288] = 915, },
    [553] = { [286] = 833, [288] = 918, },
    [554] = { [286] = 832, [288] = 916, },
    [555] = { [286] = 826, [288] = 906, },
    [556] = { [286] = 825, [288] = 905, },
    [557] = { [286] = 823, [288] = 904, },
    [558] = { [286] = 824, [288] = 903, },
    [560] = { [286] = 830, [288] = 908, },
    [564] = { [291] = 850, },
    [565] = { [291] = 846, },
    [568] = { [291] = 851, },
    [574] = { [287] = 1074, [289] = 1122, [311] = 1207, [312] = 1211, [314] = 1225, },
    [575] = { [287] = 1075, [289] = 1125, [311] = 1204, [312] = 1210, [314] = 1224, },
    [576] = { [287] = 1077, [289] = 1132, [311] = 1197, [312] = 1213, [314] = 1227, },
    [578] = { [287] = 1067, [289] = 1124, [311] = 1205, [312] = 1212, [314] = 1226, },
    [580] = { [291] = 852, },
    [585] = { [286] = 835, [288] = 917, },
    [595] = { [287] = 1065, [289] = 1126, [311] = 1203, [312] = 1214, [314] = 1228, },
    [599] = { [287] = 1069, [289] = 1128, [311] = 1201, [312] = 1215, [314] = 1229, },
    [600] = { [287] = 1070, [289] = 1129, [311] = 1200, [312] = 1218, [314] = 1232, },
    [601] = { [287] = 1066, [289] = 1121, [311] = 1208, [312] = 1219, [314] = 1233, },
    [602] = { [287] = 1068, [289] = 1127, [311] = 1202, [312] = 1216, [314] = 1230, },
    [603] = { [292] = 1106, [293] = 1107, },
    [604] = { [287] = 1071, [289] = 1130, [311] = 1199, [312] = 1217, [314] = 1231, },
    [608] = { [287] = 1073, [289] = 1123, [311] = 1206, [312] = 1209, [314] = 1223, },
    [615] = { [292] = 1101, [293] = 1097, },
    [616] = { [292] = 1102, [293] = 1094, },
    [619] = { [287] = 1072, [289] = 1131, [311] = 1198, [312] = 1220, [314] = 1234, },
    [624] = { [292] = 1095, [293] = 1096, },
    --[631] = { [292] = 1110, [293] = 1111, },
    --[632] = { [287] = 1078, [289] = 1134, [314] = 1240, },
    [649] = { [292] = 1100, [293] = 1104, },
    [650] = { [287] = 1076, [289] = 1133, [312] = 1238, [314] = 1239, },
    --[658] = { [287] = 1079, [289] = 1135, [314] = 1241, },
    --[668] = { [287] = 1080, [289] = 1136, [314] = 1242, },
    --[724] = { [292] = 1108, [293] = 1109, },
}