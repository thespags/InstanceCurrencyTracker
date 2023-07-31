# Instance and Currency Tracker
Tracks instance and currency information across all characters and realms on your account.
The window is very configurable see [Options] for details.

The addon uses IDs so should work in any language however labels are not localized.

Feel free to comment for additional features or suggestions.

## Viewing Frame
By default the addon window is anchored to the Looking For Group Frame (`i` by default).  
This can be disabled in the options menu, and replaced with a minimap icon.  
Otherwise `/ict` will bring up the window.  

## Information Collected
+ Instance lockout and encounter information  
+ Currency available for an instance  
+ Total currency in an instance  
+ Currency collected and available for each character  
+ Daily quest completed and prerequisites met  

## Options
+ Show Realm Name  
_Enables `[Realm] Player` versus `Player` for name fields._
+ Verbose Currency  
_Multi-line currency versus single line currency information_
+ Simple Currency Tooltip  
_Shows only current and available currency per player, otherwise includes instances and quests collected._
+ Group Message
_Enables messaging to your group collected currency, otherwise prints to your chat window only._
+ Reset Timers
_Show the one day, three day, five day, or weekly reset timers._  
_Note: three and five require you to complete a raid with those lockout as there's no API to access the data._  
+ Instances  
_Select the instances you wish to view, defaults to all WOTLK instances._
+ All Quests  
_Shows all quests including those you have not met the prerequisite for._
+ Currency  
_Select the currency you wish to view defaults to all currencies._
+ Display
_Enable/Disable anchoring to the LFG frame and viewing the mini map icon._

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
