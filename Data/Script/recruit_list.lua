require 'common'
require "menu.recruit.RecruitListMainMenu"

RECRUIT_LIST = {}
--[[
    recruit_list.lua

    This file contains all functions necessary to generate Recruitment Lists for dungeons, as well as
    the routine used to show the list itself
]]--

--- ----------------------------------------------
--- Constants
--- ----------------------------------------------
-- Modes
RECRUIT_LIST.hide =                    0
RECRUIT_LIST.unrecruitable_not_seen =  1
RECRUIT_LIST.not_seen =                2
RECRUIT_LIST.unrecruitable =           3
RECRUIT_LIST.seen =                    4
RECRUIT_LIST.extra_seen =              5
RECRUIT_LIST.obtained =                6
RECRUIT_LIST.extra_obtained =          7
RECRUIT_LIST.obtainedMultiForm =       8
RECRUIT_LIST.extra_obtainedMultiForm = 9

--- -----------------------------------------------
--- SV structure
--- -----------------------------------------------
-- Returns if the game has been completed or not
function RECRUIT_LIST.gameCompleted()
    if SV.guildmaster_summit.GameComplete == nil then SV.guildmaster_summit.GameComplete = false end -- if true, hides the recruit list if it's the player's first time on a floor
    return SV.guildmaster_summit.GameComplete
end

-- Returns the current state of Scanner Mode
function RECRUIT_LIST.scannerMode()
    SV.Services = SV.Services or {}
    if SV.Services.RecruitList_scanner_mode == nil then SV.Services.RecruitList_scanner_mode = false end -- if true, allows the player to view the summary of any obtained mon's spawn entry
    return SV.Services.RecruitList_scanner_mode
end

-- Toggles the current state of Scanner Mode
function RECRUIT_LIST.toggleScannerMode()
    if RECRUIT_LIST.scannerMode() then SV.Services.RecruitList_scanner_mode = false else
        SV.Services.RecruitList_scanner_mode = true
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
    return SV.Services.RecruitList_icon_mode
end

-- Toggles the current state of Icon Mode
function RECRUIT_LIST.toggleIconMode()
    if RECRUIT_LIST.iconMode() then SV.Services.RecruitList_icon_mode = false else
        SV.Services.RecruitList_icon_mode = true
    end
end


-- Returns true if the string is a valid zone index, false otherwise
function RECRUIT_LIST.zoneExists(zone)
    return not not _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]:ContainsKey(zone)
end

-- Returns the ZoneEntrySummary associated to the given zone
function RECRUIT_LIST.getZoneSummary(zone)
    if RECRUIT_LIST.zoneExists(zone) then
        return _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]:Get(zone)
    end
    return nil
end

-- Initializes the basic dungeon list data structure
function RECRUIT_LIST.generateDungeonListBaseSV()
    SV.Services = SV.Services or {}
    SV.Services.RecruitList = SV.Services.RecruitList or {}
end

-- Initializes the data slot for the supplied segment if not already present
function RECRUIT_LIST.generateDungeonListSV(zone, segment)
    RECRUIT_LIST.generateDungeonListBaseSV()
    if not RECRUIT_LIST.zoneExists(zone) then return end            -- abort if zone does not exist
    SV.Services.RecruitList[zone] = SV.Services.RecruitList[zone] or {}

    -- update old data if present
    local defaultFloor = 0
    if type(SV.Services.RecruitList[zone][segment]) == "number" then
        defaultFloor = SV.Services.RecruitList[zone][segment]
        SV.Services.RecruitList[zone][segment] = nil
    end

    if not SV.Services.RecruitList[zone][segment] then
        local segment_data = _DATA:GetZone(zone).Segments[segment]
        if segment_data == nil then return end         -- abort if segment does not exist
            SV.Services.RecruitList[zone][segment] = {
                floorsCleared = defaultFloor,           -- number of floors cleared in the dungeon
                totalFloors = segment_data.FloorCount,  -- total amount of floors in this segment
                completed = false,                      -- true if the dungeon has been completed
                name = "Segment "..tostring(segment)    -- segment display name
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
    if not RECRUIT_LIST.zoneExists(zone) then return end
    local segment_data = _DATA:GetZone(zone).Segments[segment]
    if segment_data == nil then return end

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
    if SV.Services.RecruitList[zone] == nil then return 0 end
    if SV.Services.RecruitList[zone][segment] == nil then return 0 end
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

-- Returns a segment's spawn list data structure
function RECRUIT_LIST.getSegmentData(zone, segment)
    RECRUIT_LIST.generateDungeonListSV(zone, segment)
    if SV.Services.RecruitList[zone] == nil then return nil end
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
        if not RECRUIT_LIST.zoneExists(zone) then return end
        local zone_summary = RECRUIT_LIST.getZoneSummary(zone)

        local entry = {
            zone = zone,
            cap = zone_summary.LevelCap,
            level = zone_summary.Level,
            length = zone_summary.CountedFloors,
            name = zone_summary.Name:ToLocal()
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
                other.length = zone_summary.CountedFloors --fix in case of old summary error
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

--- -----------------------------------------------
--- Functions
--- -----------------------------------------------
-- returns the current map as a table of properties {string zone, int segment, int floor}
function RECRUIT_LIST.getCurrentMap()
    local mapData = {
        zone = _ZONE.CurrentZoneID,
        segment = _ZONE.CurrentMapID.Segment,
        floor = GAME:GetCurrentFloor().ID + 1
    }
    return mapData
end

-- this stays for debug purposes
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
    if not segmentData then                                 --load data now if it was not already done
        if not RECRUIT_LIST.zoneExists(zone) then return false end
        segmentData = _DATA:GetZone(zone).Segments[segment]
    end
    if segmentData == nil then return false end

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
    if not RECRUIT_LIST.zoneExists(zone) then return list end

    if not RECRUIT_LIST.gameCompleted() then
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
                local spawn = spawnlist:GetSpawn(j).Spawn -- RogueEssence.LevelGen.MobSpawn
                local entry = {
                    spawns = {{
                        data = spawn,
                        dungeon = {zone = zone, segment = segment},
                        range = {
                            min = range.Min+1,
                            max = math.min(range.Max, segmentData.FloorCount)
                        }
                    }},
                    species = spawn.BaseForm.Species,
                    mode = RECRUIT_LIST.not_seen, -- defaults to "???". this will be calculated later
                    -- state is added later
                }
                entry.min = entry.spawns[1].range.min
                entry.max = entry.spawns[1].range.max
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
                        spawns = {{
                            data = spawn,
                            dungeon = {zone = zone, segment = segment},
                            range = {
                                min = range.Min+1,
                                max = math.min(range.Max, segmentData.FloorCount)
                            }
                        }},
                        species = spawn.BaseForm.Species,
                        mode = RECRUIT_LIST.not_seen, -- defaults to "???". this will be calculated later
                        -- state is added later
                    }
                    entry.min = entry.spawns[1].range.min
                    entry.max = entry.spawns[1].range.max
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
                    for _, spawn in pairs(next.spawns) do table.insert(current.spawns, spawn) end
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
        elem.state = state

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
            local spawn = spawnList:GetSpawn(j)

            if spawn:CanSpawn() then
                local member = spawn.BaseForm.Species
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
                local features = spawn.SpawnFeatures
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
                if mode > RECRUIT_LIST.hide then
                    if not list.entries[member] then
                        table.insert(list.keys, member)
                        list.entries[member] = {
                            spawn = {{data = spawn}},
                            mode = mode,
                            state = state
                        }
                    else
                        table.insert(list.entries[member].spawn, {data = spawn})
                    end
                end
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
                list.entries[member] = {
                    mode = mode
                }
            end
        end
    end

    local ret = {}
    for _,key in pairs(list.keys) do
        local state = _DATA.Save:GetMonsterUnlock(key)
        if list.entries[key].spawn == nil then state = nil end
        local entry = {
            spawns = list.entries[key].spawn,
            species = key,
            mode = list.entries[key].mode,
            state = state
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

-- Checks if the last used version is higher than the supplied one. No parameter is mandatory
function RECRUIT_LIST.checkMinVersion(Major, Minor, Build, Revision)
    Major = Major or 0
    Minor = Minor or 0
    Build = Build or 0
    Revision = Revision or 0
    if RECRUIT_LIST.version.Major > Major then return true end
    if RECRUIT_LIST.version.Major == Major and RECRUIT_LIST.version.Minor > Minor then return true end
    if RECRUIT_LIST.version.Minor == Minor and RECRUIT_LIST.version.Build > Build then return true end
    if RECRUIT_LIST.version.Build == Build and RECRUIT_LIST.version.Revision > Revision then return true end
    return false
end