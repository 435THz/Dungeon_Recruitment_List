require 'common'

REC_LIST = {}
--[[
    recruit_list.lua

    This file contains all functions necessary to generate Recruitment Lists for dungeons, as well as
    the routine used to show the list itself
]]--

-- -----------------------------------------------
-- Settings
-- -----------------------------------------------
REC_LIST.hideUnexploredFloorList = false

-- -----------------------------------------------
-- Constants
-- -----------------------------------------------
REC_LIST.hide =                    0
REC_LIST.undiscovered =            1
REC_LIST.discovered =              2
REC_LIST.extra_discovered =        3
REC_LIST.obtained =                4
REC_LIST.extra_obtained =          5
REC_LIST.obtainedMultiForm =       6
REC_LIST.extra_obtainedMultiForm = 7

REC_LIST.colorList = {'#FFFFFF','#FFFFFF','#00FFFF','#FFFF00','#FFFFA0','#FFA500','#FFE0A0'}

-- -----------------------------------------------
-- SV structure
-- -----------------------------------------------
--[[this will contain every dungeon's highest reached floor
-- All seen Pokemon in the pokedex
--local seen_pokemon = {}

--for entry in luanet.each(_DATA.Save.Dex) do
--    if entry.Value == RogueEssence.Data.GameProgress.UnlockState.Discovered then
--        table.insert(seen_pokemon, entry.Key)
--    end
--end

--print( seen_pokemon[ math.random( #seen_pokemon ) ] ) ]]--

-- -----------------------------------------------
-- Functions
-- -----------------------------------------------
function REC_LIST.generateSV(zone, segment)
    SV.Services = SV.Services or {}
    SV.Services.RecruitList = SV.Services.RecruitList or {}
    SV.Services.RecruitList[zone] = SV.Services.RecruitList[zone] or {}
    SV.Services.RecruitList[zone][segment] = SV.Services.RecruitList[zone][segment] or 0
end

function REC_LIST.checkFloor()
    local loc = REC_LIST.getCurrentMap()

    REC_LIST.generateSV(loc.zone, loc.segment)
    return SV.Services.RecruitList[loc.zone][loc.segment]>=loc.floor
end

function REC_LIST.colorName(monster, mode)
    local name = _DATA:GetMonster(monster).Name:ToLocal()
    if mode == 1 then name = '???' end
    local color = REC_LIST.colorList[mode]
    return '[color='..color..']'..name..'[color]'
end

function REC_LIST.getCurrentMap()
    local mapData = {
        zone = _ZONE.CurrentZoneID,
        segment = _ZONE.CurrentMapID.Segment,
        floor = GAME:GetCurrentFloor().ID + 1
    }
    return mapData
end

-- Extracts a list of all mons spawnable in a dungeon, then maps them to the display mode that
-- should be used for that mon's name in the menu. Includes only mons that can respawn.
function REC_LIST.compileFullDungeonList(zone, segment)
    local species = {}  -- used to compact multiple entries that contain the same species
    local list = {}     -- list of all keys in the list. populated only at the end


    REC_LIST.generateSV(zone, segment)
    local segmentData = _DATA:GetZone(zone).Segments[segment]
    local segSteps = segmentData.ZoneSteps
    local highest = SV.Services.RecruitList[zone][segment]

    for i = 0, segSteps.Count-1, 1 do
        local step = segSteps[i]
        if REC_LIST.getClass(step) == "RogueEssence.LevelGen.TeamSpawnZoneStep" then
            local spawnlist = step.Spawns
            for j=0, spawnlist.Count-1, 1 do
                local range = spawnlist:GetSpawnRange(j)
                local spawn = spawnlist:GetSpawn(j).Spawn.BaseForm.Species
                local entry = {
                    min = range.Min+1,
                    max = range.Max,
                    species = spawn,
                    mode = REC_LIST.undiscovered -- defaults to "???". this will be calculated later
                }

                -- keep only if under explored limit
                if entry.min <= highest then
                    species[entry.species] = species[entry.species] or {}
                    table.insert(species[entry.species], entry)
                end
            end
        end
    end

    for _, entry in pairs(species) do
        -- sort species list
        table.sort(entry, function (a, b)
            return a.min < b.min
        end)
        local current = entry[1]

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

    -- sort the final list by min floor, max floor and then dex
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

        -- check if the mon has been seen or obtained
        if state == RogueEssence.Data.GameProgress.UnlockState.Discovered then
            elem.mode = REC_LIST.discovered
        elseif state == RogueEssence.Data.GameProgress.UnlockState.Completed then
            if _DATA:GetMonster(elem.species).Forms.Count>1 then
                elem.mode = REC_LIST.obtainedMultiForm --special color for multi-form mons
            else
                elem.mode = REC_LIST.obtained
            end
        end
        print(tostring(elem.min).."F-"..tostring(elem.max).."F: "..elem.species.."; mode "..tostring(elem.mode))
    end

    return list
end

-- Extracts a list of all mons spawnable and spawned on the current floor and
-- then pairs them to the display mode that should be used for that mon's name in the menu
function REC_LIST.compileFloorList()
    local list = {
        keys = {},
        entries = {}
    }
    -- abort immediately if we're not inside a dungeon
    if RogueEssence.GameManager.Instance.CurrentScene ~= RogueEssence.Dungeon.DungeonScene.Instance then
        return list
    end

    local map = _ZONE.CurrentMap
    local spawns = map.TeamSpawns

    for i = 0, spawns.Count-1, 1 do
        local spawnList = spawns:GetSpawn(i):GetPossibleSpawns()
        for j = 0, spawnList.Count-1, 1 do
            local member = spawnList:GetSpawn(j).BaseForm.Species
            local state = _DATA.Save:GetMonsterUnlock(member)
            local mode = REC_LIST.undiscovered -- default is to "???" respawning mons if unknown

            -- check if the mon has been seen or obtained
            if state == RogueEssence.Data.GameProgress.UnlockState.Discovered then
                mode = REC_LIST.discovered
            elseif state == RogueEssence.Data.GameProgress.UnlockState.Completed then
                if _DATA:GetMonster(member).Forms.Count>1 then
                    mode = REC_LIST.obtainedMultiForm --special color for multi-form mons
                else
                    mode = REC_LIST.obtained
                end
            end

            -- check if the mon is recruitable
            local features = spawnList:GetSpawn(j).SpawnFeatures
            for f = 0, features.Count-1, 1 do
                if REC_LIST.getClass(features[f]) == "PMDC.LevelGen.MobSpawnUnrecruitable" then
                    mode = REC_LIST.hide -- do not show in recruit list if cannot recruit
                end
            end

            -- add the member and its display mode to the list
            if mode>0 and not list.entries[member] then
                table.insert(list.keys, member)
                list.entries[member] = mode
            end
        end
    end

    -- sort spawn list
    table.sort(list.keys, function (a, b)
        return _DATA:GetMonster(a).IndexNum < _DATA:GetMonster(b).IndexNum
    end)

    local teams = map.MapTeams
    for i = 0, teams.Count-1, 1 do
        local team = teams[i].Players
        for j = 0, team.Count-1, 1 do
            local member = team[j].BaseForm.Species
            local state = _DATA.Save:GetMonsterUnlock(member)
            local mode = REC_LIST.hide -- default is to not show non-respawning mons if unknown

            -- check if the mon has been seen or obtained
            if state == RogueEssence.Data.GameProgress.UnlockState.Discovered then
                mode = REC_LIST.extra_discovered
            elseif state == RogueEssence.Data.GameProgress.UnlockState.Completed then
                if _DATA:GetMonster(member).Forms.Count>1 then
                    mode = REC_LIST.extra_obtainedMultiForm
                else
                    mode = REC_LIST.extra_obtained
                end
            end
            -- do not show in recruit list if cannot recruit
            if team[j].Unrecruitable then mode = REC_LIST.hide end

            -- add the member and its display mode to the list
            if mode>REC_LIST.hide and not list.entries[member] then
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

function REC_LIST.getClass(csobject)
    if not csobject then return "nil" end
    local namet = getmetatable(csobject).__name
    if not namet then return type(csobject) end
    for a in namet:gmatch('([^,]+)') do
        return a
    end
end

function REC_LIST.contains(table, key, value)
    -- if the table does not exist return false
    if not table then return false end

    -- if the key is supplied
    if key then
        -- if the value is supplied return whether or not the key-value pair exists
        if value then return table[key] ~= nil and table[key] == value
        -- if the value is omitted return whether or not the key exists
        else return table[key] ~= nil end
    end

    -- if nether key nor value are supplied return false
    if value == nil then return false end

    -- if only the value is supplied look inside the list and return true if found, false otherwise
    for _, val in pairs(table) do
        if val == value then return true end
    end
    return false
end


-- -----------------------------------------------
-- Recruitment List Menu
-- -----------------------------------------------
-- Menu that displays the recruitment list to the player
RecruitmentListMenu = Class('RecruitmentListMenu')

function RecruitmentListMenu:initialize(zone, segment)
    assert(self, "RecruitmentListMenu:initialize(): self is nil!")
    self.fullDungeon = false
    if zone and segment~=nil then
        self.fullDungeon = true
    end

    self.ENTRY_LINES = 10
    self.ENTRY_COLUMNS = 2
    self.ENTRY_LIMIT = self.ENTRY_LINES * self.ENTRY_COLUMNS

    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)
    self.dirPressed = false
    self.list = {}
    if self.fullDungeon then
        self.list = REC_LIST.compileFullDungeonList(zone, segment)
    else
        self.list = REC_LIST.compileFloorList()
    end
    self.page = 0
    self.PAGE_MAX = (#self.list+1)//self.ENTRY_LIMIT

    self:DrawMenu()
end

function RecruitmentListMenu:DrawMenu()
    --Standard menu divider. Reuse this whenever you need a menu divider at the top for a title.
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))

    local title = "Recruitment List"
    --Add page number if it has more than one
    if self.PAGE_MAX>0 then
        title = title.." ("..tostring(self.page+1).."/"..tostring(self.PAGE_MAX+1)..")"
    end
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(title, RogueElements.Loc(16, 8)))

    --how many entries we have populated so far
    local count = 0

    --other helper indexes
    local start_pos = self.page * self.ENTRY_LIMIT
    local end_pos = math.min(start_pos+self.ENTRY_LIMIT, #self.list)
    start_pos = start_pos + 1

    -- add a special message if there are no entries
    if #self.list<1 then
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("No recruits available", RogueElements.Loc(16, 24)))
        return
    end

    if not self.fullDungeon and not REC_LIST.checkFloor() and REC_LIST.hideUnexploredFloorList then
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("You cannot view this list because this is your", RogueElements.Loc(16, 24)))
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("first time reaching this floor.", RogueElements.Loc(16, 38)))
        return
    end

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
        local x = xpad + xdist * col
        local y = ypad + ydist * line
        local text = REC_LIST.colorName(self.list[i].species, self.list[i].mode)
        if self.fullDungeon then
            local loc = REC_LIST.getCurrentMap()
            local maxFloor = SV.Services.RecruitList[loc.zone][loc.segment]
            local text_fl = tostring(self.list[i].min).."F"
            if self.list[i].min ~= self.list[i].max then
                text_fl = text_fl.."-"
                if self.list[i].max > maxFloor then
                    text_fl = text_fl.."??"
                else
                    text_fl = text_fl..tostring(self.list[i].max).."F"
                end
            end
            self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(text_fl, RogueElements.Loc(x, y)))
            x = x+50
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
            if self.page >= self.PAGE_MAX then
                _GAME:SE("Menu/Cancel")
                self.page = self.PAGE_MAX
            else
                self.page = self.page +1
                _GAME:SE("Menu/Skip")
                self:DrawMenu()
            end
            self.dirPressed = true
        end
    elseif input.Direction == RogueElements.Dir8.Left then
        if not self.dirPressed then
            if self.page <= 0 then
                _GAME:SE("Menu/Cancel")
                self.page = 0
            else
                self.page = self.page -1
                _GAME:SE("Menu/Skip")
                self:DrawMenu()
            end
            self.dirPressed = true
        end
    elseif input.Direction == RogueElements.Dir8.None then
        self.dirPressed = false
    end
    -- TODO MANDATORY: FIND OUT IF CHANGE PAGE WORKS
end