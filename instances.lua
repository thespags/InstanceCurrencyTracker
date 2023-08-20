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
    for k, _ in pairs(Instances.Encounters[self.id]) do
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

function Instances:activityId()
    return Instances.Expansions[self.id].activityId
end

function Instances:numOfEncounters()
    return self.encounterSize
end

function Instances:encounters()
    return self.Encounters[self.id]
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

function Instances:isVisible(expansion)
    if expansion and expansion == self.legacy or self.legacy then
        return ICT.getOrCreateDisplayLegacyInstances(expansion or self.legacy)[self.id]
    end
    return ICT.getOrCreateDisplayInstances()[self.id]
end

-- This comparison groups instances with the same name together across multiple sizes.
-- This is intended for sorting with respect to dungeons and raids separately.
function Instances:__lt(other)
    if ICT.db.options.orderLockLast then
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

-- How to order expansions, we sort from highest to lowest (reverse) so adding new currencies is easier.
ICT.WOTLK = "Wrath of the Lich King"
ICT.TBC = "The Burning Crusade"
ICT.VANILLA = "Vanilla"
ICT.Expansions = {
    [ICT.VANILLA] = 0,
    [ICT.TBC] = 1,
    [ICT.WOTLK] = 2
}

function ICT.ExpansionSort(a, b)
    return ICT.Expansions[a] > ICT.Expansions[b]
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
    -- Override for Gundrak as lastboss is the optional boss. 
    local index = instance.id == 604 and 4 or instance:numOfEncounters()
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

-- Attaches the localize name to info for sorting in the options menu.
local infos
function Instances.infos()
    if infos then
        return infos
    end
    infos = {}
    for k, v in pairs(Instances.Expansions) do
        local info = Instances:new({}, v.id, v.size)
        infos[k] = info
        -- todo check if this is needed?
        info.name = GetRealZoneText(k)
        info.legacySize = Instances.Expansions[v.id].legacySize
        info.legacy = Instances.Expansions[v.id].legacy
    end
    return infos
end

Instances.Encounters = {
    [33] = { "Rethilgore", "Razorclaw the Butcher", "Baron Silverlaine", "Commander Springvale", "Odo the Blindwatcher", "Fenrus the Devourer", "Wolf Master Nandos", "Archmage Arugal" },
    [36] = { "Rhahk'zor", "Sneed", "Gilnid", "Mr. Smite", "Cookie", "Captain Greenskin", "Edwin VanCleef" },
    [43] = { "Lady Anacondra", "Lord Cobrahn", "Kresh", "Lord Pythas", "Skum", "Lord Serpentis", "Verdan the Everliving", "Mutanus the Devourer" },
    [47] = { "Roogug", "Death Speaker Jargba", "Aggem Thorncurse", "Overlord Ramtusk", "Agathelos the Raging", "Charlga Razorflank" },
    [48] = { "Ghamoo-ra", "Lady Sarevess", "Gelihast", "Lorgus Jett", "Old Serra'kis", "Twilight Lord Kelris", "Aku'mai" },
    [70] = { "Revelosh", "The Lost Dwarves", "Ironaya", "Ancient Stone Keeper", "Galgann Firehammer", "Grimlok", "Archaedas" },
    [90] = { "Grubbis", "Viscous Fallout", "Electrocutioner 6000", "Crowd Pummeler 9-60", "Mekgineer Thermaplugg" },
    [109] = { "Avatar of Hakkar", "Jammal'an the Prophet", "Dreamscythe", "Weaver", "Morphaz", "Hazzas", "Shade of Eranikus" },
    [129] = { "Tuten'kash", "Mordresh Fire Eye", "Glutton", "Amnennar the Coldbringer" },
    [189] = { "Interrogator Vishas", "Bloodmage Thalnos", "Houndmaster Loksey", "Arcanist Doan", "Herod", "High Inquisitor Fairbanks", "High Inquisitor Whitemane" },
    [209] = { "Hydromancer Velratha", "Ghaz'rilla", "Antu'sul", "Theka the Martyr", "Witch Doctor Zum'rah", "Nekrum Gutchewer", "Shadowpriest Sezz'ziz", "Chief Ukorz Sandscalp" },
    [229] = { "Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone", "Mother Smolderweb", "Urok Doomhowl", "Quartermaster Zigris", "Halycon", "Gizrul the Slavener", "Overlord Wyrmthalak", "Pyroguard Emberseer", "Solakar Flamewreath", "Warchief Rend Blackhand", "The Beast", "General Drakkisath" },
    [230] = { "High Interrogator Gerstahn", "Lord Roccor", "Houndmaster Grebmar", "Ring of Law", "Pyromancer Loregrain", "Lord Incendius", "Warder Stilgiss", "Fineous Darkvire", "Bael'Gar", "General Angerforge", "Golem Lord Argelmach", "Hurley Blackbreath", "Phalanx", "Ribbly Screwspigot", "Plugger Spazzring", "Ambassador Flamelash", "The Seven", "Magmus", "Emperor Dagran Thaurissan" },
    [249] = { "Onyxia" },
    [269] = { "Aeonus", "Chrono Lord Deja", "Temporus" },
    [309] = { "High Priestess Jeklik", "High Priest Venoxis", "High Priestess Mar'li", "Bloodlord Mandokir", "Edge of Madness", "High Priest Thekal", "Gahz'ranka", "High Priestess Arlokk", "Jin'do the Hexxer", "Hakkar" },
    [329] = { "Hearthsinger Forresten", "Timmy the Cruel", "Commander Malor", "Willey Hopebreaker", "Instructor Galford", "Balnazzar", "The Unforgiven", "Baroness Anastari", "Nerub'enkan", "Maleki the Pallid", "Magistrate Barthilas", "Ramstein the Gorger", "Lord Aurius Rivendare" },
    [349] = { "Noxxion", "Razorlash", "Tinkerer Gizlock", "Lord Vyletongue", "Celebras the Cursed", "Landslide", "Rotgrip", "Princess Theradras" },
    [389] = { "Oggleflint", "Jergosh the Invoker", "Bazzalan", "Taragaman the Hungerer" },
    [409] = { "Lucifron", "Magmadar", "Gehennas", "Garr", "Shazzrah", "Baron Geddon", "Sulfuron Harbinger", "Golemagg the Incinerator", "Majordomo Executus", "Ragnaros" },
    [429] = { "Zevrim Thornhoof", "Hydrospawn", "Lethtendris", "Alzzin the Wildshaper", "Tendris Warpwood", "Illyanna Ravenoak", "Magister Kalendris", "Immol'thar", "Prince Tortheldrin", "Guard Mol'dar", "Stomper Kreeg", "Guard Fengus", "Guard Slip'kik", "Captain Kromcrush", "Cho'Rush the Observer", "King Gordok" },
    [469] = { "Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer", "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", "Nefarian" },
    [509] = { "Kurinnaxx", "General Rajaxx", "Moam", "Buru the Gorger", "Ayamiss the Hunter", "Ossirian the Unscarred" },
    [531] = { "The Prophet Skeram", "Silithid Royalty", "Battleguard Sartura", "Fankriss the Unyielding", "Viscidus", "Princess Huhuran", "Twin Emperors", "Ouro", "C'thun" },
    [532] = { "Attumen the Huntsman", "Moroes", "Maiden of Virtue", "Opera Hall", "The Curator", "Terestian Illhoof", "Shade of Aran", "Netherspite", "Chess Event", "Prince Malchezaar", "Nightbane" },
    [533] = { "Anub'Rekhan", "Grand Widow Faerlina", "Maexxna", "Noth the Plaguebringer", "Heigan the Unclean", "Loatheb", "Instructor Razuvious", "Gothik the Harvester", "The Four Horsemen", "Patchwerk", "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad" },
    [534] = { "Rage Winterchill", "Anetheron", "Kaz'rogal", "Azgalor", "Archimonde" },
    [540] = { "Blood Guard Porung", "Grand Warlock Nethekurse", "Warbringer O'mrogg", "Warchief Kargath Bladefist" },
    [542] = { "The Maker", "Keli'dan the Breaker", "Broggok" },
    [543] = { "Omor the Unscarred", "Vazruden the Herald", "Watchkeeper Gargolmar" },
    [544] = { "Magtheridon" },
    [545] = { "Hydromancer Thespia", "Mekgineer Steamrigger", "Warlord Kalithresh" },
    [546] = { "Ghaz'an", "Hungarfen", "Swamplord Musel'ek", "The Black Stalker" },
    [547] = { "Mennu the Betrayer", "Quagmirran", "Rokmar the Crackler" },
    [548] = { "Hydross the Unstable", "The Lurker Below", "Leotheras the Blind", "Fathom-Lord Karathress", "Morogrim Tidewalker", "Lady Vashj" },
    [550] = { "Al'ar", "Void Reaver", "High Astromancer Solarian", "Kael'thas Sunstrider" },
    [552] = { "Dalliah the Doomsayer", "Harbinger Skyriss", "Wrath-Scryer Soccothrates", "Zereketh the Unbound" },
    [553] = { "Commander Sarannis", "High Botanist Freywinn", "Laj", "Thorngrin the Tender", "Warp Splinter" },
    [554] = { "Nethermancer Sepethrea", "Pathaleon the Calculator", "Mechano-Lord Capacitus", "Gatewatcher Gyro-Kill", "Gatewatcher Iron-Hand" },
    [555] = { "Ambassador Hellmaw", "Blackheart the Inciter", "Murmur", "Grandmaster Vorpil" },
    [556] = { "Talon King Ikiss", "Darkweaver Syth", "Anzu" },
    [557] = { "Nexus-Prince Shaffar", "Pandemonius", "Yor", "Tavarok" },
    [558] = { "Exarch Maladaar", "Shirrak the Dead Watcher" },
    [560] = { "Lieutenant Drake", "Epoch Hunter", "Captain Skarloc" },
    [564] = { "High Warlord Naj'entus", "Supremus", "Shade of Akama", "Teron Gorefiend", "Gurtogg Bloodboil", "Reliquary of Souls", "Mother Shahraz", "The Illidari Council", "Illidan Stormrage" },
    [565] = { "High King Maulgar", "Gruul the Dragonkiller" },
    [568] = { "Akil'zon", "Nalorakk", "Jan'alai", "Halazzi", "Hex Lord Malacrass", "Zul'jin" },
    [574] = { "Prince Keleseth", "Skarvold & Dalronn", "Ingvar the Plunderer" },
    [575] = { "Svala Sorrowgrave", "Gortok Palehoof", "Skadi the Ruthless", "King Ymiron" },
    [576] = { "Grand Magus Telestra", "Anomalus", "Ormorok the Tree-Shaper", "Keristrasza" },
    [578] = { "Drakos the Interrogator", "Varos Cloudstrider", "Mage-Lord Urom", "Ley-Guardian Eregos" },
    [580] = { "Kalecgos", "Brutallus", "Felmyst", "Eredar Twins", "M'uru", "Kil'jaeden" },
    [585] = { "Kael'thas Sunstrider", "Priestess Delrissa", "Selin Fireheart", "Vexallus" },
    [595] = { "Meathook", "Salram the Fleshcrafter", "Chrono-Lord Epoch", "Mal'ganis" },
    [599] = { "Krystallus", "Maiden of Grief", "Tribunal of Ages", "Sjonnir the Ironshaper" },
    [600] = { "Trollgore", "Novos the Summoner", "King Dred", "The Prophet Tharon'ja" },
    [601] = { "Krik'thir the Gatewatcher", "Hadronox", "Anub'arak" },
    [602] = { "General Bjarngrim", "Volkhan", "Ionar", "Loken" },
    [603] = { "Flame Leviathan", "Ignis the Furnace Master", "Razorscale", "XT-002 Deconstructor", "The Iron Council", "Kologarn", "Auriaya", "Hodir", "Thorim", "Freya", "Mimiron", "General Vezax", "Yogg-Saron", "Algalon the Observer" },
    [604] = { "Slad'ran", "Drakkari Colossus", "Moorabi", "Gal'darah", "Eck the Ferocious" },
    [608] = { "First Prisoner", "Second Prisoner", "Erekem", "Moragg", "Ichoron", "Xevozz", "Lavanthor", "Zuramat", "Cyanigosa" },
    [615] = { "Vesperon", "Tenebron", "Shadron", "Sartharion" },
    [616] = { "Malygos" },
    [619] = { "Elder Nadox", "Prince Taldaram", "Jedoga Shadowseeker", "Herald Volazj", "Amanitar" },
    [624] = { "Archavon the Stone Watcher", "Emalon the Storm Watcher", "Koralon the Flame Watcher", "Toravon the Ice Watcher" },
    --[631] = { "Lord Marrowgar", "Lady Deathwhisper", "Icecrown Gunship Battle", "Deathbringer Saurfang", "Festergut", "Rotface", "Professor Putricide", "Blood Council", "Queen Lana'thel", "Valithria Dreamwalker", "Sindragosa", "The Lich King" },
    --[632] = { "Bronjahm", "Devourer of Souls" },
    [649] = { "Northrend Beasts", "Lord Jaraxxus", "Faction Champions", "Val'kyr Twins", "Anub'arak" },
    [650] = { "Grand Champions", "Argent Champion", "The Black Knight" },
    --[658] = { "Forgemaster Garfrost", "Krick", "Overlrod Tyrannus" },
    --[668] = { "Falric", "Marwyn", "Escaped from Arthas" },
    --[724] = { "Baltharus the Warborn", "Saviana Ragefire", "General Zarithrian", "Halion" },
}

-- Size here is the smallest for the specific raid, we use this for sorting.
Instances.Expansions = {
    [249] = { activityId = 1156, expansion = 2, id = 249, legacy = 0, legacySize = 40, size = 10, },
    [269] = { activityId = 907, expansion = 1, id = 269, size = 5, },
    [309] = { activityId = 836, expansion = 0, id = 309, size = 20, },
    [409] = { activityId = 839, expansion = 0, id = 409, size = 40, },
    [469] = { activityId = 840, expansion = 0, id = 469, size = 40, },
    [509] = { activityId = 842, expansion = 0, id = 509, size = 20, },
    [531] = { activityId = 843, expansion = 0, id = 531, size = 40, },
    [532] = { activityId = 844, expansion = 1, id = 532, size = 10, },
    [533] = { activityId = 1098, expansion = 2, id = 533, size = 10, },
    [534] = { activityId = 849, expansion = 1, id = 534, size = 25, },
    [540] = { activityId = 914, expansion = 1, id = 540, size = 5, },
    [542] = { activityId = 912, expansion = 1, id = 542, size = 5, },
    [543] = { activityId = 913, expansion = 1, id = 543, size = 5, },
    [544] = { activityId = 845, expansion = 1, id = 544, size = 25, },
    [545] = { activityId = 910, expansion = 1, id = 545, size = 5, },
    [546] = { activityId = 911, expansion = 1, id = 546, size = 5, },
    [547] = { activityId = 1082, expansion = 1, id = 547, size = 5, },
    [548] = { activityId = 848, expansion = 1, id = 548, size = 25, },
    [550] = { activityId = 847, expansion = 1, id = 550, size = 25, },
    [552] = { activityId = 915, expansion = 1, id = 552, size = 5, },
    [553] = { activityId = 918, expansion = 1, id = 553, size = 5, },
    [554] = { activityId = 916, expansion = 1, id = 554, size = 5, },
    [555] = { activityId = 906, expansion = 1, id = 555, size = 5, },
    [556] = { activityId = 905, expansion = 1, id = 556, size = 5, },
    [557] = { activityId = 904, expansion = 1, id = 557, size = 5, },
    [558] = { activityId = 903, expansion = 1, id = 558, size = 5, },
    [560] = { activityId = 908, expansion = 1, id = 560, size = 5, },
    [564] = { activityId = 850, expansion = 1, id = 564, size = 25, },
    [565] = { activityId = 846, expansion = 1, id = 565, size = 25, },
    [568] = { activityId = 851, expansion = 1, id = 568, size = 10, },
    [574] = { activityId = 1225, expansion = 2, id = 574, size = 5, },
    [575] = { activityId = 1224, expansion = 2, id = 575, size = 5, },
    [576] = { activityId = 1227, expansion = 2, id = 576, size = 5, },
    [578] = { activityId = 1226, expansion = 2, id = 578, size = 5, },
    [580] = { activityId = 852, expansion = 1, id = 580, size = 25, },
    [585] = { activityId = 917, expansion = 1, id = 585, size = 5, },
    [595] = { activityId = 1228, expansion = 2, id = 595, size = 5, },
    [599] = { activityId = 1229, expansion = 2, id = 599, size = 5, },
    [600] = { activityId = 1232, expansion = 2, id = 600, size = 5, },
    [601] = { activityId = 1233, expansion = 2, id = 601, size = 5, },
    [602] = { activityId = 1230, expansion = 2, id = 602, size = 5, },
    [603] = { activityId = 1107, expansion = 2, id = 603, size = 10, },
    [604] = { activityId = 1231, expansion = 2, id = 604, size = 5, },
    [608] = { activityId = 1223, expansion = 2, id = 608, size = 5, },
    [615] = { activityId = 1101, expansion = 2, id = 615, size = 10, },
    [616] = { activityId = 1102, expansion = 2, id = 616, size = 10, },
    [619] = { activityId = 1234, expansion = 2, id = 619, size = 5, },
    [624] = { activityId = 1096, expansion = 2, id = 624, size = 10, },
    --[631] = { activityId = 1111, expansion = 2, id = 631, size = 10, },
    --[632] = { activityId = 1240, expansion = 2, id = 632, size = 5, },
    [649] = { activityId = 1105, expansion = 2, id = 649, size = 10, },
    [650] = { activityId = 1239, expansion = 2, id = 650, size = 5, },
    --[658] = { activityId = 1241, expansion = 2, id = 658, size = 5, },
    --[668] = { activityId = 1242, expansion = 2, id = 668, size = 5, },
    --[724] = { activityId = 1109, expansion = 2, id = 724, size = 10, },
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