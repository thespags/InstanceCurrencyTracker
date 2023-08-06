# Instance and Currency Tracker
Tracks instance and currency information across all characters and realms on your account.
By default shows a single character view with tooltips to compare, this can be changed
under 'Options' to show multiple characters. See additional configuritions under [Options] for more details.
Be sure to hover over items to see tooltips for more details.

The addon uses IDs so should work in any language however labels are not localized.

Feel free to comment for additional features or suggestions.

## Viewing Frame
By default the addon window is anchored to the Looking For Group Frame (`i` by default).  
This can be disabled in the options menu, and replaced with a minimap icon.  
Otherwise `/ict` will bring up the window.  

## Information Collected
+ Character
 + Specs and Talents
 + GearScore and iLvl if TacoTip addon is available
 + Professions
+ Instance lockout and encounter information  
+ Currency available for an instance  
+ Total currency in an instance  
+ Currency collected and available for each character  
+ Daily quest completed and prerequisites met  
+ Feature needed is enabling profession quests, pvp, and pre WOTLK currencies.

## Options
+ Show Realm Name  
_Enables `[Realm] Player` versus `Player` for name fields._
+ Multi Player View  
_Shows all players side by side versus a single player._
+ Group Message  
_Enables messaging to your group collected currency, otherwise prints to your chat window only._
+ Players
_Enable/Disable the players to appear in the dropdown list and multi player view._
+ Reset Timers  
_Show the one day, three day, five day, or weekly reset timers._  
_Note: three and five require you to complete a raid with those lockout as there's no API to access the data._  
+ Instances  
_Select the instances you wish to view, defaults to all WOTLK instances._
+ All Quests  
_Shows all quests including those you have not met the prerequisite for._
+ Currency  
_Select the currency you wish to view defaults to all currencies._
+ Frame  
    + Display  
    _Enable/Disable anchoring to the LFG frame and viewing the mini map icon._
    + Order Lock Last"
    _Orders locked instances and completed quests after available instances and quests._
    + Verbose Currency  
    _Multi-line currency versus single line currency information_
    + Simple Currency Tooltip  
    _Shows only current and available currency per player, otherwise includes instances and quests collected._

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
