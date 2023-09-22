local L = LibStub("AceLocale-3.0"):NewLocale("InstanceCurrencyTracker", "enUS", true, true);

L["Initialized Instance Currency Tracker: %s..."] = "Initialized Instance Currency Tracker: %s..."
L["Creating player: %s"] = "Creating player: %s"
L["%s reset, updating info."] = "%s reset, updating info."

------ Professions
L["alchemy"] = "Alchemy"
L["archaeology"] = "Archaeology"
L["blacksmithing"] = "Blacksmithing"
L["cooking"] = "Cooking"
L["enchanting"] = "Enchanting"
L["engineering"] = "Engineering"
L["firstAid"] = "First Aid"
L["fishing"] = "Fishing"
L["herbalism"] = "Herbalism"
L["herbalismskills"] = "Herbalism Skills"
L["inscription"] = "Inscription"
L["jewelcrafting"] = "Jewelcrafting"
L["leatherworking"] = "Leatherworking"
L["mining"] = "Mining"
L["miningskills"] = "Mining Skills"
L["skinning"] = "Skinning"
L["skinningskills"] = "Skinning Skills"
L["tailoring"] = "Tailoring"

-- Sections
L["Info"] = "Info"
L["Bags"] = "Bags"
L["Specs"] = "Specs"
L["Professions"] = "Professions"
L["Cooldowns"] = "Cooldowns"
L["Dungeons"] = "Dungeons"
L["Raids"] = "Raids"
L["Currency"] = "Currency"
L["Quests"] = "Quests"

-- Character Info
L["Level"] = "Level"
L["Guild"] = "Guild"
L["Guild Rank"] = "Guild Rank"
L["Gold"] = "Gold"
L["Durability"] = "Durability"
L["XP"] = "XP"
L["Rested XP"] = "Rested XP"
L["Bubbles"] = "Bubbles"
L["Resting"] = "Resting"
L["Not Resting"] = "Not Resting"
L["Resting State"] = "Resting State"
L["Realm Gold"] = "Realm Gold"

-- Bag Tooltip
L["Bag Space"] = "Bag Space"
L["Bag"] = "Bag"
L["Free / Total"] = "Free / Total"
L["Personal Bags"] = "Personal Bags"
L["Bank Bags"] = "Bank Bags"
L["BagTooltipNote"] = "Note: Bank bags require opening and closing the bank for each character."
L["General"] = "General"
L["Arrows"] = "Arrows"
L["Bullets"] = "Bullets"
L["Soul Shards"] = "Soul Shards"

-- Gear Info
L["Talents"] = "Talents"
L["Gear"] = "Gear"
L["Missing"] = "Missing"
L["Items"] = "Items"
L["Major"] = "Major"
L["Minor"] = "Minor"
L["Enchants"] = "Enchants"
L["GearScore"] = "GearScore"
L["iLvl"] = "iLvl"

-- Other Info
L["Encounters"] = "Encounters"
L["Locks"] = "Locks"
L["Current"] = "Current"
L["Available"] = "Available"
L["Queued Available"] = "Queued Available"
L["Locked"] = "Locked"
L["Queued Locked"] = "Queued Locked"
L["Completed"] = "Completed"
L["Missing Prerequesite"] = "Missing Prerequesite"

-- Options
L["Messages"] = "Messages"
L["Character Info"] = "Character Info"
L["Characters"] = "Characters"
L["Reset Timers"] = "Reset Timers"
L["Instances"] = "Instances"
L["Difficulty"] = "Difficulty"
L["Frame"] = "Frame"

-- Player Options
L["Show Level"] = "Show Level"
L["Show Guild"] = "Show Guild"
L["Show Guild Rank"] = "Show Guild Rank"
L["Show Gold"] = "Show Gold"
L["Show Durability"] = "Show Durability"
L["Show XP"] = "Show XP"
L["Show Rested XP"] = "Show Rested XP"
L["Show Resting State"] = "Show Resting State"
L["Show Bags"] = "Show Bags"
L["Show Bank Bags"] = "Show Bank Bags"
L["Show Specs"] = "Show Specs"
L["Show Gear Scores"] = "Show Gear Scores"
L["Show Professions"] = "Show Professions"

-- Message Options
L["Send Group Messages"] = "Send Group Messages"
L["SendGroupMessagesTooltip"] = "Messages your party or raid on leaving an instance with the collected currency. Otherwise prints to your chat window only."
L["Send LFG Messages"] = "Send LFG Messages"
L["SendLFGMessagesTooltip"] = "Prints messages when enqueuing or dequeuing LFG window when clicking ICT buttons."

-- Quest Options
L["Hide Unavailable Quests"] = "Hide Unavailable Quests"
L["Show Quests"] = "Show Quests"

-- Frame Options
L["Anchor to LFG"] = "Anchor to LFG"
L["AnchorToLFGTooltip"] = "Brings up the frame when viewing the LFG frame otherwise detaches from the frame."
L["Show Minimap Icon"] = "Show Minimap Icon"
L["Order Lock Last"] = "Order Lock Last"
L["OrderLockLastTooltip"] = "Orders locked instances and completed quests after available instances and quests."
L["Verbose Currency"] = "Verbose Currency"
L["VerboseCurrencyTooltip"] = "Multiline currency view or a single line currency view."
L["Verbose Currency Tooltip"] = "Verbose Currency Tooltip"
L["VerboseCurrencyTooltipTooltip"] = "Shows instances and quests currency available and total currency for the hovered over currency."
L["Show Realm Name"] = "Show Realm Name"
L["ShowRealmNameTooltip"] = "Shows [{realm name}] {player name} versus {player name}."
L["Show Level Slider"] = "Show Level Slider"
L["ShowLevelSliderTooltip"] = "Displays the slider bar to control minimum character level."

-- Tooltips
L["LevelSliderTooltip"] = "Minimum level alts to show."
L["EncountersSection"] = "Shows the available boss fights for the current lockout,\nout of the total for any given lockout."
L["CurrencySection"] = "Shows the available currency for the current lockout,\nout of the total for any given lockout."
L["Available / Total"] = "Available / Total"
L["Shows the quest reward."] = "Shows the quest reward."

-- Queuing
L["Enqueuing %s"] = "Enqueuing %s"
L["Dequeuing %s"] = "Dequeuing %s"
L["Enqueued all non lock %s %s."] = "Enqueued all non lock %s %s."
L["Enqueued too many instances: %s"] = "Enqueued too many instances: %s"
L["Listing removed."] = "Listing removed."
L["No more instances queued, delisting."] = "No more instances queued, delisting."
L["Ignoring %s, as Blizzard doesn't let you queue raids and dungeons together."] = "Ignoring %s, as Blizzard doesn't let you queue raids and dungeons together."
L["Cannot queue, not currently the group leader."] = "Cannot queue, not currently the group leader."

-- Gear Tab


-- Slash Commands
L["Invalid command"] = "Invalid command"
L["Unknown character: %s"] = "Unknown character: %s"
L["Wiped character: %s"] = "Wiped character: %s"
L["Wiped %s characters on realm: %s"] = "Wiped %s characters on realm: %s"
L["Wiped %s characters"] = "Wiped %s characters"

--errors
L["No skill found: %s"] = "No skill found: %s"
L["Unknown bag type %s (%s), please report this on the addon page."] = "Unknown bag type %s (%s), please report this on the addon page."
L["Cooldown skillId: %s"] = "Cooldown skillId: %s"
L["Cooldown missing expansion: %s"] = "Cooldown missing expansion: %s"