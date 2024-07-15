--[[
    Example Service
    
    This is an example to demonstrate how to use the BaseService class to implement a game service.
    
    **NOTE:** After declaring you service, you have to include your package inside the main.lua file!
]]--
require 'origin.common'
require 'origin.services.baseservice'
require 'recruit_list.recruit_list'

--Declare class MenuTools
local MenuTools = Class('MenuTools', BaseService)

--[[---------------------------------------------------------------
    MenuTools:initialize()
      MenuTools class constructor
---------------------------------------------------------------]]
function MenuTools:initialize()
    BaseService.initialize(self)
    PrintInfo('MenuTools:initialize()')
  end

--[[---------------------------------------------------------------
    MenuTools:OnSaveLoad()
      When the Continue button is pressed this is called!
---------------------------------------------------------------]]
function MenuTools:OnSaveLoad()
    PrintInfo("\n<!> MenuTools: LoadSavedData..")
    if _DATA.Save then
        for i=0, _DATA.Save.Mods.Count-1, 1 do
            local mod = _DATA.Save.Mods[i]
            if mod.Namespace == "enable_mission_board" then
                MenuTools.MissionBoard = true
                break
            end
        end
    end

    local lang = STRINGS:LocaleCode()
    if lang ~= SV.Services.RecruitList_lastLanguage then
        for _, ordered_zone_data in pairs(RECRUIT_LIST.getDungeonOrder()) do
            local zone_id = ordered_zone_data.zone
            ordered_zone_data.name = RECRUIT_LIST.getZoneSummary(zone_id).Name:ToLocal()
            local zone_data = RECRUIT_LIST.getDungeonListSV()[zone_id]
            if zone_data then
                for segment_id, segment_data in pairs(zone_data) do
                    segment_data.name = RECRUIT_LIST.build_segment_name(_DATA:GetZone(zone_id).Segments[segment_id])
                end
            end
        end
        SV.Services.RecruitList_lastLanguage = lang
    end
end

--[[---------------------------------------------------------------
    MenuTools:OnMenuButtonPressed()
      When the main menu button is pressed or the main menu should be enabled this is called!
      This is called as a coroutine.
---------------------------------------------------------------]]
function MenuTools:OnMenuButtonPressed()
    -- TODO: Remove this when the memory leak is fixed or confirmed not a leak
    if MenuTools.MainMenu == nil then
        MenuTools.MainMenu = RogueEssence.Menu.MainMenu()
    end

    MenuTools.MainMenu:SetupChoices()
    local index = 4
    if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
        index = 5
    end
    MenuTools.MainMenu.Choices:RemoveAt(index)
    MenuTools.MainMenu.Choices:Insert(index, RogueEssence.Menu.MenuTextChoice(STRINGS:FormatKey("MENU_OTHERS_TITLE"), function () _MENU:AddMenu(MenuTools:CustomDungeonOthersMenu(), false) end))

    --Custom menu stuff for jobs.
    --Check if we're in a dungeon or not. Only do main menu changes outside of a dungeon.
    if MenuTools.MissionBoard and SV.MissionsEnabled and RogueEssence.GameManager.Instance.CurrentScene ~= RogueEssence.Dungeon.DungeonScene.Instance then
        --not in a dungeon
        --Add Job List option
        local has_missions = MenuTools.HasMissions()
        local job_list_color = Color.Red
        if has_missions then
            job_list_color = Color.White
        end

        MenuTools.MainMenu.Choices:Insert(4, RogueEssence.Menu.MenuTextChoice(Text.FormatKey("MENU_JOBLIST_TITLE"), function () _MENU:AddMenu(BoardMenu:new(COMMON.MISSION_BOARD_TAKEN, nil, MenuTools.MainMenu).menu, false) end, has_missions, job_list_color))
    end

    MenuTools.MainMenu:SetupTitleAndSummary()

    MenuTools.MainMenu:InitMenu()
    TASK:WaitTask(_MENU:ProcessMenuCoroutine(MenuTools.MainMenu))
end

--How many missions are taken? Probably shoulda just had a variable that kept track, but oh well...
function MenuTools.HasMissions()
    if not SV.TakenBoard then return false end
    for i = 1, 8, 1 do
        if SV.TakenBoard[i] and SV.TakenBoard[i].Client ~= "" then
            return true
        end
    end

    return count
end

function MenuTools:CustomDungeonOthersMenu()
    -- TODO: Remove this when the memory leak is fixed or confirmed not a leak
    if MenuTools.OthersMenu == nil then
        MenuTools.OthersMenu = RogueEssence.Menu.OthersMenu()
    end
    local menu = MenuTools.OthersMenu;
    menu:SetupChoices();

    local isGround = RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Ground.GroundScene.Instance
    local enabled = not isGround or not _DATA.Save.NoRecruiting
    local color = Color.White
    if not enabled then color = Color.Red end
    menu.Choices:Insert(1, RogueEssence.Menu.MenuTextChoice("Recruits", function () _MENU:AddMenu(RecruitListMainMenu:new(menu.Bounds.Width+menu.Bounds.X+2).menu, true) end, enabled, color))

    if SV.MissionsEnabled and RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
        menu.Choices:Add(RogueEssence.Menu.MenuTextChoice("Mission Objectives", function () _MENU:AddMenu(DungeonJobList:new().menu, false) end))
    end
    menu:InitMenu();
    return menu
end

--[[---------------------------------------------------------------
    MenuTools:OnDungeonFloorEnd()
      When leaving a dungeon floor this is called.
---------------------------------------------------------------]]
function MenuTools:OnDungeonFloorEnd(_, _)
    assert(self, 'MenuTools:OnDungeonFloorEnd() : self is null!')
    local location = RECRUIT_LIST.getCurrentMap()
    RECRUIT_LIST.generateDungeonListSV(location.zone, location.segment)

    -- update floor count for this location
    RECRUIT_LIST.updateFloorsCleared(location.zone, location.segment, location.floor)
    RECRUIT_LIST.markAsExplored(location.zone, location.segment)
end

--[[---------------------------------------------------------------
    MenuTools:OnUpgrade()
      When version differences are found while loading a save this is called.
---------------------------------------------------------------]]
function MenuTools:OnUpgrade()
    assert(self, 'MenuTools:OnUpgrade() : self is null!')
    PrintInfo("RecruitList =>> Loading version")
    RECRUIT_LIST.version = {Major = 0, Minor = 0, Build = 0, Revision = 0}
    -- get old version
    for i=0, _DATA.Save.Mods.Count-1, 1 do
        local mod = _DATA.Save.Mods[i]
        if mod.Name == "Dungeon Recruitment List" then
            RECRUIT_LIST.version = mod.Version
            break
        end
    end

    --remove spoiler mode leftover data
    if not RECRUIT_LIST.checkMinVersion(3) then
        SV.Services.RecruitList_spoiler_mode = nil
    end

    --hide accidental dev mode message
    if not RECRUIT_LIST.checkMinVersion(2, 3, 1) then
        SV.Services.RecruitList_show_unrecruitable = nil
    end

    -- update dungeon list data
    local list =  RECRUIT_LIST.getDungeonListSV()
    if not RECRUIT_LIST.checkMinVersion(2, 2) then
        SV.Services.RecruitList_DungeonOrder = {}
        for zone, zone_data in pairs(list) do
            for segment, _ in pairs(zone_data) do
                if RECRUIT_LIST.checkMinVersion(2, 0) then
                    RECRUIT_LIST.generateDungeonListSV(zone, segment)
                else
                    RECRUIT_LIST.updateSegmentName(zone, segment)
                end
                RECRUIT_LIST.markAsExplored(zone, segment)
            end
        end
    end

    -- update dungeon order data
    if not RECRUIT_LIST.checkMinVersion(2) then
        local order = RECRUIT_LIST.getDungeonOrder()
        for _, entry in pairs(order) do
            if list[entry.zone] then
                for segment, _ in pairs(list[entry.zone]) do
                    RECRUIT_LIST.markAsExplored(entry.zone, segment)
                end
            end
        end

        -- add all completed dungeons
        for entry in luanet.each(_DATA.Save.DungeonUnlocks) do
            if entry.Value == RogueEssence.Data.GameProgress.UnlockState.Completed and
                    not RECRUIT_LIST.segmentDataExists(entry.Key, 0) then

                local data = RECRUIT_LIST.getSegmentData(entry.Key, 0)
                if data ~= nil then
                    local length = data.totalFloors
                    RECRUIT_LIST.updateFloorsCleared(entry.Key,0, length)
                    RECRUIT_LIST.markAsExplored(entry.Key, 0)
                end
            end
        end
    end

    PrintInfo("RecruitList =>> Loaded version")
end


---Summary
-- Subscribe to all channels this service wants callbacks from
function MenuTools:Subscribe(med)
    med:Subscribe("MenuTools", EngineServiceEvents.LoadSavedData,     function() self.OnSaveLoad(self) end )
    med:Subscribe("MenuTools", EngineServiceEvents.MenuButtonPressed, function() self.OnMenuButtonPressed() end )
    med:Subscribe("MenuTools", EngineServiceEvents.DungeonFloorExit,  function(dungeonloc, result) self.OnDungeonFloorEnd(self, dungeonloc, result) end )
    med:Subscribe("MenuTools", EngineServiceEvents.UpgradeSave,       function(_) self.OnUpgrade(self) end )
end

---Summary
-- un-subscribe to all channels this service subscribed to
function MenuTools:UnSubscribe(_)
end

---Summary
-- The update method is run as a coroutine for each services.
function MenuTools:Update(_)
    --  while(true)
    --    coroutine.yield()
    --  end
end

--Add our service
SCRIPT:AddService("MenuTools", MenuTools:new())
return MenuTools