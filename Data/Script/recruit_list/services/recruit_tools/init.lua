--[[
    Example Service
    
    This is an example to demonstrate how to use the BaseService class to implement a game service.
    
    **NOTE:** After declaring you service, you have to include your package inside the main.lua file!
]]--
require 'origin.common'
require 'origin.services.baseservice'
require 'recruit_list.recruit_list'

--Declare class RecruitTools
local RecruitTools = Class('RecruitTools', BaseService)

--[[---------------------------------------------------------------
    RecruitTools:initialize()
      RecruitTools class constructor
---------------------------------------------------------------]]
function RecruitTools:initialize()
    BaseService.initialize(self)
    PrintInfo('RecruitTools:initialize()')
  end

--[[---------------------------------------------------------------
    RecruitTools:OnSaveLoad()
      When the Continue button is pressed this is called!
---------------------------------------------------------------]]
function RecruitTools:OnSaveLoad()
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
    RecruitTools:OnAddMenu(menu)
      When a menu is about to be added to the menu stack this is called!
---------------------------------------------------------------]]
function RecruitTools:OnAddMenu(menu)
    local labels = RogueEssence.Menu.MenuLabel
    if menu:HasLabel() and menu.Label == labels.OTHERS_MENU then

        local isGround = RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Ground.GroundScene.Instance
        local enabled = true
        local color = Color.White
        local choice = RogueEssence.Menu.MenuTextChoice("Recruits", function () _MENU:AddMenu(RecruitListMainMenu:new(menu.Bounds.Width+menu.Bounds.X+2).menu, true) end, enabled, color)
        
        -- put in place of Recruitment Search if present
        local index = menu:GetChoiceIndexByLabel("OTH_RECRUIT")
        if index >0 then
            menu.Choices[index] = choice
        else
            -- put right before Settings if present
            index = menu:GetChoiceIndexByLabel(labels.OTH_SETTINGS)
            -- fall back to either 1 or choices count if the check fails
            if index <0 then index = math.min(1, menu.Choices.Count) end
            menu.Choices:Insert(index, choice)
        end
        menu:InitMenu()
    end
end

--[[---------------------------------------------------------------
    RecruitTools:OnDungeonFloorEnd()
      When leaving a dungeon floor this is called.
---------------------------------------------------------------]]
function RecruitTools:OnDungeonFloorEnd(_, _)
    assert(self, 'RecruitTools:OnDungeonFloorEnd() : self is null!')
    local location = RECRUIT_LIST.getCurrentMap()
    RECRUIT_LIST.generateDungeonListSV(location.zone, location.segment)

    -- update floor count for this location
    RECRUIT_LIST.updateFloorsCleared(location.zone, location.segment, location.floor)
    RECRUIT_LIST.markAsExplored(location.zone, location.segment)
end

--[[---------------------------------------------------------------
    RecruitTools:OnUpgrade()
      When version differences are found while loading a save this is called.
---------------------------------------------------------------]]
function RecruitTools:OnUpgrade()
    assert(self, 'RecruitTools:OnUpgrade() : self is null!')
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
function RecruitTools:Subscribe(med)
    med:Subscribe("RecruitTools", EngineServiceEvents.LoadSavedData,     function() self.OnSaveLoad(self) end )
    med:Subscribe("RecruitTools", EngineServiceEvents.AddMenu,           function(_, args) self.OnAddMenu(self, args[0]) end )
    med:Subscribe("RecruitTools", EngineServiceEvents.DungeonFloorExit,  function(dungeonloc, result) self.OnDungeonFloorEnd(self, dungeonloc, result) end )
    med:Subscribe("RecruitTools", EngineServiceEvents.UpgradeSave,       function(_) self.OnUpgrade(self) end )
end

---Summary
-- un-subscribe to all channels this service subscribed to
function RecruitTools:UnSubscribe(_)
end

---Summary
-- The update method is run as a coroutine for each services.
function RecruitTools:Update(_)
    --  while(true)
    --    coroutine.yield()
    --  end
end

--Add our service
SCRIPT:AddService("RecruitTools", RecruitTools:new())
return RecruitTools