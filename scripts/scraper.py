import csv
import pprint
import sys
import urllib.request
from collections import OrderedDict


def get_key(header, value):
    for i, x in enumerate(header):
        if x == value:
            return i
    raise Exception("value doesn't exist")


def key_string(v):
    if type(v) is str:
        return str(v)
    elif type(v) is int:
        return "[{0}]".format(v)
    else:
        raise Exception("unknown key type")


# A complicated thing of sorting and new lines to print a python map as a lua map.
# Some things we want sorted for readability, map keys, number lists.
# Other things we don't want sorted like encounter order.
ignored_zones = {631, 632, 658, 668, 724}

def to_string(v, newline=True, sort=True):
    if type(v) is dict:
        keys = list(v.keys())
        keys.sort()
        output = "{"
        indent = "\n    " if newline else " "
        for key in keys:
            comment = "--" if key in ignored_zones else ""
            output += indent + "{2}{0} = {1},".format(
                key_string(v=key),
                to_string(v=v[key], newline=False, sort=sort),
                comment
            )
        output += "\n}" if newline else " }"
        return output
    elif type(v) is set:
        return to_string(list(v), sort=sort)
    elif type(v) is list:
        if sort:
            v.sort()
        return "{ " + ", ".join(map(lambda x: to_string(x, sort=sort), v)) + " }"
    elif type(v) is str:
        return "\"{0}\"".format(v)
    elif type(v) is bool:
        return "true" if v else "false"
    else:
        return str(v)


enchantments = {}
with open("SpellItemEnchantment.csv") as file:
    csvreader = csv.reader(file)
    header = next(csvreader)

    for row in csvreader:
        enchantments[int(row[0])] = row[1]

encounters = {}
with open("DungeonEncounter.csv") as file:
    csvreader = csv.reader(file)
    header = next(csvreader)
    idIndex = get_key(header, "MapID")
    orderIndex = get_key(header, "OrderIndex")
    nameIndex = get_key(header, "Name_lang")

    for row in csvreader:
        key = int(row[idIndex])
        if key not in encounters:
            encounters[key] = OrderedDict()
        encounters[key][int(row[orderIndex])] = row[nameIndex]
    # sort by order index
    for k, v in encounters.items():
        sortedV = []
        for _, encounter in sorted(v.items()):
            sortedV.append(encounter)
        encounters[k] = sortedV

difficulties = {}
with open("Difficulty.csv") as file:
    csvreader = csv.reader(file)
    header = next(csvreader)
    idIndex = get_key(header, "ID")
    maxPlayersIndex = get_key(header, "MaxPlayers")

    for row in csvreader:
        difficulties[int(row[idIndex])] = int(row[maxPlayersIndex])

resetIntervals = {1: 1, 2: 7, 3: 3, 4: 5}
resets = {}
with open("MapDifficulty.csv") as file:
    csvreader = csv.reader(file)
    header = next(csvreader)
    idIndex = get_key(header, "MapID")
    resetIndex = get_key(header, "ResetInterval")
    maxPlayersIndex = get_key(header, "MaxPlayers")

    for row in csvreader:
        reset = int(row[resetIndex])
        # skip instances with no lockout
        if reset == 0:
            continue
        id = int(row[idIndex])
        if id not in resets:
            resets[id] = {}
        maxPlayers = int(row[maxPlayersIndex])
        resets[id][maxPlayers] = resetIntervals[reset]

activityIdLookups = {
    0: {5: [285], 20: [290], 40: [290]},
    1: {5: [286], 20: [291], 40: [291]},
    2: {5: [287, 289, 311, 312, 314], 20: [292], 40: [293]},
}

ignore_lfg_category = {116, 118, 120}
activities = {}
with open("GroupFinderActivity.csv") as file:
    csvreader = csv.reader(file)
    header = next(csvreader)
    idIndex = get_key(header, "MapID")
    valueIndex = get_key(header, "ID")
    difficultyIndex = get_key(header, "Field_3_4_0_43659_004")
    categoryIndex = get_key(header, "GroupFinderCategoryID")

    for row in csvreader:
        category = int(row[categoryIndex])
        # Ignore outdoor zones, pvp, and customer
        if category in ignore_lfg_category:
            continue
        id = int(row[idIndex])
        if id not in activities:
            activities[id] = {}
        difficulty = int(row[difficultyIndex])
        activities[id][difficulty] = int(row[valueIndex])

expansions = {}
with open("LFGDungeons.csv") as file:
    csvreader = csv.reader(file)
    header = next(csvreader)
    idIndex = get_key(header, "MapID")
    difficultyIdIndex = get_key(header, "DifficultyID")
    expansionIndex = get_key(header, "ExpansionLevel")
    nameIndex = get_key(header, "Name_lang")

    for row in csvreader:
        difficulty = int(row[difficultyIdIndex])
        # skip open world (0) and vanilla dungeons (1) which have no lockout
        if difficulty == 0 or difficulty == 1:
            continue
        id = int(row[idIndex])
        if id not in expansions:
            expansions[id] = {}
        expansions[id]["expansion"] = int(row[expansionIndex])
        expansions[id]["id"] = id
        size = difficulties[difficulty]
        prev = expansions[id].get("size", size)
        expansions[id]["size"] = min(prev, size)
    expansions[249]["legacy"] = 0
    expansions[249]["legacySize"] = 40

f = open("instances.lua", "w")
f.write("Instances.Encounters = " + to_string(encounters, sort=False))
f.write("\n\n-- Size here is the smallest for the specific raid, we use this for sorting.")
f.write("\nInstances.Expansions = " + to_string(expansions))
f.write("\n\n-- Corresponds to the number of days on the lockout for the size.")
f.write("\nInstances.Resets = " + to_string(resets))
f.write("\n\n-- How to find the activity id for a specific zone, size and difficulty.")
f.write("\nInstances.ActivityIdLookups = " + to_string(activityIdLookups))
f.write("\n\n-- The id for LFG selection.")
f.write("\nInstances.Activities = " + to_string(activities))
f.close()

f = open("items.lua", "w")
f.write("ICT.Enchants = " + to_string(enchantments))
f.close()
