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
function REC_LIST.colorName(monster, mode)
    local name = _DATA:GetMonster(monster).Name.ToLocal()
    if mode == 1 then name = '???' end
    local color = REC_LIST.colorList[mode]
    return '[color ='..color..']'..name..'[color]'
end

function REC_LIST.getCurrentMap()
    local mapData = {
        zone = _ZONE.CurrentZoneID,
        segment = _ZONE.CurrentMapID.Segment,
        floor = GAME:GetCurrentFloor().ID + 1
    }
    return mapData
end

function REC_LIST.test()
    local list = REC_LIST.compileRecruitList(false)
    for entry, value in pairs(list) do
        print(entry, value)
    end
end

function REC_LIST.compileRecruitList(fullDungeon) --TODO full dungeon list and option
    local location = REC_LIST.getCurrentMap()
    if not location.zone or not location.segment or not location.floor or location.zone<0 or location.floor<0 then
        return {}
    end

    SV.RecruitList = SV.RecruitList or {}
    SV.RecruitList[location.zone] = SV.RecruitList[location.zone] or {}
    SV.RecruitList[location.zone][location.segment] = SV.RecruitList[location.zone][location.segment] or location.floor
    if SV.RecruitList[location.zone][location.segment]< location.floor then
        SV.RecruitList[location.zone][location.segment] = location.floor
    end

    --[[if fullDungeon then
        return REC_LIST.compileFullDungeonList(location)
    else]]--
        return REC_LIST.compileFloorList(location)
    --end
end

--[[
function REC_LIST.compileFullDungeonList(location)
    local list = {}
    local segmentData = _DATA:GetZone(location.zone).Segments[location.segment]
    local floorData = segmentData.Floors[location.floor]
    local segSteps = segmentData.ZoneSteps
    local highest = SV.RecruitList[location.zone][location.segment]

    for i = 0, segSteps.Count-1, 1 do
        local step = segSteps[i]
        if REC_LIST.getClass(step) == "RogueEssence.LevelGen.TeamSpawnZoneStep" then
            local spawnlist = step.Spawns
            for j=0, spawnlist.Count-1, 1 do
                local range = spawnlist:GetSpawnRange(j)
                local spawn = spawnlist:GetSpawn(j).Spawn.BaseForm
                print(tostring(range.Min+1).."F-"..tostring(range.Max).."F: "..spawn.Species..'['..tostring(spawn.Form)..']')
                local entry = {
                    min = range.Min,
                    max = range.Max,
                    species = spawn.Species,
                    form = spawn.Form
                }
                if entry.min < highest then
                    list[entry.min] = list[entry.min] or {}
                    table.insert(list[entry.min], entry)
                end
            end
        end
    end

    for i = 0, highest, 1 do

    end
end
]]--


-- Extracts a list of all mons spawnable and spawned on the current floor and
-- then maps it to the display mode that should be used for that mon's name in the menu
function REC_LIST.compileFloorList()
    local list = {}

    local map = _ZONE.CurrentMap
    local spawns = map.TeamSpawns

    print("  starting...")
    for i = 0, spawns.Count-1, 1 do
        local spawnList = spawns:GetSpawn(i):GetPossibleSpawns()
        for j = 0, spawnList.Count-1, 1 do
            local member = spawnList:GetSpawn(j).BaseForm.Species
            local state = _DATA.Save:GetMonsterUnlock(member)
            local mode = REC_LIST.undiscovered
            print(member)
            if state == RogueEssence.Data.GameProgress.UnlockState.Discovered then
                mode = REC_LIST.discovered
            elseif state == RogueEssence.Data.GameProgress.UnlockState.Completed then
                if _DATA:GetMonster(member).Forms.Count>1 then
                    mode = REC_LIST.obtainedMultiForm
                else
                    mode = REC_LIST.obtained
                end
            end

            -- add the member and its display mode to the list
            if not list[member] then list[member] = mode end
        end
    end
    print("  end of spawn list")

    local teams = map.MapTeams
    for i = 0, teams.Count-1, 1 do
        local team = teams[i].Players
        for j = 0, team.Count-1, 1 do
            local member = team[j].BaseForm.Species
            local state = _DATA.Save:GetMonsterUnlock(member)
            local mode = 0
            print(member)
            if state == RogueEssence.Data.GameProgress.UnlockState.Discovered then
                mode = REC_LIST.extra_discovered
            elseif state == RogueEssence.Data.GameProgress.UnlockState.Completed then
                if _DATA:GetMonster(member).Forms.Count>1 then
                    mode = REC_LIST.extra_obtainedMultiForm
                else
                    mode = REC_LIST.extra_obtained
                end
            end

            -- add the member and its display mode to the list
            if mode>0 and not list[member] then list[member] = mode end
        end
    end
    print("  end of spawned list")

    return list
end

function REC_LIST.getClass(csobject)
    local namet = getmetatable(csobject).__name
    for a in namet:gmatch('([^,]+)') do
        return a
    end
end

function REC_LIST.contains(table, key, value)
    -- if the table does not exist return false
    if not table then return false end

    -- if the key is required
    if key then
        -- if the value is required return whether or not the key-value pair exists
        if value then return table[key] ~= nil and table[key] == value
        -- if the value is omitted return whether or not the key exists
        else return table[key] ~= nil end
    end

    -- if both key and value exist return false
    if value == nil then return false end

    -- if only the value is required look in the list and return true if found, false otherwise
    for _, val in pairs(table) do
        if val == value then return true end
    end
    return false
end


-- -----------------------------------------------
-- Recruitment List Menu
-- -----------------------------------------------
RecruitmentListMenu = Class('RecruitmentListMenu')

function RecruitmentListMenu:initialize()
    assert(self, "RecruitmentListMenu:initialize(): self is nil!")
    self.ENTRY_LINES = 8
    self.ENTRY_COLUMNS = 2
    self.ENTRY_LIMIT = self.ENTRY_LINES * self.ENTRY_COLUMNS

    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)

    self.list = {}
    local ls = compileRecruitList(false)
    for species, mode in pairs(ls) do
        local entry = {
            species = species,
            mode = mode
        }
        table.insert(self.list, entry)
    end
    self.page = 0

    self:DrawMenu()
end

function RecruitmentListMenu:DrawMenu()
    --Standard menu divider. Reuse this whenever you need a menu divider at the top for a title.
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))

    --Standard title. Reuse this whenever a title is needed.
    self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("Recruitment List", RogueElements.Loc(16, 8)))

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
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(text, RogueElements.Loc(x, y)))
        count = count + 1
    end
end

function RecruitmentListMenu:Update(input)
    if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    end
    -- TODO MANDATORY: FIND OUT HOW TO CHANGE PAGE
end