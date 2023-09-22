# Instance and Currency Tracker
Tracks instance and currency information across all characters and realms on your account.
As well as other character information, such as gear, professions, cooldowns.
Useful way to see missing enchants, gems, glyphs or ready cooldowns.

By default shows a single character view with tooltips to compare, this can be changed
under 'Options' to show multiple characters. See additional configuritions under [Options] for more details.
Be sure to hover over items to see tooltips for more details.

The addon uses IDs so should work in any language however labels are not localized.

Feel free to comment for additional features or suggestions.

## Queuing
For the current player, you can queue to a single instance or all unlocked instances by the icon for the instance type.
You can dequeue by clicking the instance again or the icon which will dequeue all instances. 

By default, the difficulty is set to the highest (as of phase 3 that's Titan Runed Beta). However you can select which difficulty under the options
tab. If multiple difficulties are selected, you will be queued to all types for that instance. Currently, difficulty is _not_ per character but account wide.

Note: Blizzard does not let you queue across instance types. i.e. You cannot queue to dungeons and raids.

## Viewing Frame
By default the addon window is anchored to the Looking For Group Frame (`i` by default).  
This can be disabled in the options menu, and replaced with a minimap icon.  
Otherwise `/ict` will bring up the window.  

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
    + Available and Total Currency per character
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
    + Order Lock Last"  
    _Orders locked instances and completed quests after available instances and quests._
    + Verbose Currency  
    _Multi-line currency versus single line currency information_
    + Simple Currency Tooltip  
    _Shows only current and available currency per player, otherwise includes instances and quests collected._
+ Minimum Character Level Slider  
_Controsl the characters visible based on level._

## Color Codes
**Purple** Locked Instances and Completed Dailies  
**White** Available Instances and Dailies  
**Red** Dailies where you don't meet the prerequisites  

## Wiping Data
\# current player  
`/ict wipe`  
\# specific player  
`/ict wipe player [{REALM_NAME}] {PLAYER_NAME}`  
\# all players on realm  
`/ict wipe realm {REALM_NAME}`  
\# all players  
`/ict wipe all`