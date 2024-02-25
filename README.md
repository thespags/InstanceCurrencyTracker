# Alt Anon (Instance Currency Tracker)
Originally designed to track instance lockouts and currency information across all your characters and realms on multiple accounts, specifically for WOTLK.
The addon has now expanded to include much more information such as gear, professions, cooldowns, hence Alt Anon.
Also it provides a useful way to see missing enchants, gems, glyphs or ready cooldowns.

The addon uses IDs so should work in any language however labels are not localized.

Feel free to comment for additional features or suggestions.  
Or visit my dev discord: https://discord.gg/yY6Q6EgNRu

## Viewing Frame
You can view either via the mini icon or via the Looking For Group Frame (`i` by default) if available in the version of the game.
This can be disabled in the options menu, and replaced with a minimap icon.  
Otherwise `/ict` will bring up the window.  

## Multiple Accounts
You can link your account to share character data. Accounts must be BNet friends with each other.
Click the cogwheel in the lower, then on both accounts select the other to link. This will enable
cross character communication while both accounts are on the same realm and faction to share data. Blizzard
doesn't allow addon's to communicate across realms or faction.

## Information Collected
+ Character
    + Specs, Talents, Glyphs and Gear plus Durability
    + Shows missing Glyphs, Gems and Enchants
    + GearScore and iLvl if TacoTip addon is available
    + Professions
        + Clickable to bring up tradeskill frame.
    + Profession Cooldowns
        + Clickable to create the item if materials and location are met.
    + Level, XP, Rested XP, and Resting State
    + Guild and Guild Rank
    + Bags and Bank Bags
        + Shows Bags by type and individual Bags
        + Bank Bags requires you to view the bank
    + Gold
        + Shows Gold by realm
+ Instance 
    + Encounters completed and available
    + Lockout per character
    + Currency completed and available for the instance 
+ Currency
    + Total Instance Currency
    + Quest rewards Currency
    + Total Currency per character
+ Quests
    + Quest rewards
    + Quest completed per character
    + Prerequisites met per character
    + Quests are viewed by currency unless no currency associated.

## Options
+ Show Realm Name  
_Enables `[Realm] Player` versus `Player` for name fields._
+ Multi Player View  
_Shows all players side by side versus a single player._
+ Group Message  
_Enables messaging to your group collected currency, otherwise prints to your chat window only._
+ Characters  
_Enable/Disable the characters to appear in the dropdown list and multi player view._
+ Character Info  
_Enable/Disable line information about the character to appear under their name._  
+ Gear Info
_Enable/Disable information for the gear tab._  
+ Reset Timers  
_Show the one day, three day, five day, or weekly reset timers._  
_Note: three and five require you to complete a raid with those lockout as there's no API to access the data._  
+ Instances  
_Select the instances you wish to view, defaults to all WOTLK instances._  
+ Difficulty  
_The difficulty when queuing, normal, heroic, heroic+, heroic++, etc._  
+ Quests 
    + Hide unavailable Quests
    _Do not show quests that a character has not met the prequisite._  
    + Show Quests
    _Shows the quest section._  
    + Show Fishing Daily  
    _Shows the fishing daily quest, otherwise quests are controlled by currency._  
+ Currency  
_Select the currency you wish to view defaults to all currencies._
+ Cooldowns  
_Select the cooldowns you wish to view, sorted by expansion._
+ Frame  
    + Display  
    _Enable/Disable anchoring to the LFG frame and viewing the mini map icon._
    + Order Lock Last
    _Orders locked instances and completed quests after available instances and quests._
    + Simple Currency Tooltip  
    _Shows only current and available currency per player, otherwise includes instances and quests collected._
+ Minimum Character Level Slider  
_Controls the characters visible based on level._

## Color Codes
**Purple** Locked Instances and Completed Dailies  
**White** Available Instances and Dailies  
**Red** Dailies where you don't meet the prerequisites  

## Slash Commands
\# current player  
`/ict wipe`  
\# specific player  
`/ict wipe player [{REALM_NAME}] {PLAYER_NAME}`  
\# all players on realm  
`/ict wipe realm {REALM_NAME}`  
\# all players  
`/ict wipe all`
\# change font (recommended values 10-24)ß
`/ict font {number}
