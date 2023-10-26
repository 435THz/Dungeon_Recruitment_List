require 'common'

REC_LIST = {}
--[[
    recruit_list.lua

    This file contains all functions necessary to generate Recruitment Lists for dungeons, as well as
    the routine used to show the list itself
]]--

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

REC_LIST.info_list_title = "Recruitment List Info"
REC_LIST.info_colors_title = "Recruitment List Colors"
REC_LIST.info_list = {
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
        "but are not supposed to appear normally. This can",
        "include Monster House members plus any enemy",
        "that simply doesn't respawn after defeat.",
        "See the Color list for more details."
    },
    -- page 3
    {
        "Be careful, however: if on the floor there's a",
        "Pokémon you never met before that is not part",
        "of the floor's spawn list, it will not appear",
        "in the [color=#00FFFF]Recruitment List[color] regardless of",
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
        "This mod comes with a Spoiler Mode that",
        "obscures the current floor's [color=#00FFFF]Recruitment List[color]",
        "during your first visit.",
        "You can toggle it from the Options menu,",
        "accessible only outside of Dungeons."
    }
}
REC_LIST.info_colors = {
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
        "Colors used for Pokémon that do not keep",
        "appearing upon defeat (only shown in floor):",
        "",
        "Never met Pokémon are not shown at all.",
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
-- Returns the current state of Spoiler Mode
function REC_LIST.spoilerMode()
    SV.Services = SV.Services or {}
    SV.Services.RecruitList_spoiler_mode = SV.Services.RecruitList_spoiler_mode or false -- if true, hides the recruit list if it's the player's first time on a floor
    return SV.Services.RecruitList_spoiler_mode
end

-- Initializes the data slot for the supplied segment if not already present
function REC_LIST.generateSV(zone, segment)
    SV.Services = SV.Services or {}
    SV.Services.RecruitList = SV.Services.RecruitList or {}
    SV.Services.RecruitList[zone] = SV.Services.RecruitList[zone] or {}
    SV.Services.RecruitList[zone][segment] = SV.Services.RecruitList[zone][segment] or 0
end

-- Adds the supplied dungeon to the ordered list of explored areas if the section
-- has spawn data and the zone is not already part of the list
function REC_LIST.markAsExplored(zone, segment)
    SV.Services.RecruitList_DungeonOrder = SV.Services.RecruitList_DungeonOrder or {}

    -- sort function that sorts keys by recommended level and length, leaving reset dungeons always last
    local sort = function (a, b)
        -- put level-reset dungeons at the end
        if a.cap ~= b.cap then return b.cap end
        -- order non-level-reset dungeons by ascending recommended level
        if not a.cap and a.level ~= b.level then return a.level < b.level end
        -- order dungeons by ascending length
        if a.length ~= b.length then return not a.length < b.length end
        -- order dungeons alphabetically
        return a.zone < b.zone
    end

    if REC_LIST.isDungeonValid(zone, segment) then
        local zone_data = _DATA:GetZone(zone)
        local len = 100
        if zone_data.summary then len = zone_data.summary.CountedFloors end
        local entry = {
            zone = zone,
            cap = zone_data.LevelCap,
            level = zone_data.Level,
            length = len,
            name = zone_data:GetColoredName()
        }
        for i=1, #SV.Services.RecruitList_DungeonOrder, 1 do
            local other = SV.Services.RecruitList_DungeonOrder[i]
            if entry.zone == other.zone then return end
            if sort(entry, other) then
                table.insert(SV.Services.RecruitList_DungeonOrder, i, entry)
                return
            end
        end
        table.insert(SV.Services.RecruitList_DungeonOrder, entry)
    end
end

-- -----------------------------------------------
-- Functions
-- -----------------------------------------------

-- Checks if the supplied location floor is higher than the highest reached floor in the current segment
-- if no location is supplied then it uses the current location
-- location is a table of properties {string zone, int segment, int floor}
function REC_LIST.checkFloor(loc)
    if not loc then loc = REC_LIST.getCurrentMap() end

    REC_LIST.generateSV(loc.zone, loc.segment)
    return SV.Services.RecruitList[loc.zone][loc.segment] < loc.floor
end

-- Wraps a string with a color bracket corresponding to mode. If mode is 1, the
-- string is replaced with "???" before wrapping
function REC_LIST.colorName(monster, mode)
    local name = _DATA:GetMonster(monster).Name:ToLocal()
    if mode == 1 then name = '???' end
    local color = REC_LIST.colorList[mode]
    return '[color='..color..']'..name..'[color]'
end

-- returns the current map as a table of properties {string zone, int segment, int floor}
function REC_LIST.getCurrentMap()
    local mapData = {
        zone = _ZONE.CurrentZoneID,
        segment = _ZONE.CurrentMapID.Segment,
        floor = GAME:GetCurrentFloor().ID + 1
    }
    return mapData
end

-- Checks if the player has visited at list one dungeon segment that contains spawn data
function REC_LIST.hasVisitedValidDungeons()
    if not SV.Services or not SV.Services.RecruitList_DungeonOrder then return false end
    return #SV.Services.RecruitList_DungeonOrder > 0
end

-- Checks if the specified dungeon segment has been visited and contains spawn data
function REC_LIST.isDungeonValid(zone, segment, segmentData)
    if not segmentData then segmentData = _DATA:GetZone(zone).Segments[segment] end
    if not SV.Services or not SV.Services.RecruitList or not SV.Services.RecruitList[zone] or not SV.Services.RecruitList[zone][segment] then return false end
    if SV.Services.RecruitList[zone][segment] <= 0 then return false end
    local segSteps = segmentData.ZoneSteps
    for i = 0, segSteps.Count-1, 1 do
        local step = segSteps[i]
        if REC_LIST.getClass(step) == "RogueEssence.LevelGen.TeamSpawnZoneStep" then
            return true
        end
    end
    return false
end

-- Returns a list of all segments of a zone that have a spawn property and of which
-- at least 1 floor was completed.
-- Return is a table with properties {int id, string name, int length}
function REC_LIST.getValidSegments(zone)
    local list = {}

    local segments = _DATA:GetZone(zone).Segments
    for i = 0, segments.Count-1, 1 do
        if REC_LIST.isDungeonValid(zone, i, segments[i]) then
            local entry = {
                id = i,
                name = tostring(i),             -- placeholder in case we cannot find a name
                length = segments[i].FloorCount
            }

            -- look for a title property to extract the name from
            local segSteps = segments[i].ZoneSteps
            for j = 0, segSteps.Count-1, 1 do
                local step = segSteps[j]
                if REC_LIST.getClass(step) == "PMDC.LevelGen.FloorNameDropZoneStep" then
                    local name = step.Name:ToLocal()
                    for a in name:gmatch(("[^\r\n]+")) do
                        entry.name = a
                        break
                    end
                    break
                end
            end

            table.insert(list,entry)
        end
    end
    return list
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
    end
    return list
end

-- Extracts a list of all mons spawnable and spawned on the current floor and
-- then pairs them to the display mode that should be used for that mon's name in the menu
-- Non-respawning mons are always at the end of the list
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

-- Returns the class of an object as string. Useful to extract and check C# classes
function REC_LIST.getClass(csobject)
    if not csobject then return "nil" end
    local namet = getmetatable(csobject).__name
    if not namet then return type(csobject) end
    for a in namet:gmatch('([^,]+)') do
        return a
    end
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
    if not self.fullDungeon and REC_LIST.spoilerMode() and REC_LIST.checkFloor() then
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
        local x = xpad + xdist * col
        local y = ypad + ydist * line
        local text = REC_LIST.colorName(self.list[i].species, self.list[i].mode)
        if self.fullDungeon then
            local maxFloor = SV.Services.RecruitList[self.fullDungeon_zone][self.fullDungeon_segment]
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
end

-- -----------------------------------------------
-- Recruitment List Main Menu
-- -----------------------------------------------
-- Main menu for the Recruitment List mod. Accessible only in Ground maps

RecruitMainChoice = Class('RecruitMainChoice')

function RecruitMainChoice:initialize(x)
    assert(self, "RecruitMainChoice:initialize(): self is nil!")

    -- set up option 1
    local text1 = "List"
    local enabled1 = true
    local fn1 = function() _MENU:AddMenu(RecruitmentListMenu:new("Recruitment List").menu, false) end
    -- set up option 4
    local enabled4 = false

    -- adjust if not in dungeon
    if RogueEssence.GameManager.Instance.CurrentScene ~= RogueEssence.Dungeon.DungeonScene.Instance then
        text1 = "Dungeon"
        enabled1 = REC_LIST.hasVisitedValidDungeons()
        fn1 = function() _MENU:AddMenu(RecruitDungeonChoice:new().menu, false) end
        enabled4 = true
    end

    local options = {
        {text1, enabled1, fn1},
        {"Info",   true, function() _MENU:AddMenu(RecruitTextShowMenu:new(REC_LIST.info_list_title, REC_LIST.info_list).menu, false) end},
        {"Colors", true, function() _MENU:AddMenu(RecruitTextShowMenu:new(REC_LIST.info_colors_title, REC_LIST.info_colors).menu, false) end},
        {"Options", enabled4, function() _MENU:AddMenu(RecruitOptionsChoice:new(x, 46).menu, true) end}
    }
    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(x, 46, 64, options, 0, function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end)
end

-- -----------------------------------------------
-- Recruitment List Colors Menu
-- -----------------------------------------------
-- Explains the various colors to the player
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
            if self.page <= 1 then
                _GAME:SE("Menu/Cancel")
                self.page = 1
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
end

-- -----------------------------------------------
-- Recruitment List Main Menu
-- -----------------------------------------------
-- Main menu for the Recruitment List mod. Accessible only in Ground maps

RecruitOptionsChoice = Class('RecruitOptionsChoice')

function RecruitOptionsChoice:initialize(x, y)
    assert(self, "RecruitOptionsChoice:initialize(): self is nil!")

    self.parent_bounds = {
        x = x,
        y = y
    }
    local xx = self.parent_bounds.x+70
    local yy = self.parent_bounds.y+14*3
    local spoiler = "Off"
    if REC_LIST.spoilerMode() then spoiler = "[color=#FFFF00]On[color]" end
    local text = "Spoiler Mode: "..spoiler
    local options = {
        {text, true, function() self:ToggleSpoilerMode() end}
    }
    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(xx,yy, 64, options, 0, function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end)
end

function RecruitOptionsChoice:ToggleSpoilerMode()
    if REC_LIST.spoilerMode() then SV.Services.RecruitList_spoiler_mode = false
    else SV.Services.RecruitList_spoiler_mode = true
    end
    _MENU:RemoveMenu()
    _MENU:AddMenu(RecruitOptionsChoice:new(self.parent_bounds.x, self.parent_bounds.y).menu, true)
end


-- -----------------------------------------------
-- Recruitment List Dungeon Choice Menu
-- -----------------------------------------------
-- Menu for choosing what dungeon to visualize the recruit list of

RecruitDungeonChoice = Class('RecruitDungeonChoice')

function RecruitDungeonChoice:initialize()
    local exit_fn = function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end

    self.entries = SV.Services.RecruitList_DungeonOrder

    local choices = {}
    for _,entry in pairs(self.entries) do
        local zone_name = entry.name
        table.insert(choices, RogueEssence.Menu.MenuTextChoice(zone_name, function() self:chooseNextMenu(entry.zone) end))
    end

    local choices_array = luanet.make_array(RogueEssence.Menu.MenuTextChoice,choices)
    self.menu = RogueEssence.Menu.CustomMultiPageMenu(RogueElements.Loc(16,16), 128, "Dungeons", choices_array, 0, 10, exit_fn, exit_fn)
end

function RecruitDungeonChoice:chooseNextMenu(zone)
    local segments = REC_LIST.getValidSegments(zone)
    if #segments < 2 then
        local segment = segments[1]
        local title = "[color=#FFC663]"..segment.name
        local max_fl = SV.Services.RecruitList[zone][segment.id]
        if max_fl < segment.length then
            title = title.." (Up to "..max_fl.."F)"
        end
        title = title.."[color]"
        _MENU:AddMenu(RecruitmentListMenu:new(title, zone, segment.id).menu, false)
    else
        _MENU:AddMenu(RecruitSegmentChoice:new(zone, segments).menu, true)
    end
end

-- -----------------------------------------------
-- Recruitment List Dungeon Segment Menu
-- -----------------------------------------------
-- Menu for choosing what segment of a specific dungeon to visualize the recruit list of
-- only shown if the chosen dungeon has more than 1 valid explored segments

RecruitSegmentChoice = Class('RecruitSegmentChoice')

function RecruitSegmentChoice:initialize(zone, segments)
    assert(self, "RecruitSegmentChoice:initialize(): self is nil!")
    local options = {}

    for _,segment in pairs(segments) do
        local text = segment.name
        local title = "[color=#FFC663]"..text
        local max_fl = SV.Services.RecruitList[zone][segment.id]
        if max_fl < segment.length then
            title = title.." (Up to "..max_fl.."F)"
        end
        title = title.."[color]"
        local func = function() _MENU:AddMenu(RecruitmentListMenu:new(title, zone, segment.id).menu, false) end

        table.insert(options, RogueEssence.Menu.MenuTextChoice("[color=#FFC663]"..text.."[color]", func))
    end

    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(148, 32, 128, options, 0, function() _GAME:SE("Menu/Cancel"); _MENU:RemoveMenu() end)
end