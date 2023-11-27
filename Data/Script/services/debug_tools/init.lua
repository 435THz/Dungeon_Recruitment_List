--[[
    Debug Tools
]]--
require 'common'
require 'services.baseservice'
require 'recruit_list'

--Declare class DebugTools
local DebugTools = Class('DebugTools', BaseService)


--[[---------------------------------------------------------------
    DebugTools:initialize()
      DebugTools class constructor
---------------------------------------------------------------]]
function DebugTools:initialize()
    BaseService.initialize(self)
    PrintInfo('DebugTools:initialize()')
end

--[[---------------------------------------------------------------
    DebugTools:__gc()
      DebugTools class gc method
      Essentially called when the garbage collector collects the service.
	  TODO: Currently causes issues.  wait for Audino to debug later.
  ---------------------------------------------------------------]]
--function DebugTools:__gc()
--  PrintInfo('*****************DebugTools:__gc()')
--end

--[[---------------------------------------------------------------
    DebugTools:OnInit()
      Called on initialization of the script engine by the game!
---------------------------------------------------------------]]
function DebugTools:OnInit()
    assert(self, 'DebugTools:OnInit() : self is null!')
    PrintInfo("\n<!> DebugTools: Init..")
end

--[[---------------------------------------------------------------
    DebugTools:OnDeinit()
      Called on de-initialization of the script engine by the game!
---------------------------------------------------------------]]
function DebugTools:OnDeinit()
    assert(self, 'DebugTools:OnDeinit() : self is null!')
    PrintInfo("\n<!> DebugTools: Deinit..")
end

--[[---------------------------------------------------------------
    DebugTools:OnMenuButtonPressed()
      When the main menu button is pressed or the main menu should be enabled this is called!
      This is called as a coroutine.
---------------------------------------------------------------]]
function DebugTools:OnMenuButtonPressed()
    if DebugTools.MainMenu == nil then
        DebugTools.MainMenu = RogueEssence.Menu.MainMenu()
    end
    DebugTools.MainMenu:SetupChoices()


    local index = 4
    if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
        index = 5
    end
    DebugTools.MainMenu.Choices:RemoveAt(index)
    DebugTools.MainMenu.Choices:Insert(index, RogueEssence.Menu.MenuTextChoice("Others", function () _MENU:AddMenu(DebugTools:CustomDungeonOthersMenu(), false) end))

    DebugTools.MainMenu:SetupTitleAndSummary()
    DebugTools.MainMenu:InitMenu()
    TASK:WaitTask(_MENU:ProcessMenuCoroutine(DebugTools.MainMenu))
end

function DebugTools:CustomDungeonOthersMenu()
    local menu = RogueEssence.Menu.OthersMenu()
    menu:SetupChoices();
    menu.Choices:Insert(1, RogueEssence.Menu.MenuTextChoice("Recruits", function () _MENU:AddMenu(RecruitMainChoice:new(menu.Bounds.Width+menu.Bounds.X+2).menu, true) end))
    menu:InitMenu();
    return menu
end

--[[---------------------------------------------------------------
    DebugTools:OnNewGame()
      When a new save file is loaded this is called!
---------------------------------------------------------------]]
function DebugTools:OnNewGame()
    assert(self, 'DebugTools:OnNewGame() : self is null!')

    for ii = 1, _DATA.Start.Chars.Count, 1 do
        _DATA.Save:RogueUnlockMonster(_DATA.Start.Chars[ii-1].ID.Species)
    end

    if _DATA.Save.ActiveTeam.Players.Count > 0 then
        local talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
        _DATA.Save.ActiveTeam.Players[0].ActionEvents:Add(talk_evt)
        _DATA.Save:RegisterMonster(_DATA.Save.ActiveTeam.Players[0].BaseForm.Species)

        _DATA.Save.ActiveTeam:SetRank("normal")
        if not GAME:InRogueMode() then
            _DATA.Save.ActiveTeam.Bank = 1000
        end
        SV.General.Starter = _DATA.Save.ActiveTeam.Players[0].BaseForm
    else
        PrintInfo("\n<!> DebugTools: Preparing debug save file")
        _DATA.Save.ActiveTeam:SetRank("normal")
        _DATA.Save.ActiveTeam.Name = "Debug"
        _DATA.Save.ActiveTeam.Money = 1000
        _DATA.Save.ActiveTeam.Bank = 1000000

        local mon_id = RogueEssence.Dungeon.MonsterID("bulbasaur", 0, "normal", Gender.Male)
        _DATA.Save.ActiveTeam.Players:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 50, "", 0))
        mon_id = RogueEssence.Dungeon.MonsterID("charmander", 0, "normal", Gender.Male)
        _DATA.Save.ActiveTeam.Players:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 50, "", 0))
        mon_id = RogueEssence.Dungeon.MonsterID("squirtle", 0, "normal", Gender.Male)
        _DATA.Save.ActiveTeam.Players:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 50, "", 0))


        local talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
        _DATA.Save.ActiveTeam.Players[0].ActionEvents:Add(talk_evt)
        talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
        _DATA.Save.ActiveTeam.Players[1].ActionEvents:Add(talk_evt)
        talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
        _DATA.Save.ActiveTeam.Players[2].ActionEvents:Add(talk_evt)

        _DATA.Save.ActiveTeam.Leader.IsFounder = true

        _DATA.Save:UpdateTeamProfile(true)

        local dungeon_keys = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]:GetOrderedKeys(false)
        for ii = 0, dungeon_keys.Count-1 ,1 do
            GAME:UnlockDungeon(dungeon_keys[ii])
        end

        --for ii = 900, 2370, 1 do
        --  GAME:GivePlayerStorageItem(ii)
        --  SV.unlocked_trades[ii] = true
        --end

        --for ii = 1, 10000, 1 do
        --  mon_id = RogueEssence.Dungeon.MonsterID("bulbasaur", 0, "normal", Gender.Male)
        --  _DATA.Save.ActiveTeam.Assembly:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 50, "", 0))
        --end

        if SV.base_camp ~= nil then
            SV.base_camp.ExpositionComplete = true
            SV.base_camp.IntroComplete = true
        end
        if SV.test_grounds ~= nil then
            SV.test_grounds.DemoComplete = true
        end
        SV.General.Starter = _DATA.Save.ActiveTeam.Players[0].BaseForm
    end
end


--[[---------------------------------------------------------------
    DebugTools:OnLossPenalty()
      Called when the player fails a dungeon in main progress
  ---------------------------------------------------------------]]
function DebugTools:OnLossPenalty(save)
    assert(self, 'DebugTools:OnLossPenalty() : self is null!')

    --remove money
    save.ActiveTeam.Money = 0
    local inv_count = save.ActiveTeam:GetInvCount() - 1

    --remove bag items
    for i = inv_count, 0, -1 do
        local entry = _DATA:GetItem(save.ActiveTeam:GetInv(i).ID)
        if not entry.CannotDrop then
            save.ActiveTeam:RemoveFromInv(i)
        end
    end

    --remove equips
    local player_count = save.ActiveTeam.Players.Count
    for i = 0, player_count - 1, 1 do
        local player = save.ActiveTeam.Players[i]
        if player.EquippedItem.ID ~= '' and player.EquippedItem.ID ~= nil then
            local entry = _DATA:GetItem(player.EquippedItem.ID)
            if not entry.CannotDrop then
                player:SilentDequipItem()
            end
        end
    end
end

--[[---------------------------------------------------------------
    DebugTools:OnDungeonFloorEnd()
      When leaving a dungeon floor this is called.
---------------------------------------------------------------]]
function DebugTools:OnDungeonFloorEnd(ignore, ignore2)
    assert(self, 'DebugTools:OnDungeonFloorEnd() : self is null!')
    local location = RECRUIT_LIST.getCurrentMap()
    RECRUIT_LIST.generateDungeonListSV(location.zone, location.segment)

    -- update floor count for this location
    RECRUIT_LIST.updateFloorsCleared(location.zone, location.segment, location.floor)
    RECRUIT_LIST.markAsExplored(location.zone, location.segment)
end

--[[---------------------------------------------------------------
    DebugTools:OnUpgrade()
      When version differences are found while loading a save this is called.
---------------------------------------------------------------]]
function DebugTools:OnUpgrade()
    assert(self, 'DebugTools:OnUpgrade() : self is null!')
    PrintInfo("RecruitList =>> Loading version")
    local old_version = {Major = 0, Minor = 0}
    -- get old version
    for i=0, _DATA.Save.Mods.Count-1, 1 do
        local mod = _DATA.Save.Mods[i]
        if mod.Name == "Dungeon Recruitment List" then
            old_version = mod.Version
            break
        end
    end

    -- update dungeon list data
    local list =  RECRUIT_LIST.getDungeonListSV()
    if old_version.Major < 2 or (old_version.Major == 2 and old_version.Minor < 2) then
        SV.Services.RecruitList_DungeonOrder = {}
        for zone, zone_data in pairs(list) do
            for segment, _ in pairs(zone_data) do
                if old_version.Major < 2 or (old_version.Major == 2 and old_version.Minor < 0) then
                    RECRUIT_LIST.generateDungeonListSV(zone, segment)
                else
                    RECRUIT_LIST.updateSegmentName(zone, segment)
                end
                RECRUIT_LIST.markAsExplored(zone, segment)
            end
        end
    end

    -- update dungeon order data
    if old_version.Major < 2 or (old_version.Major == 2 and old_version.Minor < 0) then
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
                local length = RECRUIT_LIST.getSegmentData(entry.Key, 0).totalFloors
                RECRUIT_LIST.updateFloorsCleared(entry.Key,0, length)
                RECRUIT_LIST.markAsExplored(entry.Key, 0)
            end
        end
    end

    PrintInfo("RecruitList =>> Loaded version")
end


---Summary
-- Subscribe to all channels this service wants callbacks from
function DebugTools:Subscribe(med)
    med:Subscribe("DebugTools", EngineServiceEvents.Init,              function() self.OnInit(self) end )
    med:Subscribe("DebugTools", EngineServiceEvents.Deinit,            function() self.OnDeinit(self) end )
    med:Subscribe("DebugTools", EngineServiceEvents.MenuButtonPressed, function() self.OnMenuButtonPressed() end )
    med:Subscribe("DebugTools", EngineServiceEvents.NewGame,           function() self.OnNewGame(self) end )
    med:Subscribe("DebugTools", EngineServiceEvents.LossPenalty,       function(_, args) self.OnLossPenalty(self, args[0]) end )
    med:Subscribe("DebugTools", EngineServiceEvents.DungeonFloorExit,  function(dungeonloc, result) self.OnDungeonFloorEnd(self, dungeonloc, result) end )
    med:Subscribe("DebugTools", EngineServiceEvents.UpgradeSave,       function(mapid) self.OnUpgrade(self) end )
    --  med:Subscribe("DebugTools", EngineServiceEvents.GraphicsUnload,    function() self.OnGraphicsUnload(self) end )
    --  med:Subscribe("DebugTools", EngineServiceEvents.Restart,           function() self.OnRestart(self) end )
end

---Summary
-- un-subscribe to all channels this service subscribed to
function DebugTools:UnSubscribe(med)
end

---Summary
-- The update method is run as a coroutine for each services.
function DebugTools:Update(gtime)
    --  while(true)
    --    coroutine.yield()
    --  end
end

--Add our service
SCRIPT:AddService("DebugTools", DebugTools:new())
return DebugTools