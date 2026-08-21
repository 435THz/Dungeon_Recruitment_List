RECRUIT_LIST = {}
--[[
    recruit_list.lua

    This file contains all functions necessary to generate Recruitment Lists for dungeons, as well as
    the routine used to show the list itself
]]--

---@alias MonsterID {Species:string,Form:integer,Skin:string,Gender:any}
---@alias segment_entry {floorsCleared:integer,totalFloors:integer,completed:boolean,name:string}
---@alias zone_order_entry {zone:string,cap:boolean,level:integer,length:integer,name:string}
---@alias fullDungeonSpawn_entry {elements:{data:any,dungeon:{zone:string,segment:integer},range:{min:integer,max:integer}}[],type:string,monster:MonsterID, forms:integer[]?, mode:integer,enabled:boolean,min:integer,max:integer}
---@alias floorSpawn_entry {elements:{data:any,dungeon:{zone:string,segment:integer},range:{min:integer,max:integer}}[],type:string,monster:MonsterID,mode:integer,enabled:boolean}

-- ----------------------------------------------
-- Constants
-- ----------------------------------------------

---@type table<string, string>
RECRUIT_LIST.variants = {}
RECRUIT_LIST.variants.VARIANT_KEY_ALOLA = "VARIANT_ABBR_ALOLA"
RECRUIT_LIST.variants.VARIANT_KEY_GALAR = "VARIANT_ABBR_GALAR"
RECRUIT_LIST.variants.VARIANT_KEY_HISUI = "VARIANT_ABBR_HISUI"
RECRUIT_LIST.variants.VARIANT_KEY_PALDEA = "VARIANT_ABBR_PALDEA"
---@type table<string, table<integer, string>>
RECRUIT_LIST.abbreviations = {}
RECRUIT_LIST.abbreviations.basculegion = {[0]="SPECIES_ABBR_BASCULEGION_0", [1]="SPECIES_ABBR_BASCULEGION_1"}
RECRUIT_LIST.abbreviations.basculin = {[0]="SPECIES_ABBR_BASCULIN_0", [1]="SPECIES_ABBR_BASCULIN_1", [2]="SPECIES_ABBR_BASCULIN_2"}
RECRUIT_LIST.abbreviations.burmy = {[0]="SPECIES_ABBR_BURMY_0", [1]="SPECIES_ABBR_BURMY_1", [2]="SPECIES_ABBR_BURMY_2"}
RECRUIT_LIST.abbreviations.deerling = {[0]="SPECIES_ABBR_DEERLING_0", [1]="SPECIES_ABBR_DEERLING_1", [2]="SPECIES_ABBR_DEERLING_2", [3]="SPECIES_ABBR_DEERLING_3"}
RECRUIT_LIST.abbreviations.deoxys = {[0]="SPECIES_ABBR_DEOXYS_0", [1]="SPECIES_ABBR_DEOXYS_1", [2]="SPECIES_ABBR_DEOXYS_2", [3]="SPECIES_ABBR_DEOXYS_3"}
RECRUIT_LIST.abbreviations.dudunsparce = {[0]="SPECIES_ABBR_DUDUNSPARCE_0", [1]="SPECIES_ABBR_DUDUNSPARCE_1"}
RECRUIT_LIST.abbreviations.flabebe = {[0]="SPECIES_ABBR_FLABEBE_0", [1]="SPECIES_ABBR_FLABEBE_1", [2]="SPECIES_ABBR_FLABEBE_2", [3]="SPECIES_ABBR_FLABEBE_3", [4]="SPECIES_ABBR_FLABEBE_4"}
RECRUIT_LIST.abbreviations.floette = {[0]="SPECIES_ABBR_FLOETTE_0", [1]="SPECIES_ABBR_FLOETTE_1", [2]="SPECIES_ABBR_FLOETTE_2", [3]="SPECIES_ABBR_FLOETTE_3", [4]="SPECIES_ABBR_FLOETTE_4", [5]="SPECIES_ABBR_FLOETTE_5"}
RECRUIT_LIST.abbreviations.florges = {[0]="SPECIES_ABBR_FLORGES_0", [1]="SPECIES_ABBR_FLORGES_1", [2]="SPECIES_ABBR_FLORGES_2", [3]="SPECIES_ABBR_FLORGES_3", [4]="SPECIES_ABBR_FLORGES_4"}
RECRUIT_LIST.abbreviations.gastrodon = {[0]="SPECIES_ABBR_GASTRODON_0", [1]="SPECIES_ABBR_GASTRODON_1"}
RECRUIT_LIST.abbreviations.gourgeist = {[0]="SPECIES_ABBR_GOURGEIST_0", [1]="SPECIES_ABBR_GOURGEIST_1", [2]="SPECIES_ABBR_GOURGEIST_2", [3]="SPECIES_ABBR_GOURGEIST_3"}
RECRUIT_LIST.abbreviations.indeedee = {[0]="SPECIES_ABBR_INDEEDEE_0", [1]="SPECIES_ABBR_INDEEDEE_1"}
RECRUIT_LIST.abbreviations.lycanroc = {[0]="SPECIES_ABBR_LYCANROC_0", [1]="SPECIES_ABBR_LYCANROC_1", [2]="SPECIES_ABBR_LYCANROC_2"}
RECRUIT_LIST.abbreviations.maushold = {[0]="SPECIES_ABBR_MAUSHOLD_0", [1]="SPECIES_ABBR_MAUSHOLD_1"}
RECRUIT_LIST.abbreviations.meowstic = {[0]="SPECIES_ABBR_MEOWSTIC_0", [1]="SPECIES_ABBR_MEOWSTIC_1"}
RECRUIT_LIST.abbreviations.oricorio = {[0]="SPECIES_ABBR_ORICORIO_0", [1]="SPECIES_ABBR_ORICORIO_1", [2]="SPECIES_ABBR_ORICORIO_2", [3]="SPECIES_ABBR_ORICORIO_3"}
RECRUIT_LIST.abbreviations.pumpkaboo = {[0]="SPECIES_ABBR_PUMPKABOO_0", [1]="SPECIES_ABBR_PUMPKABOO_1", [2]="SPECIES_ABBR_PUMPKABOO_2", [3]="SPECIES_ABBR_PUMPKABOO_3"}
RECRUIT_LIST.abbreviations.sawsbuck = {[0]="SPECIES_ABBR_SAWSBUCK_0", [1]="SPECIES_ABBR_SAWSBUCK_1", [2]="SPECIES_ABBR_SAWSBUCK_2", [3]="SPECIES_ABBR_SAWSBUCK_3"}
RECRUIT_LIST.abbreviations.shellos = {[0]="SPECIES_ABBR_SHELLOS_0", [1]="SPECIES_ABBR_SHELLOS_1"}
RECRUIT_LIST.abbreviations.squawkabilly = {[0]="SPECIES_ABBR_SQUAWKABILLY_0", [1]="SPECIES_ABBR_SQUAWKABILLY_1", [2]="SPECIES_ABBR_SQUAWKABILLY_2", [3]="SPECIES_ABBR_SQUAWKABILLY_3"}
RECRUIT_LIST.abbreviations.tauros = {[0]="SPECIES_ABBR_TAUROS_0", [1]="SPECIES_ABBR_TAUROS_1", [2]="SPECIES_ABBR_TAUROS_2", [3]="SPECIES_ABBR_TAUROS_3"}
RECRUIT_LIST.abbreviations.tatsugiri = {[0]="SPECIES_ABBR_TATSUGIRI_0", [1]="SPECIES_ABBR_TATSUGIRI_1", [2]="SPECIES_ABBR_TATSUGIRI_2"}
RECRUIT_LIST.abbreviations.toxtricity = {[0]="SPECIES_ABBR_TOXTRICITY_0", [1]="SPECIES_ABBR_TOXTRICITY_1"}
RECRUIT_LIST.abbreviations.urshifu = {[0]="SPECIES_ABBR_URSHIFU_0", [1]="SPECIES_ABBR_URSHIFU_1"}
RECRUIT_LIST.abbreviations.wormadam = {[0]="SPECIES_ABBR_WORMADAM_0", [1]="SPECIES_ABBR_WORMADAM_1", [2]="SPECIES_ABBR_WORMADAM_2"}
---@type table<string, table<integer|"all"|"group"|"redirect_completion", integer|boolean>>
RECRUIT_LIST.redirects = {}
RECRUIT_LIST.redirects.alcremie =    {all = 0, group = true}
RECRUIT_LIST.redirects.darmanitan =  {[1] = 0, [3] = 2, redirect_completion=true}
RECRUIT_LIST.redirects.furfrou =     {all = 0, group = true}
RECRUIT_LIST.redirects.magearna =    {[1] = 0, group = true}
RECRUIT_LIST.redirects.polteageist = {[1] = 0, group = true}
RECRUIT_LIST.redirects.sinistea =    {[1] = 0, group = true}
RECRUIT_LIST.redirects.vivillon =    {all = 0, group = true}
---@type table<string, boolean>
RECRUIT_LIST.single_species = {}
RECRUIT_LIST.single_species.aegislash = true
RECRUIT_LIST.single_species.arceus = true
RECRUIT_LIST.single_species.castform = true
RECRUIT_LIST.single_species.cherrim = true
RECRUIT_LIST.single_species.cramorant = true
RECRUIT_LIST.single_species.dialga = true
RECRUIT_LIST.single_species.eiscue = true
RECRUIT_LIST.single_species.enamorus = true
RECRUIT_LIST.single_species.eternatus = true
RECRUIT_LIST.single_species.genesect = true
RECRUIT_LIST.single_species.giratina = true
RECRUIT_LIST.single_species.hoopa = true
RECRUIT_LIST.single_species.keldeo = true
RECRUIT_LIST.single_species.kyurem = true
RECRUIT_LIST.single_species.landorus = true
RECRUIT_LIST.single_species.meloetta = true
RECRUIT_LIST.single_species.minior = true
RECRUIT_LIST.single_species.morpeko = true
RECRUIT_LIST.single_species.necrozma = true
RECRUIT_LIST.single_species.ogerpon = true
RECRUIT_LIST.single_species.palafin = true
RECRUIT_LIST.single_species.palkia = true
RECRUIT_LIST.single_species.shaymin = true
RECRUIT_LIST.single_species.sylvally = true
RECRUIT_LIST.single_species.terapagos = true
RECRUIT_LIST.single_species.thundurus = true
RECRUIT_LIST.single_species.tornadus = true
RECRUIT_LIST.single_species.wishiwashi = true
RECRUIT_LIST.single_species.zacian = true
RECRUIT_LIST.single_species.zamazenta = true
RECRUIT_LIST.single_species.zygarde = true

RECRUIT_LIST.hide =                    0
RECRUIT_LIST.unrecruitable_not_seen =  1
RECRUIT_LIST.not_seen =                2
RECRUIT_LIST.extra_not_seen =          3
RECRUIT_LIST.unrecruitable =           4
RECRUIT_LIST.seen =                    5
RECRUIT_LIST.extra_seen =              6
RECRUIT_LIST.obtained =                7
RECRUIT_LIST.extra_obtained =          8
RECRUIT_LIST.obtained_partial =        9
RECRUIT_LIST.extra_obtained_partial =  10

RECRUIT_LIST.FloorNameDropZoneStep = luanet.import_type('PMDC.LevelGen.FloorNameDropZoneStep')
RECRUIT_LIST.TeamSpawnZoneStep = luanet.import_type('RogueEssence.LevelGen.TeamSpawnZoneStep')
RECRUIT_LIST.FeatureUnrecruitable = luanet.import_type('PMDC.LevelGen.MobSpawnUnrecruitable')
RECRUIT_LIST.Unlock = RogueEssence.Data.GameProgress.UnlockState
RECRUIT_LIST.ZoneIndex = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]
RECRUIT_LIST.MonsterIndex = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Monster]

require 'origin.common'
require "recruit_list.menu.recruit.RecruitListMainMenu"

--- -----------------------------------------------
--- SV structure
--- -----------------------------------------------
--- Returns whether the game has been completed or not
--- @return boolean #true if guidmaster_summit.GameCompleted is true, false otherwise
function RECRUIT_LIST.gameCompleted()
    if SV.guildmaster_summit.GameComplete == nil then SV.guildmaster_summit.GameComplete = false end
    return SV.guildmaster_summit.GameComplete
end

--- Returns the current state of Scanner Mode
--- @return boolean #true if scanner mode is enabled, false otherwise
function RECRUIT_LIST.scannerMode()
    SV.Services = SV.Services or {}
    if SV.Services.RecruitList_scanner_mode == nil then SV.Services.RecruitList_scanner_mode = false end -- if true, allows the player to view the summary of any obtained mon's spawn entry
    return SV.Services.RecruitList_scanner_mode
end

--- Toggles the current state of Scanner Mode
function RECRUIT_LIST.toggleScannerMode()
    if RECRUIT_LIST.scannerMode() then SV.Services.RecruitList_scanner_mode = false else
        SV.Services.RecruitList_scanner_mode = true
    end
end

--- Returns the current state of Show Unrecruitable
--- @return boolean #true if show_unrecruitable is true or the game is in dev mode, false otherwise
function RECRUIT_LIST.showUnrecruitable()
    SV.Services = SV.Services or {}
    if SV.Services.RecruitList_show_unrecruitable == nil then SV.Services.RecruitList_show_unrecruitable = false end
    -- always shows unrecruitable in dev mode
    return SV.Services.RecruitList_show_unrecruitable or RogueEssence.DiagManager.Instance.DevMode
end

--- Toggles the current state of Show Unrecruitable
function RECRUIT_LIST.toggleShowUnrecruitable()
    if RECRUIT_LIST.showUnrecruitable() then SV.Services.RecruitList_show_unrecruitable = false else
        SV.Services.RecruitList_show_unrecruitable = true
    end
end

--- Returns the current state of Icon Mode
--- @return boolean #true if icon mode is enabled, false otherwise
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

--- Checks if a zone id corresponds to an existing zone
--- @param zone string the zone id to check for
--- @return boolean #true if the string is a valid zone index, false otherwise
function RECRUIT_LIST.zoneExists(zone)
    return not not RECRUIT_LIST.ZoneIndex:ContainsKey(zone)
end

--- Returns the ZoneEntrySummary associated to the given zone id
--- @param zone string the zone id to check for
--- @return any #the ZoneEntrySummary of the zone
function RECRUIT_LIST.getZoneSummary(zone)
    if RECRUIT_LIST.zoneExists(zone) then
        return RECRUIT_LIST.ZoneIndex:Get(zone)
    end
    return nil
end

--- Initializes the basic dungeon list data structure
function RECRUIT_LIST.generateDungeonListBaseSV()
    SV.Services = SV.Services or {}
    SV.Services.RecruitList = SV.Services.RecruitList or {} --[[@as table<string, table<integer, segment_entry>>]]
end

--- Initializes the data slot for the supplied segment if not already present
--- @param zone string the zone to initialize
--- @param segment integer the segment to initialize
function RECRUIT_LIST.generateDungeonListSV(zone, segment)
    RECRUIT_LIST.generateDungeonListBaseSV()
    if not RECRUIT_LIST.zoneExists(zone) then return end  -- abort if zone does not exist
    SV.Services.RecruitList[zone] = SV.Services.RecruitList[zone] or {}

    -- update old data if present
    local defaultFloor = 0
    if type(SV.Services.RecruitList[zone][segment]) == "number" then
        defaultFloor = SV.Services.RecruitList[zone][segment] --[[@as integer]]
        SV.Services.RecruitList[zone][segment] = nil
    end

    if not SV.Services.RecruitList[zone][segment] then
        if segment < 0 or segment >= _DATA:GetZone(zone).Segments.Count then return end -- abort if segment does not exist
        local segment_data = _DATA:GetZone(zone).Segments[segment]
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

--- Returns the name of the provided segment
--- @param segment_data any a ZoneSegmentBase object
--- @return string #the localized name of the segment, without floor number
function RECRUIT_LIST.build_segment_name(segment_data)
    local segSteps = segment_data.ZoneSteps
    local sub_name = {}
    local exit = false
    -- look for a title property to extract the name from
    for j = 0, segSteps.Count-1, 1 do
        local step = segSteps[j]
        if LUA_ENGINE:TypeOf(step) == luanet.ctype(RECRUIT_LIST.FloorNameDropZoneStep) then
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

--- Updates a specific segment's name. Usually called after changing language.
--- @param zone string the zone that contains the segment to update
--- @param segment integer the segment to update
function RECRUIT_LIST.updateSegmentName(zone, segment)
    if not RECRUIT_LIST.zoneExists(zone) then return end
    local segment_data = _DATA:GetZone(zone).Segments[segment]
    if segment_data == nil then return end

    local name = RECRUIT_LIST.build_segment_name(segment_data)
    SV.Services.RecruitList[zone][segment].name = name
end

--- Returns the basic dungeon list data structure
--- @return table<string, table<integer, segment_entry>>
function RECRUIT_LIST.getDungeonListSV()
    RECRUIT_LIST.generateDungeonListBaseSV()
    return SV.Services.RecruitList
end

--- Returns the number of floors cleared on the provided segment
--- @param zone string the zone that contains the segment to read data from
--- @param segment integer the segment to read data from
---@return integer the number of floors cleared in the segment
function RECRUIT_LIST.getFloorsCleared(zone, segment)
    RECRUIT_LIST.generateDungeonListSV(zone, segment)
    if SV.Services.RecruitList[zone] == nil then return 0 end
    if SV.Services.RecruitList[zone][segment] == nil then return 0 end
    return SV.Services.RecruitList[zone][segment].floorsCleared
end

--- Updates the number of floors cleared on the provided segment
--- if the provided floor number is higher than the currently stored one
--- @param zone string the zone that contains the segment to update
--- @param segment integer the segment to update
--- @param floor integer the new number of completed floors. Only stored if higher than the old one
function RECRUIT_LIST.updateFloorsCleared(zone, segment, floor)
    if RECRUIT_LIST.checkFloor(zone, segment, floor) then
        SV.Services.RecruitList[zone][segment].floorsCleared = floor
    end
end

--- Marks the provided segment as a completed area
--- @param zone string the zone that contains the segment to update
--- @param segment integer the segment to update
function RECRUIT_LIST.markAsCompleted(zone, segment)
    local sv = RECRUIT_LIST.getDungeonListSV()
    if sv[zone] and sv[zone][segment] then
        SV.Services.RecruitList[zone][segment].completed = true
    end
end

--- Checks if the supplied location floor is higher than the highest reached floor in the current segment.
--- if no complete location is supplied then it uses the current location
--- location is a table of properties {string zone, int segment, int floor}
--- @param zone string? the zone that contains the segment to check
--- @param segment integer? the segment to check
--- @param floor integer? the floor to check for
--- @return boolean #true if floor is greater than the segment's stored value
function RECRUIT_LIST.checkFloor(zone, segment, floor)
    if not zone or not segment or not floor then
        local loc = RECRUIT_LIST.getCurrentMap()
        zone = loc.zone
        segment = loc.segment
        floor = loc.floor
    end
    return RECRUIT_LIST.getFloorsCleared(zone, segment) < floor
end

--- Returns a segment's spawn list data structure
--- @param zone string the zone to get
--- @param segment integer the segment to get
--- @return segment_entry|nil #the data associated to the segment, or nil if there is none
function RECRUIT_LIST.getSegmentData(zone, segment)
    RECRUIT_LIST.generateDungeonListSV(zone, segment)
    if SV.Services.RecruitList[zone] == nil then return nil end
    return SV.Services.RecruitList[zone][segment]
end

-- Returns whether or not a segment's spawn list data structure exists
--- @param zone string the zone to check
--- @param segment integer the segment to check
--- @return boolean #true if there is data associated to the segment, false otherwise
function RECRUIT_LIST.segmentDataExists(zone, segment)
    return SV.Services ~= nil and SV.Services.RecruitList ~= nil and SV.Services.RecruitList[zone] ~= nil
            and SV.Services.RecruitList[zone][segment] ~= nil
end


--- Generates the data slot for dungeon order if not already present
function RECRUIT_LIST.generateOrderSV()
    SV.Services = SV.Services or {}
    SV.Services.RecruitList_DungeonOrder = SV.Services.RecruitList_DungeonOrder or {} --[[@as zone_order_entry[] ]]
end

--- Returns the ordered list of all explored dungeons
--- @return zone_order_entry[] #the order list
function RECRUIT_LIST.getDungeonOrder()
    RECRUIT_LIST.generateOrderSV()
    return SV.Services.RecruitList_DungeonOrder
end

--- Checks if the player has visited at list one dungeon segment that contains spawn data
--- @return boolean #true if the dungeon order has at least 1 entry, false otherwise
function RECRUIT_LIST.hasVisitedValidDungeons()
    return #RECRUIT_LIST.getDungeonOrder() > 0
end

--- Adds the supplied dungeon to the ordered list of explored areas if the segment
--- has spawn data and the zone is not already part of the list
--- @param zone string the zone to register
--- @param segment integer the segment to check for
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

--- sort function that sorts dungeons by recommended level and length, leaving reset dungeons always last
--- @param a zone_order_entry a zone order entry
--- @param b zone_order_entry another zone order entry
--- @return boolean #true if ``a`` should be placed in the order before ``b``, false otherwise
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

function RECRUIT_LIST.getMonsterCompletion(species, form)
    if RECRUIT_LIST.single_species[species] then
        return _DATA.Save:GetMonsterUnlock(species)
    elseif RECRUIT_LIST.redirects[species] and RECRUIT_LIST.redirects[species].redirect_completion then
        if RECRUIT_LIST.redirects[species].all then
            return _DATA.Save:GetMonsterUnlock(species)
        elseif RECRUIT_LIST.redirects[species][form] then
            return RECRUIT_LIST.getCompletionRedirect(species, form)
        end
    end
    local monster_summary = RECRUIT_LIST.MonsterIndex:Get(species)
    local form_summary = monster_summary.Forms[form]
    while form_summary.Temporary and form>0 do
        form = form-1
        form_summary = monster_summary.Forms[form]
    end
    return _DATA.Save:GetMonsterFormUnlock(species, form)
end

function RECRUIT_LIST.getCompletionRedirect(species, form)
    local checked = {}
    local completion = _DATA.Save:GetMonsterFormUnlock(species, form)
    local redirect = RECRUIT_LIST.redirects[species]
    checked[form] = true
    form = redirect[form]
    while form and not checked[form] and completion ~= RECRUIT_LIST.Unlock.Completed do
        local compl = _DATA.Save:GetMonsterFormUnlock(species, form)
        if completion == RECRUIT_LIST.Unlock.None or compl == RECRUIT_LIST.Unlock.Completed then
            completion = compl
        end
        checked[form] = true
        form = redirect[form]
    end
end

function RECRUIT_LIST.getMonsterFormName(species, form)
    if RECRUIT_LIST.single_species[species] then return _DATA:GetMonster(species).Name:ToLocal() end
    if RECRUIT_LIST.redirects[species] and RECRUIT_LIST.redirects[species].group then return _DATA:GetMonster(species).Name:ToLocal() end
    if RECRUIT_LIST.redirects[species] and RECRUIT_LIST.redirects[species].all then form = RECRUIT_LIST.redirects[species].all end
    if RECRUIT_LIST.redirects[species] and RECRUIT_LIST.redirects[species][form] then form = RECRUIT_LIST.redirects[species][form] end

    if RECRUIT_LIST.abbreviations[species] and RECRUIT_LIST.abbreviations[species][form] then
        return STRINGS:FormatKey(RECRUIT_LIST.abbreviations[species][form])
    else
        local monster_summary = RECRUIT_LIST.MonsterIndex:Get(species)
        local form_summary = monster_summary.Forms[form]
        while form_summary.Temporary and form>0 do
            form = form-1
            form_summary = monster_summary.Forms[form]
        end
        
        local name = _DATA:GetMonster(species).Forms[form].FormName:ToLocal()
        for p, r in pairs(RECRUIT_LIST.variants) do
            local pattern = STRINGS:FormatKey(p)
            if string.find(name, pattern, 1, true) then
                name = string.gsub(name, pattern, STRINGS:FormatKey(r), 1)
                break
            end
        end
        return name
    end
end

--- returns the current map as a table of properties ``{string zone, int segment, int floor}``
--- @return {zone:string,segment:integer,floor:integer} the current locatioon
function RECRUIT_LIST.getCurrentMap()
    local mapData = {
        zone = _ZONE.CurrentZoneID,
        segment = _ZONE.CurrentMapID.Segment,
        floor = GAME:GetCurrentFloor().ID + 1
    }
    return mapData
end

--- Debug function. Pretty prints tables.
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

--- Checks if the specified dungeon segment has been visited and contains spawn data
--- @param zone string the zone to check for
--- @param segment integer the segment to check for
--- @param segmentData any? the ZoneSegmentBase object associated to the location. It will be loaded if not already.
--- @param includeNotExplored? boolean if true, unexplored segments will also count as valid
--- @return boolean #true if the dungeon has spawn data and either has been visited, or ``includeNotExplored`` is set
function RECRUIT_LIST.isSegmentValid(zone, segment, segmentData, includeNotExplored)
    if not segmentData then --load data now if it was not already done
        if not RECRUIT_LIST.zoneExists(zone) then return false end
        if segment < 0 or segment >= _DATA:GetZone(zone).Segments.Count then return false end
        segmentData = _DATA:GetZone(zone).Segments[segment]
    end

    if not includeNotExplored and (not SV.Services or not SV.Services.RecruitList or not SV.Services.RecruitList[zone] or not SV.Services.RecruitList[zone][segment]) then return false end

    if not includeNotExplored and RECRUIT_LIST.getSegmentData(zone, segment).floorsCleared <= 0 then return false end
    local segSteps = segmentData.ZoneSteps
    for i = 0, segSteps.Count-1, 1 do
        local step = segSteps[i]
        if LUA_ENGINE:TypeOf(step) == luanet.ctype(RECRUIT_LIST.TeamSpawnZoneStep) then
            return true
        end
    end
    return false
end

--- Returns a list of all segments of a zone that have a spawn property and of which
--- at least 1 floor was completed.
--- @param zone string the zone to extract data of
--- @return {id:integer,name:string,completed:boolean,floorsCleared:integer}[] a list of completion data
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
                ---@cast seg_data segment_entry
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

--- Extracts a list of all mons spawnable in a dungeon, then maps them to the display mode that
--- should be used for that mon's name in the menu. Includes only mons that can respawn.
--- @param zone string the zone to generate the list for
--- @param segment integer the segment to generate the list for
--- @return fullDungeonSpawn_entry[] #the list of spawn entries in the currently explored part of the dungeon
function RECRUIT_LIST.compileFullDungeonList(zone, segment)
    --- @type table<string,table<integer,fullDungeonSpawn_entry>>
    local species = {} -- used to compact multiple entries that contain the same species and form
    --- @type table<string, MonsterID>
    local groups = {} -- used to compact multiple entries that use the same species name

    RECRUIT_LIST.generateDungeonListSV(zone, segment)
    local segmentData = _DATA:GetZone(zone).Segments[segment]
    local segSteps = segmentData.ZoneSteps
    local highest = RECRUIT_LIST.getFloorsCleared(zone,segment)
    for i = 0, segSteps.Count-1, 1 do
        local step = segSteps[i]
        if LUA_ENGINE:TypeOf(step) == luanet.ctype(RECRUIT_LIST.TeamSpawnZoneStep) then
            --- @type fullDungeonSpawn_entry[]
            local entry_list = {}

            -- Check Spawns
            local spawnlist = step.Spawns
            for j=0, spawnlist.Count-1, 1 do
                local range = spawnlist:GetSpawnRange(j)
                local spawn = spawnlist:GetSpawn(j).Spawn -- RogueEssence.LevelGen.MobSpawn
                ---@type fullDungeonSpawn_entry
                local entry = {
                    elements = {{
                        data = spawn,
                        dungeon = {zone = zone, segment = segment},
                        range = {
                            min = range.Min+1,
                            max = math.min(range.Max, segmentData.FloorCount)
                        }
                    }},
                    type = "spawn",
                    monster = spawn.BaseForm,
                    mode = RECRUIT_LIST.not_seen, -- defaults to "???". this will be calculated later
                    enabled = false               -- false by default. this will be calculated later
                }
                if RECRUIT_LIST.redirects[spawn.BaseForm.Species] and RECRUIT_LIST.redirects[spawn.BaseForm.Species].group then
                    if groups[spawn.BaseForm.Species] then
                        entry.monster = groups[spawn.BaseForm.Species]
                    else
                        groups[spawn.BaseForm.Species] = entry.monster
                    end
                end
                entry.min = entry.elements[1].range.min
                entry.max = entry.elements[1].range.max
                -- check if the mon is recruitable
                local recruitable = true
                local features = spawn.SpawnFeatures
                for f = 0, features.Count-1, 1 do
                    if LUA_ENGINE:TypeOf(features[f]) == luanet.ctype(RECRUIT_LIST.FeatureUnrecruitable) then
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
                    ---@type fullDungeonSpawn_entry
                    local entry = {
                        elements = {{
                            data = spawn,
                            dungeon = {zone = zone, segment = segment},
                            range = {
                                min = range.Min+1,
                                max = math.min(range.Max, segmentData.FloorCount)
                            }
                        }},
                        type = "spawn",
                        monster = spawn.BaseForm,
                        mode = RECRUIT_LIST.not_seen, -- defaults to "???". this will be calculated later
                        enabled = false               -- false by default. this will be calculated later
                    }
                    if RECRUIT_LIST.redirects[spawn.BaseForm.Species] and RECRUIT_LIST.redirects[spawn.BaseForm.Species].group then
                        if groups[spawn.BaseForm.Species] then
                            entry.monster = groups[spawn.BaseForm.Species]
                        else
                            groups[spawn.BaseForm.Species] = entry.monster
                        end
                    end
                    entry.min = entry.elements[1].range.min
                    entry.max = entry.elements[1].range.max
                    -- check if the mon is recruitable
                    local recruitable = true
                    local features = spawn.SpawnFeatures
                    for f = 0, features.Count-1, 1 do
                        if LUA_ENGINE:TypeOf(features[f]) == luanet.ctype(RECRUIT_LIST.FeatureUnrecruitable) then
                            recruitable = false
                            entry.mode = RECRUIT_LIST.unrecruitable
                        end
                    end
                    if recruitable or RECRUIT_LIST.showUnrecruitable() then
                        table.insert(entry_list, entry)
                    end
                end
            end

            -- Group by species and form
            for _, entry in pairs(entry_list) do
                -- keep only if under explored limit
                if entry.mode > RECRUIT_LIST.hide and entry.min <= highest then
                    species[entry.monster.Species] = species[entry.monster.Species] or {}
                    species[entry.monster.Species][entry.monster.Form] = species[entry.monster.Species][entry.monster.Form] or {}
                    table.insert(species[entry.monster.Species][entry.monster.Form], entry)
                end
            end
        end
    end

    ---@type fullDungeonSpawn_entry[]
    local list = {}     -- final return list

    for _, tbl in pairs(species) do
        for _, entries in pairs(tbl) do
            -- sort form-specific list by first appearance
            table.sort(entries, function (a, b)
                return a.min < b.min
            end)
            ---@type fullDungeonSpawn_entry
            local current = entries[1]

            -- fuse entries whose floor boundaries touch or overlap
            -- put final entries in output list
            if #entries>1 then
                for i = 2, #entries, 1 do
                    local next = entries[i]
                    if current.max+1 >= next.min then
                        current.max = math.max(current.max, next.max)
                        for _, element in pairs(next.elements) do table.insert(current.elements, element) end
                    else
                        table.insert(list, current)
                        current = next
                    end
                end
            end
            table.insert(list, current)
        end
    end

    -- sort output list by min floor, max floor and then dex and form
    table.sort(list, function (a, b)
        if a.min == b.min then
            if a.max == b.max then
                if _DATA:GetMonster(a.monster.Species).IndexNum == _DATA:GetMonster(b.monster.Species).IndexNum then
                    return a.monster.Form < b.monster.Form
                end
                return _DATA:GetMonster(a.monster.Species).IndexNum < _DATA:GetMonster(b.monster.Species).IndexNum
            end
            return a.max < b.max
        end
        return a.min < b.min
    end)

    for _, elem in pairs(list) do
        local unlockState = RECRUIT_LIST.getMonsterCompletion(elem.monster.Species, elem.monster.Form)
        if elem.mode ~= RECRUIT_LIST.unrecruitable then
            -- check if the form has been seen or obtained
            if unlockState == RECRUIT_LIST.Unlock.Discovered then
                elem.mode = RECRUIT_LIST.seen
                elem.enabled = true
            elseif unlockState == RECRUIT_LIST.Unlock.Completed then
                elem.mode = RECRUIT_LIST.obtained
                elem.enabled = true
            end
            if RECRUIT_LIST.redirects[elem.monster.Species] and RECRUIT_LIST.redirects[elem.monster.Species].group then
                elem.mode = -1
                for _, entry in ipairs(elem.elements) do
                    local entryState = RECRUIT_LIST.getMonsterCompletion(entry.data.BaseForm.Species, entry.data.BaseForm.Form)
                    if elem.mode == RECRUIT_LIST.not_seen then
                        if entryState == RECRUIT_LIST.Unlock.Discovered then elem.mode = RECRUIT_LIST.seen
                        elseif entryState == RECRUIT_LIST.Unlock.Completed then
                            elem.mode = RECRUIT_LIST.obtained_partial
                        end
                    elseif elem.mode == RECRUIT_LIST.seen and entryState == RECRUIT_LIST.Unlock.Completed then
                        elem.mode = RECRUIT_LIST.obtained_partial
                    elseif elem.mode == RECRUIT_LIST.obtained and (entryState == RECRUIT_LIST.Unlock.None or entryState == RECRUIT_LIST.Unlock.Discovered) then
                        elem.mode = RECRUIT_LIST.obtained_partial
                    end
                    if elem.mode == RECRUIT_LIST.obtained_partial then break end
                end
            end
        else
            if unlockState == RECRUIT_LIST.Unlock.None then
                elem.mode = RECRUIT_LIST.unrecruitable_not_seen
            else elem.enabled = true end
        end
    end
    return list
end

--- Extracts a list of all mons spawnable and spawned on the current floor and
--- then pairs them to the display mode that should be used for that mon's name in the menu
--- Non-respawning mons are always at the end of the list
--- @return floorSpawn_entry[] #the list of spawn entries and extra characters in the currently explored part of the dungeon
function RECRUIT_LIST.compileFloorList()
    -- abort immediately if we're not inside a dungeon or recruitment is disabled
    if _DATA.Save.NoRecruiting then return {} end
    if RogueEssence.GameManager.Instance.CurrentScene ~= RogueEssence.Dungeon.DungeonScene.Instance then return {} end

    --- @type {groups:table<string,MonsterID>, keys:MonsterID[],entries:table<string,table<integer,{chars:{data:any}|nil,spawn:{data:any}[]|nil,mode:integer,enabled:boolean}>>}
    local list = {
        keys = {},
        entries = {},
        groups = {}
    }

    local map = _ZONE.CurrentMap
    local spawns = map.TeamSpawns

    -- check the current floor's spawn list
    for i = 0, spawns.Count-1, 1 do
        local spawnList = spawns:GetSpawn(i):GetPossibleSpawns()
        for j = 0, spawnList.Count-1, 1 do
            local spawn = spawnList:GetSpawn(j)

            if spawn:CanSpawn() then
                local member = spawn.BaseForm
                local unlockState = RECRUIT_LIST.getMonsterCompletion(member.Species, member.Form)
                local mode = RECRUIT_LIST.not_seen -- default is to "???" respawning mons if unknown
                local enabled = false              -- false by default

                -- check if the mon has been seen or obtained
                if unlockState == RECRUIT_LIST.Unlock.Discovered then
                    mode = RECRUIT_LIST.seen
                    enabled = true
                elseif unlockState == RECRUIT_LIST.Unlock.Completed then
                    mode = RECRUIT_LIST.obtained
                    enabled = true
                end

                -- check if the mon is recruitable
                local features = spawn.SpawnFeatures
                for f = 0, features.Count-1, 1 do
                    if LUA_ENGINE:TypeOf(features[f]) == luanet.ctype(RECRUIT_LIST.FeatureUnrecruitable) then
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
                    list.entries[member.Species] = list.entries[member.Species] or {}
                    if RECRUIT_LIST.redirects[member.Species] and RECRUIT_LIST.redirects[member.Species].group then
                        if list.groups[member.Species] then member = list.groups[member.Species]
                        else list.groups[member.Species] = member end
                    end
                    if not list.entries[member.Species][member.Form] then
                        table.insert(list.keys, member)
                        list.entries[member.Species][member.Form] = {
                            spawn = {{data = spawn}},
                            mode = mode,
                            enabled = enabled
                        }
                    else
                        local entry = list.entries[member.Species][member.Form]
                        table.insert(entry.spawn, { data = spawn })
                        if entry.mode ~= mode then
                            if entry.mode == RECRUIT_LIST.not_seen then
                                if mode == RECRUIT_LIST.seen then entry.mode = RECRUIT_LIST.seen
                                elseif mode == RECRUIT_LIST.obtained then entry.mode = RECRUIT_LIST.obtained_partial end
                            elseif entry.mode == RECRUIT_LIST.seen and mode == RECRUIT_LIST.obtained then
                                entry.mode = RECRUIT_LIST.obtained_partial
                            elseif entry.mode == RECRUIT_LIST.obtained and (mode == RECRUIT_LIST.not_seen or mode == RECRUIT_LIST.seen) then
                                entry.mode = RECRUIT_LIST.obtained_partial
                            end
                        end
                    end
                end
            end
        end
    end

    -- sort spawn list
    table.sort(list.keys, function(a, b)
        if a.Species == b.Species then
            return a.Form < b.Form
        end
        return _DATA:GetMonster(a.Species).IndexNum < _DATA:GetMonster(b.Species).IndexNum
    end)

    -- check all mons on the floor that are not in spawn list
    local teams = map.MapTeams
    for i = 0, teams.Count-1, 1 do
        local team = teams[i].Players
        for j = 0, team.Count-1, 1 do
            local char = team[j]
            local member = char.BaseForm
            local unlockState = RECRUIT_LIST.getMonsterCompletion(member.Species, member.Form)
            local mode = RECRUIT_LIST.extra_not_seen -- default is "???"

            -- check if the mon has been seen or obtained
            if unlockState == RECRUIT_LIST.Unlock.Discovered then
                mode = RECRUIT_LIST.extra_seen
            elseif unlockState == RECRUIT_LIST.Unlock.Completed then
                mode = RECRUIT_LIST.extra_obtained
            elseif RECRUIT_LIST.redirects[member.Species] and RECRUIT_LIST.redirects[member.Species].group and
                    _DATA.Save:GetMonsterUnlock(member.Species) ~= RECRUIT_LIST.Unlock.None then
                mode = RECRUIT_LIST.extra_seen
            end
            -- do not show in recruit list if cannot recruit, no matter the list or mode
            if char.Unrecruitable then mode = RECRUIT_LIST.hide end

            -- add the member and its display mode to the list
            if mode > RECRUIT_LIST.hide then
                if RECRUIT_LIST.redirects[member.Species] and RECRUIT_LIST.redirects[member.Species].group then
                    if list.groups[member.Species] then member = list.groups[member.Species]
                    else list.groups[member.Species] = member end
                end
                list.entries[member.Species] = list.entries[member.Species] or {}
                if not list.entries[member.Species][member.Form] then
                    table.insert(list.keys, member)
                    list.entries[member.Species][member.Form] = {
                        chars = {{data = char}},
                        mode = mode,
                        enabled = true
                    }
                elseif list.entries[member.Species][member.Form].chars then
                    local entry = list.entries[member.Species][member.Form]
                    table.insert(entry.chars, { data = char })
                    if entry.mode ~= mode then
                        if entry.mode == RECRUIT_LIST.extra_seen and mode == RECRUIT_LIST.extra_obtained then
                            entry.mode = RECRUIT_LIST.extra_obtained_partial
                        elseif entry.mode == RECRUIT_LIST.extra_obtained and mode == RECRUIT_LIST.extra_seen then
                            entry.mode = RECRUIT_LIST.extra_obtained_partial
                        end
                    end
                end
            end
        end
    end

    --- @type floorSpawn_entry[]
    local ret = {}
    for _, key in pairs(list.keys) do
        local entryList = list.entries[key.Species][key.Form].spawn
        local entryType = "spawn"
        if entryList == nil then
            entryList = list.entries[key.Species][key.Form].chars
            entryType = "chars"
        end
        local entry = {
            type = entryType,
            elements = entryList --[[@as {data:any}]],
            monster = key,
            mode = list.entries[key.Species][key.Form].mode,
            enabled = list.entries[key.Species][key.Form].enabled
        }
        table.insert(ret,entry)
    end
    return ret
end

--- Checks if the last used version is higher than the supplied one. No parameter is mandatory
--- @param Major integer? the major version number
--- @param Minor integer? the minor version number
--- @param Build integer? the build number
--- @param Revision integer? the revision number
--- @return boolean #true if the last used version is higher than the supplied one, false otherwise
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