import csv
from collections import OrderedDict
import requests
from lxml import html
import json

url = "https://wago.tools/db2"
response = requests.get(url)
tree = html.fromstring(response.content)
data = tree.xpath('//div[@id="app"]//@data-page')[0]
json_object = json.loads(data)
print(json_object["versions"])


files = {"DungeonEncounter", "GroupFinderActivity",
         "LFGDungeons", "MapDifficulty", "SpellItemEnchantment"}
for file in files:
    url = "https://wago.tools/db2/{0}/csv?build=3.4.3.51126".format(file)
    response = requests.get(url)
    open(file + ".csv", "wb").write(response.content)


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
ignored_sort = {"encounters"}


def to_string(v, level=0, ignore=False, sort=True):
    if type(v) is dict:
        if len(v) == 0:
            return "{}"
        newline = level == 0 or level == 1
        indent = "\n" + "    " * (level + 1) if newline else " "
        keys = list(v.keys())
        keys.sort()
        output = "{"
        for key in keys:
            ignored = key in ignored_zones
            sort = key not in ignored_sort
            comment = "--" if ignore or ignored else ""
            output += "{0}{1}{2} = {3},".format(
                indent,
                comment,
                key_string(v=key),
                to_string(v=v[key], level=level+1, ignore=ignored, sort=sort),
            )
        comment = "--" if ignore else ""
        output += "\n" + "    " * level + comment + "}" if newline else " }"
        return output
    elif type(v) is set:
        return to_string(list(v), sort=sort)
    elif type(v) is list:
        if len(v) == 0:
            return "{}"
        if sort:
            v.sort()
        return "{ " + ", ".join(map(lambda x: to_string(x, sort=sort), v)) + " }"
    elif type(v) is str:
        return "\"{0}\"".format(v)
    elif type(v) is bool:
        return "true" if v else "false"
    else:
        return str(v)


def read_spell_item_enchantment():
    with open("SpellItemEnchantment.csv") as file:
        csvreader = csv.reader(file)
        header = next(csvreader)

        for row in csvreader:
            enchantments[int(row[0])] = row[1]


def read_dungeons():
    with open("LFGDungeons.csv") as file:
        csvreader = csv.reader(file)
        header = next(csvreader)
        id_index = get_key(header, "MapID")
        difficulty_id_index = get_key(header, "DifficultyID")
        expansion_index = get_key(header, "ExpansionLevel")
        # name_index = get_key(header, "Name_lang")

        for row in csvreader:
            difficulty = int(row[difficulty_id_index])
            # skip open world (0) and vanilla dungeons (1) which have no lockout
            if difficulty == 0:
                continue
            key = int(row[id_index])
            if key not in infos:
                infos[key] = {"sizes": set(), "resets": {}, "encounters": OrderedDict(), "activities": {}}
            infos[key]["expansion"] = int(row[expansion_index])
        infos[249]["legacy"] = {"expansion": 0, "size": 40}


def read_dungeon_encounter(file_name, ids=None):
    with open(file_name) as file:
        csvreader = csv.reader(file)
        header = next(csvreader)
        id_index = get_key(header, "MapID")
        difficulty_index = get_key(header, "DifficultyID")
        order_index = get_key(header, "OrderIndex")
        name_index = get_key(header, "Name_lang")
        flags_index = get_key(header, "Flags")

        for row in csvreader:
            # Ignore Violet Hold bosses as they are random for the first 2 encounters.
            # Flags is probably a bit vector and this may be different in later expansions.
            flags = int(row[flags_index])
            if flags == 20:
                continue

            key = int(row[id_index])
            if key not in infos or (ids is not None and key not in ids):
                continue
            order = int(row[order_index])
            name = row[name_index]
            infos[key]["encounters"][order] = name
            difficulty = int(row[difficulty_index])
            if key not in name_to_difficulty:
                name_to_difficulty[key] = {}
            name_to_difficulty[key][name] = difficulty


def sort_encounters():
    # sort by order index
    for k, v in infos.items():
        sorted_v = []
        for _, encounter in sorted(v["encounters"].items()):
            sorted_v.append(encounter)
        infos[k]["encounters"] = sorted_v
        index = len(sorted_v)
        difficulty = 2
        while difficulty == 2:
            index -= 1
            difficulty = name_to_difficulty[k][sorted_v[index]]
        infos[k]["lastBossIndex"] = index + 1


def read_map_difficulty():
    reset_intervals = {1: 1, 2: 7, 3: 3, 4: 5}
    with open("MapDifficulty.csv") as file:
        csvreader = csv.reader(file)
        header = next(csvreader)
        id_index = get_key(header, "MapID")
        reset_index = get_key(header, "ResetInterval")
        max_players_index = get_key(header, "MaxPlayers")

        for row in csvreader:
            reset = int(row[reset_index])
            # skip instances with no lockout
            if reset == 0:
                continue
            key = int(row[id_index])
            if key not in infos:
                print("Missing Id: " + to_string(key))
                continue
            max_players = int(row[max_players_index])
            infos[key]["resets"][max_players] = reset_intervals[reset]
            infos[key]["sizes"].add(max_players)


def read_group_finder_activity():
    # activity_id_lookups = {
    #     0: {5: [285], 20: [290], 40: [290]},
    #     1: {5: [286], 10: [291], 25: [291]},
    #     2: {5: [287, 289, 311, 312, 314], 10: [292], 25: [293]},
    # }
    ignore_lfg_category = {116, 118, 120}
    ignore_names = {"Trial of the Grand Crusader"}
    with open("GroupFinderActivity.csv") as file:
        csvreader = csv.reader(file)
        header = next(csvreader)
        id_index = get_key(header, "MapID")
        value_index = get_key(header, "ID")
        name_index = get_key(header, "FullName_lang")
        # difficulty_index = get_key(header, "Field_3_4_0_43659_004")
        category_index = get_key(header, "GroupFinderCategoryID")
        max_players_index = get_key(header, "MaxPlayers")

        for row in csvreader:
            category = int(row[category_index])
            name = row[name_index]
            # Ignore outdoor zones, pvp, and customer
            if category in ignore_lfg_category or name in ignore_names:
                continue
            key = int(row[id_index])
            if key not in infos:
                print("Missing Id: " + to_string(key))
                continue
            # difficulty = int(row[difficulty_index])
            max_players = int(row[max_players_index])
            activities = infos[key]["activities"]
            if max_players not in activities:
                activities[max_players] = []
            activities[max_players].append(int(row[value_index]))


name_to_difficulty = {}
infos = {}
read_dungeons()
read_dungeon_encounter("DungeonEncounter-1.14.csv", ids={34, 289})
read_dungeon_encounter("DungeonEncounter.csv")
sort_encounters()
read_map_difficulty()
read_group_finder_activity()

f = open("instances.lua", "w")
f.write("infos = " + to_string(infos))
f.write("""

for k, v in pairs(infos) do
    infos[k] = Instances:new(v)
    v.id = k
end""")
f.close()

enchantments = {}
read_spell_item_enchantment()
f = open("items.lua", "w")
f.write("ICT.Enchants = " + to_string(enchantments))
f.close()
