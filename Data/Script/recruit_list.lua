require 'common'

RECRUIT_LIST = {}
--[[
    recruit_list.lua

    This file contains all functions necessary to generate Recruitment Lists for dungeons, as well as
    the routine used to show the list itself
]]--

-- -----------------------------------------------
-- Constants
-- -----------------------------------------------
-- Modes
RECRUIT_LIST.hide =                    0
RECRUIT_LIST.unrecruitable_not_seen =  1
RECRUIT_LIST.not_seen =                2
RECRUIT_LIST.unrecruitable =           3
RECRUIT_LIST.seen =                    4
RECRUIT_LIST.floor_seen =              5  --TODO we just keep this for the future
RECRUIT_LIST.extra_seen =              6
RECRUIT_LIST.obtained =                7
RECRUIT_LIST.floor_obtained =          8  --TODO we just keep this for the future
RECRUIT_LIST.extra_obtained =          9
RECRUIT_LIST.obtainedMultiForm =       10
RECRUIT_LIST.floor_obtainedMultiForm = 11 --TODO we just keep this for the future
RECRUIT_LIST.extra_obtainedMultiForm = 12

-- Mode colors
RECRUIT_LIST.colorList = { '#989898', '#FFFFFF', '#989898', '#FFFFFF', '#FFFFFF', '#00FFFF', '#FFFF00', '#FFFF00', '#FFFFA0', '#FFA500', '#FFA500', '#FFE0A0'}
RECRUIT_LIST.colorError = '#FF0000'

-- Mode patterns
-- {pattern, spacing, show_always}
RECRUIT_LIST.patternList = {
    {        '\u{E10B}{t}', 10, false},
    {                '???',  0, false},
    {        '\u{E10B}???', 10, false},
    {                '{t}',  0, false},
    {               '*{t}',  6,  true},
    {        '\u{E111}{t}', 10, false},
    {        '{t}\u{E10C}',  0, false},
    {       '*{t}\u{E10C}',  6,  true},
    {'\u{E111}{t}\u{E10C}', 10, false},
    {        '{t}\u{E10D}',  0, false},
    {       '*{t}\u{E10D}',  6,  true},
    {'\u{E111}{t}\u{E10D}', 10, false}
}

-- Info menu content
RECRUIT_LIST.info_list_title = "Recruitment List Info"
RECRUIT_LIST.info_colors_title = "Recruitment List Colors"
RECRUIT_LIST.info_list = {
    -- page 1
    {
        "The [color=#00FFFF]Recruitment List[color], as the name suggests,",
        "shows the list of Pokémon that can be recruited",
        "in a dungeon. If a Pokémon has not been",
        "registered yet, it will be listed as a \"???\".",
        "",
        "The [color=#00FFFF]Recruitment List[color] works differently depending",
        "on where you are: If you're inside of a [color=#FFC060]Dungeon[color],",
        "it will show you the list of recruitable Pokémon",
        "on the current floor. If not, it will show the",
        "list of all Pokémon in a [color=#FFC060]Dungeon[color] instead."
    },
    -- page 2
    {
        "When inside a [color=#FFC060]Dungeon[color], the current floor will be",
        "scanned, and the List will not only contain all",
        "species that can spawn naturally in there, but",
        "also all Pokémon that are currently on the floor",
        "but are not supposed to appear normally."--[[.." If a",]] --TODO we just keep this for the future
--        "Pokémon is marked with an \"*\", that means it can",
--        "spawn on the floor but it is not guaranteed to,",
--        "and it will not respawn upon defeat."
    },
    -- page 3
    {
        "Be careful: if on your floor there's a Pokémon",
        "you never met before and that is not part of",
        "the floor's spawn list, it will not appear in",
        "the [color=#00FFFF]Recruitment List[color] regardless of",
        "whether or not it can be recruited."
    },
    -- page 4
    {
        "When not in a [color=#FFC060]Dungeon[color], you have the option to",
        "choose any [color=#FFC060]Dungeon[color] you have ever visited.",
        "Doing so will open a detailed list of all Pokémon",
        "available in the portion of that [color=#FFC060]Dungeon[color] that you",
        "have already explored, complete with the floor",
        "ranges at which they can appear.",
        "You will only see the spawn list for the [color=#FFC060]Dungeon[color]",
        "in question, as explained in the Color list.",
        "[color=#FF0000]WARNING[color]: The bigger dungeons can take a bit",
        "to load."
    },
    -- page 5
    {
        "This mod comes with a [color=#FFFF00]Spoiler Mode[color] that",
        "obscures the current floor's [color=#00FFFF]Recruitment List[color]",
        "during your first visit.",
        "There is also an accessibility option, active",
        "by default, that uses icons on top of coloring",
        "the various entries of the list.",
        "You can toggle these modes from the Options",
        "menu, accessible only outside of [color=#FFC060]Dungeons[color]."
    }
}
RECRUIT_LIST.postgame_message = {
    "The title of [color=#FFA0FF]Guildmaster[color] grants you the ability",
    "to see which [color=#FFC060]Dungeons[color] still contain unexplored",
    "sections. You will not be able to open their",
    "[color=#00FFFF]Recruitment List[color] until you enter them, though.",
    "",
    "This function is only active if [color=#FFFF00]Spoiler Mode[color]",
    "is turned off."
}

RECRUIT_LIST.dev_RecruitFilter = {
    -- icon mode
    {
        "[color=#FFA0FF]DEV MODE ONLY[color]:",
        "Being in [color=#FFA0FF]Dev Mode[color] grants you the ability to see",
        "even Pokémon that are in a [color=#FFC060]Dungeon[color]'s spawn list",
        "but cannot be recruited. These Pokémon will",
        "appear \u{E10B}[color=#989898]greyed out[color] in the [color=#00FFFF]Recruitment List[color]."
    },
    -- no icon mode
    {
        "[color=#FFA0FF]DEV MODE ONLY[color]:",
        "Being in [color=#FFA0FF]Dev Mode[color] grants you the ability to see",
        "even Pokémon that are in a [color=#FFC060]Dungeon[color]'s spawn list",
        "but cannot be recruited. These Pokémon will",
        "appear [color=#989898]greyed out[color] in the [color=#00FFFF]Recruitment List[color]."
    }
}
-- Colors menu content
RECRUIT_LIST.info_colors = {
    -- page 1
    {
        "Colors used for Pokémon that keep appearing",
        "as long as you stay in this Dungeon:",
        "",
        "???(White): You have never met this Pokémon.",
        "White: You have never recruited this Pokémon.",
        "[color=#FFFF00]Yellow[color]\u{E10C}: You have recruited this Pokémon.",
        "[color=#FFA500]Orange[color]\u{E10D}: You have recruited this Pokémon, but it",
        "  has multiple forms and the Recruitment List",
        "  cannot tell which ones nor how many you have."
    },
    -- page 2
    {
        "Colors used for Pokémon that appeared in",
        "special circumstances (only shown in floor):",
        "",
        "\u{E111}[color=#00FFFF]Cyan[color]: You have never recruited this Pokémon.",
        "\u{E111}[color=#FFFFA0]Faded Yellow[color]\u{E10C}: You have recruited this",
        "  Pokémon.",
        "\u{E111}[color=#FFE0A0]Faded Orange[color]\u{E10D}: You have recruited this",
        "  Pokémon, but it has multiple forms and the ",
        "  Recruitment List cannot tell which ones nor",
        "  how many you have."
    }
}

RECRUIT_LIST.info_colors_iconless = {
    -- page 1
    {
        "Colors used for Pokémon that keep appearing",
        "as long as you stay in this Dungeon:",
        "",
        "???(White): You have never met this Pokémon.",
        "White: You have never recruited this Pokémon.",
        "[color=#FFFF00]Yellow[color]: You have recruited this Pokémon.",
        "[color=#FFA500]Orange[color]: You have recruited this Pokémon, but it",
        "  has multiple forms and the Recruitment List",
        "  cannot tell which ones nor how many you have."
    },
    -- page 2
    {
        "Colors used for Pokémon that appeared in",
        "special circumstances (only shown in floor):",
        "",
        "[color=#00FFFF]Cyan[color]: You have never recruited this Pokémon.",
        "[color=#FFFFA0]Faded Yellow[color]: You have recruited this Pokémon.",
        "[color=#FFE0A0]Faded Orange[color]: You have recruited this Pokémon,",
        "  but it has multiple forms and the Recruitment",
        "  List cannot tell which ones nor how many you",
        "  have."
    }
}
-- -----------------------------------------------
-- SV structure
-- -----------------------------------------------
-- Returns if the game has been completed or not
function RECRUIT_LIST.gameCompleted()
    if SV.guildmaster_summit.GameComplete == nil then SV.guildmaster_summit.GameComplete = false end -- if true, hides the recruit list if it's the player's first time on a floor
    return SV.guildmaster_summit.GameComplete
end

-- Returns the current state of Spoiler Mode
function RECRUIT_LIST.spoilerMode()
    SV.Services = SV.Services or {}
    if SV.Services.RecruitList_spoiler_mode == nil then SV.Services.RecruitList_spoiler_mode = false end -- if true, hides the recruit list if it's the player's first time on a floor
    return SV.Services.RecruitList_spoiler_mode
end

-- Toggles the current state of Spoiler Mode
function RECRUIT_LIST.toggleSpoilerMode()
    if RECRUIT_LIST.spoilerMode() then SV.Services.RecruitList_spoiler_mode = false else
        SV.Services.RecruitList_spoiler_mode = true
    end
end

-- Returns the current state of Show Unrecruitable
function RECRUIT_LIST.showUnrecruitable()
    SV.Services = SV.Services or {}
    if SV.Services.RecruitList_show_unrecruitable == nil then SV.Services.RecruitList_show_unrecruitable = false end
    -- always shows unrecruitable in dev mode
    return SV.Services.RecruitList_show_unrecruitable or RogueEssence.DiagManager.Instance.DevMode
end

-- Toggles the current state of Show Unrecruitable
function RECRUIT_LIST.toggleShowUnrecruitable()
    if RECRUIT_LIST.showUnrecruitable() then SV.Services.RecruitList_show_unrecruitable = false else
        SV.Services.RecruitList_show_unrecruitable = true
    end
end

-- Returns the current state of Show Unrecruitable
function RECRUIT_LIST.iconMode()
    SV.Services = SV.Services or {}
    if SV.Services.RecruitList_icon_mode == nil then SV.Services.RecruitList_icon_mode = true end
    -- always shows unrecruitable in dev mode
    return SV.Services.RecruitList_icon_mode
end

-- Toggles the current state of Show Unrecruitable
function RECRUIT_LIST.toggleIconMode()
    if RECRUIT_LIST.iconMode() then SV.Services.RecruitList_icon_mode = false else
        SV.Services.RecruitList_icon_mode = true
    end
end



-- Initializes the basic dungeon list data structure
function RECRUIT_LIST.generateDungeonListBaseSV()
    SV.Services = SV.Services or {}
    SV.Services.RecruitList = SV.Services.RecruitList or {}
end

-- Initializes the data slot for the supplied segment if not already present
function RECRUIT_LIST.generateDungeonListSV(zone, segment)
    RECRUIT_LIST.generateDungeonListBaseSV()
    SV.Services.RecruitList[zone] = SV.Services.RecruitList[zone] or {}

    -- update old data if present
    local defaultFloor = 0
    if type(SV.Services.RecruitList[zone][segment]) == "number" then
        defaultFloor = SV.Services.RecruitList[zone][segment]
        SV.Services.RecruitList[zone][segment] = nil
    end

    if not SV.Services.RecruitList[zone][segment] then
        local segment_data = _DATA:GetZone(zone).Segments[segment]
        SV.Services.RecruitList[zone][segment] = {
            --TODO we just keep this for the future
--            special = {},                           -- {species -> species} list of pokémon to be listed with no specific floor, ordered by dex number.
            reload = false,                         -- if true, need to reload list. useless if list does not exist
            floorsCleared = defaultFloor,           -- number of floors cleared in the dungeon
            totalFloors = segment_data.FloorCount,  -- total amount of floors in this segment
            completed = false,                      -- true if the dungeon has been completed
            name = "Segment "..tostring(segment),   -- segment display name
        }

        local name = RECRUIT_LIST.build_segment_name(segment_data)
        SV.Services.RecruitList[zone][segment].name = name
    end
end

-- returns the name of the provided segment
function RECRUIT_LIST.build_segment_name(segment_data)
    local segSteps = segment_data.ZoneSteps
    local sub_name = {}
    local exit = false
    -- look for a title property to extract the name from
    for j = 0, segSteps.Count-1, 1 do
        local step = segSteps[j]
        if RECRUIT_LIST.getClass(step) == "PMDC.LevelGen.FloorNameDropZoneStep" then
            exit = true
            local name = step.Name:ToLocal()
            for substr in name:gmatch(("[^\r\n]+")) do
                table.insert(sub_name,substr)
            end
        end
        if exit then break end
    end

    local stringbuild = sub_name[1] --no i don't come from Java as well what makes you think that
    -- build the name out of the found property
    for i=2, #sub_name, 1 do
        -- look for a floor counter in this string piece
        local result = string.match(sub_name[i], "(%a?){0}")
        if result == nil then -- if not found
            stringbuild = stringbuild.." "..sub_name[i] -- add to the name string
        end
    end
    return stringbuild
end

function RECRUIT_LIST.updateSegmentName(zone, segment)
    local segment_data = _DATA:GetZone(zone).Segments[segment]
    local name = RECRUIT_LIST.build_segment_name(segment_data)
    SV.Services.RecruitList[zone][segment].name = name
end

-- Returns the basic dungeon list data structure
function RECRUIT_LIST.getDungeonListSV()
    RECRUIT_LIST.generateDungeonListBaseSV()
    return SV.Services.RecruitList
end

-- Returns the number of floors cleared on the provided segment
function RECRUIT_LIST.getFloorsCleared(zone, segment)
    RECRUIT_LIST.generateDungeonListSV(zone, segment)
    return SV.Services.RecruitList[zone][segment].floorsCleared
end

-- Updates the number of floors cleared on the provided segment
-- if the provided floor number is higher than the currently stored one
function RECRUIT_LIST.updateFloorsCleared(zone, segment, floor)
    if RECRUIT_LIST.checkFloor(zone, segment, floor) then
        SV.Services.RecruitList[zone][segment].floorsCleared = floor
    end
end

-- Marks the provided segment as a completed area
function RECRUIT_LIST.markAsCompleted(zone, segment)
    local sv = RECRUIT_LIST.getDungeonListSV()
    if sv[zone] and sv[zone][segment] then
        SV.Services.RecruitList[zone][segment].completed = true
    end
end

-- Checks if the supplied location floor is higher than the highest reached floor in the current segment
-- if no location is supplied then it uses the current location
-- location is a table of properties {string zone, int segment, int floor}
function RECRUIT_LIST.checkFloor(zone, segment, floor)
    if not zone or not segment or not floor then
        local loc = RECRUIT_LIST.getCurrentMap()
        zone = loc.zone
        segment = loc.segment
        floor = loc.floor
    end
    return RECRUIT_LIST.getFloorsCleared(zone, segment) < floor
end

-- Marks the segment as pending for an extra spawn list update.
function RECRUIT_LIST.markForUpdate(zone, segment)
    RECRUIT_LIST.markAsExplored(zone, segment)
    RECRUIT_LIST.generateDungeonListSV(zone, segment)
    SV.Services.RecruitList[zone][segment].reload = true
end

-- Adds a new Pokémon to the segment's extra recruit list TODO we just keep this for the future
--[[function RECRUIT_LIST.registerExtraRecruit(zone, segment, monster)
    local data = RECRUIT_LIST.getSegmentData(zone, segment)
    if data.special[monster] then return end -- discard if not new
    data.special[monster] = monster
end]]

-- Returns a segment's spawn list data structure
function RECRUIT_LIST.getSegmentData(zone, segment)
    RECRUIT_LIST.generateDungeonListSV(zone, segment)
    return SV.Services.RecruitList[zone][segment]
end

-- Returns whether or not a segment's spawn list data structure exists
function RECRUIT_LIST.segmentDataExists(zone, segment)
    return SV.Services and SV.Services.RecruitList and SV.Services.RecruitList[zone]
            and SV.Services.RecruitList[zone][segment]
end


-- Generates the data slot for dungeon order if not already present
function RECRUIT_LIST.generateOrderSV()
    SV.Services = SV.Services or {}
    SV.Services.RecruitList_DungeonOrder = SV.Services.RecruitList_DungeonOrder or {}
end

-- Returns the ordered list of all explored dungeons
function RECRUIT_LIST.getDungeonOrder()
    RECRUIT_LIST.generateOrderSV()
    return SV.Services.RecruitList_DungeonOrder
end

-- Checks if the player has visited at list one dungeon segment that contains spawn data
function RECRUIT_LIST.hasVisitedValidDungeons()
    return #RECRUIT_LIST.getDungeonOrder() > 0
end

-- Adds the supplied dungeon to the ordered list of explored areas if the section
-- has spawn data and the zone is not already part of the list
function RECRUIT_LIST.markAsExplored(zone, segment)

    if RECRUIT_LIST.isSegmentValid(zone, segment) then
        local zone_data = _DATA:GetZone(zone)

        local entry = {
            zone = zone,
            cap = zone_data.LevelCap,
            level = zone_data.Level,
            length = zone_data:GenerateEntrySummary().CountedFloors,
            name = zone_data.Name:ToLocal()
        }
        --mark as completed if necessary
        if not RECRUIT_LIST.checkFloor(zone, segment, RECRUIT_LIST.getSegmentData(zone, segment).totalFloors) then
            RECRUIT_LIST.markAsCompleted(zone, segment)
        end

        --add to list if not already present
        for i=1, #RECRUIT_LIST.getDungeonOrder(), 1 do
            local other = RECRUIT_LIST.getDungeonOrder()[i]
            -- if found then update data
            if entry.zone == other.zone then
                other.name = entry.name -- update name data if necessary
                other.length = zone_data:GenerateEntrySummary().CountedFloors --fix for old summary error
                return
            end
            -- if not found then add to list
            if RECRUIT_LIST.sortZones(entry, other) then
                table.insert(RECRUIT_LIST.getDungeonOrder(), i, entry)
                return
            end
        end
        table.insert(RECRUIT_LIST.getDungeonOrder(), entry)
    elseif not RECRUIT_LIST.getSegmentData(zone, segment).completed then
        --mark as completed if necessary
        if not RECRUIT_LIST.checkFloor(zone, segment, RECRUIT_LIST.getSegmentData(zone, segment).totalFloors) then
            RECRUIT_LIST.markAsCompleted(zone, segment)
        end
    end
end

-- sort function that sorts dungeons by recommended level and length, leaving reset dungeons always last
function RECRUIT_LIST.sortZones(a, b)
    -- put level-reset dungeons at the end
    if a.cap ~= b.cap then return b.cap end
    -- order non-level-reset dungeons by ascending recommended level
    if not a.cap and a.level ~= b.level then return a.level < b.level end
    -- order dungeons by ascending length
    if a.length ~= b.length then return a.length < b.length end
    -- order dungeons alphabetically
    return a.zone < b.zone
end

-- -----------------------------------------------
-- Functions
-- -----------------------------------------------
-- Applies a pattern and wraps the supplied monster's name with a color bracket.
-- Color bracket and pattern are corresponding to mode.
-- Returns both the fully compiled text and the spacing it requires.
function RECRUIT_LIST.formatName(monster, mode)
    local name = _DATA:GetMonster(monster).Name:ToLocal()
    local pattern = RECRUIT_LIST.tri(mode>0, RECRUIT_LIST.patternList[mode], RECRUIT_LIST.patternList[4])
    local color = RECRUIT_LIST.tri(mode>0, RECRUIT_LIST.colorList[mode], RECRUIT_LIST.colorError)

    if pattern[3] or RECRUIT_LIST.iconMode() then name = string.gsub(pattern[1], "{t}", name) end
    local spacing = RECRUIT_LIST.tri(pattern[3] or RECRUIT_LIST.iconMode(), pattern[2], 0)
    return '[color='..color..']'..name..'[color]', spacing
end

-- returns the current map as a table of properties {string zone, int segment, int floor}
function RECRUIT_LIST.getCurrentMap()
    local mapData = {
        zone = _ZONE.CurrentZoneID,
        segment = _ZONE.CurrentMapID.Segment,
        floor = GAME:GetCurrentFloor().ID + 1
    }
    return mapData
end

-- TODO remove in final version... or not
function RL_printall(table, level, root)
    if root == nil then print(" ") end

    if table == nil then print("<nil>") return end
    if level == nil then level = 0 end
    for key, value in pairs(table) do
        local spacing = ""
        for _=1, level*2, 1 do
            spacing = " "..spacing
        end
        if type(value) == 'table' then
            print(spacing..tostring(key).." = {")
            RL_printall(value,level+1, false)
            print(spacing.."}")
        else
            print(spacing..tostring(key).." = "..tostring(value))
        end
    end

    if root == nil then print(" ") end
end

-- Checks if the specified dungeon segment has been visited and contains spawn data
function RECRUIT_LIST.isSegmentValid(zone, segment, segmentData, includeNotExplored)

    if not segmentData then segmentData = _DATA:GetZone(zone).Segments[segment] end --load data now if not already

    if not includeNotExplored and (not SV.Services or not SV.Services.RecruitList or not SV.Services.RecruitList[zone] or not SV.Services.RecruitList[zone][segment]) then return false end

    if not includeNotExplored and RECRUIT_LIST.getSegmentData(zone, segment).floorsCleared <= 0 then return false end
    if RECRUIT_LIST.getSegmentData(zone, segment).special and #RECRUIT_LIST.getSegmentData(zone, segment).special>0 then
        return true
    end
    local segSteps = segmentData.ZoneSteps
    for i = 0, segSteps.Count-1, 1 do
        local step = segSteps[i]
        if RECRUIT_LIST.getClass(step) == "RogueEssence.LevelGen.TeamSpawnZoneStep" then
            return true
        end
    end
    return false
end

-- Returns a list of all segments of a zone that have a spawn property and of which
-- at least 1 floor was completed.
-- Return is a list of tables with properties {int id, string name, boolean completed}
function RECRUIT_LIST.getValidSegments(zone)
    local list = {}

    if not RECRUIT_LIST.gameCompleted() or RECRUIT_LIST.spoilerMode() then
        local segments = RECRUIT_LIST.getDungeonListSV()[zone]
        if segments == nil then return list end
        for i, segment in pairs(segments) do
            if RECRUIT_LIST.isSegmentValid(zone, i) then
                local entry = {
                    id = i,
                    name = segment.name,
                    completed = segment.completed,
                    floorsCleared = segment.floorsCleared
                }
                table.insert(list,entry)
            end
        end
    else
        local segmentsData = _DATA:GetZone(zone).Segments
        for i=0, segmentsData.Count-1, 1 do
            local seg_data = RECRUIT_LIST.getSegmentData(zone, i)
            if RECRUIT_LIST.isSegmentValid(zone, i, nil, true) then
                local entry = {
                    id = i,
                    name = seg_data.name,
                    completed = seg_data.completed,
                    floorsCleared = seg_data.floorsCleared
                }
                table.insert(list,entry)
            end
        end
    end
    return list
end

-- Extracts a list of all mons spawnable in a dungeon, then maps them to the display mode that
-- should be used for that mon's name in the menu. Includes only mons that can respawn.
function RECRUIT_LIST.compileFullDungeonList(zone, segment)
    local species = {}  -- used to compact multiple entries that contain the same species
    local list = {}     -- list of all keys in the list. populated only at the end

    RECRUIT_LIST.generateDungeonListSV(zone, segment)
    local segmentData = _DATA:GetZone(zone).Segments[segment]
    local segSteps = segmentData.ZoneSteps
    local highest = RECRUIT_LIST.getFloorsCleared(zone,segment)
    for i = 0, segSteps.Count-1, 1 do
        local step = segSteps[i]
        if RECRUIT_LIST.getClass(step) == "RogueEssence.LevelGen.TeamSpawnZoneStep" then
            local entry_list = {}

            -- Check Spawns
            local spawnlist = step.Spawns
            for j=0, spawnlist.Count-1, 1 do
                local range = spawnlist:GetSpawnRange(j)
                local spawn = spawnlist:GetSpawn(j).Spawn
                local entry = {
                    min = range.Min+1,
                    max = math.min(range.Max, segmentData.FloorCount),
                    species = spawn.BaseForm.Species,
                    mode = RECRUIT_LIST.not_seen, -- defaults to "???". this will be calculated later
                }
                -- check if the mon is recruitable
                local recruitable = true
                local features = spawn.SpawnFeatures
                for f = 0, features.Count-1, 1 do
                    if RECRUIT_LIST.getClass(features[f]) == "PMDC.LevelGen.MobSpawnUnrecruitable" then
                        recruitable = false
                        entry.mode = RECRUIT_LIST.unrecruitable
                    end
                end
                if recruitable or RECRUIT_LIST.showUnrecruitable() then
                    table.insert(entry_list, entry)
                end
            end

            -- Check Specific Spawns
            spawnlist = step.SpecificSpawns -- SpawnRangeList
            for j=0, spawnlist.Count-1, 1 do
                local range = spawnlist:GetSpawnRange(j)
                local spawns = spawnlist:GetSpawn(j):GetPossibleSpawns() -- SpawnList
                for s=0, spawns.Count-1, 1 do
                    local spawn = spawns:GetSpawn(s)

                    local entry = {
                        min = range.Min+1,
                        max = math.min(range.Max, segmentData.FloorCount),
                        species = spawn.BaseForm.Species,
                        mode = RECRUIT_LIST.not_seen, -- defaults to "???". this will be calculated later
                    }
                    -- check if the mon is recruitable
                    local recruitable = true
                    local features = spawn.SpawnFeatures
                    for f = 0, features.Count-1, 1 do
                        if RECRUIT_LIST.getClass(features[f]) == "PMDC.LevelGen.MobSpawnUnrecruitable" then
                            recruitable = false
                            entry.mode = RECRUIT_LIST.unrecruitable
                        end
                    end
                    if recruitable or RECRUIT_LIST.showUnrecruitable() then
                        table.insert(entry_list, entry)
                    end
                end
            end

            -- Mix everything up
            for _, entry in pairs(entry_list) do
                -- keep only if under explored limit
                if entry.mode > RECRUIT_LIST.hide and entry.min <= highest then
                    species[entry.species] = species[entry.species] or {}
                    table.insert(species[entry.species], entry)
                end
            end
        end
    end

    for _, entry in pairs(species) do
        -- sort species-specific list by first appearance
        table.sort(entry, function (a, b)
            return a.min < b.min
        end)
        local current = entry[1]

        -- fuse entries whose floor boundaries touch or overlap
        -- put final entries in output list
        if #entry>1 then
            for i = 2, #entry, 1 do
                local next = entry[i]
                if current.max+1 >= next.min then
                    current.max = math.max(current.max, next.max)
                else
                    table.insert(list,current)
                    current = next
                end
            end
        end
        table.insert(list,current)
    end

    -- sort output list by min floor, max floor and then dex
    table.sort(list, function (a, b)
        if a.min == b.min then
            if a.max == b.max then
                return _DATA:GetMonster(a.species).IndexNum < _DATA:GetMonster(b.species).IndexNum
            end
            return a.max < b.max
        end
        return a.min < b.min
    end)

    for _,elem in pairs(list) do
        local state = _DATA.Save:GetMonsterUnlock(elem.species)

        if elem.mode ~= RECRUIT_LIST.unrecruitable then
            -- check if the mon has been seen or obtained
            if state == RogueEssence.Data.GameProgress.UnlockState.Discovered then
                    elem.mode = RECRUIT_LIST.seen
            elseif state == RogueEssence.Data.GameProgress.UnlockState.Completed then
                if RECRUIT_LIST.check_multi_form(elem.species) then
                    elem.mode = RECRUIT_LIST.obtainedMultiForm --special color for multi-form mons
                else
                    elem.mode = RECRUIT_LIST.obtained
                end
            end
        elseif state == RogueEssence.Data.GameProgress.UnlockState.None then
            elem.mode = RECRUIT_LIST.unrecruitable_not_seen
        end
    end
    return list
end

-- Extracts a list of all mons spawnable and spawned on the current floor and
-- then pairs them to the display mode that should be used for that mon's name in the menu
-- Non-respawning mons are always at the end of the list
function RECRUIT_LIST.compileFloorList()
    -- abort immediately if we're not inside a dungeon or recruitment is disabled
    if _DATA.Save.NoRecruiting then return {} end
    if RogueEssence.GameManager.Instance.CurrentScene ~= RogueEssence.Dungeon.DungeonScene.Instance then return {} end

    local list = {
        keys = {},
        entries = {}
    }

    local map = _ZONE.CurrentMap
    local spawns = map.TeamSpawns

    -- check the current floor's spawn list
    for i = 0, spawns.Count-1, 1 do
        local spawnList = spawns:GetSpawn(i):GetPossibleSpawns()
        for j = 0, spawnList.Count-1, 1 do
            local member = spawnList:GetSpawn(j).BaseForm.Species
            local state = _DATA.Save:GetMonsterUnlock(member)
            local mode = RECRUIT_LIST.not_seen -- default is to "???" respawning mons if unknown

            -- check if the mon has been seen or obtained
            if state == RogueEssence.Data.GameProgress.UnlockState.Discovered then
                mode = RECRUIT_LIST.seen
            elseif state == RogueEssence.Data.GameProgress.UnlockState.Completed then
                if RECRUIT_LIST.check_multi_form(member) then
                    mode = RECRUIT_LIST.obtainedMultiForm --special color for multi-form mons
                else
                    mode = RECRUIT_LIST.obtained
                end
            end

            -- check if the mon is recruitable
            local features = spawnList:GetSpawn(j).SpawnFeatures
            for f = 0, features.Count-1, 1 do
                if RECRUIT_LIST.getClass(features[f]) == "PMDC.LevelGen.MobSpawnUnrecruitable" then
                    if RECRUIT_LIST.showUnrecruitable() then
                        if mode == RECRUIT_LIST.not_seen then
                            mode = RECRUIT_LIST.unrecruitable_not_seen
                        else
                            mode = RECRUIT_LIST.unrecruitable
                        end
                    else
                        mode = RECRUIT_LIST.hide -- do not show in recruit list if cannot recruit
                    end
                end
            end

            -- add the member and its display mode to the list
            if mode > RECRUIT_LIST.hide and not list.entries[member] then
                table.insert(list.keys, member)
                list.entries[member] = mode
            end
        end
    end

    -- sort spawn list
    table.sort(list.keys, function (a, b)
        return _DATA:GetMonster(a).IndexNum < _DATA:GetMonster(b).IndexNum
    end)

    -- check all mons on the floor that are not in spawn list
    local teams = map.MapTeams
    for i = 0, teams.Count-1, 1 do
        local team = teams[i].Players
        for j = 0, team.Count-1, 1 do
            local member = team[j].BaseForm.Species
            local state = _DATA.Save:GetMonsterUnlock(member)
            local mode = RECRUIT_LIST.hide -- default is to not show non-respawning mons if unknown

            -- check if the mon has been seen or obtained
            if state == RogueEssence.Data.GameProgress.UnlockState.Discovered then
                mode = RECRUIT_LIST.extra_seen
            elseif state == RogueEssence.Data.GameProgress.UnlockState.Completed then
                if RECRUIT_LIST.check_multi_form(member) then
                    mode = RECRUIT_LIST.extra_obtainedMultiForm
                else
                    mode = RECRUIT_LIST.extra_obtained
                end
            end
            -- do not show in recruit list if cannot recruit, no matter the list or mode
            if team[j].Unrecruitable then mode = RECRUIT_LIST.hide end

            -- add the member and its display mode to the list
            if mode> RECRUIT_LIST.hide and not list.entries[member] then
                table.insert(list.keys, member)
                list.entries[member] = mode
            end
        end
    end

    local ret = {}
    for _,key in pairs(list.keys) do
        local entry = {
            species = key,
            mode = list.entries[key]
        }
        table.insert(ret,entry)
    end
    return ret
end

--returns whether the mon has more than 1 non-temporary form
function RECRUIT_LIST.check_multi_form(monster)
    local forms = _DATA:GetMonster(monster).Forms
    if forms.Count == 1 then return false end
    local count = 0
    for i=0, forms.Count-1, 1 do
        if not forms[i].Temporary then count = count+1 end
        if count>1 then return true
        end
    end
    return false
end

-- Returns the class of an object as string. Useful to extract and check C# class names
function RECRUIT_LIST.getClass(csobject)
    if not csobject then return "nil" end
    local namet = getmetatable(csobject).__name
    if not namet then return type(csobject) end
    for a in namet:gmatch('([^,]+)') do
        return a
    end
end

-- quick ternary conditional operator implementation
function RECRUIT_LIST.tri(check, y, n)
    if check then return y else return n end
end
-- -----------------------------------------------
-- Recruitment List Menu
-- -----------------------------------------------
-- Menu that displays the recruitment list to the player
RecruitmentListMenu = Class('RecruitmentListMenu')

function RecruitmentListMenu:initialize(title, zone, segment)
    assert(self, "RecruitmentListMenu:initialize(): self is nil!")
    self.title = title
    self.fullDungeon = false
    self.fullDungeon_zone = zone
    self.fullDungeon_segment = segment
    if zone and segment~=nil then
        self.fullDungeon = true
    else
        local loc = RECRUIT_LIST.getCurrentMap()
        self.fullDungeon_zone = loc.zone
        self.fullDungeon_segment = loc.segment
    end

    self.ENTRY_LINES = 10
    self.ENTRY_COLUMNS = 2
    self.ENTRY_LIMIT = self.ENTRY_LINES * self.ENTRY_COLUMNS

    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)
    self.dirPressed = false
    self.list = {}
    if self.fullDungeon then
        self.list = RECRUIT_LIST.compileFullDungeonList(zone, segment)
    else
        self.list = RECRUIT_LIST.compileFloorList()
    end
    self.page = 0
    self.PAGE_MAX = math.max(0, (#self.list-1)//self.ENTRY_LIMIT)

    self:DrawMenu()
end

function RecruitmentListMenu:DrawMenu()
    self.menu.MenuElements:Clear()
    --Standard menu divider. Reuse this whenever you need a menu divider at the top for a title.
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))

    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(self.title, RogueElements.Loc(16, 8)))

    -- add a special message if there are no entries
    if #self.list<1 then
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("No recruits available", RogueElements.Loc(16, 24)))
        return
    end
    -- add a special message if spoiler mode is on
    if not self.fullDungeon and RECRUIT_LIST.spoilerMode() and RECRUIT_LIST.checkFloor() then
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("You cannot view this list because this is your", RogueElements.Loc(16, 24)))
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("first time reaching this floor.", RogueElements.Loc(16, 38)))
        return
    end

    --Add page number if it has more than one
    if self.PAGE_MAX>0 then
        local pagenum = "("..tostring(self.page+1).."/"..tostring(self.PAGE_MAX+1)..")"
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(pagenum, RogueElements.Loc(self.menu.Bounds.Width - 8, 8),RogueElements.DirH.Right))
    end

    --how many entries we have populated so far
    local count = 0

    --other helper indexes
    local start_pos = self.page * self.ENTRY_LIMIT
    local end_pos = math.min(start_pos+self.ENTRY_LIMIT, #self.list)
    start_pos = start_pos + 1


    --populate entries with mon list
    for i=start_pos, end_pos, 1 do
        -- positional parameters
        local line = count % self.ENTRY_LINES
        local col = count // self.ENTRY_LINES
        local xpad = 16
        local ypad = 24
        local xdist = ((self.menu.Bounds.Width-32)//self.ENTRY_COLUMNS)
        local ydist = 14

        -- add element
        local text, xadjust = RECRUIT_LIST.formatName(self.list[i].species, self.list[i].mode)
        local x = xpad + xdist * col - xadjust
        local y = ypad + ydist * line
        if self.fullDungeon then
            local maxFloor = RECRUIT_LIST.getFloorsCleared(self.fullDungeon_zone, self.fullDungeon_segment)
            local text_fl = tostring(self.list[i].min).."F"
            if self.list[i].min ~= self.list[i].max then
                text_fl = text_fl.."-"
                if self.list[i].max > maxFloor then
                    text_fl = text_fl.."??"
                else
                    text_fl = text_fl..tostring(self.list[i].max).."F"
                end
            else
                text_fl = text_fl.."   "
                if self.list[i].min > 9 then text_fl = text_fl.." " end
            end
            text = text_fl.." "..text
        end
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(text, RogueElements.Loc(x, y)))
        count = count + 1
    end
end

function RecruitmentListMenu:Update(input)
    if input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input.Direction == RogueElements.Dir8.Right then
        if not self.dirPressed then
            if self.PAGE_MAX == 0 then
                _GAME:SE("Menu/Cancel")
                self.page = self.PAGE_MAX
            else
                self.page = (self.page+1) % (self.PAGE_MAX+1)
                _GAME:SE("Menu/Skip")
                self:DrawMenu()
            end
            self.dirPressed = true
        end
    elseif input.Direction == RogueElements.Dir8.Left then
        if not self.dirPressed then
            if self.PAGE_MAX == 0 then
                _GAME:SE("Menu/Cancel")
                self.page = 0
            else
                self.page = (self.page-1) % (self.PAGE_MAX+1)
                _GAME:SE("Menu/Skip")
                self:DrawMenu()
            end
            self.dirPressed = true
        end
    elseif input.Direction == RogueElements.Dir8.None then
        self.dirPressed = false
    end
end

-- -----------------------------------------------
-- Recruitment List Main Menu
-- -----------------------------------------------
-- Main menu for the Recruitment List mod.

RecruitMainChoice = Class('RecruitMainChoice')

function RecruitMainChoice:initialize(x, starting_choice)
    assert(self, "RecruitMainChoice:initialize(): self is nil!")
    if not starting_choice then starting_choice = 0 end

    -- set up option 1
    local text1 = "List"
    local enabled1 = true
    local fn1 = function() _MENU:AddMenu(RecruitmentListMenu:new("Recruitment List").menu, false) end
    -- set up option 4
    local enabled4 = false

    -- adjust if not in dungeon
    if RogueEssence.GameManager.Instance.CurrentScene ~= RogueEssence.Dungeon.DungeonScene.Instance then
        text1 = "Dungeon"
        enabled1 = RECRUIT_LIST.hasVisitedValidDungeons()
        fn1 = function() _MENU:AddMenu(RecruitDungeonChoice:new().menu, false) end
        enabled4 = true
    end

    local info_list = {}
    for i = 1, #RECRUIT_LIST.info_list, 1 do
        table.insert(info_list, RECRUIT_LIST.info_list[i])
    end
    if RECRUIT_LIST.gameCompleted() then table.insert(info_list, RECRUIT_LIST.postgame_message) end
    if RECRUIT_LIST.showUnrecruitable() then table.insert(info_list, RECRUIT_LIST.dev_RecruitFilter[RECRUIT_LIST.tri(RECRUIT_LIST.iconMode(),1,2)]) end

    local color_list = RECRUIT_LIST.tri(RECRUIT_LIST.iconMode(),RECRUIT_LIST.info_colors,RECRUIT_LIST.info_colors_iconless)

    local options = {
        {text1, enabled1, fn1},
        {"Info",   true, function() _MENU:AddMenu(RecruitTextShowMenu:new(RECRUIT_LIST.info_list_title, info_list).menu, false) end},
        {"Colors", true, function() _MENU:AddMenu(RecruitTextShowMenu:new(RECRUIT_LIST.info_colors_title, color_list).menu, false) end},
        {"Options", enabled4, function() _MENU:AddMenu(RecruitOptionsChoice:new(x, 46).menu, true) end}
    }
    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(x, 46, 64, options, starting_choice, function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end)
end

-- -----------------------------------------------
-- Recruitment Text Show Menu
-- -----------------------------------------------
-- Shows text and divides it in multiple pages
RecruitTextShowMenu = Class('RecruitTextShowMenu')

function RecruitTextShowMenu:initialize(title, lines)
    assert(self, "RecruitTextShowMenu:initialize(): self is nil!")

    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)
    self.dirPressed = false
    self.page = 1

    self.title = title
    self.lines = lines
    self.PAGE_MAX = #self.lines
    self:DrawMenu()
end

function RecruitTextShowMenu:DrawMenu()
    self.menu.MenuElements:Clear()
    --Standard menu divider. Reuse this whenever you need a menu divider at the top for a title.
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))

    local title = self.title
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(title, RogueElements.Loc(16, 8)))
    --Add page number if it has more than one
    if self.PAGE_MAX > 1 then
        local pagenum = "("..tostring(self.page).."/"..tostring(self.PAGE_MAX)..")"
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(pagenum, RogueElements.Loc(self.menu.Bounds.Width - 8, 8),RogueElements.DirH.Right))
    end

    for i=1, #self.lines[self.page], 1 do
        -- positional parameters
        local line = i-1
        local ypad = 24
        local ydist = 14

        -- add element
        local y = ypad + ydist * line
        local x = 16
        local text = self.lines[self.page][i]
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(text, RogueElements.Loc(x, y)))
    end
end

function RecruitTextShowMenu:Update(input)
    if input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input.Direction == RogueElements.Dir8.Right then
        if not self.dirPressed then
            if self.PAGE_MAX == 1 then
                _GAME:SE("Menu/Cancel")
                self.page = 1
            else
                local p_index = self.page-1
                self.page = ((p_index+1) % (self.PAGE_MAX))+1
                _GAME:SE("Menu/Skip")
                self:DrawMenu()
                self.dirPressed = true
            end
        end
    elseif input.Direction == RogueElements.Dir8.Left then
        if not self.dirPressed then
            if self.PAGE_MAX == 1 then
                _GAME:SE("Menu/Cancel")
                self.page = 1
            else
                local p_index = self.page-1
                self.page = ((p_index-1) % (self.PAGE_MAX))+1
                _GAME:SE("Menu/Skip")
                self:DrawMenu()
                self.dirPressed = true
            end
        end
    elseif input.Direction == RogueElements.Dir8.None then
        self.dirPressed = false
    end
end

-- -----------------------------------------------
-- Recruitment List Options Choice
-- -----------------------------------------------
-- Small menu that allows toggling the mod's options. Accessible only in Ground maps

RecruitOptionsChoice = Class('RecruitOptionsChoice')

function RecruitOptionsChoice:initialize(x, y, starting_choice)
    assert(self, "RecruitOptionsChoice:initialize(): self is nil!")

    self.parent_bounds = {
        x = x,
        y = y
    }
    local off = "Off"
    local on = "[color=#FFFF00]On[color] "
    local text1 = "Icon Mode: "   ..RECRUIT_LIST.tri(RECRUIT_LIST.iconMode(), on, off)
    local text2 = "Spoiler Mode: "..RECRUIT_LIST.tri(RECRUIT_LIST.spoilerMode(), on, off)
    local options = {
        {text1, true, function() self:ToggleIconMode() end},
        {text2, true, function() self:ToggleSpoilerMode() end}
    }
    local xx = self.parent_bounds.x+70
    local yy = self.parent_bounds.y+14*(4-#options)

    if not starting_choice then starting_choice = #options-1 end
    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(xx,yy, 64, options, starting_choice, function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end)
end

function RecruitOptionsChoice:ToggleSpoilerMode()
    RECRUIT_LIST.toggleSpoilerMode()
    self:reset_contents()
end

function RecruitOptionsChoice:ToggleIconMode()
    RECRUIT_LIST.toggleIconMode()
    self:reset_contents()
end

function RecruitOptionsChoice:reset_contents()
    _MENU:RemoveMenu() --remove self
    _MENU:RemoveMenu() --remove parent
    _MENU:AddMenu(RecruitMainChoice:new(self.parent_bounds.x, 3).menu, true) --refresh parent
    _MENU:AddMenu(RecruitOptionsChoice:new(self.parent_bounds.x, self.parent_bounds.y, self.menu.CurrentChoice).menu, true) --refresh self
end

-- -----------------------------------------------
-- Recruitment List Dungeon Choice Menu
-- -----------------------------------------------
-- Menu for choosing what dungeon to visualize the recruit list of

RecruitDungeonChoice = Class('RecruitDungeonChoice')

function RecruitDungeonChoice:initialize()
    local exit_fn = function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end

    self.entries = RECRUIT_LIST.getDungeonOrder()

    local choices = {}
    for _,entry in pairs(self.entries) do
        local completed = RECRUIT_LIST.getSegmentData(entry.zone,0).completed
        local zone_name = "[color="..RECRUIT_LIST.tri(completed, "#FFC663", "#00FFFF").."]"..entry.name.."[color]"
        table.insert(choices, RogueEssence.Menu.MenuTextChoice(zone_name, function() self:chooseNextMenu(entry.zone) end))
    end

    local choices_array = luanet.make_array(RogueEssence.Menu.MenuTextChoice,choices)
    self.menu = RogueEssence.Menu.ScriptableMultiPageMenu(RogueElements.Loc(16,16), 128, "Dungeons", choices_array, 0, 10, exit_fn, exit_fn)
end

function RecruitDungeonChoice:chooseNextMenu(zone)
    local segments = RECRUIT_LIST.getValidSegments(zone)
    if #segments < 2 then
        local segment = segments[1]
        local max_fl = RECRUIT_LIST.getFloorsCleared(zone, segment.id)
        local title = RECRUIT_LIST.tri(segment.completed,"[color=#FFC663]"..segment.name.."[color]","[color=#00FFFF]"..segment.name.." (Up to "..max_fl.."F)[color]")
        _MENU:AddMenu(RecruitmentListMenu:new(title, zone, segment.id).menu, false)
    else
        _MENU:AddMenu(RecruitSegmentChoice:new(zone, segments, self.menu.CurrentChoice).menu, true)
    end
end

-- -----------------------------------------------
-- Recruitment List Dungeon Segment Menu
-- -----------------------------------------------
-- Menu for choosing what segment of a specific dungeon to visualize the recruit list of
-- only shown if the chosen dungeon has more than 1 valid explored segments

RecruitSegmentChoice = Class('RecruitSegmentChoice')

function RecruitSegmentChoice:initialize(zone, segments, super_index)
    assert(self, "RecruitSegmentChoice:initialize(): self is nil!")
    local options = {}
    local segments_data = {}

    -- construct data and text
    for _,segment in pairs(segments) do
        local enabled = segment.floorsCleared>0
        local color = RECRUIT_LIST.tri(segment.completed,"#FFC663",RECRUIT_LIST.tri(enabled,"#00FFFF","#FF0000"))
        local text = "[color="..color.."]"..segment.name
        local title = text
        local max_fl = RECRUIT_LIST.getFloorsCleared(zone, segment.id)
        if not segment.completed then
            title = title.." (Up to "..max_fl.."F)"
        end
        title = title.."[color]"
        text = text.."[color]"
        local entry = {
            id = segment.id,
            title = title,
            option = text,
            enabled = enabled
        }
        table.insert(segments_data, entry)
    end

    local reverse = false
    local top_slot = super_index
    local bottom_slot = top_slot + #segments_data-1
    if bottom_slot > 9 then top_slot, reverse = top_slot-#segments_data+1, true end
    if top_slot<0 then top_slot, reverse = super_index-bottom_slot+9, false end

    -- sort by segment id
    if not reverse then table.sort(segments_data, function (a, b) return a.id < b.id end)
    else table.sort(segments_data, function (a, b) return a.id > b.id end) end

    -- add to menu
    for _, entry in pairs(segments_data) do
        local func = function() _MENU:AddMenu(RecruitmentListMenu:new(entry.title, zone, entry.id).menu, false) end

        table.insert(options, RogueEssence.Menu.MenuTextChoice(entry.option, func, entry.enabled, Color.White))
    end
    local starting_choice = RECRUIT_LIST.tri(reverse, #options-1, 0)

    local x = 32+14*top_slot
    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(148, x, 128, options, starting_choice, function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end)
end